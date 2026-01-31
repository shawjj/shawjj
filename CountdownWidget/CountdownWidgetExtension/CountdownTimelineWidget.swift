import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct CountdownEntry: TimelineEntry {
    let date: Date
    let countdown: CountdownItem?
    let allCountdowns: [CountdownItem]
}

struct CountdownProvider: IntentTimelineProvider {
    typealias Entry = CountdownEntry
    typealias Intent = SelectCountdownIntent

    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            countdown: CountdownItem(name: "My Event", targetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!),
            allCountdowns: []
        )
    }

    func getSnapshot(for configuration: SelectCountdownIntent, in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let countdowns = loadCountdowns()
        let selected = selectedCountdown(from: countdowns, intent: configuration)
        completion(CountdownEntry(date: Date(), countdown: selected, allCountdowns: countdowns))
    }

    func getTimeline(for configuration: SelectCountdownIntent, in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let countdowns = loadCountdowns()
        let selected = selectedCountdown(from: countdowns, intent: configuration)
        let entry = CountdownEntry(date: Date(), countdown: selected, allCountdowns: countdowns)

        // Refresh at midnight so the day count updates
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func loadCountdowns() -> [CountdownItem] {
        guard let defaults = UserDefaults(suiteName: CountdownStore.appGroupID),
              let data = defaults.data(forKey: "countdowns"),
              let items = try? JSONDecoder().decode([CountdownItem].self, from: data) else {
            return []
        }
        return items
    }

    private func selectedCountdown(from countdowns: [CountdownItem], intent: SelectCountdownIntent) -> CountdownItem? {
        if let selectedID = intent.countdown?.identifier,
           let uuid = UUID(uuidString: selectedID),
           let match = countdowns.first(where: { $0.id == uuid }) {
            return match
        }
        // Default to the nearest upcoming countdown
        return countdowns
            .sorted(by: { $0.targetDate < $1.targetDate })
            .first
    }
}

// MARK: - Widget Definition

struct CountdownTimelineWidget: Widget {
    let kind = "CountdownWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectCountdownIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Count down the days to your event.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Views

struct CountdownWidgetView: View {
    let entry: CountdownEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(countdown: entry.countdown)
            case .systemMedium:
                MediumWidgetView(countdown: entry.countdown)
            case .systemLarge:
                LargeWidgetView(countdowns: entry.allCountdowns)
            default:
                SmallWidgetView(countdown: entry.countdown)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Small

struct SmallWidgetView: View {
    let countdown: CountdownItem?

    var body: some View {
        if let countdown {
            VStack(spacing: 8) {
                Text(countdown.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if countdown.isToday {
                    Text("Today!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                } else {
                    Text("\(countdown.daysRemaining)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text(countdown.daysRemaining == 1 ? "day" : "days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("No Countdowns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Medium

struct MediumWidgetView: View {
    let countdown: CountdownItem?

    var body: some View {
        if let countdown {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    if countdown.isToday {
                        Text("Today!")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(countdown.daysRemaining)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                        Text(countdown.daysRemaining == 1 ? "day" : "days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 80)

                VStack(alignment: .leading, spacing: 6) {
                    Text(countdown.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(countdown.targetDate, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("No Countdowns")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Large

struct LargeWidgetView: View {
    let countdowns: [CountdownItem]

    private var sorted: [CountdownItem] {
        countdowns.sorted(by: { $0.targetDate < $1.targetDate })
    }

    var body: some View {
        if countdowns.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No Countdowns")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Open the app to add one")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Countdowns")
                    .font(.headline)
                    .padding(.bottom, 8)

                ForEach(Array(sorted.prefix(5).enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(item.targetDate, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if item.isToday {
                            Text("Today!")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(item.daysRemaining)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                                Text(item.daysRemaining == 1 ? "day" : "days")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

import AppIntents
import Foundation

struct CountdownEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Countdown")
    static var defaultQuery = CountdownEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CountdownEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CountdownEntity] {
        let all = loadAll()
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CountdownEntity] {
        loadAll()
    }

    func defaultResult() async -> CountdownEntity? {
        loadAll().first
    }

    private func loadAll() -> [CountdownEntity] {
        guard let defaults = UserDefaults(suiteName: CountdownStore.appGroupID),
              let data = defaults.data(forKey: "countdowns"),
              let items = try? JSONDecoder().decode([CountdownItem].self, from: data) else {
            return []
        }
        return items
            .sorted(by: { $0.targetDate < $1.targetDate })
            .map { CountdownEntity(id: $0.id.uuidString, name: $0.name) }
    }
}

struct SelectCountdownIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Countdown"
    static var description: IntentDescription = "Choose which countdown to display"

    @Parameter(title: "Countdown")
    var countdown: CountdownEntity?
}

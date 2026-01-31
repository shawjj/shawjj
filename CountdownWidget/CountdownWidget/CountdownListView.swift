import SwiftUI

struct CountdownListView: View {
    @EnvironmentObject var store: CountdownStore
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if store.countdowns.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("No Countdowns")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Tap + to create your first countdown")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.countdowns.sorted(by: { $0.targetDate < $1.targetDate })) { item in
                            NavigationLink(destination: EditCountdownView(item: item)) {
                                CountdownRow(item: item)
                            }
                        }
                        .onDelete { offsets in
                            let sorted = store.countdowns.sorted(by: { $0.targetDate < $1.targetDate })
                            let idsToDelete = offsets.map { sorted[$0].id }
                            store.countdowns.removeAll { idsToDelete.contains($0.id) }
                        }
                    }
                }
            }
            .navigationTitle("Countdowns")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCountdownView()
            }
        }
    }
}

struct CountdownRow: View {
    let item: CountdownItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.targetDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.isToday {
                Text("Today!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            } else {
                VStack(alignment: .trailing) {
                    Text("\(item.daysRemaining)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text(item.daysRemaining == 1 ? "day" : "days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI

struct EditCountdownView: View {
    @EnvironmentObject var store: CountdownStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var targetDate: Date
    private let itemID: UUID

    init(item: CountdownItem) {
        self.itemID = item.id
        _name = State(initialValue: item.name)
        _targetDate = State(initialValue: item.targetDate)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
            }
            Section("Date") {
                DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            Section {
                Button("Delete Countdown", role: .destructive) {
                    store.countdowns.removeAll { $0.id == itemID }
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Countdown")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let updated = CountdownItem(id: itemID, name: name.trimmingCharacters(in: .whitespaces), targetDate: targetDate)
                    store.update(updated)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

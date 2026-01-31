import SwiftUI

struct AddCountdownView: View {
    @EnvironmentObject var store: CountdownStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Vacation, Birthday", text: $name)
                }
                Section("Date") {
                    DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("New Countdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = CountdownItem(name: name.trimmingCharacters(in: .whitespaces), targetDate: targetDate)
                        store.add(item)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

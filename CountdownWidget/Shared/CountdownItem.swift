import Foundation

struct CountdownItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var targetDate: Date

    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: today, to: target)
        return max(components.day ?? 0, 0)
    }

    var isToday: Bool {
        daysRemaining == 0
    }

    init(id: UUID = UUID(), name: String, targetDate: Date) {
        self.id = id
        self.name = name
        self.targetDate = targetDate
    }
}

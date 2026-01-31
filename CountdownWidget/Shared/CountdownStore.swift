import Foundation
import WidgetKit

class CountdownStore: ObservableObject {
    static let shared = CountdownStore()
    static let appGroupID = "group.com.shawjj.countdownwidget"
    private static let storageKey = "countdowns"

    @Published var countdowns: [CountdownItem] = [] {
        didSet { save() }
    }

    init() {
        load()
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }

    func load() {
        guard let data = defaults?.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data) else {
            countdowns = []
            return
        }
        countdowns = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(countdowns) else { return }
        defaults?.set(data, forKey: Self.storageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func add(_ item: CountdownItem) {
        countdowns.append(item)
    }

    func delete(at offsets: IndexSet) {
        countdowns.remove(atOffsets: offsets)
    }

    func update(_ item: CountdownItem) {
        if let index = countdowns.firstIndex(where: { $0.id == item.id }) {
            countdowns[index] = item
        }
    }
}

import SwiftUI

@main
struct CountdownWidgetApp: App {
    @StateObject private var store = CountdownStore.shared

    var body: some Scene {
        WindowGroup {
            CountdownListView()
                .environmentObject(store)
        }
    }
}

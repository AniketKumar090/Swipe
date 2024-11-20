import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        NavigationView {
            HomeView()
        }.navigationViewStyle(.stack)
    }
}


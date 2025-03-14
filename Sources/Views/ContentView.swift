import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ProjectsListView()
                .navigationTitle("My Collages")
        }
    }
}

#Preview {
    ContentView()
} 
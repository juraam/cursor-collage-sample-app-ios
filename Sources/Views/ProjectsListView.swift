import SwiftUI

struct ProjectsListView: View {
    @StateObject private var projectManager = ProjectManager()
    @State private var showingNewProject = false
    
    var body: some View {
        List {
            ForEach(projectManager.projects) { project in
                NavigationLink(destination: EditorView(project: project, projectManager: projectManager)) {
                    ProjectRow(project: project)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingNewProject = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NavigationStack {
                let newProject = Project(name: "New Project", thumbnail: nil, lastModified: Date())
                EditorView(project: newProject, projectManager: projectManager)
                    .onAppear {
                        projectManager.addProject(newProject)
                    }
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack {
            if let thumbnail = project.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading) {
                Text(project.name)
                    .font(.headline)
                Text(project.lastModified.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProjectsListView()
    }
} 
import SwiftUI

class ProjectManager: ObservableObject {
    @Published var projects: [Project] = []
    private let fileManager = FileManager.default
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    init() {
        loadProjects()
    }
    
    private func loadProjects() {
        let projectsURL = documentsPath.appendingPathComponent("projects.json")
        
        guard let data = try? Data(contentsOf: projectsURL),
              let decodedProjects = try? JSONDecoder().decode([Project].self, from: data) else {
            return
        }
        
        projects = decodedProjects
    }
    
    func saveProjects() {
        let projectsURL = documentsPath.appendingPathComponent("projects.json")
        
        guard let data = try? JSONEncoder().encode(projects) else {
            return
        }
        
        try? data.write(to: projectsURL)
    }
    
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
    }
    
    func deleteProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.remove(at: index)
            // Delete project data file
            let projectURL = projectDataURL(for: project)
            try? fileManager.removeItem(at: projectURL)
            saveProjects()
        }
    }
    
    private func projectDataURL(for project: Project) -> URL {
        documentsPath.appendingPathComponent("\(project.id.uuidString).json")
    }
    
    func loadProject(_ project: Project) -> (items: [CollageItem], background: Color, backgroundImage: UIImage?, format: CanvasFormat)? {
        let projectURL = projectDataURL(for: project)
        
        guard let data = try? Data(contentsOf: projectURL),
              let projectData = try? JSONDecoder().decode(ProjectData.self, from: data) else {
            return nil
        }
        
        return (projectData.items, projectData.background, projectData.backgroundImage, projectData.format)
    }
    
    func saveProject(_ project: Project, items: [CollageItem], background: Color, backgroundImage: UIImage?, format: CanvasFormat) {
        let projectURL = projectDataURL(for: project)
        let projectData = ProjectData(items: items, background: background, backgroundImage: backgroundImage, format: format)
        
        guard let data = try? JSONEncoder().encode(projectData) else {
            return
        }
        
        try? data.write(to: projectURL)
        
        // Update project's lastModified date and thumbnail
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].lastModified = Date()
            // You might want to generate a thumbnail from the first image or the entire collage
            if let firstImage = items.first(where: { $0.type == .photo })?.image {
                projects[index].thumbnail = firstImage
            }
            saveProjects()
        }
    }
}

struct ProjectData: Codable {
    struct CodableImage: Codable {
        let imageData: Data
        
        init(_ image: UIImage) throws {
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw EncodingError.invalidValue(image, EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to encode image to JPEG"))
            }
            self.imageData = data
        }
        
        func toUIImage() throws -> UIImage {
            guard let image = UIImage(data: imageData) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to create image from data"))
            }
            return image
        }
    }
    
    let items: [CollageItem]
    let background: Color
    let format: CanvasFormat
    private let backgroundImageData: CodableImage?
    
    var backgroundImage: UIImage? {
        try? backgroundImageData?.toUIImage()
    }
    
    init(items: [CollageItem], background: Color, backgroundImage: UIImage?, format: CanvasFormat) {
        self.items = items
        self.background = background
        self.format = format
        self.backgroundImageData = try? backgroundImage.map(CodableImage.init)
    }
    
    enum CodingKeys: String, CodingKey {
        case items
        case background
        case backgroundImageData
        case format
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([CollageItem].self, forKey: .items)
        background = try container.decode(Color.self, forKey: .background)
        format = try container.decode(CanvasFormat.self, forKey: .format)
        backgroundImageData = try container.decodeIfPresent(CodableImage.self, forKey: .backgroundImageData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(background, forKey: .background)
        try container.encode(format, forKey: .format)
        try container.encodeIfPresent(backgroundImageData, forKey: .backgroundImageData)
    }
}

// Extend Color to be Codable
extension Color: Codable {
    struct ColorComponents: Codable {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let components = ColorComponents(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            opacity: Double(alpha)
        )
        try container.encode(components)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let components = try container.decode(ColorComponents.self)
        
        self = Color(.sRGB,
                    red: components.red,
                    green: components.green,
                    blue: components.blue,
                    opacity: components.opacity)
    }
}

// Remove UIImage Codable extension since we're handling it through CodableImage
extension UIImage {
    func encoded() throws -> Data {
        guard let data = self.jpegData(compressionQuality: 0.8) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: [],
                debugDescription: "Failed to encode image to JPEG"))
        }
        return data
    }
    
    static func decoded(from data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Failed to create image from data"))
        }
        return image
    }
} 
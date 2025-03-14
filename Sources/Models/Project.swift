import SwiftUI

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var lastModified: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, name, lastModified
    }
    
    var thumbnail: UIImage?
    
    init(id: UUID = UUID(), name: String, thumbnail: UIImage?, lastModified: Date) {
        self.id = id
        self.name = name
        self.thumbnail = thumbnail
        self.lastModified = lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        thumbnail = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(lastModified, forKey: .lastModified)
    }
} 
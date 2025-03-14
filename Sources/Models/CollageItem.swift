import SwiftUI

struct CollageItem: Identifiable, Codable {
    let id: UUID
    var type: ItemType
    var position: CGPoint
    var size: CGSize
    var rotation: Angle
    var zIndex: Double
    
    // Photo properties
    var image: UIImage?
    var borderWidth: CGFloat
    var borderColor: Color
    var hasBackground: Bool
    
    // Text properties
    var text: String
    var font: String
    var fontSize: CGFloat
    var textColor: Color
    
    enum ItemType: String, Codable {
        case photo
        case text
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, position, size, rotation, zIndex
        case imageData, borderWidth, borderColor, hasBackground
        case text, font, fontSize, textColor
    }
    
    init(type: ItemType) {
        self.id = UUID()
        self.type = type
        self.position = .zero
        self.size = CGSize(width: 200, height: 200)
        self.rotation = .zero
        self.zIndex = 0
        
        // Initialize with defaults based on type
        switch type {
        case .photo:
            self.image = nil
            self.borderWidth = 0
            self.borderColor = .clear
            self.hasBackground = true
            self.text = ""
            self.font = ""
            self.fontSize = 0
            self.textColor = .black
        case .text:
            self.image = nil
            self.borderWidth = 0
            self.borderColor = .clear
            self.hasBackground = true
            self.text = "Double tap to edit"
            self.font = "Helvetica"
            self.fontSize = 24
            self.textColor = .black
        }
    }
    
    static func newPhoto(image: UIImage) -> CollageItem {
        var item = CollageItem(type: .photo)
        item.image = image
        item.size = CGSize(width: 300, height: 300)
        return item
    }
    
    static func newText() -> CollageItem {
        CollageItem(type: .text)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(position, forKey: .position)
        try container.encode(size, forKey: .size)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(zIndex, forKey: .zIndex)
        
        if let image = image {
            try container.encode(ProjectData.CodableImage(image), forKey: .imageData)
        }
        
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encode(borderColor, forKey: .borderColor)
        try container.encode(hasBackground, forKey: .hasBackground)
        try container.encode(text, forKey: .text)
        try container.encode(font, forKey: .font)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(textColor, forKey: .textColor)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ItemType.self, forKey: .type)
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(CGSize.self, forKey: .size)
        rotation = try container.decode(Angle.self, forKey: .rotation)
        zIndex = try container.decode(Double.self, forKey: .zIndex)
        
        if let codableImage = try container.decodeIfPresent(ProjectData.CodableImage.self, forKey: .imageData) {
            image = try? codableImage.toUIImage()
        } else {
            image = nil
        }
        
        borderWidth = try container.decode(CGFloat.self, forKey: .borderWidth)
        borderColor = try container.decode(Color.self, forKey: .borderColor)
        hasBackground = try container.decode(Bool.self, forKey: .hasBackground)
        text = try container.decode(String.self, forKey: .text)
        font = try container.decode(String.self, forKey: .font)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        textColor = try container.decode(Color.self, forKey: .textColor)
    }
}

// Extend CGPoint to be Codable
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
}

// Extend CGSize to be Codable
extension CGSize: Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }
}

// Extend Angle to be Codable
extension Angle: Codable {
    enum CodingKeys: String, CodingKey {
        case degrees
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(degrees, forKey: .degrees)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let degrees = try container.decode(Double.self, forKey: .degrees)
        self.init(degrees: degrees)
    }
} 
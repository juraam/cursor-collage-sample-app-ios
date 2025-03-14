import SwiftUI

enum CanvasFormat: String, CaseIterable, Codable {
    case square = "Square"
    case portrait = "Portrait"
    case landscape = "Landscape"
    case story = "Story"
    
    var aspectRatio: CGFloat {
        switch self {
        case .square:
            return 1.0
        case .portrait:
            return 3.0/4.0
        case .landscape:
            return 16.0/9.0
        case .story:
            return 9.0/16.0
        }
    }
    
    func size(fitting width: CGFloat, height: CGFloat) -> CGSize {
        let maxWidth = width * 0.8
        let maxHeight = height * 0.8
        
        if aspectRatio < 1 {
            // Vertical formats
            let targetHeight = min(maxHeight, maxWidth / aspectRatio)
            let targetWidth = targetHeight * aspectRatio
            return CGSize(width: targetWidth, height: targetHeight)
        } else {
            // Horizontal and square formats
            let targetWidth = min(maxWidth, maxHeight * aspectRatio)
            let targetHeight = targetWidth / aspectRatio
            return CGSize(width: targetWidth, height: targetHeight)
        }
    }
} 
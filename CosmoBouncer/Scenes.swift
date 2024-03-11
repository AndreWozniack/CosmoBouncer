import Foundation
import SpriteKit

enum Scenes : String, Identifiable, CaseIterable {
    case start, intro, tutorial, game, end, freePlay
    
    var id: String {self.rawValue}
}

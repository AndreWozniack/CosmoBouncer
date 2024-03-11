import Foundation
import SpriteKit
import SwiftUI

class GameManager: ObservableObject {
    @Published var selectedScene = Scenes.freePlay

    
    func goToScene(_ scene: Scenes){
        withAnimation {
            selectedScene = scene
        }
    }
}

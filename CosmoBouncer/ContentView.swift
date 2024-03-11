import SwiftUI
import SpriteKit


struct ContentView: View {
    @StateObject var gameManager = GameManager()
    
    var body: some View {
        VStack {
            switch gameManager.selectedScene {
            case .start:
                SpriteView(scene: start()).transition(.opacity)
            case .intro:
                SpriteView(scene: intro()).transition(.opacity)
            case .tutorial:
                SpriteView(scene: tutorial()).transition(.opacity)
            case .game:
                SpriteView(scene: game()).transition(.opacity)
            case .end:
                SpriteView(scene: end()).transition(.opacity)
            case .freePlay:
                SpriteView(scene: start()).transition(.opacity)
            }
            
        }.ignoresSafeArea()
            .background(Color(.black))
    }
    
    
    func start() -> SKScene {
        let screenSize = UIScreen.main.bounds.size
        let scene = StartScene()
        scene.size = screenSize
        scene.scaleMode = .aspectFill
        scene.gameManager = gameManager
        return scene
    }
    func intro() -> SKScene {
        let screenSize = UIScreen.main.bounds.size
        let scene = IntroScene()
        scene.size = screenSize
        scene.scaleMode = .aspectFill
        scene.gameManager = gameManager
        return scene
    }
    func tutorial() -> SKScene {
        let screenSize = UIScreen.main.bounds.size
        let scene = TutorialScene()
        scene.size = screenSize
        scene.scaleMode = .aspectFill
        scene.gameManager = gameManager
        return scene
    }
    func game() -> SKScene {
        let scene = GameScene(fileNamed: "GameScene")!
        scene.size = CGSize(width: 6000, height: 6000)
        scene.scaleMode = .aspectFill
        scene.gameManager = gameManager
        return scene
    }
    
    func end() -> SKScene {
        let screenSize = UIScreen.main.bounds.size
        let scene = EndScene()
        scene.size = screenSize
        scene.scaleMode = .aspectFill
        scene.gameManager = gameManager
        return scene
    }
    
    func freeplay() -> SKScene {
        let scene = Freeplay()
        scene.size = CGSize(width: 6000, height: 6000)
        scene.scaleMode = .aspectFill
        scene.gameManager = gameManager
        return scene
    }
}


import SpriteKit

class StartScene: SKScene {
    weak var gameManager : GameManager?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        createBackground()
        createStartButton()
        createLogo()
        createInstruction()

    }
    
    private func createBackground() {
        let background = SKSpriteNode(imageNamed: "backgroundImage")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.size = CGSize(width: frame.width + 100, height: frame.height + 100)
        background.zPosition = -2
        addChild(background)
    }
    private func createLogo() {
        let logo = SKSpriteNode(imageNamed: "cosmoBouncer")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        logo.setScale(0.2)
        addChild(logo)
    }
    
    private func createStartButton() {
        let startButton = SKSpriteNode(imageNamed: "start")
        startButton.name = "startButton"
        startButton.position = CGPoint(x: frame.midX, y: frame.midY - 200)
        startButton.setScale(0.3)
        addChild(startButton)
    }
    private func createInstruction() {
        let instruction = SKLabelNode(text:  "For a better game experience, lock the screen rotation in portrait mode")
        instruction.name = "startButton"
        instruction.fontSize = 30
        instruction.fontName = "Helvetica-BoldOblique"
        instruction.position = CGPoint(x: frame.midX, y: frame.midY - 500)
        instruction.preferredMaxLayoutWidth = 600
        instruction.numberOfLines = 2
        
        addChild(instruction)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchedNode = atPoint(touch.location(in: self))
        if touchedNode.name == "startButton" {
            presentIntroScene()
        }
    }
    
    private func presentIntroScene() {
        gameManager?.goToScene(.intro)
    }
}

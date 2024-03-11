import SpriteKit
import AVFoundation

class IntroScene: SKScene {
    weak var gameManager: GameManager?
    
    private let introTexts = [
        "Bob, a small ball, arrives at an unknown Solar System.",
        "Driven by curiosity and courage, he decides to explore.",
        "On his journey, he unravels planetary secrets and mysteries.",
        "Learning about gravity, he understands the phenomena of the universe.",
        "Help Bob explore and get to know this intriguing Solar System."
    ]
    private var currentTextIndex = 0
    private var currentTextNode: SKLabelNode?
    
    
    // MARK: Change Scene Functions
    func goToScene(scene: SKScene.Type, size: CGSize) {
        let newScene = scene.init(size: size)
        newScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 2.0)
        view?.presentScene(newScene, transition: transition)
    }
    func goToTutorialScene() {
        gameManager?.goToScene(.tutorial)
    }
    
    
    // MARK: Text Functions
    private func fadeInText(completion: @escaping () -> Void) {
        guard let currentTextNode = currentTextNode else {
            completion()
            return
        }
        let fadeInDuration = 0.8
        let fadeInAction = SKAction.fadeIn(withDuration: fadeInDuration)
        currentTextNode.run(fadeInAction, completion: completion)
    }
    private func fadeOutText(completion: @escaping () -> Void) {
        guard let currentTextNode = currentTextNode else {
            completion()
            return
        }
        let fadeOutDuration = 0.6
        let fadeOutAction = SKAction.fadeOut(withDuration: fadeOutDuration)
        currentTextNode.run(fadeOutAction, completion: completion)
    }
    private func showText() {
        guard currentTextIndex < introTexts.count else {
            goToTutorialScene()
            return
        }
        let textNode = SKLabelNode(text: introTexts[currentTextIndex])
        textNode.fontSize = 40
        textNode.fontName = "KGRedHands"
        textNode.position = CGPoint(x: frame.midX, y: frame.midY)
        textNode.numberOfLines = 6
        textNode.alpha = 0
        textNode.preferredMaxLayoutWidth = 700
        textNode.horizontalAlignmentMode = .center
        textNode.verticalAlignmentMode = .center
        textNode.lineBreakMode = .byClipping
        addChild(textNode)
        currentTextNode = textNode
        fadeInText {}
    }
    private func createBackButton() {
        let backButton = SKSpriteNode(imageNamed: "backButton")
        backButton.position = CGPoint(x: frame.minX + 150, y: frame.minY + 100)
        backButton.alpha = 0
        backButton.name = "backButton"
        backButton.setScale(0.28)
        addChild(backButton)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        backButton.run(fadeIn)
    }
    private func createNextButton() {
        let nextButton = SKSpriteNode(imageNamed: "nextButton")
        nextButton.position = CGPoint(x: frame.maxX - 150, y: frame.minY + 100)
        nextButton.alpha = 0
        nextButton.name = "nextButton"
        nextButton.setScale(0.28)
        addChild(nextButton)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        nextButton.run(fadeIn)
    }
    private func handleBackButtonTouched() {
        if currentTextIndex > 0 {
            fadeOutText {
                self.currentTextNode?.removeFromParent()
                self.currentTextIndex -= 1
                self.showText()
            }
        }
    }
    private func handleTextTouched() {
        fadeOutText {
            self.currentTextNode?.removeFromParent()
            self.currentTextIndex += 1
            self.showText()
        }
    }
    
    
    // MARK: Code
    override func didMove(to view: SKView) {
        backgroundColor = .black
        createNextButton()
        createBackButton()
        showText()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let touchedNode = nodes(at: location).first {
            if touchedNode.name == "backButton" {
                handleBackButtonTouched()
                return
            }
        }
        if let currentTextNode = currentTextNode, currentTextNode.contains(location) {
            handleTextTouched()
        }
        let touchedNode = atPoint(touch.location(in: self))
        if touchedNode.name == "nextButton" {
            handleTextTouched()
        }
    }
}

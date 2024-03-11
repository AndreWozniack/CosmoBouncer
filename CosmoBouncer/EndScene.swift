import SpriteKit
import AVFoundation


class EndScene: SKScene {
    weak var gameManager : GameManager?
    
    private var currentTextIndex = 0
    private var currentTextNode: SKLabelNode?
    private var isNextButton = false
    private var bob = SKSpriteNode()
    private var touchCount = 0
    private var didDrag = false
    private var touchStartPosition: CGPoint?
    private var isFirstTouch = true
    private var lastTouchPosition: CGPoint = .zero
    private var trail = [CGPoint]()
    private var instructionTextNode: SKLabelNode = SKLabelNode(text: "")
    let cameraNode = SKCameraNode()
    var ui = SKShapeNode()
    var box = SKShapeNode()
    let playerCategory: UInt32 = 0x1 << 0
    let planetCategory: UInt32 = 0x1 << 1
    
    private let introTexts = [
        
        "Gravity is the attractive force that exists between all objects with mass. In space, it is responsible for keeping planets in orbit around the Sun and moons around the planets.",
        
        
        "Gravity determines the shape of planets, keeping them spherical and compact. It also influences the atmosphere, climate, and tides of planets, and is crucial for the formation of planetary systems and stars.",
        
        
        "Yes, a planet's gravitational force depends on its mass and radius. More massive and dense planets have stronger gravity, while smaller and less dense planets have weaker gravity. For example, gravity on Jupiter is much stronger than on Earth",
        
        
        "As Bob travels through the Solar System, he experiences different levels of gravity on each planet. This affects his speed, direction, and mobility. He needs to adapt and learn to use gravity to his advantage for efficient exploration.",
        ""

        
    ]
    
    private let titles = [
        "What is gravity?",
        "How does gravity affect planets?",
        "Does gravity vary between planets?",
        "The effect of gravity on Bob:",
        "After exploring this incredible Solar System, Bob heads towards others, continuing his mission to explore the vast and immense universe."
    ]
    
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
    private func createBob() -> SKSpriteNode {
        let bobTexture = SKTexture(imageNamed: "bob_1")
        let bob = SKSpriteNode(texture: bobTexture)
        bob.name = "bob"
        bob.setScale(0.08)
        bob.physicsBody = SKPhysicsBody(circleOfRadius: bob.size.height/2)
        bob.physicsBody?.angularDamping = 8
        bob.position = CGPoint(x: frame.minX + 100, y: frame.minY + 300)
        bob.physicsBody?.categoryBitMask = playerCategory
        bob.physicsBody?.collisionBitMask = planetCategory
        bob.physicsBody?.contactTestBitMask = planetCategory
        return bob
    }
    private func animateBob() {
        guard let bob = childNode(withName: "bob") as? SKSpriteNode else { return }
        
        let texture1 = SKTexture(imageNamed: "bob_1")
        let texture2 = SKTexture(imageNamed: "bob_2")
        
        let showTexture1 = SKAction.setTexture(texture1)
        let wait1 = SKAction.wait(forDuration: 1.8)
        let showTexture2 = SKAction.setTexture(texture2)
        let wait2 = SKAction.wait(forDuration: 0.5)
        
        let sequence = SKAction.sequence([showTexture1, wait1, showTexture2, wait2])
        let repeatForever = SKAction.repeatForever(sequence)
        bob.run(repeatForever)
    }
    private func createTrail() {
        let trailNode = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: bob.position)
        trailNode.path = path
        trailNode.strokeColor = .green
        trailNode.lineWidth = 4
        trailNode.zPosition = -1
        addChild(trailNode)

        let waitAction = SKAction.wait(forDuration: 1)
        let updateTrailAction = SKAction.run {
            self.trail.append(self.bob.position)
            while self.trail.count > 20 {
                self.trail.removeFirst()
            }
            let path = CGMutablePath()
            path.move(to: self.trail[0])
            for i in 1..<self.trail.count {
                path.addLine(to: self.trail[i])
            }
            trailNode.path = path
        }
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.fadeOut(withDuration: 1),
            SKAction.removeFromParent()
        ])
        let sequenceAction = SKAction.sequence([waitAction, updateTrailAction, removeAction])
        trailNode.run(sequenceAction)
    }
    private func createCircle(at position: CGPoint) {
        let circle = SKShapeNode(circleOfRadius: 20)
        circle.position = position
        circle.fillColor = .white
        circle.alpha = 0.2
        addChild(circle)
        let remove = SKAction.removeFromParent()
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let sequence = SKAction.sequence([wait, fadeOut, remove])
        circle.zPosition = -2
        circle.run(sequence)

    }
    private func goToStartScene() {
        gameManager?.goToScene(.start)
    }
    private func showText(_ text: String, at position: CGPoint, fontSize: CGFloat = 20) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.position = position
        label.fontSize = fontSize
        label.fontName = "HelveticaNeue-Medium"
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = 700
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 12
        addChild(label)
        return label
    }
    private func animateTexts(_ texts: [String], titles: [String], delay: TimeInterval, yOffset: CGFloat = 30, yOffsetBetweenPairs: CGFloat = 180) {
        let startY = frame.maxY - 100
        var currentY = startY

        for (index, title) in titles.enumerated() {
            let titleIndex = index
            let titleLabel = showText(title, at: CGPoint(x: frame.midX, y: currentY + 50))
            titleLabel.fontName = "KGRedHands"
            titleLabel.alpha = 0
            currentY -= yOffset / 2

            let answer = texts[titleIndex]
            let answerLabel = showText(answer, at: CGPoint(x: frame.midX, y: currentY))
            titleLabel.fontName = "KGRedHands"
            titleLabel.fontColor = .green
            answerLabel.alpha = 0
            currentY -= yOffsetBetweenPairs

            let wait = SKAction.wait(forDuration: delay * TimeInterval(index))
            let fadeIn = SKAction.fadeIn(withDuration: 0.5)

            let sequence = SKAction.sequence([wait, fadeIn])
            titleLabel.run(sequence)
            answerLabel.run(sequence)
        }
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
    
    // MARK: Code
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let delay: TimeInterval = 2.5
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        anchorPoint = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        ui = SKShapeNode(rectOf: CGSize(width: view.bounds.width * 4, height: view.bounds.height * 4))
        ui.zPosition = 2
        
        bob.position = ui.position
        box.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        box.physicsBody?.categoryBitMask = planetCategory
        box.physicsBody?.collisionBitMask = playerCategory
        box.physicsBody?.contactTestBitMask = playerCategory
        addChild(box)
        bob = createBob()
        addChild(bob)
        animateBob()
        animateTexts(introTexts, titles: titles , delay: delay)
        createNextButton()
    }
    override func update(_ currentTime: TimeInterval) {
        createTrail()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let intensity: CGFloat = 40
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            var directionVector = CGVector(dx: touchLocation.x - bob.position.x, dy: touchLocation.y - bob.position.y)
            directionVector.normalize()
            bob.physicsBody?.applyImpulse(CGVector(dx: directionVector.dx * intensity, dy: directionVector.dy * intensity))
        }
        guard let touch = touches.first else { return }
        let touchedNode = atPoint(touch.location(in: self))
        if touchedNode.name == "nextButton" {
            goToStartScene()
        }
        for touch in touches {
            let location = touch.location(in: self)
            createCircle(at: location)
        }
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            createCircle(at: location)
        }
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let intensity: CGFloat = 10
        var directionVector = CGVector(dx: touchLocation.x - bob.position.x, dy: touchLocation.y - bob.position.y)
        directionVector.normalize()
        bob.physicsBody?.applyImpulse(CGVector(dx: directionVector.dx * intensity, dy: directionVector.dy * intensity))
        lastTouchPosition = touchLocation
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = .zero
    }
}

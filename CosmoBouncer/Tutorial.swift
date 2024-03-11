import SpriteKit

class TutorialScene : SKScene {
    weak var gameManager: GameManager?
    
    private var touchCount = 0
    private var didDrag = false
    private var touchStartPosition: CGPoint?
    private var bob : SKSpriteNode = SKSpriteNode(imageNamed: "bob")
    private var isFirstTouch = true
    private var lastTouchPosition: CGPoint = .zero
    private var trail = [CGPoint]()
    private var instructionTextNode: SKLabelNode = SKLabelNode(text: "")
    let cameraNode = SKCameraNode()
    var ui = SKShapeNode()
    var box = SKShapeNode()
    let playerCategory: UInt32 = 0x1 << 0
    let planetCategory: UInt32 = 0x1 << 1
    
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
    private func goToIntroScene() {
        gameManager?.goToScene(.game)
        
    
    }
    private func createInstructionText() -> SKLabelNode {
        let instructionText = SKLabelNode(text: "Tap on the screen to give Bob a boost.")
        instructionText.fontSize = 30
        instructionText.fontName = "KGRedHands"
        instructionText.position = CGPoint(x: frame.midX, y: frame.maxY - 250)
        instructionText.horizontalAlignmentMode = .center
        instructionText.verticalAlignmentMode = .center
        addChild(instructionText)
        return instructionText
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

    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = UIColor.black
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        anchorPoint = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        ui = SKShapeNode(rectOf: CGSize(width: view.bounds.width * 4, height: view.bounds.height * 4))
        ui.zPosition = 2
        
        // for debug UI
        ui.strokeColor = .red
        ui.lineWidth = 8
        
        bob.position = ui.position
        
        box.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        box.physicsBody?.categoryBitMask = planetCategory
        box.physicsBody?.collisionBitMask = playerCategory
        box.physicsBody?.contactTestBitMask = playerCategory
        addChild(box)

        instructionTextNode = createInstructionText()
        bob.setScale(0.03)
        bob.physicsBody = SKPhysicsBody(circleOfRadius: bob.size.height/2)
        bob.physicsBody?.angularDamping = 8
        bob.position = CGPoint(x: frame.minX + 300, y: frame.minY + 300)
        bob.physicsBody?.categoryBitMask = playerCategory
        bob.physicsBody?.collisionBitMask = planetCategory
        bob.physicsBody?.contactTestBitMask = planetCategory
        addChild(bob)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.createNextButton()
        }

        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            createCircle(at: location)
        }
        guard let touch = touches.first else { return }
        if isFirstTouch {
            instructionTextNode.text = "Swipe on the screen to move Bob around."
            isFirstTouch = false
        }
        let intensity: CGFloat = 20
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            var directionVector = CGVector(dx: touchLocation.x - bob.position.x, dy: touchLocation.y - bob.position.y)
            directionVector.normalize()
            bob.physicsBody?.applyImpulse(CGVector(dx: directionVector.dx * intensity, dy: directionVector.dy * intensity))
        }
        let touchedNode = atPoint(touch.location(in: self))
        if touchedNode.name == "nextButton" {
            goToIntroScene()
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            createCircle(at: location)
        }
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let intensity: CGFloat = 3
        var directionVector = CGVector(dx: touchLocation.x - bob.position.x, dy: touchLocation.y - bob.position.y)
        directionVector.normalize()
        bob.physicsBody?.applyImpulse(CGVector(dx: directionVector.dx * intensity, dy: directionVector.dy * intensity))
        lastTouchPosition = touchLocation
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = .zero
    }
    override func update(_ currentTime: TimeInterval) {
        createTrail()
    }
    
}

import SpriteKit
import GameplayKit

class Freeplay: SKScene, SKPhysicsContactDelegate {
    weak var gameManager: GameManager?

    private var bob = SKSpriteNode()
    private var planets = [SKSpriteNode]()
    private let G: CGFloat = 6.674 * pow(10, -11) // Constante gravitacional
    private let scale: CGFloat = 1000000000 // Escala para adaptar a constante gravitacional ao nosso jogo
    private var planetGenerator = PlanetGenerator()
    private let playerCategory: UInt32 = 0x1 << 0
    private let planetCategory: UInt32 = 0x1 << 1
    private let gravityCategory: UInt32 = 0x1 << 2

    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.backgroundColor = UIColor.black

        let bob = createBob()
        addChild(bob)
        generatePlanets()
    }

    private func createBob() -> SKSpriteNode {
        let bobTexture = SKTexture(imageNamed: "bob_1")
        let bob = SKSpriteNode(texture: bobTexture)
        bob.name = "bob"
        bob.setScale(0.06)
        bob.physicsBody = SKPhysicsBody(circleOfRadius: bob.size.height/2)
        bob.physicsBody?.categoryBitMask = playerCategory
        bob.physicsBody?.contactTestBitMask = planetCategory
        bob.physicsBody?.collisionBitMask = planetCategory
        bob.physicsBody?.angularDamping = 8
        bob.physicsBody?.mass = 10
        bob.position = CGPoint(x: frame.minX + 2000 , y: frame.minY + 2000)
        return bob
    }

    private func generatePlanets() {
        self.planets = planetGenerator.generatePlanets(in: self)
        for planet in planets {
            addChild(planet)
        }
    }

//    private func calculateGravitationalForce(between body1: SKSpriteNode, and body2: SKSpriteNode) -> CGVector {
//        let dx = body2.position.x - body1.position.x
//        let dy = body2.position.y - body1.position.y
//        let distance = sqrt(dx*dx + dy*dy)
//        
//        let forceMagnitude = G * (body1.physicsBody!.mass * body2.physicsBody!.mass) / (distance * distance * scale)
//        let forceVector = CGVector(dx: forceMagnitude * dx / distance, dy: forceMagnitude * dy / distance)
//        
//        return forceVector
//    }

    override func update(_ currentTime: TimeInterval) {
//        for planet in planets {
//            let gravityForce = calculateGravitationalForce(between: bob, and: planet)
//            bob.physicsBody?.applyForce(gravityForce)
//        }
    }
}

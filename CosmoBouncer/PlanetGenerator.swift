import SpriteKit
import Foundation

class PlanetGenerator {

    private let maxPlanets = 12
    private let minPlanetSize: CGFloat = 50
    private let maxPlanetSize: CGFloat = 150
    private let maxMass: CGFloat = 1000
    private let planetCategory: UInt32 = 0x1 << 1

    func generatePlanets(in scene: SKScene) -> [SKSpriteNode] {
        var planets = [SKSpriteNode]()

        for _ in 0..<maxPlanets {
            let size = CGFloat.random(in: minPlanetSize...maxPlanetSize)
            let mass = CGFloat.random(in: size...maxMass)
            let x = CGFloat.random(in: -scene.size.width/2...scene.size.width/2)
            let y = CGFloat.random(in: -scene.size.height/2...scene.size.height/2)
            let position = CGPoint(x: x, y: y)

            let planet = SKSpriteNode(color: .random(), size: CGSize(width: size, height: size))
            planet.position = position
            planet.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
            planet.physicsBody?.mass = mass
            planet.physicsBody?.categoryBitMask = planetCategory
            planets.append(planet)
        }

        return planets
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
    }
}

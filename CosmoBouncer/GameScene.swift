import SpriteKit
import AVFoundation


class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var gameManager : GameManager?
    
    private var isFirstTouch = true
    private var showTail = false
    private var earth = SKSpriteNode()
    private var mars = SKSpriteNode()
    private var bob = SKSpriteNode()
    private var trail = [CGPoint]()
    private var totalPlanets = 8
    private var planetsLabel: SKSpriteNode!
    private var ui = SKShapeNode()
    private var visitedPlanetsSet = Set<String>()
    private var lastTouchPosition: CGPoint = .zero
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var lastTimeBobMoved: TimeInterval?
    private var checkPlanets : [SKSpriteNode] = []
    private var gravities : [SKFieldNode] = []
    private var cometTrail: SKEmitterNode?
    private var timeSinceOutOfRange: TimeInterval = 0
    private var lastDiscoveredPlanets : [SKSpriteNode] = []
    private var showReset = true
    private var resetButton = SKSpriteNode()
    
    private let fadeDuration: TimeInterval = 5.0
    private let startLabel = SKLabelNode(text: "Tap the screen to start")
    private let cameraNode = SKCameraNode()
    private let uiGame = SKNode()
    private let playerCategory: UInt32 = 0x1 << 0
    private let planetCategory: UInt32 = 0x1 << 1
    private let gravityCategory: UInt32 = 0x1 << 2
    private let radiansToDegrees =  180  /  CGFloat .pi
    private let degreesToRadians =  CGFloat .pi /  180
    private let planets: [String] = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
    private let gravityForces : [Float] = [9.8, 3.7, 8.87, 3.711, 24.79, 10.44, 8.69, 11.15]
    private let planetGravity: [String: Float] = [ "Mercury": 3.7, "Venus": 8.87, "Earth": 9.8, "Mars": 3.711, "Jupiter": 24.79, "Saturn": 10.44, "Uranus": 8.69, "Neptune": 11.15]
    
    private func distanceBetween(_ pointA: CGPoint, _ pointB: CGPoint) -> CGFloat {
        let dx = pointA.x - pointB.x
        let dy = pointA.y - pointB.y
        return sqrt(dx*dx + dy*dy)
    }
    private func playBackgroundMusic() {
        if let backgroundMusicURL = Bundle.main.url(forResource: "Space", withExtension: "mp3") {
            backgroundMusicPlayer = try? AVAudioPlayer(contentsOf: backgroundMusicURL)
            backgroundMusicPlayer?.numberOfLoops = -1 // Repetir infinitamente
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            let fadeStep = 0.01
            let fadeInterval = fadeDuration * fadeStep
            let timer = Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: true) { timer in
                if self.backgroundMusicPlayer?.volume ?? 0 < 1.0 {
                    self.backgroundMusicPlayer?.volume += Float(fadeStep)
                } else {
                    timer.invalidate()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    private func createPlanet(planet : SKSpriteNode, dynamic : Bool) -> SKSpriteNode {
        planet.physicsBody = SKPhysicsBody(circleOfRadius: planet.size.height/2)
        planet.physicsBody?.categoryBitMask = planetCategory
        planet.physicsBody?.contactTestBitMask = playerCategory
        planet.physicsBody?.isDynamic = dynamic
        planet.run(SKAction.repeatForever(SKAction.rotate(byAngle: 2 * CGFloat.pi, duration: CGFloat.random(in: 1...5))))
        return planet
    }
    private func createSolarSystem(dynamic : Bool) -> [SKSpriteNode] {
        var solarSystem : [SKSpriteNode] = []
        for i in 0..<planets.count {
            let planet : SKSpriteNode = childNode(withName: planets[i]) as! SKSpriteNode
            planet.name = planets[i]
            solarSystem.append(createPlanet(planet: planet, dynamic: dynamic))
        }
        return solarSystem
    }
    private func createGravity(planet : SKSpriteNode) -> SKFieldNode {
        let gravityField = SKFieldNode.radialGravityField()
        let force = planetGravity[planet.name ?? ""] ?? Float(1)
        if planet.name == "Jupiter" {
            let radius = planet.size.height/2 * 10
            let fieldRadious = SKShapeNode(circleOfRadius: radius)
            fieldRadious.fillColor = .darkGray
            fieldRadious.alpha = 0.3
            fieldRadious.strokeColor = .darkGray
            fieldRadious.lineWidth = 8
            
            gravityField.position = planet.position
            gravityField.region = SKRegion(radius: Float(radius))
            gravityField.strength = force
            gravityField.falloff = 0.005
            gravityField.addChild(fieldRadious)
            
        } else {
            let radius = planet.size.height/2 * 20
            let fieldRadious = SKShapeNode(circleOfRadius: radius)
            fieldRadious.fillColor = .darkGray
            fieldRadious.alpha = 0.3
            fieldRadious.strokeColor = .darkGray
            fieldRadious.lineWidth = 8
            
            gravityField.position = planet.position
            gravityField.region = SKRegion(radius: Float(radius))
            gravityField.strength = force * 2
            gravityField.falloff = 0.001
            gravityField.addChild(fieldRadious)
            
        }
        gravityField.categoryBitMask = gravityCategory
        return gravityField
    }
    private func findClosestPlanet() -> SKSpriteNode? {
        var closestPlanet: SKSpriteNode?
        var smallestDistance: CGFloat = CGFloat.infinity
        for node in self.children {
            if let planet = node as? SKSpriteNode, planet.physicsBody?.categoryBitMask == planetCategory {
                let distance = planet.position.distance(from: planet.position)
                if distance < smallestDistance {
                    smallestDistance = distance
                    closestPlanet = planet
                }
            }
        }
        return closestPlanet
    }
    private func findClosestPlanet(position : CGPoint) -> SKSpriteNode? {
        var closestPlanet: SKSpriteNode?
        var smallestDistance: CGFloat = CGFloat.infinity
        for node in self.children {
            if let planet = node as? SKSpriteNode, planet.physicsBody?.categoryBitMask == planetCategory {
                let distance = planet.position.distance(from: position)
                if distance < smallestDistance {
                    smallestDistance = distance
                    closestPlanet = planet
                }
            }
        }
        return closestPlanet
    }
    private func listClosestPlanets() -> [SKSpriteNode] {
        var planets: [SKSpriteNode] = []
        for node in self.children {
            if let planet = node as? SKSpriteNode, planet.physicsBody?.categoryBitMask == planetCategory {
                planets.append(planet)
            }
        }
        let sortedPlanets = planets.sorted(by: {
            let distance1 = $0.position.distance(from: bob.position)
            let distance2 = $1.position.distance(from: bob.position)
            return distance1 < distance2
        })
        return sortedPlanets
    }
    private func findClosestPlanets(count: Int) -> [SKSpriteNode] {
        var closestPlanets: [SKSpriteNode] = []
        var smallestDistances: [CGFloat] = Array(repeating: CGFloat.infinity, count: count)
        
        for node in self.children {
            if let planet = node as? SKSpriteNode, planet.physicsBody?.categoryBitMask == planetCategory {
                let distance = bob.position.distance(from: planet.position)
                for i in 0..<count {
                    if distance < smallestDistances[i] {
                        smallestDistances.insert(distance, at: i)
                        closestPlanets.insert(planet, at: i)
                        
                        // Verifique se o número de elementos no array é maior que 'count'
                        if closestPlanets.count > count {
                            closestPlanets.removeLast()
                            smallestDistances.removeLast()
                        }
                        break
                    }
                }
            }
        }
        return closestPlanets
    }
    private func createTrail() {
        let trailNode = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: bob.position)
        trailNode.path = path
        trailNode.strokeColor = .green
        trailNode.lineWidth = 7
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
    private func adjustCameraZoomToShowClosestPlanets() {
        let closestPlanets = findClosestPlanets(count: 2)
        if closestPlanets.count == 2 {
            let distance = closestPlanets[0].position.distance(from: closestPlanets[1].position)
            let screenSize = UIScreen.main.bounds
            let maxDimension = max(screenSize.width, screenSize.height)
            let scale = (distance + maxDimension / 4) / maxDimension - 2.5
            let zoomAction = SKAction.scale(to: scale, duration: 0.5)
            camera?.run(zoomAction)
        }
    }
    private func showBalloonWithText(for planetName: String) {
        ui.enumerateChildNodes(withName: "*") { node, _ in
            if let nodeName = node.name, nodeName.hasSuffix("balloon") {
                node.removeFromParent()
            }
        }
        
        // Crie uma SKSpriteNode com a imagem desejada
        let imageNode = SKSpriteNode(imageNamed: "\(planetName)_balloon")
        imageNode.name = "\(planetName)_balloon"
        
        // Defina o tamanho e a posição da imagem
        imageNode.position = CGPoint(x: ui.frame.midX, y: ui.frame.maxY - 500)
        imageNode.setScale(1.2)
        
        // Adicione a imagem à cena
        ui.addChild(imageNode)
        
        // Configure as ações de sequência
        let wait = SKAction.wait(forDuration: 20)
        let remove = SKAction.removeFromParent()
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        // Aplique as ações de sequência na imagem
        imageNode.run(sequence)
    }
    private func showBalloonWithText( text: String) {
        ui.enumerateChildNodes(withName: "*") { node, _ in
            if let nodeName = node.name, nodeName.hasSuffix("_balloon") {
                node.removeFromParent()
            }
        }
        let balloon = SKShapeNode(rect: CGRect(x: size.width - 200, y: 400, width: 400, height: 400), cornerRadius: 10)
        balloon.fillColor = .white
        balloon.strokeColor = .black
        balloon.name = "balloon"
        ui.addChild(balloon)
        let text = SKLabelNode(text: text)
        text.fontSize = 100
        text.fontName = "KGRedHands"
        text.fontColor = .white
        text.horizontalAlignmentMode = .center
        text.verticalAlignmentMode = .center
        text.lineBreakMode = .byClipping
        text.numberOfLines = 3
        text.preferredMaxLayoutWidth = 2500
        text.name = "balloonText"
        balloon.addChild(text)
        text.position = CGPoint(x: 0, y: 0)
        
        balloon.position = CGPoint(x: ui.frame.midX, y: ui.frame.maxY - 500)
        let wait = SKAction.wait(forDuration: 20)
        let remove = SKAction.removeFromParent()
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        balloon.run(sequence)
        text.run(sequence)
    }
    private func goToEndScene() {
        gameManager?.goToScene(.end)
    }
    private func createCircle(at position: CGPoint) {
        let circle = SKShapeNode(circleOfRadius: 80)
        circle.position = position
        circle.fillColor = .white
        circle.alpha = 0.2
        addChild(circle)
        let remove = SKAction.removeFromParent()
        let wait = SKAction.wait(forDuration: 0.3)
        let sequence = SKAction.sequence([wait, remove])
        circle.run(sequence)
    }
    private func createPlanetLabel(planetName: String) -> SKSpriteNode {
        let planetLabel = SKSpriteNode(imageNamed: "\(planetName)_check1")
        planetLabel.name = "\(planetName)_check1"
        return planetLabel
    }
    private func addPlanetLabels() {
        let labelMargin: CGFloat = 200
        let screenWidth = ui.frame.width

        // Calcular o espaço total disponível para os labels
        let totalSpacing = screenWidth - 2 * labelMargin

        // Calcular a largura total dos labels
        let totalLabelWidth: CGFloat = planets.reduce(0) { totalWidth, planetName in
            let label = createPlanetLabel(planetName: planetName)
            return totalWidth + label.size.width
        }

        // Calcular o espaço entre os labels
        let spacingBetweenLabels = (totalSpacing - totalLabelWidth) / CGFloat(planets.count - 1)

        var currentPositionX = labelMargin
        for planetName in planets {
            let planetLabel = createPlanetLabel(planetName: planetName)
            planetLabel.position = CGPoint(x: currentPositionX - (ui.frame.width / 2) + 200, y: ui.frame.minY + 600)
            currentPositionX += planetLabel.size.width + spacingBetweenLabels
            checkPlanets.append(planetLabel)
            ui.addChild(planetLabel)
        }
    }
    private func changeFieldRadiusColor(planetName: String) {
        if let gravityFieldNode = childNode(withName: "\(planetName)_gravity") as? SKFieldNode {
            if let fieldRadiusNode = gravityFieldNode.children.first as? SKShapeNode {
                fieldRadiusNode.fillColor = .green
                fieldRadiusNode.zPosition = -3
                fieldRadiusNode.alpha = 0.2
            }
        }
    }
    private func addCometTrail(to character: SKSpriteNode) -> SKEmitterNode? {
        if let trail = SKEmitterNode(fileNamed: "CometTrail") {
            trail.position = CGPoint.zero
            trail.zPosition = character.zPosition - 2
            trail.targetNode = self
            character.addChild(trail)
            trail.particleBirthRate = 0 // Inicialmente desativado
            return trail
        }
        return nil
    }
    private func birthRate(forSpeed speed: CGFloat, minValue: CGFloat, maxValue: CGFloat) -> CGFloat {
        let slope = (maxValue - minValue) / 1000 // Ajuste o denominador para controlar a relação entre velocidade e birthRate
        return minValue + slope * (speed - 10)
    }
    private func createNextButton() {
        let nextButton = SKSpriteNode(imageNamed: "nextButton")
        nextButton.position = CGPoint(x: ui.frame.maxX - 400, y: ui.frame.minY + 200)
        nextButton.alpha = 0
        nextButton.name = "nextButton"
        ui.addChild(nextButton)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        nextButton.run(fadeIn)
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
        bob.position = CGPoint(x: frame.minX + 2000 , y: frame.minY + 2000)
        return bob
    }
    private func animateBob() {
        guard let bob = childNode(withName: "bob") as? SKSpriteNode else { return }
        
        let texture1 = SKTexture(imageNamed: "bob_1")
        let texture2 = SKTexture(imageNamed: "bob_2")
        
        let showTexture1 = SKAction.setTexture(texture1)
        let wait1 = SKAction.wait(forDuration: 1.8)
        let showTexture2 = SKAction.setTexture(texture2)
        let wait2 = SKAction.wait(forDuration: 0.6)
        
        let sequence = SKAction.sequence([showTexture1, wait1, showTexture2, wait2])
        let repeatForever = SKAction.repeatForever(sequence)
        bob.run(repeatForever)
    }
    private func createResetButton() {
        resetButton = SKSpriteNode(imageNamed: "resetButton")
        resetButton.name = "resetButton"
        resetButton.position = CGPoint(x: ui.frame.minX + 600, y: ui.frame.minY + 200)
        ui.addChild(resetButton)
    }
    private func resetBobPosition() {
        let planet = lastDiscoveredPlanet()
        bob.position = CGPoint(
            x: planet.position.x + planet.size.height,
            y: planet.position.y + planet.size.height)
        bob.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    }
    private func lastDiscoveredPlanet() -> SKSpriteNode {
        if let last = lastDiscoveredPlanets.last {
            return last
        } else {
            return childNode(withName: "Earth") as! SKSpriteNode
        }
    }
    private func changeLabelImage(for planetName: String) {
        if let planetLabel = ui.childNode(withName: "\(planetName)_check1") as? SKSpriteNode {
            let pos = planetLabel.position
            planetLabel.childNode(withName: "\(planetName)_check1")?.removeFromParent()
            let imageName = "\(planetName)_check2"
            let imageNode = SKSpriteNode(imageNamed: imageName)
            imageNode.name = imageName
            imageNode.position = pos
            ui.addChild(imageNode)
        }
    }

    
    override func didMove(to view: SKView) {
        playBackgroundMusic()
        anchorPoint = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        ui = SKShapeNode(rectOf: CGSize(width: view.bounds.width * 4.4, height: view.bounds.height * 4.4))
        ui.zPosition = 2
        ui.strokeColor = .clear
        
        // Setting game camera
        cameraNode.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        cameraNode.setScale(7)
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.addChild(ui)
        
        // Scene config
        self.physicsWorld.contactDelegate = self
        self.backgroundColor = UIColor.black
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        let solarSystem = createSolarSystem(dynamic: false)
        for planet in solarSystem {
            let gravity = createGravity(planet: planet)
            gravity.name = (planet.name ?? "") + "_gravity"
            gravities.append(gravity)
            addChild(gravity)
        }
        startLabel.fontName = "KGRedHands"
        startLabel.fontSize = 300
        startLabel.position = CGPoint(x: ui.frame.midX, y: ui.frame.midY + 400)
        ui.addChild(startLabel)
        bob.position = CGPoint(x: frame.minX + 2000 , y: frame.minY + 2000)
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        
        for node in touchedNodes {
            if node.name == "nextButton" {
                goToEndScene()
            }
        }
        for touch in touches {
            let location = touch.location(in: self)
            createCircle(at: location)
        }
        if isFirstTouch {
            addPlanetLabels()
            showBalloonWithText(text: "Bob arrived in the solar system")
            startLabel.alpha = 0
            let location = touches.first!.location(in: self)
            let closestPlanet = findClosestPlanet(position: location)
            bob = createBob()
            addChild(bob)
            animateBob()
            cometTrail = addCometTrail(to: bob)
            
            let wait = SKAction.wait(forDuration: 0.3)
            let moveBob = SKAction.move(to: location, duration: 2)
            let moveBobToPlanet = SKAction.move(to:CGPoint(
                x: closestPlanet!.position.x + closestPlanet!.size.height/2,
                y: closestPlanet!.position.y + closestPlanet!.size.height/2),
                                                duration: 1)
            moveBob.timingMode = .easeInEaseOut
            moveBobToPlanet.timingMode = .easeInEaseOut
            let sequece = SKAction.sequence([moveBob, wait, moveBobToPlanet])
            bob.run(sequece)
            cameraNode.run(moveBob)
            isFirstTouch = false
            createResetButton()
            
        }
        let intensity: CGFloat = 200
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            var directionVector = CGVector(dx: touchLocation.x - bob.position.x, dy: touchLocation.y - bob.position.y)
            directionVector.normalize()
            bob.physicsBody?.applyImpulse(CGVector(dx: directionVector.dx * intensity, dy: directionVector.dy * intensity))
        }
        for touch in touches {
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)
            
            for node in nodesAtPoint {
                if node.name == "resetButton" {
                    resetBobPosition()
                }
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let intensity: CGFloat = 40
        var directionVector = CGVector(dx: touchLocation.x - bob.position.x, dy: touchLocation.y - bob.position.y)
        directionVector.normalize()
        bob.physicsBody?.applyImpulse(CGVector(dx: directionVector.dx * intensity, dy: directionVector.dy * intensity))
        lastTouchPosition = touchLocation
        for touch in touches {
            let location = touch.location(in: self)
            createCircle(at: location)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = .zero
    }
    override func update(_ currentTime: TimeInterval) {
        createTrail()
        var closestPlanet: SKNode?
        var closestDistance: CGFloat = CGFloat.infinity
        for node in self.children {
            if node.physicsBody?.categoryBitMask == planetCategory {
                let rotation = CGFloat.random(in: 10...800)
                node.physicsBody?.applyAngularImpulse(rotation)
                let distance = distanceBetween(bob.position, node.position)
                
                if distance < closestDistance {
                    closestPlanet = node
                    closestDistance = distance
                }
            }
        }
        if showTail {
            let moveToBob = SKAction.move(to: bob.position, duration: 0.5)
            camera?.run(moveToBob)
            let minimumSpeed: CGFloat = 10.0
            if let bobPhysicsBody = bob.physicsBody, bobPhysicsBody.velocity.length() > minimumSpeed {
                lastTimeBobMoved = currentTime
            }
            if let lastTimeBobMoved = lastTimeBobMoved, currentTime - lastTimeBobMoved > 1.5 {
                let cameraZoomAction = SKAction.scale(to: 0.8, duration: 1.5)
                cameraNode.run(cameraZoomAction)
            } else {
                adjustCameraZoomToShowClosestPlanets()
            }
        }
        if let closestPlanet = closestPlanet {
            let angle = atan2(closestPlanet.position.y - bob.position.y, closestPlanet.position.x - bob.position.x) + (-270 * degreesToRadians)
            let rotateAction = SKAction.rotate(toAngle: angle, duration: 0.19)
            bob.run(rotateAction)
        }

        let bobSpeed = bob.physicsBody?.velocity.length() ?? 0
        if bobSpeed > 10 {
            let minBirthRate: CGFloat = 100 // Ajuste este valor conforme necessário
            let maxBirthRate: CGFloat = 40000 // Ajuste este valor conforme necessário
            cometTrail?.particleBirthRate = birthRate(forSpeed: bobSpeed, minValue: minBirthRate, maxValue: maxBirthRate)
        } else {
            cometTrail?.particleBirthRate = 0
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == planetCategory || contact.bodyB.categoryBitMask == planetCategory {
            showTail = true
            let planetNode = contact.bodyA.categoryBitMask == planetCategory ? contact.bodyA.node : contact.bodyB.node
            if let planetName = planetNode?.name, !visitedPlanetsSet.contains(planetName) {
                visitedPlanetsSet.insert(planetName)
                showBalloonWithText(for: planetName)
            }
        }
        if contact.bodyA.categoryBitMask == playerCategory && contact.bodyB.categoryBitMask == planetCategory {
            if let planetName = contact.bodyB.node?.name {
                showBalloonWithText(for: planetName)
                changeFieldRadiusColor(planetName: planetName)
                visitedPlanetsSet.insert(planetName)
                lastDiscoveredPlanets.append(childNode(withName: planetName) as! SKSpriteNode)
                changeLabelImage(for: planetName)
                let balloon = childNode(withName: "balloon")
                balloon?.isHidden = true
                for gravity in gravities {
                    if gravity.name == "\(planetName)_gravity" {
                        changeFieldRadiusColor(planetName: planetName)
                    }
                }
            }
        } else if contact.bodyB.categoryBitMask == playerCategory && contact.bodyA.categoryBitMask == planetCategory {
            if let planetName = contact.bodyA.node?.name {
                showBalloonWithText(for: planetName)
                changeFieldRadiusColor(planetName: planetName)
                visitedPlanetsSet.insert(planetName)
                lastDiscoveredPlanets.append(childNode(withName: planetName) as! SKSpriteNode)
                changeLabelImage(for: planetName)
                let balloon = childNode(withName: "balloon")
                balloon?.isHidden = true
                for gravity in gravities {
                    if gravity.name == "\(planetName)_gravity" {
                        changeFieldRadiusColor(planetName: planetName)
                    }
                }
            }
        }
        if visitedPlanetsSet.count == 8 {
            createNextButton()
            startLabel.text = "Bob has completed his awe-inspiring journey through the wonders of the Solar System."
            startLabel.preferredMaxLayoutWidth = 3700
            startLabel.position = CGPoint(x: ui.frame.midX, y: ui.frame.midY + 1000)
            startLabel.fontSize = 130
            startLabel.lineBreakMode = .byClipping
            startLabel.numberOfLines = 2
            let wait = SKAction.wait(forDuration: 4)
            let show = SKAction.fadeIn(withDuration: 2.5)
            let sequence = SKAction.sequence([wait, show])
            startLabel.run(sequence)
        }
    }
}

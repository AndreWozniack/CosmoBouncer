import SpriteKit

extension CGVector {
    
    init(_ vector: CGVector) {
        self.init(dx: vector.dx, dy: vector.dy)
    }
    
    // mutating functions can mutate the state of self
    @discardableResult mutating func subtract(_ v: CGVector) -> Self {
        self.dx -= v.dx
        self.dy -= v.dy
        return self
    }
    
    @discardableResult mutating func add(_ v: CGVector) -> Self {
        self.dx += v.dx
        self.dy += v.dy
        return self
    }
    
    @discardableResult mutating func scale(_ s: CGFloat) -> Self {
        self.dx *= s
        self.dy *= s
        return self
    }
    
    @discardableResult mutating func subtract(_ v: CGPoint) -> Self {
        self.dx -= v.x
        self.dy -= v.y
        return self
    }
    
    @discardableResult mutating func add(_ v: CGPoint) -> Self {
        self.dx += v.x
        self.dy += v.y
        return self
    }
    
    func lengthSquared() -> Double {
        return pow(self.dx, 2) + pow(self.dy, 2)
    }
    
    func length() -> Double {
        return sqrt(lengthSquared())
    }
    
    mutating func normalize() {
        let length = self.length()
        self.dx /= length
        self.dy /= length
    
        
    }
    
    func distanceSquared(from v: CGPoint) -> CGFloat {
        let dx = self.dx - v.x
        let dy = self.dy - v.y
        return dx * dx + dy * dy
    }
    
    func distance(from v: CGPoint) -> CGFloat {
        return sqrt(distanceSquared(from: v))
    }
    
}

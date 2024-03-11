import SpriteKit

extension CGPoint {
    
    // mutating functions can mutate the state of self
    @discardableResult mutating func subtract(_ v: CGVector) -> Self {
        self.x -= v.dx
        self.y -= v.dy
        return self
    }
    
    @discardableResult mutating func add(_ v: CGVector) -> Self {
        self.x += v.dx
        self.y += v.dy
        return self
    }
    
    @discardableResult mutating func scale(_ s: CGFloat) -> Self {
        self.x *= s
        self.y *= s
        return self
    }
    
    @discardableResult mutating func subtract(_ v: CGPoint) -> Self {
        self.x -= v.x
        self.y -= v.y
        return self
    }
    
    @discardableResult mutating func add(_ v: CGPoint) -> Self {
        self.x += v.x
        self.y += v.y
        return self
    }
    
    func lengthSquared() -> Double {
        return self.x * self.x + self.y * self.y
    }
    
    func length() -> Double {
        return sqrt(lengthSquared())
    }
    
    mutating func normalize() {
        let length = self.length()
        self.x /= length
        self.y /= length
    }
    
    func distanceSquared(from v: CGPoint) -> CGFloat {
        let dx = self.x - v.x
        let dy = self.y - v.y
        return dx * dx + dy * dy
    }
    
    func distance(from v: CGPoint) -> CGFloat {
        return sqrt(distanceSquared(from: v))
    }
    func midPoint(point2: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x + point2.x) / 2.0, y: (self.y + point2.y) / 2.0)
    }

}

//
//  PlanetGravity.swift
//  CosmoBouncer
//
//  Created by André Wozniack on 13/04/23.
//

import Foundation
import SpriteKit


class PlanetNode: SKNode {
    let planet: SKSpriteNode
    let gravityField: SKFieldNode

    init(planet: SKSpriteNode, gravityField: SKFieldNode) {
        self.planet = planet
        self.gravityField = gravityField
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

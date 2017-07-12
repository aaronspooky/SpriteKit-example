//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Sergio A. Balderas on 11/07/17.
//  Copyright © 2017 Sergio A. Balderas. All rights reserved.
//

import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

class GameScene: SKScene, SKPhysicsContactDelegate {
  
  struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Monster: UInt32 = 0b1 // 1
    static let Projectile: UInt32 = 0b10 // 2
  }
  
  let playerOne = SKSpriteNode(imageNamed: "player")
  var monsterDestroyed = 0
    
    override func didMove(to view: SKView) {
      
      backgroundColor = SKColor.white
      playerOne.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
      addChild(playerOne)
      
      run(SKAction.repeatForever(
        SKAction.sequence([
          SKAction.run(addMonster),
          SKAction.wait(forDuration: 1.0)
          ])
      ))
      
      physicsWorld.gravity = CGVector.zero
      physicsWorld.contactDelegate = self
      
      let backgroundMusic = SKAudioNode(fileNamed: "bakcground-music-acc.caf")
      backgroundMusic.autoplayLooped = true
      addChild(backgroundMusic)
    }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
  
  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func addMonster() {
    
    let monsterEvil = SKSpriteNode(imageNamed: "monster")
    
    monsterEvil.physicsBody = SKPhysicsBody(rectangleOf: monsterEvil.size)
    monsterEvil.physicsBody?.isDynamic = true
    monsterEvil.physicsBody?.categoryBitMask = PhysicsCategory.Monster
    monsterEvil.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
    monsterEvil.physicsBody?.collisionBitMask = PhysicsCategory.None
    
    let actualY = random(min: monsterEvil.size.height/2, max: size.height - monsterEvil.size.height/2)
    
    monsterEvil.position = CGPoint(x: size.width + monsterEvil.size.width/2, y: actualY)
    
    addChild(monsterEvil)
    
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    let actionMove = SKAction.move(to: CGPoint(x: -monsterEvil.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
    
    let actionMoveDone = SKAction.removeFromParent()
    monsterEvil.run(SKAction.sequence([actionMove, actionMoveDone]))
    
    let loseAction = SKAction.run() {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    monsterEvil.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
  }
  
  func projectileDidCollideWithMonster(projectileAttack: SKSpriteNode, monsterEvil: SKSpriteNode) {
    print("Hit")
    projectileAttack.removeFromParent()
    monsterEvil.removeFromParent()
    
    monsterDestroyed += 1
    if (monsterDestroyed > 30) {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
    if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) && (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
      if let monster = firstBody.node as? SKSpriteNode, let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectileAttack: projectile, monsterEvil: monster)
      }
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    
    let touchLocation = touch.location(in: self)
    
    let projectileAttack = SKSpriteNode(imageNamed: "projectile")
    projectileAttack.position = playerOne.position
    
    let offset = touchLocation - projectileAttack.position
    
    if (offset.x < 0) {
      return
    }
    
    addChild(projectileAttack)
    
    let direction = offset.normalized()
    
    let shootAmount = direction * 1000
    
    let realDest = shootAmount + projectileAttack.position
    
    projectileAttack.physicsBody = SKPhysicsBody(circleOfRadius: projectileAttack.size.width/2)
    projectileAttack.physicsBody?.isDynamic = true
    projectileAttack.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
    projectileAttack.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
    projectileAttack.physicsBody?.collisionBitMask = PhysicsCategory.None
    projectileAttack.physicsBody?.usesPreciseCollisionDetection = true
    
    let actionMove = SKAction.move(to: realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    projectileAttack.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
}

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

//
//  GameScene.swift
//  Higher
//
//  Created by Aryan Chaubal on 7/8/20.
//  Copyright © 2020 Aryan Chaubal. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // nodes
    var ball = SKShapeNode()
    var scoreNode = SKLabelNode()
    
    // constants
    let ballRadius: CGFloat = 20
    let obstacleWidth: CGFloat = 200
    let obstacleSpawnInterval = 1.5
    let colors: [SKColor] = [.red, .blue, .gray, .green, .magenta, .orange, .purple]
    
    // game variables
    var inProgress = false
    var firstTouch: CGFloat? = nil
    var ballColor: SKColor = .red
    var obstacleTranslateDuration: TimeInterval = 3
    var timer = Timer()
    var died = false
    var score = 0 {
        didSet {
            scoreNode.text = String(score)
        }
    }
    
    override func didMove(to view: SKView) {
        setUpView()
        setUpScoreLabel()
        setUpBall()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !inProgress && !died {
            inProgress = true
            startGame()
        } else if died {
            prepareForRestart()
        } else {
            // game is already started
            firstTouch = touches.first?.location(in: self).y
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentTouch = touches.first?.location(in: self).y
        if firstTouch != nil && currentTouch != nil && inProgress {
            ball.position.y = ball.position.y + currentTouch! - firstTouch!
            firstTouch = currentTouch!
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        firstTouch = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
//        obstacleTranslateDuration -= inProgress ? 0.001 : 0
    }
    
}

// MARK:  - Setup methods

extension GameScene {
    
    func setUpView() {
        self.scene?.backgroundColor = .black
        physicsWorld.contactDelegate = self
    }
    
    func setUpScoreLabel() {
        scoreNode.color = .white
        scoreNode.position = CGPoint(x: self.frame.width / 2, y: self.frame.height - 200)
        scoreNode.fontSize = 70
        scoreNode.fontName = "Avenir-Black"
        scoreNode.text = "Tap to start"
        
        self.addChild(scoreNode)
    }
    
    func setUpBall() {
        ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.position = CGPoint(x: self.frame.width / 4, y: self.frame.height / 2)
        ball.fillColor = ballColor
        ball.strokeColor = ballColor
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        ball.physicsBody!.isDynamic = true
        ball.physicsBody!.affectedByGravity = false
        ball.physicsBody?.categoryBitMask = PhysicsBitMask.ball
        ball.physicsBody?.contactTestBitMask = PhysicsBitMask.obstacle
        ball.physicsBody?.collisionBitMask = PhysicsBitMask.obstacle
        ball.name = "ball"
        self.addChild(ball)
    }
    
}

// MARK:  - Game methods

extension GameScene {
    
    func startGame() {

        score = 0
        
        enumerateChildNodes(withName: "main_stack") { (node, _) in
            node.removeFromParent()
        }
        
        ball.position = CGPoint(x: self.frame.width / 4, y: self.frame.height / 2)
        
        // spawn obstacles
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(obstacleSpawnInterval), target: self, selector: #selector(spawnObstacle), userInfo: nil, repeats: true)
        
    }
    
    func prepareForRestart() {

        died = false
        scoreNode.text = "Tap to Start"
        enumerateChildNodes(withName: "main_stack") { (node, _) in
            node.removeFromParent()
        }
        
        ball.position = CGPoint(x: self.frame.width / 4, y: self.frame.height / 2)
        inProgress = false
    }
    
    func finishGame() {
        timer.invalidate()
        died = true
        inProgress = false
        enumerateChildNodes(withName: "main_stack") { (node, _) in
            node.removeAllActions()
            node.speed = 0
        }
    }
    
    func incrementScore() {
        score += 1
    }
    
    func resetScore() {
        score = 0
    }
    
    @objc func spawnObstacle() {
        let stackCount = Int.random(in: 4 ... 8)
        let height = self.frame.height / CGFloat(stackCount)
        let stack = SKNode()
        let indexForBall = Int.random(in: 1 ... stackCount - 2)
        for i in -1 ... stackCount {
            let stackObstacle = SKShapeNode(rect: CGRect(x: self.frame.width + obstacleWidth, y: CGFloat(i) * height, width: obstacleWidth, height: height))
            let isBallColor = i == indexForBall
            let currentColor = isBallColor ? ballColor : generateRandomColor()
            
            stackObstacle.strokeColor = currentColor
            stackObstacle.fillColor = currentColor
            stackObstacle.physicsBody = SKPhysicsBody(edgeLoopFrom: stackObstacle.path!)
            if !isBallColor {
                stackObstacle.name = "obstacle"
                // set up physics body to collide
                stackObstacle.physicsBody?.isDynamic = false
                stackObstacle.physicsBody?.categoryBitMask = PhysicsBitMask.obstacle
                stackObstacle.physicsBody?.contactTestBitMask = PhysicsBitMask.ball
                stackObstacle.physicsBody?.collisionBitMask = PhysicsBitMask.ball
            } else {
                stackObstacle.name = "coin"
                stackObstacle.physicsBody?.categoryBitMask = PhysicsBitMask.coin
                stackObstacle.physicsBody?.contactTestBitMask = PhysicsBitMask.ball
            }
            
            stack.addChild(stackObstacle)
        }
        stack.name = "main_stack"
        self.addChild(stack)
        
        let translateAction = SKAction.moveBy(x: -(self.frame.width + 2 * obstacleWidth), y: CGFloat(250 * (Int.random(in: -1 ... 1))), duration: obstacleTranslateDuration)
        let disappearAction = SKAction.removeFromParent()
        stack.run(translateAction) {
            stack.run(disappearAction)
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let first = contact.bodyA.node!
        let second = contact.bodyB.node!
        
        if first.name == "ball" && second.name == "coin" {
            // second is the coin
            second.removeFromParent()
            // increment score
            incrementScore()
        } else if first.name == "coin" && second.name == "ball" {
            // first is the coin
            first.removeFromParent()
            // increment score
            incrementScore()
        } else if first.name == "ball" && second.name == "obstacle" {
            // game over
            finishGame()
        } else if first.name == "obstacle" && second.name == "ball" {
            // game over
            finishGame()
        }
    }
    
    func generateRandomColor() -> SKColor {
        var color = colors.randomElement()
        if color == ballColor {
            color = generateRandomColor()
        }
        return color!
    }
    
}


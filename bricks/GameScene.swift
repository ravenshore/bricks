//
//  GameScene.swift
//  bricks
//
//  Created by Razvigor Andreev on 1/13/15.
//  Copyright (c) 2015 Razvigor Andreev. All rights reserved.
//

import SpriteKit
import AVFoundation

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let BlockNodeCategoryName = "blockNode"
var isFingerOnPaddle = false

// creating the bit masks
let BallCategory   : UInt32 = 0x1 << 0 // 00000000000000000000000000000001
let BottomCategory : UInt32 = 0x1 << 1 // 00000000000000000000000000000010
let BlockCategory  : UInt32 = 0x1 << 2 // 00000000000000000000000000000100
let PaddleCategory : UInt32 = 0x1 << 3 // 00000000000000000000000000001000
let BorderCategory : UInt32 = 0x1 << 4 // 00000000000000000000000000010000

var ball: SKSpriteNode!
var bg: SKSpriteNode!
var borderBody: SKPhysicsBody!
var score: Int = 0
var level: Int = 1
var scoreLabel: SKLabelNode!
var levelLabel: SKLabelNode!
var highScoreLabel: SKLabelNode!
var mass: CGFloat = 0.55
var multiplier: CGFloat = 1
var maxV: CGFloat = 500
var numberOfBlocks: Int = 3
var paddle: SKSpriteNode!
var paddleWidth: CGFloat = 200
var ppl: Int = 1
var gameOver = false


var backgroundMusicPlayer: AVAudioPlayer!
var audioPlayer: AVAudioPlayer!

func documentsDirectory() -> String {
    let documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
    return documentsFolderPath
}
// Get path for a file in the directory

func fileInDocumentsDirectory(filename: String) -> String {
    return documentsDirectory().stringByAppendingPathComponent(filename)
}

let scoreSavePath = fileInDocumentsDirectory("highScore.txt")



class GameScene: SKScene, SKPhysicsContactDelegate {
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        
        highScoreLabel = childNodeWithName("highScoreLabel") as SKLabelNode!
        loadHighScore()
        generatePaddle()
        generateBackground()
        gameOver = false
        
        playMusic("arcade.wav", loops: -1)
         scoreLabel = childNodeWithName("scoreLabel") as SKLabelNode!
         levelLabel = childNodeWithName("levelLabel") as  SKLabelNode!
        
        
        levelLabel.text = ("Level: \(level)")
        // 1. Create a physics body that borders the screen
        borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        // 2. Set the friction of that physicsBody to 0
        borderBody.friction = 0
        // 3. Set physicsBody of scene to borderBody
        self.physicsBody = borderBody
        // 4. Create the Bottom
        let bottomRect = CGRectMake(frame.origin.x, frame.origin.y + 5 , frame.size.width, 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFromRect: bottomRect)
        addChild(bottom)
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        ball = childNodeWithName(BallCategoryName) as SKSpriteNode
        ball.physicsBody!.applyImpulse(CGVectorMake(0, 10))
        ball.physicsBody!.mass = mass
        
        
        
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        
        
        
        borderBody.categoryBitMask = BorderCategory
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | PaddleCategory |  BorderCategory
        
        println(ball.anchorPoint)
        
        
        // 1. Store some useful constants
//        numberOfBlocks = 9
        
        let blockWidth = SKSpriteNode(imageNamed: "brick1.png").size.width
        let blockHeight = SKSpriteNode(imageNamed: "brick1.png").size.height
        
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        
        let padding: CGFloat = 10.0
        let totalPadding = padding * CGFloat(numberOfBlocks - 1)
        
        // 2. Calculate the xOffset
        let xOffset = (CGRectGetWidth(frame) - totalBlocksWidth - totalPadding) / 2
        let yOffset = blockHeight + 5
        
        // 3. Create the blocks and add them to the scene
        for i in 0..<numberOfBlocks + 1{
            let block = SKSpriteNode(imageNamed: "brick1.png")
            block.position = CGPointMake(xOffset + CGFloat(CGFloat(i))*blockWidth + CGFloat(i-1)*padding, CGRectGetHeight(frame) * 0.8)
            block.physicsBody = SKPhysicsBody(rectangleOfSize: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            block.physicsBody!.dynamic = false
            addChild(block)
        }
        for i in 0..<numberOfBlocks {
            
            let block1 = SKSpriteNode(imageNamed: "brick1.png")
            block1.position = CGPointMake(xOffset + CGFloat(CGFloat(i))*blockWidth + CGFloat(i-1)*padding + blockWidth * 0.5, CGRectGetHeight(frame) * 0.8 + yOffset)
            block1.physicsBody = SKPhysicsBody(rectangleOfSize: block1.frame.size)
            block1.physicsBody!.allowsRotation = false
            block1.physicsBody!.friction = 0.0
            block1.physicsBody!.affectedByGravity = false
            block1.name = BlockCategoryName
            block1.physicsBody!.categoryBitMask = BlockCategory
            block1.physicsBody!.dynamic = false
            addChild(block1)
        }
        
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var touch = touches.anyObject() as UITouch!
        var touchLocation = touch.locationInNode(self)
        
        if let body = physicsWorld.bodyAtPoint(touchLocation) {
            if body.node!.name == PaddleCategoryName {
                println("Began touch on paddle")
                isFingerOnPaddle = true
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        // 1. Check whether user touched the paddle
        if isFingerOnPaddle {
            // 2. Get touch location
            var touch = touches.anyObject() as UITouch!
            var touchLocation = touch.locationInNode(self)
            var previousLocation = touch.previousLocationInNode(self)
            
            // 3. Get node for paddle
            var paddle = childNodeWithName(PaddleCategoryName) as SKSpriteNode!
            
            // 4. Calculate new position along x for paddle
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            
            // 5. Limit x so that paddle won't leave screen to left or right
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            
            // 6. Update paddle position
            paddle.position = CGPointMake(paddleX, paddle.position.y)
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        isFingerOnPaddle = false
    }
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        // 1. Create local variables for two physics bodies
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // 2. Assign the two physics bodies so that the one with the lower category is always stored in firstBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 3. react to the contact between ball and bottom
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
            //TODO: Replace the log statement with display of Game Over Scene
            println("hit bottom")
            gameOver = true
             score = 0
             maxV = 500
            level = 1
            numberOfBlocks = 3
            levelLabel.text = ("Level: \(level)")
            ppl = 1
            saveHighScore()
             self.removeAllChildren();
            if let mainView = view {
               
                println("hit bottom1")
                let gameOverScene = GameOverScene.unarchiveFromFile("GameOverScene") as GameOverScene!
                gameOverScene.gameWon = false
                
                mainView.presentScene(gameOverScene)
                println("hit bottom2")
                
            }
        }
        
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
            
            let secondBodyNode = contact.bodyA.node as SKSpriteNode
            playAudio("jump.wav", loops: 0)
            println("hit block")
            let sparkEmmiter = SKEmitterNode(fileNamed: "brickFx.sks")
            sparkEmmiter.position = secondBodyNode.position
            sparkEmmiter.name = "brickFx"
            sparkEmmiter.zPosition = 1
            sparkEmmiter.targetNode = self
            sparkEmmiter.particleLifetime = 1
            self.addChild(sparkEmmiter)
            
            secondBody.node!.removeFromParent()
            score = score + ppl
            
            
            
//            Check if the game has been won
            if isGameWon() {
                
                self.removeAllChildren()
                maxV = maxV + 200
                level++
                levelLabel.text = ("Level: \(level)")
                numberOfBlocks = numberOfBlocks + 2
                
                ppl++
               
                if let mainView = view {
                    
                    
                    let gameOverScene = GameOverScene.unarchiveFromFile("GameOverScene") as GameOverScene!
                    gameOverScene.gameWon = true
                    
                    mainView.presentScene(gameOverScene)
                
                }
            }
            
           
        }
        
        
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BorderCategory {
            
           println("hit border")
            
                let currentVector = contact.contactNormal
                println("Bonk \(currentVector.dx), \(currentVector.dy)")
                let currentImpact = contact.collisionImpulse
                println("Power: \(currentImpact)")
                if currentImpact <= 5.0 && currentImpact > 0 {
                    println("Impulse power, Mr Sulu")
                    if currentVector.dx == 0 { // only the top
                        firstBody.applyImpulse(CGVector(dx: 2, dy: -1))
                    }
                    if currentVector.dy == 0 { // dx is -1 on the right wall, 1 on the left.
                        let dx = currentVector.dx
                        println("Applying impulse with dx = \(dx)")
                        firstBody.applyImpulse(CGVector(dx: dx + 5, dy: -1))
                    }
                }
            if currentVector.dy == 0 { // bouncing left and right
                
                let dy = currentVector.dy
                let dx = currentVector.dx
                println("DX is : \(dx)")
                if ball.position.y < 300 { // if ball is in bottom half of the screen
                println("Applying impulse with dy = \(dy) + 20")
                firstBody.applyImpulse(CGVector(dx: 0, dy: 20))
                } else { // if ball is in the top half of the screen
                    println("Applying impulse with dy = \(dy) -25")
                    firstBody.applyImpulse(CGVector(dx: 0, dy: -25))
                }
            }
            
            let sparkEmmiter = SKEmitterNode(fileNamed: "spark.sks")
            sparkEmmiter.position = ball.position
            sparkEmmiter.name = "sparkEmmitter"
            sparkEmmiter.zPosition = 1
            sparkEmmiter.targetNode = self
            sparkEmmiter.particleLifetime = 0.5
            
            
            self.addChild(sparkEmmiter)
            
            
            }
        
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory && gameOver == false {
            let ball = self.childNodeWithName(BallCategoryName) as SKSpriteNode!
            let paddle = self.childNodeWithName(PaddleCategoryName) as SKSpriteNode!
            let relativePosition = ((ball.position.x - paddle.position.x))
            println("Relative position is: \(relativePosition)")
            println("Multiplier is: \(multiplier)")
            let xImpulse = relativePosition * multiplier
            println("xImpulse is: \(xImpulse)")
            let impulseVector = CGVector(dx: xImpulse, dy: CGFloat(10))
            ball.physicsBody!.applyImpulse(impulseVector)
            
        }
        
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodesWithName(BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    
    override func update(currentTime: NSTimeInterval) {
        let ball = self.childNodeWithName(BallCategoryName) as SKSpriteNode!
        scoreLabel.text = ("Score: \(score)")
        
        let maxSpeed: CGFloat = maxV
        let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        if speed > maxSpeed {
            ball.physicsBody!.linearDamping = 0.4
        }
        else {
            ball.physicsBody!.linearDamping = 0.0
            
        }
    }
    
    
   
    func delay(delay:Double, closure:()->()) {
        
        dispatch_after(
            dispatch_time( DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
        
        
    }
    
    func playAudio(filename: String, loops: Int) {
        let url = NSBundle.mainBundle().URLForResource(
            filename, withExtension: nil)
        if (url == nil) {
            println("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        
        audioPlayer =
            AVAudioPlayer(contentsOfURL: url, error: &error)
        if audioPlayer == nil {
            println("Could not create audio player: \(error!)")
            return
        }
        
        audioPlayer.numberOfLoops = loops
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    
    func playMusic(filename: String, loops: Int) {
        let url = NSBundle.mainBundle().URLForResource(
            filename, withExtension: nil)
        if (url == nil) {
            println("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        
        backgroundMusicPlayer =
            AVAudioPlayer(contentsOfURL: url, error: &error)
        if backgroundMusicPlayer == nil {
            println("Could not create audio player: \(error!)")
            return
        }
        
        backgroundMusicPlayer.numberOfLoops = loops
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    }

    func generatePaddle() {
        
        
        paddle = SKSpriteNode(imageNamed: "paddleN\(level).png")
        paddle.position = CGPoint(x: CGRectGetWidth(frame) / 2 , y: 50)
        paddle.physicsBody = SKPhysicsBody(rectangleOfSize: paddle.frame.size)
        paddle.physicsBody!.allowsRotation = false
        paddle.physicsBody!.friction = 0.0
        paddle.physicsBody!.affectedByGravity = false
        paddle.name = PaddleCategoryName
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        paddle.physicsBody!.dynamic = false
        addChild(paddle)
        
    }
    
    func generateBackground() {
        
        bg = SKSpriteNode(imageNamed: "bg\(level).png")
        bg.anchorPoint = CGPoint(x: 0, y: 0)
        let frameW = self.frame.size.width
        let frameH = self.frame.size.height
        println(frameW, frameH)
        addChild(bg)
        bg.size.width = frameW
        bg.size.height = frameH
        bg.zPosition = -10
        
    }
    
    func saveText(text: String, path: String) -> Bool {
        var error: NSError? = nil
        let status = text.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: &error)
        if !status { //status == false {
            println("Error saving file at path: \(path) with error: \(error?.localizedDescription)")
        }
        return status
    }
    
    
    
    
    
    // Load text
    
    func loadTextFromPath(path: String) -> String? {
        var error: NSError? = nil
        let text = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)
        if text == nil {
            println("Error loading text from path: \(path) error: \(error?.localizedDescription)")
        }
        return text
    }
    
    
    func loadHighScore() {
        
        if let savedHighScore = loadTextFromPath(scoreSavePath) {
        highScoreLabel.text = savedHighScore
            println("\(savedHighScore)")
        }
        
    }
    
    func saveHighScore() {
       
        let currentScore = scoreLabel.text
        if let savedHighScore = loadTextFromPath(scoreSavePath) {
            if currentScore > savedHighScore {
        saveText(scoreLabel.text, path: scoreSavePath )
            }
        } else {
            
            saveText(scoreLabel.text, path: scoreSavePath )
        }
    }
}

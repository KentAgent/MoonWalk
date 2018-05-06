//
//  GameScene.swift
//  StunningRunning
//
//  Created by Georgios on 2018-04-16.
//  Copyright © 2018 Georgios. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

struct PhysicsCategory {
    static let player : UInt32 = 0x1 << 1
    static let ground : UInt32 = 0x1 << 2
    static let wall : UInt32 = 0x1 << 3
}

enum Obstacles : Int {
    case small
    case medium
    case big
}

enum Velocities : Int {
    case slow
    case medium
    case fast
}

enum Heights : Int {
    case low
    case mid
    case high
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //AdMob app ID:
    // adMob ID: ca-app-pub-2929582938496453~4062246824
    
    //AdMob SDK ID:
    // ca-app-pub-2929582938496453/3633789841
    
    var obstacleSprite : SKShapeNode!
    
    var grayFilter : SKShapeNode!
    
    var scrollingGround : ScrollingBackground?
    var scrollingMountainsFront : ScrollingBackground?
    var scrollingMountainsBack : ScrollingBackground?
    
    var playerParentNode : SKNode?
    var playerNode : SKSpriteNode?
    let groundLevel : CGFloat = SKSpriteNode.init(imageNamed: "ground").size.height * 0.75
    
    var scoreLabel : SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var highScoreLabel : SKLabelNode!
    var highScore = 0 {
        didSet {
            highScoreLabel.text = "High Score: \(highScore)"
        }
    }
    
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    let spark = SKEmitterNode(fileNamed: "spark")!
    
    var numberOfJumpsLeft = 2
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        
        setupGameScene()
        setupMotionManager()
        
    }
    
    func setupMotionManager() {
        //Detect motion from tilting device. Optimized for landscape orientation
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = self.motionManager.accelerometerData {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.y) * -1 + self.xAcceleration * -0.5
            }
        }
    }
    
    func setupGameScene() {
        createNodes()
        startSpawningObstacles()
        loadSavedHighScore()
    }
    
    func loadSavedHighScore() {
            highScore = UserDefaults.standard.integer(forKey: "highScore")
    }
    
    func createNodes() {
        setupScrollingNodes()
        setupPlayer()
        setupScoreLabel()
        setupHighScoreLabel()
    }
    
    func startSpawningObstacles() {
        // Start spawning obstacles after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.run(SKAction.repeatForever(SKAction.sequence([SKAction.run {
                self.spawnObstacle()
                if self.obstacleSprite.position.x < 0 {
                    self.obstacleSprite.removeFromParent()
                }
                }, SKAction.wait(forDuration: 0.5)])))
        }
    }
    
    func setupGrayFilter() {
        grayFilter = SKShapeNode(rect: CGRect(x: 0, y: 0, width: (scene?.size.width)!, height: (scene?.size.height)!))
        grayFilter.alpha = 1
        grayFilter.blendMode = .screen
        grayFilter.fillColor = UIColor.gray
        grayFilter.zPosition = 25
        addChild(grayFilter)
    }
    
    func loadGrayFilter() {
        setupGrayFilter()
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.grayFilter.removeFromParent()
        }
        
    }
    
    func setupScrollingNodes() {
        scrollingGround = ScrollingBackground.scrollingNodeWithImage(imageName: "ground", containerWidth: self.size.width)
        scrollingGround?.scrollingSpeed = 1
        scrollingGround?.anchorPoint = .zero
        scrollingGround?.zPosition = 5
        
        scrollingGround?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: (scene?.size.width)! * 2, height: groundLevel + 20))
        scrollingGround?.physicsBody?.categoryBitMask = PhysicsCategory.ground
        scrollingGround?.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.wall
        scrollingGround?.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall
        scrollingGround?.physicsBody?.affectedByGravity = false
        scrollingGround?.physicsBody?.isDynamic = false
        self.addChild(scrollingGround!)
        
        scrollingMountainsBack = ScrollingBackground.scrollingNodeWithImage(imageName: "mountains_back", containerWidth: self.size.width)
        scrollingMountainsBack?.scrollingSpeed = 1.5
        scrollingMountainsBack?.anchorPoint = .zero
        scrollingMountainsBack?.zPosition = 1
        self.addChild(scrollingMountainsBack!)
        
        scrollingMountainsFront?.anchorPoint = .zero
        scrollingMountainsFront = ScrollingBackground.scrollingNodeWithImage(imageName: "mountains_front", containerWidth: self.size.width)
        scrollingMountainsFront?.scrollingSpeed = 3
        scrollingMountainsFront?.anchorPoint = .zero
        scrollingMountainsFront?.zPosition = 2
        self.addChild(scrollingMountainsFront!)
    }
    
    func setupPlayer() {
        playerNode = SKSpriteNode(imageNamed: "face")
        playerNode?.size = CGSize(width: 50, height: 50)
        playerNode?.position = CGPoint(x: 60, y: groundLevel)
        playerNode?.zPosition = 10
        playerNode?.name = "playerNode"
        
        playerNode?.physicsBody = SKPhysicsBody(circleOfRadius: (playerNode?.size.width)! / 2)
        playerNode?.physicsBody?.categoryBitMask = PhysicsCategory.player
        playerNode?.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.ground
        playerNode?.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.ground
        playerNode?.physicsBody?.affectedByGravity = true
        playerNode?.physicsBody?.isDynamic = true
        playerNode?.physicsBody?.density = 4
        self.addChild(playerNode!)
    }
    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 10"
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: (scene?.size.width)! / 2, y: (scene?.size.height)! - 100)
        scoreLabel.zPosition = 20
        self.addChild(scoreLabel)
    }
    
    func setupHighScoreLabel() {
        highScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        highScoreLabel.text = "High Score: \(highScore)"
        highScoreLabel.fontSize = 10
        highScoreLabel.horizontalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: (scene?.size.width)! / 5, y: (scene?.size.height)! - 50)
        highScoreLabel.zPosition = 20
        self.addChild(highScoreLabel)
    }
    
    func updateHighScore() {
        if highScore < score {
            highScore = score
            highScoreLabel.text = "\(highScore)"
            saveHighScore()
        }
    }
    
    func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "highScore")
    }
    
    func updateScore() {
        score += 1
        scoreLabel?.text = "\(score)"
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        numberOfJumpsLeft = 2
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        updateScore()
        
        playerNode?.zRotation -= 0.1
        //spark.zRotation += 0.1
        
        if let scrollGround = self.scrollingGround {
            scrollGround.update(currentTime: currentTime)
        }
        
        if let scrollMountainsBack = self.scrollingMountainsBack {
            scrollMountainsBack.update(currentTime: currentTime)
        }
        
        if let scrollMountainsFront = self.scrollingMountainsFront {
            scrollMountainsFront.update(currentTime: currentTime)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerJump()
    }
    
    func playerJump() {
        print("Number of jumps left: \(numberOfJumpsLeft)")
        if numberOfJumpsLeft == 2 {
            playJumpSound()
            playerNode?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            playerNode?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 200))
            numberOfJumpsLeft = 1
        }
        else if numberOfJumpsLeft == 1 {
            playJumpSound()
            playerNode?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            playerNode?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 200))
            numberOfJumpsLeft = 0
        }
    }
    
    func playJumpSound() {
        self.run(SKAction.playSoundFileNamed("myman.mp3", waitForCompletion: false))
    }
    
    func playGameOverSound() {
        self.run(SKAction.playSoundFileNamed("notreallyfine.mp3", waitForCompletion: true))
    }
    
    override func didSimulatePhysics() {
        playerNode?.position.x += xAcceleration * 5
        
        if Int((playerNode?.position.x)!) < -50 || Int((playerNode?.position.x)!) > Int((self.scene?.size.width)!) + 50 {
            print("Player out of bounds!")
            self.removeAllChildren()
            self.removeAllActions()
            updateHighScore()
            score = 0
            setupGameScene()
            playGameOverSound()
            loadGrayFilter()
        }
    }
    
    func createObstacle(type : Obstacles, height: Heights) -> SKShapeNode? {
        
        obstacleSprite = SKShapeNode()
        
        switch type {
        case .small:
            obstacleSprite.path = CGPath(roundedRect: CGRect(x: -10, y: 0, width: 100, height: 70), cornerWidth: 18, cornerHeight: 18, transform: nil)
            //obstacleSprite.fillColor = UIColor(red: 0.4431, green: 0.5567, blue: 0.7345, alpha: 1)
        case .medium:
            obstacleSprite.path = CGPath(roundedRect: CGRect(x: -10, y: 0, width: 200, height: 100), cornerWidth: 18, cornerHeight: 18, transform: nil)
            //obstacleSprite.fillColor = UIColor(red: 0.1003, green: 0.4567, blue: 0.8335, alpha: 1)
        case .big:
            obstacleSprite.path = CGPath(roundedRect: CGRect(x: -10, y: 0, width: 500, height: 130), cornerWidth: 18, cornerHeight: 18, transform: nil)
            //obstacleSprite.fillColor = UIColor(red: 0.1431, green: 0.1567, blue: 0.2325, alpha: 1)
        }
        
        obstacleSprite.strokeColor = UIColor.black
        obstacleSprite.fillColor = UIColor.clear
        
        let randomHeights : CGFloat
        
        switch height {
        case .low:
            randomHeights = groundLevel - 50
        case .mid:
            randomHeights = groundLevel + 60
        case .high:
            randomHeights = groundLevel + 100
        }
        
        obstacleSprite.position = CGPoint(x: (self.scene?.size.width)!, y: randomHeights)
        obstacleSprite.zPosition = 12
        
        return obstacleSprite
    }
    
    func spawnObstacle() {
        let randomObstacleType = Obstacles(rawValue: GKRandomSource.sharedRandom().nextInt(upperBound: 3))!
        let randomHeight = Heights(rawValue: GKRandomSource.sharedRandom().nextInt(upperBound: 3))!
        
        if let newObstacle = createObstacle(type: randomObstacleType, height: randomHeight) {
            newObstacle.physicsBody = SKPhysicsBody(edgeChainFrom: newObstacle.path!)
            newObstacle.name = "obstacleSprite"
            newObstacle.physicsBody?.categoryBitMask = PhysicsCategory.wall
            newObstacle.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.ground
            newObstacle.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground
            newObstacle.physicsBody?.friction = 0.1
            newObstacle.physicsBody?.affectedByGravity = true
            newObstacle.physicsBody?.isDynamic = true
            
            self.addChild(newObstacle)
            moveObstacle(obstacle: newObstacle)
            if newObstacle.position.x < 0 {
                newObstacle.removeFromParent()
            }
            
            // Remove node after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                newObstacle.removeFromParent()
            }
        }
    }
    
    func moveObstacle(obstacle: SKShapeNode) {
        let randomSpeed = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 500) - 800)
        obstacle.physicsBody?.velocity = CGVector(dx: randomSpeed, dy: 0)
    }
        
    
}

//
//  BallViewController.swift
//  BallA5
//
//  Created by iMac21.5 on 5/24/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit
import AVFoundation

class BallViewController: UIViewController, UICollisionBehaviorDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var gameView: UIView!
    var breakout = BreakoutBehavior()

    struct Constants {
        static let BallSize: CGFloat = 40.0
        static let BallColor = "Yellow"
        static let CourtColor = "Purple"
        static let BoxPathName = "Box"
        static let PaddlePathName = "Paddle"
        static let PaddleColor = "Green"
        static let PaddleSize = CGSize(width: 80.0, height: 20.0)
        static let PaddleCornerRadius: CGFloat = 5.0
        static let BrickColumns = 10
        static let BallSpeed: Float = 1.0
        static let BrickCornerRadius: CGFloat = 10.0
        static let BrickTotalWidth: CGFloat = 1.0
        static let BrickTotalHeight: CGFloat = 0.3
        static let BrickTopSpacing: CGFloat = 0.05
        static let BrickSpacing: CGFloat = 7.0
        static let BrickColors = [UIColor.random, UIColor.random, UIColor.random]
        //static let BrickColors = [UIColor.greenColor(), UIColor.blueColor(), UIColor.redColor(), UIColor.yellowColor()]
    }
    lazy var animator: UIDynamicAnimator = { UIDynamicAnimator(referenceView: self.gameView) }()
    lazy var uid: String = {
        if let login = NSUserDefaults.standardUserDefaults().stringForKey("User.Login") {
            return login
        } else { return "" }
    }()
    var paddleWidthMultiplier = 2
    var paddleSize = Constants.PaddleSize
    //lazy var soundOn: Bool = { return NSUserDefaults.standardUserDefaults().boolForKey("Sound.F/X") }()
    lazy var cornerRadius: CGFloat = {
        //The radius of each corner oval. A value of 0 results in a rectangle without rounded corners. Values larger than half the rectangle’s width or height are clamped appropriately to half the width or height.
        if let cr = Double(NSUserDefaults.standardUserDefaults().floatForKey("Corner.Radius")) as Double? {
            if cr > 0 { return CGFloat(cr) }
        }
        return Constants.BrickCornerRadius
        }()
    
    private var bricks = [Int:Brick]()
    //Store this structure for each brick in a dictionary:
    private struct Brick {
        var relativeFrame: CGRect
        var view: UIView
        var action: BrickAction
    }
    private typealias BrickAction = ((Int) -> Void)?
    
    //To start balls automatically, add a timer which periodically checks, if there is a ball (or the maximum number of balls) and push them if necessary.
    var autoStartTimer: NSTimer?
    var audioPlayer: AVAudioPlayer!
    func prepareAudios() {
        let path = NSBundle.mainBundle().pathForResource("jazzloop2_70", ofType: "mp3")
        let url = NSURL.fileURLWithPath(path!)
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: nil)
        audioPlayer.delegate = self
        audioPlayer.numberOfLoops = 99 //-1 means continuous
        audioPlayer.prepareToPlay()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareAudios()
        self.hidesBottomBarWhenPushed = true
        animator.addBehavior(breakout)
        let defaultColumns = min(Int(gameView.bounds.maxX / paddleSize.width), Constants.BrickColumns)
        Settings(defaultColumns: defaultColumns, defaultRows: defaultColumns / 2, defaultBalls: 1, defaultDifficulty: 1, defaultSpeed: Constants.BallSpeed, defaultBallColor: Constants.BallColor, defaultCourtColor: Constants.CourtColor, defaultPaddleColor: Constants.PaddleColor, defaultPaddleWidthMultiplier: paddleWidthMultiplier, defaultBrickCornerRadius: Float(Constants.BrickCornerRadius) )
        gameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushBall:"))
        gameView.layer.backgroundColor = UIColor.colorFor(Settings().courtColor).CGColor
        //The pan gesture handles most movement. However in the heat of the game it might be necessary to move faster-that’s what the left and right swipe gestures r4
        gameView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "panPaddle:"))
        gameView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "showTabBar:"))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "swipePaddleLeft:")
        swipeLeft.direction = .Left
        gameView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "swipePaddleRight:")
        swipeRight.direction = .Right
        gameView.addGestureRecognizer(swipeRight)
        breakout.collisionDelegate = self
        self.tabBarController?.tabBar.hidden = true
        levelOne()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //Settings().type stuff set here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        breakout.speed = CGFloat(Settings().speed!)
        breakout.ballBehavior.allowsRotation = Settings().ballRotation
        gameView.layer.backgroundColor = UIColor.colorFor(Settings().courtColor).CGColor
        
        let pw = (CGFloat(Settings().paddleWidthMultiplier!) * Constants.BallSize)
        paddleSize = CGSize(width: pw, height: 20.0)
        paddle.frame.size = paddleSize
        paddle.layer.backgroundColor = UIColor.colorFor(Settings().paddleColor).CGColor
        
        if Settings().soundOn { self.audioPlayer.play() }
        cornerRadius = CGFloat(Settings().cornerRadius!) * BallViewController.Constants.BrickCornerRadius
        if Settings().changed {
            Settings().changed = false
            for (index, brick) in bricks {
                brick.view.removeFromSuperview()
            }
            bricks.removeAll(keepCapacity: true)
            
            for ball in breakout.balls {
                ball.removeFromSuperview()
            }
            animator.removeAllBehaviors()
            breakout = BreakoutBehavior()
            animator.addBehavior(breakout)
            breakout.collisionDelegate = self
            levelOne()
        }
        setAutoStartTimer()
      }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        autoStartTimer?.invalidate()
        autoStartTimer = nil
    }
    //The timer will be started only when the configuration is set to do so:
    private func setAutoStartTimer() {
        if Settings().autoStart {
            autoStartTimer =  NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "fireAutoStart:", userInfo: nil, repeats: true)
        }
    }
    //When the timer fires – and there are not “enough” balls, create a new one, place it, add it to the behavior and push it:
    func fireAutoStart(timer: NSTimer) {
        if breakout.balls.count < Settings().balls {
            let ball = createBall()
            placeBall(ball)
            breakout.addBall(ball)
            breakout.pushBall(breakout.balls.last!)
        }
    }
    var score = 0
    // MARK: - ball
    func createBall() -> UIView {
        let ballSize = CGSize(width: Constants.BallSize, height: Constants.BallSize)
        let ball = UIView(frame: CGRect(origin: CGPoint.zeroPoint, size: ballSize))
        score -= 1
        ball.layer.backgroundColor = UIColor.colorFor(Settings().ballColor).CGColor
        if let loggedInUser = User.login(uid, password: "foo") {
            ball.layer.contents = loggedInUser.image!.CGImage
            ball.layer.contentsGravity = kCAGravityCenter
            ball.layer.contentsScale = 2.0
        }
        ball.layer.cornerRadius = Constants.BallSize / 2.0
        ball.layer.borderColor = UIColor.blackColor().CGColor
        ball.layer.borderWidth = 2.0
        ball.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        ball.layer.shadowOpacity = 0.5
        return ball
    }
    func placeBall(ball: UIView) {
        //ball.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)  //from ball game
        var center = paddle.center
        center.y -= paddleSize.height/2 + Constants.BallSize/2
        ball.center = center
    }
    func pushBall(gesture: UITapGestureRecognizer) { //*** lots happening here!
        if gesture.state == .Ended {
            //if breakout.balls.count == 0 {
            if breakout.balls.count < Settings().balls {
                let ball = createBall()
                placeBall(ball)
                breakout.addBall(ball)
            }
            breakout.pushBall(breakout.balls.last!)
        }
    }
    
    // MARK: - paddle
    lazy var paddle: UIView = {
        let paddle = UIView(frame: CGRect(origin: CGPoint(x: -1 , y: -1), size: self.paddleSize))
        paddle.layer.backgroundColor = UIColor.colorFor(Settings().paddleColor).CGColor
        paddle.layer.cornerRadius = Constants.PaddleCornerRadius
        paddle.layer.borderColor = UIColor.blackColor().CGColor
        paddle.layer.borderWidth = 2.0
        paddle.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        paddle.layer.shadowOpacity = 0.5
        
        self.gameView.addSubview(paddle)
        return paddle
        }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var gameRect = gameView.bounds
        gameRect.size.height *= 2
        breakout.addBarrier(UIBezierPath(rect: gameRect), named: Constants.BoxPathName)
        //Its not nice if the player looses a ball because the device has been rotated accidentally. In such cases put the ball back on screen:
        for ball in breakout.balls {
            if !CGRectContainsRect(gameView.bounds, ball.frame) {
                placeBall(ball)
                animator.updateItemUsingCurrentState(ball)
            }
        }
        placeBricks()
        //When the paddle is outside the game view (at the beginning and possibly after device roatation), reset its position:
        resetPaddle()
    }
    func resetPaddle() {
        paddle.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.maxY - paddle.bounds.height)
        addPaddleBarrier()
    }
    func addPaddleBarrier() {
        breakout.addBarrier(UIBezierPath(roundedRect: paddle.frame, cornerRadius: Constants.PaddleCornerRadius), named: Constants.PaddlePathName)
    }
    //While panning change the position of the paddle according to the panned distance. For swipes move to the far left or right:
    func panPaddle(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            placePaddle(gesture.translationInView(gameView))
            gesture.setTranslation(CGPointZero, inView: gameView)
        default: break
        }
    }
    func showTabBar(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            self.tabBarController?.tabBar.hidden = false
        default: break
        }
    }
    func swipePaddleLeft(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            placePaddle(CGPoint(x: -gameView.bounds.maxX, y: 0.0))
        default: break
        }
    }
    func swipePaddleRight(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            placePaddle(CGPoint(x: gameView.bounds.maxX, y: 0.0))
        default: break
        }
    }
    //To change the position of the paddle, change its origin – but take care, not to move it off screen:
    func placePaddle(translation: CGPoint) {
        var origin = paddle.frame.origin
        origin.x = origin.x + translation.x
//        origin.y = gameView.bounds.maxY - Constants.PaddleSize.height
        paddle.frame.origin = origin
        addPaddleBarrier()
    }
    // MARK: - bricks 
    //just takes the relative frame information boosts it to the device dimensions, and adjusts the barriers for the collision behavior:
    func placeBricks() {
        for (index, brick) in bricks {
            brick.view.frame.origin.x = brick.relativeFrame.origin.x * gameView.bounds.width
            brick.view.frame.origin.y = brick.relativeFrame.origin.y * gameView.bounds.height
            brick.view.frame.size.width = brick.relativeFrame.width * gameView.bounds.width
            brick.view.frame.size.height = brick.relativeFrame.height * gameView.bounds.height
            brick.view.frame = CGRectInset(brick.view.frame, Constants.BrickSpacing, Constants.BrickSpacing)
            breakout.addBarrier(UIBezierPath(roundedRect: brick.view.frame, cornerRadius: cornerRadius), named: index)
        }
    }
    // MARK: - Lifecycle
    func levelOne() {
        if bricks.count > 0 { return }
        //To use the number of rows and columns from the settings use those values in setup...
        let deltaX = Constants.BrickTotalWidth / CGFloat(Settings().columns!)
        let deltaY = Constants.BrickTotalHeight / CGFloat(Settings().rows!)
        var frame = CGRect(origin: CGPointZero, size: CGSize(width: deltaX, height: deltaY))
        for row in 0..<Settings().rows! {
            for column in 0..<Settings().columns! {
                frame.origin.x = deltaX * CGFloat(column)
                frame.origin.y = deltaY * CGFloat(row) + Constants.BrickTopSpacing
                let brick = UIView(frame: frame)
                //brick.backgroundColor = Constants.BrickColors[row % Constants.BrickColors.count]
                brick.backgroundColor = UIColor.random
                brick.layer.cornerRadius = cornerRadius
                brick.layer.borderWidth = 1.5
                brick.layer.borderColor = UIColor.blackColor().CGColor
                brick.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
                brick.layer.shadowOpacity = 0.5
                
                gameView.addSubview(brick)
                
                var action: BrickAction = nil
                //Add the “black” row only when the difficulty “hard” has been chosen:
                if Settings().difficulty == 1 {
                    if row + 1 == Settings().rows! {
                    //if row + 1 == brickRows {
                        brick.backgroundColor = UIColor.blackColor()
                        action = { index in
                            if brick.backgroundColor != UIColor.blackColor() {
                                self.destroyBrickAtIndex(index)
                            } else {
                                NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "changeBrickColor:", userInfo: brick, repeats: false)
                            }
                        }
                    }
                }
                bricks[row * Settings().columns! + column] = Brick(relativeFrame: frame, view: brick, action: action)
            }
        }
    }
    func changeBrickColor(timer: NSTimer) {
        if let brick = timer.userInfo as? UIView {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                brick.backgroundColor = UIColor.cyanColor()
                }, completion: nil)
        }
    }
    //When a collision appears and the barrier identifier is an integer (equals a brick), destroy the brick:
    //Change the collision method to destroy bricks only if no special action for that brick has been defined, otherwise run that action:
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying, atPoint p: CGPoint) {
        if let index = identifier as? Int {
            if let action = bricks[index]?.action {
                action(index)
            } else {
                destroyBrickAtIndex(index)
            }
        }
    }
    //First remove the barrier – then core animate flip the brick (and make it slightly transparent). Afterwards add it to the behavior, and let it fade out completely. Finally remove the brick from the behavior, the game view and from the brick array:
    private func destroyBrickAtIndex(index: Int) {
        breakout.removeBarrier(index)
        if let brick = bricks[index] {
            UIView.transitionWithView(brick.view, duration: 0.2, options: .TransitionFlipFromBottom, animations: {
                brick.view.alpha = 0.8  //0.5
                }, completion: { (success) -> Void in
                    self.breakout.addBrick(brick.view)
                    UIView.animateWithDuration(1.2, animations: {  //1.0
                        brick.view.alpha = 0.0  //disappear
                        }, completion: { (success) -> Void in
                            self.score += 10
                            self.breakout.removeBrick(brick.view)
                            brick.view.removeFromSuperview()
                    })
            })
            bricks.removeValueForKey(index)
            if self.bricks.count == 0 {
                self.levelFinished()
            }
        }
    }
    //Don’t forget to remove the timer when a game has finished, and start it again afterwards...setAutStart
    func levelFinished() {
        autoStartTimer?.invalidate()
        autoStartTimer = nil
        for ball in breakout.balls {
            breakout.removeBall(ball)
        }
        if NSClassFromString("UIAlertController") != nil {
            let alertController = UIAlertController(title: "You Won!  score = \(score)", message: "", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Play Again", style: .Default, handler: { (action) in
                self.score = 0
                self.levelOne()
                self.setAutoStartTimer()
            }))
            alertController.addAction(UIAlertAction(title: "Quit", style: .Default, handler: { (action) in
                self.score = 0
                exit(0)
            }))
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: "Game Over", message: "asdf", delegate: self, cancelButtonTitle: "Play Again")
            alertView.show()
        }
    }
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        levelOne()
        setAutoStartTimer()
        placeBricks()
    }
}

private extension UIColor {
    class func colorFor(sel: String) -> UIColor {
        switch sel {
        case "Green": return UIColor.greenColor()
        case "Blue": return UIColor.blueColor()
        case "Orange": return UIColor.orangeColor()
        case "Red": return UIColor.redColor()
        case "Purple": return UIColor.purpleColor()
        case "Yellow": return UIColor.yellowColor()
        case "Cyan": return UIColor.cyanColor()
        case "White": return UIColor.whiteColor()
        case "Black": return UIColor.blackColor()
        default: return UIColor.blackColor()
        }
    }
    class var random: UIColor {
        switch arc4random() % 10 {
        case 0: return UIColor.greenColor()
        case 1: return UIColor.blueColor()
        case 2: return UIColor.orangeColor()
        case 3: return UIColor.redColor()
        case 4: return UIColor.purpleColor()
        case 5: return UIColor.yellowColor()
        case 6: return UIColor.brownColor()
        case 7: return UIColor.darkGrayColor()
        case 8: return UIColor.lightGrayColor()
        case 9: return UIColor.cyanColor()
        default: return UIColor.blackColor()
        }
    }
}

// User can't itself have anything UI-related
// but we can add a private UI-specific property
private extension User {
    var image: UIImage? {
        if let image = UIImage(named: login) {
            return image
        } else {
            return UIImage(named: "tennis")!
        }
    }
}
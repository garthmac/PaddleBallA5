//
//  BallViewController.swift
//  BallA5
//
//  Created by iMac21.5 on 5/24/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class BallViewController: UIViewController, UICollisionBehaviorDelegate {

    @IBOutlet weak var gameView: UIView!
    
    let breakout = BreakoutBehavior()
    lazy var animator: UIDynamicAnimator = { UIDynamicAnimator(referenceView: self.gameView) }()
    var ballColor: CGColor = {
        if let bc = NSUserDefaults.standardUserDefaults().stringForKey("Ball.Color") {
            return UIColor.colorFor(bc).CGColor
        } else { return UIColor.whiteColor().CGColor }
    }()
    lazy var paddleColor: CGColor = {
        if let pc = NSUserDefaults.standardUserDefaults().stringForKey("Paddle.Color") {
            return UIColor.colorFor(pc).CGColor
        } else { return UIColor.whiteColor().CGColor }
    }()
    lazy var courtColor: CGColor = {
        if let cc = NSUserDefaults.standardUserDefaults().stringForKey("Court.Color") {
            return UIColor.colorFor(cc).colorWithAlphaComponent(0.6).CGColor
        } else { return UIColor.blackColor().CGColor }
    }()
    lazy var uid: String = {
        if let login = NSUserDefaults.standardUserDefaults().stringForKey("User.Login") {
            return login
        } else { return "" }
    }()
    lazy var paddleSize: CGSize = {
        if let pw = NSUserDefaults.standardUserDefaults().doubleForKey("Paddle.Width") as Double? {
            if pw > 0 { return CGSize(width: pw, height: 20.0) }
        }
    return CGSize(width: 80.0, height: 20.0)
    }()
    lazy var soundOn: Bool = { return NSUserDefaults.standardUserDefaults().boolForKey("Sound.F/X")
        }()
    lazy var cornerRadius: CGFloat = {
        //The radius of each corner oval. A value of 0 results in a rectangle without rounded corners. Values larger than half the rectangle’s width or height are clamped appropriately to half the width or height.
        if let cr = Double(NSUserDefaults.standardUserDefaults().floatForKey("Corner.Radius")) as Double? {
            if cr > 0 { return CGFloat(cr) }
        }
        return 5.0
        }()
    var score = 0
    private var bricks = [Int:Brick]()
    //Store this structure for each brick in a dictionary:
    private struct Brick {
        var relativeFrame: CGRect
        var view: UIView
        var action: BrickAction
    }
    private typealias BrickAction = ((Int) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(breakout)
        gameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushBall:"))
        gameView.layer.backgroundColor = courtColor
        //The pan gesture handles most movement. However in the heat of the game it might be necessary to move faster-that’s what the left and right swipe gestures r4
        gameView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "panPaddle:"))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "swipePaddleLeft:")
        swipeLeft.direction = .Left
        gameView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "swipePaddleRight:")
        swipeRight.direction = .Right
        gameView.addGestureRecognizer(swipeRight)
        
        breakout.collisionDelegate = self
        //Because my game has only one level I define it when the view did load:
        levelOne()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let bc = NSUserDefaults.standardUserDefaults().stringForKey("Ball.Color") {
            ballColor = UIColor.colorFor(bc).CGColor
        }
        if let pc = NSUserDefaults.standardUserDefaults().stringForKey("Paddle.Color") {
            paddleColor = UIColor.colorFor(pc).CGColor
        }
        if let cc = NSUserDefaults.standardUserDefaults().stringForKey("Court.Color") {
            courtColor = UIColor.colorFor(cc).CGColor
        }
        if let login = NSUserDefaults.standardUserDefaults().stringForKey("User.Login") {
            uid = login
        }
        if let pw = NSUserDefaults.standardUserDefaults().doubleForKey("Paddle.Width") as Double? {
            paddleSize = CGSize(width: pw, height: 20.0)
        }
        if NSUserDefaults.standardUserDefaults().boolForKey("Sound.F/X") == true {
            soundOn = true
        } else { soundOn = false }
        if let cr = Double(NSUserDefaults.standardUserDefaults().floatForKey("Corner.Radius")) as Double? {
            cornerRadius = CGFloat(cr)
        }
    }
    func createBall() -> UIView {
        let ballSize = CGSize(width: Constants.BallSize, height: Constants.BallSize)
        let ball = UIView(frame: CGRect(origin: CGPoint.zeroPoint, size: ballSize))
        //ball.backgroundColor = ballColor
        ball.layer.backgroundColor = ballColor
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
        //ball.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)  //ball only game
        var center = paddle.center
        center.y -= paddleSize.height/2 + Constants.BallSize/2
        ball.center = center
    }
    func pushBall(gesture: UITapGestureRecognizer) { //*** lots happening here!
        if gesture.state == .Ended {
            if breakout.balls.count == 0 {
                let ball = createBall()
                placeBall(ball)
                breakout.addBall(ball)
            }
            breakout.pushBall(breakout.balls.last!)
        }
    }
    
    struct Constants {
        static let BallSize: CGFloat = 40.0
        //static let BallColor = UIColor.yellowColor()
        static let BoxPathName = "Box"
        static let PaddlePathName = "Paddle"
        //static let PaddleSize = CGSize(width: 80.0, height: 20.0)
        static let PaddleCornerRadius: CGFloat = 5.0
        //static let PaddleColor = UIColor.greenColor()
        //static let BrickColumns = 10
        //static let BrickRows = 5
        static let BrickTotalWidth: CGFloat = 1.0
        static let BrickTotalHeight: CGFloat = 0.3
        static let BrickTopSpacing: CGFloat = 0.05
        static let BrickSpacing: CGFloat = 7.0
        //static let BrickCornerRadius: CGFloat = 5.0
        //static let BrickColors = [UIColor.greenColor(), UIColor.blueColor(), UIColor.redColor(), UIColor.yellowColor()]
        static let BrickColors = [UIColor.random, UIColor.random]
    }
    
    lazy var paddle: UIView = {
        let paddle = UIView(frame: CGRect(origin: CGPoint(x: -1 , y: -1), size: self.paddleSize))
        paddle.layer.backgroundColor = self.paddleColor
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
//        println("paddle = \(paddle.frame.origin)")
//        println("maxY = \(gameView.bounds)")
//            let halfPaddleWidth = Constants.PaddleSize.width / 2
//            let center = gameView.bounds.maxX / 2 - halfPaddleWidth
//            println("center = \(center)")
//            let x = center - paddle.frame.origin.x
//            println("x = \(x)")
//            placePaddle(CGPoint(x: x, y: 0))
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
    //Placing the bricks, just takes the relative frame information boosts it to the device dimensions, and adjusts the barriers for the collision behavior:
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
    func levelOne() {
        if bricks.count > 0 { return }
        let brickColumns = min(Int(gameView.bounds.maxX / paddleSize.width), 10)
        let brickRows = brickColumns / 2        //more than 5 slows pushBall() too much
        let deltaX = Constants.BrickTotalWidth / CGFloat(brickColumns)
        let deltaY = Constants.BrickTotalHeight / CGFloat(brickRows)
        var frame = CGRect(origin: CGPointZero, size: CGSize(width: deltaX, height: deltaY))

        for row in 0..<brickRows {
            for column in 0..<brickColumns {
                frame.origin.x = deltaX * CGFloat(column)
                frame.origin.y = deltaY * CGFloat(row) + Constants.BrickTopSpacing
                let brick = UIView(frame: frame)
                brick.backgroundColor = Constants.BrickColors[row % Constants.BrickColors.count]
                brick.layer.cornerRadius = cornerRadius
                brick.layer.borderWidth = 1.5
                brick.layer.borderColor = UIColor.blackColor().CGColor
                brick.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
                brick.layer.shadowOpacity = 0.5
                
                gameView.addSubview(brick)
                
                var action: BrickAction = nil
                if row + 1 == brickRows {
                    brick.backgroundColor = UIColor.blackColor()
                    action = { index in
                        if brick.backgroundColor != UIColor.blackColor() {
                            self.destroyBrickAtIndex(index)
                        } else {
                            NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "changeBrickColor:", userInfo: brick, repeats: false)
                        }
                    }
                }
                bricks[row * brickColumns + column] = Brick(relativeFrame: frame, view: brick, action: action)
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
    //First remove the barrier – even if it. We core animation flip the brick (and make it slightly transparent). Afterwards add it to the behavior, and let it fade out completely. Finally remove the brick from the behavior, the game view and from the brick array:
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
                            self.score += 1
                            self.breakout.removeBrick(brick.view)
                            brick.view.removeFromSuperview()
                    })
            })
            bricks.removeValueForKey(index)
        }
    }

}

private extension UIColor {
    class func colorFor(sel: String) -> UIColor {
        switch sel {
        case "G": return UIColor.greenColor()
        case "B": return UIColor.blueColor()
        case "O": return UIColor.orangeColor()
        case "R": return UIColor.redColor()
        case "P": return UIColor.purpleColor()
        case "Y": return UIColor.yellowColor()
        case "C": return UIColor.cyanColor()
        case "W": return UIColor.whiteColor()
        default: return UIColor.blackColor()
        }
    }
}

private extension UIColor {
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

// User is our Model,
// so it can't itself have anything UI-related
// but we can add a UI-specific property
// just for us to use
// because we are the Controller
// note this extension is private
private extension User {
    var image: UIImage? {
        if let image = UIImage(named: login) {
            return image
        } else {
            return UIImage(named: "tennis")!
        }
    }
}
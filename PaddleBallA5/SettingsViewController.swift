//
//  SettingsViewController.swift
//  
//
//  Created by iMac21.5 on 5/30/15.
//
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var difficultySelector: UISegmentedControl!
    @IBOutlet weak var autoStartSwitch: UISwitch!
    @IBOutlet weak var ballsLabel: UILabel!
    @IBOutlet weak var ballStepper: UIStepper!
    @IBOutlet weak var ballRotationSwitch: UISwitch!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var ballColorLabel: UILabel!
    @IBOutlet weak var ballColorPickerView: UIPickerView!
    @IBOutlet weak var courtColorLabel: UILabel!
    @IBOutlet weak var courtColorPickerView: UIPickerView!
    @IBOutlet weak var paddleColorLabel: UILabel!
    @IBOutlet weak var paddleColorPickerView: UIPickerView!
    @IBOutlet weak var paddleWidthStepper: UIStepper!
    @IBOutlet weak var paddleWidthLabel: UILabel!
    @IBOutlet weak var columnsLabel: UILabel!
    @IBOutlet weak var columnSlider: UISlider!
    @IBOutlet weak var rowsLabel: UILabel!
    @IBOutlet weak var rowSlider: UISlider!
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var brickRadiusLabel: UILabel!
    @IBOutlet weak var brickRadiusSlider: UISlider!
    
    var pickerDataSource = ["Green", "Blue", "Orange", "Red", "Purple", "Yellow", "Cyan", "White", "Black" ]
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int { return 1 } //number of columns in the picker
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return pickerDataSource[row]
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 { ballColor = pickerDataSource[row] }
        if pickerView.tag == 1 { courtColor = pickerDataSource[row] }
        if pickerView.tag == 2 { paddleColor = pickerDataSource[row] }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        ballColorPickerView.dataSource = self
        ballColorPickerView.delegate = self
        courtColorPickerView.dataSource = self
        courtColorPickerView.delegate = self
        paddleColorPickerView.dataSource = self
        paddleColorPickerView.delegate = self
    }
    var balls: Int {
        get { return ballsLabel.text!.toInt()! }
        set {
            ballsLabel.text = "\(newValue)"
            ballStepper.value = Double(newValue)
        }
    }
    var paddleWidthMultiplier: Int {
        get { return paddleWidthLabel.text!.toInt()! }
        set {
            paddleWidthLabel.text = "\(newValue)"
            paddleWidthStepper.value = Double(newValue)
        }
    }
    var difficulty: Int {
        get { return difficultySelector.selectedSegmentIndex }
        set { difficultySelector.selectedSegmentIndex = newValue }
    }
    var autoStart: Bool {
        get { return autoStartSwitch.on }
        set { autoStartSwitch.on = newValue }
    }
    var ballRotation: Bool {
        get { return ballRotationSwitch.on }
        set { ballRotationSwitch.on = newValue }
    }
    var sound: Bool {
        get { return soundSwitch.on }
        set { soundSwitch.on = newValue }
    }
    @IBAction func ballsChanged(sender: UIStepper) {
        balls = Int(sender.value)
        Settings().balls = balls
    }
    @IBAction func paddleWidthChanged(sender: UIStepper) {
        paddleWidthMultiplier = Int(sender.value)
        Settings().paddleWidthMultiplier = paddleWidthMultiplier
    }
    @IBAction func difficultyChanged(sender: UISegmentedControl) {
        Settings().difficulty = difficulty
        if difficulty == 0 {
            paddleWidthMultiplier = max(paddleWidthMultiplier, 4)
        }
        else {
            paddleWidthMultiplier = min(paddleWidthMultiplier, 2)
        }
        paddleWidthChanged(paddleWidthStepper)
    }
    @IBAction func autoStartChanged(sender: UISwitch) {
        Settings().autoStart = autoStart
    }
    @IBAction func ballRotationChanged(sender: UISwitch) {
        Settings().ballRotation = ballRotation
    }
    @IBAction func soundChanged(sender: UISwitch) {
        Settings().soundOn = sound
    }
    var speed: Float {
        get { return speedSlider.value / 100.0}
        set {
            speedSlider.value = newValue * 100.0
            speedLabel.text = "\(Int(speedSlider.value)) %"
        }
    }
    @IBAction func speedChanged(sender: UISlider) {
        speed = sender.value / 100.0
        Settings().speed = speed
    }
    var cornerRadius: Float {
        get { return brickRadiusSlider.value / 100.0}
        set {
            brickRadiusSlider.value = newValue * 100.0
            brickRadiusLabel.text = "\(Int(brickRadiusSlider.value)) %"
        }
    }
    @IBAction func radiusChanged(sender: UISlider) {
        cornerRadius = sender.value / 100.0
        Settings().cornerRadius = cornerRadius
        Settings().changed = true
    }
    var ballColor: String {
        get { return ballColorLabel.text! }
        set {
            ballColorLabel.text = "\(newValue)"
            Settings().ballColor = "\(newValue)"
        }
    }
    var courtColor: String {
        get { return courtColorLabel.text! }
        set {
            courtColorLabel.text = "\(newValue)"
            Settings().courtColor = "\(newValue)"
        }
    }
    var paddleColor: String {
        get { return paddleColorLabel.text! }
        set {
            paddleColorLabel.text = "\(newValue)"
            Settings().paddleColor = "\(newValue)"
        }
    }
    var columns: Int {
        get { return columnsLabel.text!.toInt()! }
        set {
            columnsLabel.text = "\(newValue)"
            columnSlider.value = Float(newValue)
        }
    }
    @IBAction func columnsChanged(sender: UISlider) {
        columns = Int(sender.value)
        if columns > 11 {
            cornerRadius = min(cornerRadius, 1.0)
            radiusChanged(brickRadiusSlider)
        }
        //println("cornerRadius = \(cornerRadius) speed = \(speed)")
        Settings().columns = columns
        Settings().changed = true
    }
    var rows: Int {
        get { return rowsLabel.text!.toInt()! }
        set {
            rowsLabel.text = "\(newValue)"
            rowSlider.value = Float(newValue)
        }
    }
    @IBAction func rowsChanged(sender: UISlider) {
        rows = Int(sender.value)
        Settings().rows = rows
        Settings().changed = true
    }
    //When the view will appear (e.g. when switching back from the settings tab), check if something has changed. Reset the changed property. Remove all existing bricks from the view and destroy them. Remove any balls left. Reset the animator and the breakout behavior. Finally, recreate the bricks with the new settings. To be able to reset the breakout behavior, change it from let to var
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        balls = Settings().balls!
        difficulty = Settings().difficulty!
        autoStart = Settings().autoStart
        columns = Settings().columns!
        rows = Settings().rows!
        speed = Settings().speed!
        ballColor = Settings().ballColor
        courtColor = Settings().courtColor
        paddleColor = Settings().paddleColor
        cornerRadius = Settings().cornerRadius!
        paddleWidthMultiplier = Settings().paddleWidthMultiplier!
    }

}


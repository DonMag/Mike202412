//
//  OverridesViewController.swift
//  Mike202412
//
//  Created by Don Mag on 12/16/24.
//

import UIKit
import AudioToolbox

class OverridesViewController: UIViewController, UITextFieldDelegate {
	/// Default values
	private var courtWidth: Double = 20.0
	private var courtLength: Double = 44.0
	private var lineWidth: Double = 2.0
	private var ballType: String = "Franklin"
	private var ballContact: Double = 1.25
	private var lineColor: String = "White"
	private var alertSound: SystemSoundID = 1005
	private var useMetric: Bool = false
	
	private let formStack = UIStackView()
	
	private var textFields: [UITextField] = []
	private var unitLabels: [UILabel] = []
	private var unitToggle: UISwitch!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black
		
		kbToolbar = createToolbar()
		
		// presumably, you will be saving the values somewhere
		//	and you would load them here..
		
		// loadSavedValues()
		
		loadMetricSetting()
		
		// values have not yet been saved anywhere, so
		//	the default values are in feet/inches
		// if the saved "useMetricUnits" is TRUE,
		//	we need to update the units

		if useMetric {
			courtWidth = convertToMetric(courtWidth, isFeet: true)
			courtLength = convertToMetric(courtLength, isFeet: true)
			lineWidth = convertToMetric(lineWidth, isFeet: false)
			ballContact = convertToMetric(ballContact, isFeet: false)
		}
		
		setupForm()
		setupDefaultsButton()
		setupDismissKeyboardGesture()
		
		setupKeyboardHandlers()

	}
	
	// MARK: - Setup Methods
	
	private func loadMetricSetting() {
		useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
	}
	
	private func setupForm() {
		formStack.axis = .vertical
		formStack.spacing = 10
		
		// only add formStack if it's not already added
		if formStack.superview == nil {
			formStack.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(formStack)
			NSLayoutConstraint.activate([
				formStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
				formStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			])
		}
		
		// clear existing text field and unit label arrays
		textFields = []
		unitLabels = []
		
		addEditableField(label: "Court Width", value: courtWidth, key: \.courtWidth, isFeet: true)
		addEditableField(label: "Court Length", value: courtLength, key: \.courtLength, isFeet: true)
		addEditableField(label: "Line Width", value: lineWidth, key: \.lineWidth, isFeet: false)
		addEditableField(label: "Ball Contact", value: ballContact, key: \.ballContact, isFeet: false)
		addEditableTextField(label: "Ball Type", text: ballType, key: \.ballType)
		addEditableTextField(label: "Line Color", text: lineColor, key: \.lineColor)
		addSoundPicker()
		addUnitToggle()
	}
	
	private func addEditableField<T>(label: String, value: T, key: WritableKeyPath<OverridesViewController, T>, isFeet: Bool) {
		let fieldLabel = createLabel(withText: label)
		
		let val = Double("\(value)") ?? 0
		let textField = createTextField(
			withValue: String(format: "%.2f", val),
			tag: formStack.arrangedSubviews.count,
			keyboardType: .decimalPad
		)
		textField.addTarget(self, action: #selector(textFieldValueChanged(_:)), for: .editingDidEnd)
		
		let unitLabel = createUnitLabel(forFeet: isFeet)
		unitLabel.tag = textField.tag
		
		// add the text field and unit label to arrays
		//	so we can track / manage them easier
		textFields.append(textField)
		unitLabels.append(unitLabel)
		
		let fieldStack = createHorizontalStack(withViews: [fieldLabel, textField, unitLabel])
		formStack.addArrangedSubview(fieldStack)
	}
	
	private func addEditableTextField(label: String, text: String, key: WritableKeyPath<OverridesViewController, String>) {
		let fieldLabel = createLabel(withText: label)
		
		let textField = createTextField(
			withValue: text,
			tag: formStack.arrangedSubviews.count,
			keyboardType: .asciiCapable
		)
		textField.addTarget(self, action: #selector(textFieldTextValueChanged(_:)), for: .editingDidEnd)
		
		textField.autocapitalizationType = .none
		textField.autocorrectionType = .no

		// add a "blank" unitLabel so the fields line-up
		let blankUnitLabel = createUnitLabel(forFeet: true)
		blankUnitLabel.text = ""
		
		// add the text field and unit label to arrays
		//	so we can track / manage them easier
		textFields.append(textField)
		unitLabels.append(blankUnitLabel)
		
		let fieldStack = createHorizontalStack(withViews: [fieldLabel, textField, blankUnitLabel])
		formStack.addArrangedSubview(fieldStack)
	}
	
	private func addSoundPicker() {
		let button = UIButton(type: .system)
		button.setTitle("Select Alert Sound", for: .normal)
		button.titleLabel?.font = .systemFont(ofSize: 16)
		button.addTarget(self, action: #selector(selectAlertSound), for: .touchUpInside)
		
		button.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(button)
		
		NSLayoutConstraint.activate([
			button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			button.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 20)
		])
		
		// formStack.addArrangedSubview(button)
	}
	
	private func addUnitToggle() {
		let toggleSwitch = UISwitch()
		toggleSwitch.isOn = useMetric
		
		/// Improved visibility settings
		toggleSwitch.onTintColor = .systemBlue   /// Active state
		toggleSwitch.thumbTintColor = .white     /// Thumb color
		toggleSwitch.backgroundColor = .darkGray /// Switch background
		toggleSwitch.layer.cornerRadius = 16     /// Rounded corners
		
		toggleSwitch.addTarget(self, action: #selector(toggleUnits(_:)), for: .valueChanged)
		
		let label = UILabel()
		label.text = "Use Metric Units"
		label.textColor = .white
		label.font = .systemFont(ofSize: 16)

		self.unitToggle = toggleSwitch
		
		let stack = createHorizontalStack(withViews: [label, toggleSwitch])
		formStack.addArrangedSubview(stack)
	}
	
	private func setupDefaultsButton() {
		let defaultsButton = UIButton(type: .system)
		defaultsButton.setTitle("Restore Defaults", for: .normal)
		defaultsButton.titleLabel?.font = .systemFont(ofSize: 16)
		defaultsButton.addTarget(self, action: #selector(restoreDefaults), for: .touchUpInside)
		
		defaultsButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(defaultsButton)
		
		NSLayoutConstraint.activate([
			defaultsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			defaultsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
		])
	}
	
	
	private func setupDismissKeyboardGesture() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tapGesture)
	}
	
	// MARK: - Actions
	@objc private func textFieldValueChanged(_ textField: UITextField) {
		guard let text = textField.text, let value = Double(text) else { return }
		guard let idx = textFields.firstIndex(of: textField) else { return }
		switch idx {
		case 0: courtWidth = value
		case 1: courtLength = value
		case 2: lineWidth = value
		case 3: ballContact = value
		default: break
		}
	}
	
	@objc private func textFieldTextValueChanged(_ textField: UITextField) {
		guard let text = textField.text else { return }
		guard let idx = textFields.firstIndex(of: textField) else { return }
		switch idx {
		case 4: ballType = text
		case 5: lineColor = text
		default: break
		}
	}
	
	@objc private func toggleUnits(_ sender: UISwitch) {
		// get current metric setting
		let wasMetric = useMetric
		
		// new metric setting
		useMetric = sender.isOn
		
		/// Save setting
		UserDefaults.standard.set(useMetric, forKey: "useMetricUnits")
		
		// if useMetric changed
		//	Update labels and values
		if useMetric != wasMetric {
			updateUnits(toMetric: useMetric)
		}
	}
	
	@objc private func selectAlertSound() {
		let alert = UIAlertController(title: "Select Sound", message: nil, preferredStyle: .actionSheet)
		for soundID in 1000...1351 {
			alert.addAction(UIAlertAction(title: "Sound \(soundID)", style: .default) { _ in
				self.alertSound = SystemSoundID(soundID)
				AudioServicesPlaySystemSound(self.alertSound)
			})
		}
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}
	
	@objc private func restoreDefaults() {
		courtWidth = 20.0
		courtLength = 44.0
		lineWidth = 2.0
		ballType = "Franklin"
		ballContact = 1.25
		lineColor = "White"
		alertSound = 1005
		useMetric = false
		reloadForm()
	}
	
	@objc private func dismissKeyboard() {
		view.endEditing(true)
	}
	
	private func updateUnits(toMetric: Bool) {
		
		// first two fields are in feet/meters
		for idx in 0..<2 {
			let tf = textFields[idx]
			let ul = unitLabels[idx]

			guard let value = Double(tf.text ?? "") else { continue }

			var convertedValue: Double = 0
			
			// if toMetric was passed as true
			//	that means values WERE in inches/feet
			if toMetric {
				convertedValue = convertToMetric(value, isFeet: true)
			} else {
				convertedValue = convertToImperial(value, isFeet: true)
			}
			
			tf.text = String(format: "%.2f", convertedValue)
			ul.text = toMetric ? "m" : "ft"
		}
		
		// next two fields are in inches/centimeters
		for idx in 2..<4 {
			let tf = textFields[idx]
			let ul = unitLabels[idx]
			
			guard let value = Double(tf.text ?? "") else { continue }
			
			var convertedValue: Double = 0
			
			// if toMetric was passed as true
			//	that means values WERE in inches/feet
			if toMetric {
				convertedValue = convertToMetric(value, isFeet: true)
			} else {
				convertedValue = convertToImperial(value, isFeet: true)
			}
			
			tf.text = String(format: "%.2f", convertedValue)
			ul.text = toMetric ? "cm" : "in"
		}

	}
	
	/*
	 Why This Fix Works
	 1.    Accurate Conversions: Only converts if the current units differ from the expected units.
	 2.    Correct Parsing: Properly parses and updates field text and labels.
	 3.    Persistence & Toggle Awareness: Considers both metric and imperial units dynamically.
	 */
	
	// MARK: - Helper Methods
	private func convertToMetric(_ value: Double, isFeet: Bool) -> Double {
		isFeet ? value * 0.3048 : value * 2.54
	}
	
	private func convertToImperial(_ value: Double, isFeet: Bool) -> Double {
		isFeet ? value / 0.3048 : value / 2.54
	}

	// reloadForm() is only called by restoreDefaults()
	//	which sets default values in ft/in
	private func reloadForm() {
		
		textFields[0].text = String(format: "%.2f", courtWidth)
		unitLabels[0].text = "ft"
		
		textFields[1].text = String(format: "%.2f", courtLength)
		unitLabels[1].text = "ft"
		
		textFields[2].text = String(format: "%.2f", lineWidth)
		unitLabels[2].text = "in"
		
		textFields[3].text = String(format: "%.2f", ballContact)
		unitLabels[3].text = "in"

		textFields[4].text = ballType
		textFields[5].text = lineColor
		
		unitToggle.isOn = useMetric

	}
	
	// MARK: - UI Helper Methods
	private func createLabel(withText text: String) -> UILabel {
		let label = UILabel()
		label.textColor = .white
		label.text = text
		label.font = .systemFont(ofSize: 16)
		//label.widthAnchor.constraint(equalToConstant: 300).isActive = true       //was 150
		return label
	}
	
	private func createTextField(withValue value: String, tag: Int, keyboardType: UIKeyboardType) -> UITextField {
		let textField = UITextField()
		textField.borderStyle = .roundedRect
		textField.text = value
		textField.placeholder = "Enter"
		textField.keyboardType = keyboardType
		textField.widthAnchor.constraint(equalToConstant: 120).isActive = true  // was 80
		
		textField.delegate = self
		textField.inputAccessoryView = kbToolbar

		textField.tag = tag
		return textField
	}
	
	/// add a view to move fileds closer to labels
	
	private func createUnitLabel(forFeet: Bool) -> UILabel {
		let label = UILabel()
		label.textColor = .white
		label.text = useMetric ? (forFeet ? "m" : "cm") : (forFeet ? "ft" : "in")
		label.font = .systemFont(ofSize: 16)
		label.widthAnchor.constraint(equalToConstant: 40).isActive = true
		return label
	}
	
	private func createHorizontalStack(withViews views: [UIView]) -> UIStackView {
		let stack = UIStackView(arrangedSubviews: views)
		
		stack.axis = .horizontal
		stack.distribution = .fill
		stack.alignment = .center
		stack.spacing = 10
		
		return stack
	}
	
	// MARK: keyboard handling
	private var keyboardHeight: CGFloat = 0.0
	private var kbToolbar: UIToolbar!

	private func setupKeyboardHandlers() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			keyboardHeight = keyboardSize.height
			self.moveViewWithKeyboard(notification: notification, keyboardWillShow: true)
		}
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		self.moveViewWithKeyboard(notification: notification, keyboardWillShow: false)
	}
	
	private func moveViewWithKeyboard(notification: NSNotification, keyboardWillShow: Bool) {
		guard let userInfo = notification.userInfo else { return }
		guard let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else { return }
		guard let curve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else { return }
		
		// find the active text field
		var activeField: UITextField?
		let idx = findActiveField()
		
		// if active field was found
		if idx != -1 {
			activeField = textFields[idx]
		}
		
		// if there is an active text field, adjust the view y-origin
		//	so the field is not covered by the keyboard
		var yOffset: CGFloat = 0.0
		if let tf = activeField {
			// make sure bottom of active text field is at least
			//	8-pts above the top of the keyboard frame
			let r = tf.convert(tf.bounds, to: self.view)
			let topOfKeyboard: CGFloat = view.frame.height - self.keyboardHeight
			yOffset = max(0.0, (r.maxY + 8.0) - topOfKeyboard)
		}
		
		let animationCurve = UIView.AnimationCurve(rawValue: Int(curve)) ?? .easeInOut
		let animator = UIViewPropertyAnimator(duration: duration, curve: animationCurve) {
			if keyboardWillShow {
				self.view.frame.origin.y = 0 - yOffset
			} else {
				self.view.frame.origin.y = 0
			}
		}
		animator.startAnimation()
	}
	
	// this will loop through the text fields, searching for the current .isFirstResponder
	//	if found, it will return the index of the text field in textFields[] array
	private func findActiveField() -> Int {
		var fieldIDX: Int = -1
		for (idx, tf) in textFields.enumerated() {
			if tf.isFirstResponder {
				fieldIDX = idx
				break
			}
		}
		return fieldIDX
	}
	
	// create a tool bar with Previous / Next / Done buttons
	//	to attach to the top of the keyboard
	private func createToolbar() -> UIToolbar {
		// Create a toolbar
		let toolbar = UIToolbar()
		toolbar.sizeToFit()
		
		let previousButton = UIBarButtonItem(title: "Previous", style: .plain, target: self, action: #selector(previousTapped))
		let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextTapped))
		let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
		
		let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		
		// Add buttons to the toolbar
		toolbar.setItems([previousButton, nextButton, flexSpace, doneButton], animated: false)
		
		return toolbar
	}
	
	// keyboard toolbar Previous button action
	@objc func previousTapped() {
		let idx: Int = findActiveField()
		
		// if active field was found, move to the previous field
		if idx != -1 {
			var newIDX: Int = idx - 1
			if newIDX < 0 {
				newIDX = textFields.count - 1
			}
			textFields[newIDX].becomeFirstResponder()
		}
	}
	
	// keyboard toolbar Next button action
	@objc func nextTapped() {
		let idx: Int = findActiveField()
		
		// if active field was found, move to the next field
		if idx != -1 {
			var newIDX: Int = idx + 1
			if newIDX >= textFields.count - 1 {
				newIDX = 0
			}
			textFields[newIDX].becomeFirstResponder()
		}
	}
	
	// keyboard toolbar Done button action
	@objc func doneTapped() {
		view.endEditing(true)
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder() // Dismiss the keyboard
		return true
	}
	
}

/*
 •    Correct Keyboard Setup:
 •    Decimal Pad: For numeric fields (courtWidth, lineWidth, etc.).
 •    Default Keyboard: For text-based fields (ballType, lineColor).
 •    Cleaner Code: Reduced repetition by adding the keyboardType parameter to the text field creation method.
 */

/*
 What’s New:
 •    Dynamic Unit Labels: .in, ft, m, cm adjust instantly.
 •    Automatic Conversion: Toggling the unit switch updates the field values accordingly.
 
 */

/*
 What’s Improved:
 1.    Text Field Alignment & Width: Left-aligned and limited to 80 points for better readability.
 2.    Keyboard Dismissal: Tapping outside the text fields dismisses the keyboard.
 3.    Improved Layout: Labels have more room (150 points), and margins improved.
 4.    Bottom Spacing Fix: Fixed overlapping buttons.
 
 Let me know if you need additional adjustments! 🚀😊
 */


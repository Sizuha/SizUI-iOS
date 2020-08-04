//
//  SizPropertyTableCells.swift
//  
//
//  Created by Sizuha on 2020/05/23.
//

import UIKit

class DefaultCellPadding {
    static let left = CGFloat(24)
    static let right = CGFloat(24)
}


//MARK: - Cell: Edit Text
open class SizCellForEditText: SizPropertyTableCell, UITextFieldDelegate {
    
    open override class var cellType: SizPropertyTableRow.CellType { .editText }
    
    public var delegate: UITextFieldDelegate? = nil
    public var maxLength: Int = 0
    
    public var textField: UITextField!
    public var valueViewWidth: CGFloat = HALF_WIDTH
    
    private var contentViewRect: CGRect {
        return CGRect(
            x: 0, y: 0,
            width: contentView.frame.size.width,
            height: contentView.frame.size.height
        )
    }
    
    open override func onInit() {
        super.onInit()
        textField = UITextField(frame: .zero)
        textField.returnKeyType = .next
        textField.textColor = .inputText
        textField.delegate = self
        
        contentView.addSubview(textField)
    }
    
    public var textValue: String? {
        get { return textField.text }
        set(value) { textField.text = value }
    }
    
    public var placeholder: String? {
        get { return textField.placeholder }
        set(value) { textField.placeholder = value }
    }
    
    public override func refreshViews() {
        let width: CGFloat
        let x: CGFloat
        let rightPadding = textField.clearButtonMode == .never
            ? DefaultCellPadding.right
            : DefaultCellPadding.right/2
        
        if textLabel?.text?.isEmpty ?? true {
            width = contentView.frame.size.width - DefaultCellPadding.left - rightPadding
            x = DefaultCellPadding.left
        }
        else {
            switch self.valueViewWidth {
            case HALF_WIDTH:
                width = contentView.frame.size.width/2 - rightPadding
            default:
                width = (self.valueViewWidth > 0 ? self.valueViewWidth : contentView.frame.size.width) - rightPadding
            }
            x = contentView.frame.size.width - width - rightPadding
        }
        
        textField.frame = CGRect(
            x: x,
            y: 0,
            width: width,
            height: contentView.frame.size.height
        )
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        textValue = data as? String ?? ""
        if !row.label.isEmpty {
            textLabel?.text = row.label
            textField.textAlignment = .right
            if let textColor = row.textColor {
                textField.textColor = textColor
            }
        }
    }
        
    //--- UITextFieldDelegate ---
    
    // return NO to disallow editing.
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    // became first responder
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing?(textField)
    }
    
    // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidEndEditing?(textField)
        onValueChanged?(textField.text)
    }
    
    // if implemented, called in place of textFieldDidEndEditing:
    @available(iOS 10.0, *)
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.delegate?.textFieldDidEndEditing?(textField, reason: reason)
        onValueChanged?(textField.text)
    }
    
    // return NO to not change text
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var result = self.delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
        
        if self.maxLength > 0 {
            let currStr = textField.text! as NSString
            let length = currStr.replacingCharacters(in: range, with: string).count

            result = result && length <= self.maxLength
        }
        
        return result
    }
    
    // called when clear button pressed. return NO to ignore (no notifications)
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldClear?(textField) ?? true
    }
    
    // called when 'return' key pressed. return NO to ignore.
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldReturn?(textField) ?? true
    }
    
//    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        return true
//    }

}

//MARK: - Cell: DateTime
open class SizCellForDateTime: SizCellForEditText {
    
    open override class var cellType: SizPropertyTableRow.CellType { .datetime }
    
    open override func onInit() {
        super.textField = SizDatePickerField(frame: .zero)
        super.textField.returnKeyType = .next
        super.textField.textColor = .inputText
        
        contentView.addSubview(super.textField)
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        guard let textfield = self.textField as? SizDatePickerField else { return }
        
        if let date = data as? Date {
            textfield.date = date
            textfield.updateText()
        }
        else {
            textfield.text = nil
        }
    }
    
}

//MARK: - Cell: Stepper
open class SizCellForStepper: SizCellForEditText {
    
    open override class var cellType: SizPropertyTableRow.CellType { .stepper }
    
    private var subStepper: UIStepper!
    public var stepper: UIStepper { return self.subStepper }
    
    public var minValue: Double {
        get {
            return self.subStepper.minimumValue
        }
        set(value) {
            self.subStepper.minimumValue = Double(value)
        }
    }
    public var maxValue: Double {
        get {
            return self.subStepper.maximumValue
        }
        set(value) {
            self.subStepper.maximumValue = value
        }
    }
    
    public var enableConvertIntWhenChanged = false
    public let formatter = NumberFormatter()
    
    public var value: Double {
        get {
            return self.subStepper.value
        }
        set(value) {
            super.textValue = formatter.string(for: value)
            self.subStepper.value = value
        }
    }
    
    public var editorWidth = CGFloat(50)
    
    open override func onInit() {
        super.onInit()
        
        super.textField.isUserInteractionEnabled = false
        
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        
        self.subStepper = UIStepper()
        self.subStepper.stepValue = 1
        self.subStepper.isContinuous = false
        self.subStepper.addTarget(self, action: #selector(onStepperValueChanged), for: .valueChanged)
        
        addSubview(self.subStepper)
    }
    
    public override func refreshViews() {
        let rightPadding = super.textField.clearButtonMode == .never
            ? DefaultCellPadding.right
            : DefaultCellPadding.right/2
        
        let x = contentView.frame.maxX - editorWidth - rightPadding

        super.textField.frame = CGRect(
            x: x,
            y: 0,
            width: editorWidth,
            height: contentView.frame.size.height
        )
        
        let stepperHeight = CGFloat(29)
        self.subStepper.frame = CGRect(
            x: x - 120,
            y: (contentView.frame.size.height - stepperHeight)/2,
            width: 94,
            height: stepperHeight
        )
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        self.value = data as? Double
            ?? Double(data as? Float ?? Float(data as? Int ?? 0))
    }
    
    @objc func onStepperValueChanged(_ sender: UIStepper!) {
        if enableConvertIntWhenChanged {
            let value = Int(sender.value)
            super.textValue = formatter.string(for: value)
            onValueChanged?(Double(value))
        }
        else {
            super.textValue = formatter.string(for: sender.value)
            onValueChanged?(sender.value)
        }
    }
    
}

//MARK: - Cell: OnOff
open class SizCellForOnOff: SizPropertyTableCell {
    
    open override class var cellType: SizPropertyTableRow.CellType { .onOff }
    
    private var onOffCtrl: UISwitch!
    public var switchCtrl: UISwitch {
        return onOffCtrl
    }
    
    open override func onInit() {
        super.onInit()
        onOffCtrl = UISwitch(frame: .zero)
        onOffCtrl.addTarget(self, action: #selector(onSwitchChanged), for: .valueChanged)
        
        addSubview(onOffCtrl)
    }
    
    public override func refreshViews() {
        let width = CGFloat(49)
        let height = CGFloat(31)
        onOffCtrl.frame = CGRect(
            x: contentView.frame.size.width - DefaultCellPadding.right - width,
            y: (contentView.frame.size.height - height)/2,
            width: width,
            height: height
        )
    }
    
    @objc private func onSwitchChanged(_ uiSwitch: UISwitch) {
        onValueChanged?(uiSwitch.isOn)
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        switchCtrl.isOn = data as? Bool == true
    }
}

//MARK: - Cell: Text
open class SizCellForText: SizPropertyTableCell {
    
    open override class var cellType: SizPropertyTableRow.CellType { .text }
    
    private var valueLabel: UILabel!
    open override var detailTextLabel: UILabel? {
        return valueLabel
    }
    
    public var valueViewWidth: CGFloat = HALF_WIDTH
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        onInit()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        onInit()
    }
    
    open override func onInit() {
        super.onInit()
        self.valueLabel = UILabel(frame: .zero)
        self.valueLabel.textAlignment = .right
        self.valueLabel.textColor = .inputText
        self.valueLabel.lineBreakMode = .byTruncatingTail
        addSubview(self.valueLabel)
    }
    
    public override func refreshViews() {
        let paddingRight = accessoryType == .none ? DefaultCellPadding.right : DefaultCellPadding.right/2
        let width: CGFloat
        switch self.valueViewWidth {
        case HALF_WIDTH:
            width = contentView.frame.size.width/2
        default:
            width = self.valueViewWidth > 0 ? self.valueViewWidth : contentView.frame.size.width
        }
        
        self.valueLabel.frame = CGRect(
            x: contentView.frame.size.width - width,
            y: 0,
            width: width - paddingRight,
            height: contentView.frame.size.height
        )
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        detailTextLabel?.text = data as? String ?? ""
    }
}

//MARK: - Cell: MultiLine Text
open class SizCellForMultiLine: SizPropertyTableCell {
    
    open override class var cellType: SizPropertyTableRow.CellType { .multiLine }
    
    private var defaultRowHeight: CGFloat!
    
    private var subTextView: UITextView!
    public var textView: UITextView {
        return subTextView
    }
    
    private var subHintView: UILabel!
    public var placeholderView: UILabel {
        return subHintView
    }
    
    public func setEnableEdit(_ mode: Bool = true) {
        self.subHintView.isHidden = mode
        
        self.subTextView.isEditable = mode
        self.subTextView.isUserInteractionEnabled = mode
        self.subTextView.isScrollEnabled = mode
    }
    
    open override func onInit() {
        super.onInit()
        self.defaultRowHeight = contentView.frame.height
        
        let textView = UITextView()
        textView.frame = CGRect(x: 0, y: 0, width: editWidth, height: self.defaultRowHeight)
        textView.textAlignment = .left
        textView.textColor = .inputText
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        //textView.backgroundColor = .blue // for DEBUG
        
        self.subTextView = textView
        self.addSubview(textView)
        
        let placeholderView = UILabel()
        placeholderView.isUserInteractionEnabled = false
        
        if #available(iOS 13.0, *) {
            placeholderView.textColor = .placeholderText
        } else {
            placeholderView.textColor = .placeholderGray
        }
        
        placeholderView.font = textView.font
        self.subHintView = placeholderView
        self.addSubview(placeholderView)
        
        setEnableEdit(false)
    }
    
    public static let paddingVertical = CGFloat(10)
    
    private var paddingRight: CGFloat {
        return accessoryType == .none ? DefaultCellPadding.right : 0
    }
    
    private var editWidth: CGFloat {
        return contentView.frame.width - DefaultCellPadding.left - paddingRight
    }
    
    public override func refreshViews() {
        var height: CGFloat = super.onGetCellHieght?() ?? self.defaultRowHeight
        
        if height < 0 {
            height = self.defaultRowHeight
            
            // auto height
//            self.subTextView.frame = CGRect(x: 0, y: 0, width: width, height:0)
//            self.subTextView.sizeToFit()
//            height = self.subTextView.frame.height + SizCellForMultiLine.paddingVertical*2
        }
        
        self.subTextView.frame = CGRect(
            x: DefaultCellPadding.left,
            y: SizCellForMultiLine.paddingVertical,
            width: editWidth,
            height: height - SizCellForMultiLine.paddingVertical*2
        )
        
        subHintView.isHidden = !self.textView.text.isEmpty || self.subTextView.isEditable
        if !subHintView.isHidden {
            subHintView.frame = CGRect(
                x: DefaultCellPadding.left,
                y: (height - self.defaultRowHeight)/2,
                width: contentView.frame.width / 2,
                height: self.defaultRowHeight
            )
        }
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        contentText = data as? String ?? ""
        placeholder = row.hint
        if let textColor = row.textColor {
            textView.textColor = textColor
        }
    }
    
    public var contentText: String {
        get {
            return self.subTextView.text
        }
        set(value) {
            self.subTextView.text = value
        }
    }
    
    public var placeholder: String? {
        get {
            return self.subHintView.text
        }
        set(value) {
            self.subHintView.text = value
        }
    }
    
    open override var textLabel: UILabel? { return nil }
    open override var detailTextLabel: UILabel? { return nil }
}

//MARK: - Cell: Star Rating
open class SizCellForRating: SizPropertyTableCell, FloatRatingViewDelegate {
    
    open override class var cellType: SizPropertyTableRow.CellType { .rating }
    
    private var ratingView: FloatRatingView!
    public var ratingBar: FloatRatingView { return self.ratingView }
    
    public var delegate: FloatRatingViewDelegate? = nil
    
    open override func onInit() {
        super.onInit()
        self.ratingView = FloatRatingView(frame: .zero)
        self.ratingView.editable = true
        self.ratingView.type = .wholeRatings
        self.ratingView.minRating = 0
        self.ratingView.maxRating = 5
        addSubview(self.ratingView)
        
        self.ratingView.delegate = self
    }
    
    public override func refreshViews() {
        let width = CGFloat(180)
        let height = CGFloat(34)
        self.ratingView.frame = CGRect(
            x: contentView.frame.size.width - width - DefaultCellPadding.right,
            y: (contentView.frame.size.height - height)/2,
            width: width,
            height: height
        )
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        ratingBar.rating = data as? Double ?? 0.0
    }
    
    /// Returns the rating value when touch events end
    public func floatRatingView(_ ratingView: FloatRatingView, didUpdate rating: Double) {
        self.delegate?.floatRatingView?(ratingView, didUpdate: rating)
        onValueChanged?(rating)
    }
    
    /// Returns the rating value as the user pans
    public func floatRatingView(_ ratingView: FloatRatingView, isUpdating rating: Double) {
        self.delegate?.floatRatingView?(ratingView, isUpdating: rating)
    }
}

//MARK: - Cell: Button
open class SizCellForButton: SizPropertyTableCell {
    
    open override class var cellType: SizPropertyTableRow.CellType { .button }
    
    open override func onInit() {
        super.onInit()
        textLabel?.textAlignment = .left
    }
    
    public override func refreshViews() {}

}

//MARK: - Cell: Picker
open class SizCellForPicker: SizCellForEditText, UIPickerViewDelegate, UIPickerViewDataSource {
    
    open override class var cellType: SizPropertyTableRow.CellType { .picker }
    
    var selectionTitles: [String]! = nil
    public let picker: UIPickerView = UIPickerView()
    
    open override func onInit() {
        super.onInit()
        self.picker.delegate = self
        self.picker.dataSource = self
        self.picker.showsSelectionIndicator = true
        self.textField.inputView = self.picker
        
        // Cursorを見せない為
        self.textField.tintColor = .clear
    }
    
    public override func refreshViews() {
        super.refreshViews()
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        let selIdx = data as? Int ?? -1
        var displayText: String
        if selIdx >= 0 && selIdx < (row.selectionItems?.count ?? 0) {
            displayText = row.selectionItems?[selIdx] ?? ""
        }
        else {
            displayText = ""
        }
        textValue = displayText
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.selectionTitles.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard row >= 0 && row < self.selectionTitles.count else {
            return self.placeholder
        }
        return self.selectionTitles[row]
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.onValueChanged?(row)
    }
    
    // TextFieldで、編集メニューを見せない為
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        OperationQueue.main.addOperation {
            UIMenuController.shared.setMenuVisible(false, animated: false)
        }

        return super.canPerformAction(action, withSender: sender)
    }
    
}


//MARK: - Cell: Image

open class SizCellForImage: SizPropertyTableCell {
    open override class var cellType: SizPropertyTableRow.CellType { .image }
    
    public var contentImageView: UIImageView!
    public var imageHeight: CGFloat = 100
    
    public var paddingTop: CGFloat = 10
    
    open override func onInit() {
        super.onInit()
        
        contentImageView = UIImageView()
        contentImageView.frame = CGRect(
            x: DefaultCellPadding.left,
            y: paddingTop,
            width: contentView.frame.width - DefaultCellPadding.left - DefaultCellPadding.right,
            height: imageHeight
        )
        addSubview(contentImageView)
    }
    
    public static let paddingVertical = CGFloat(10)
    
    private var paddingRight: CGFloat {
        return accessoryType == .none ? DefaultCellPadding.right : 0
    }
    
    open override var imageView: UIImageView? { contentImageView }
    
    open override func refreshViews() {
        let paddingRight = DefaultCellPadding.right //accessoryType == .none ? DefaultCellPadding.right : 0
        
        contentImageView.frame = CGRect(
            x: DefaultCellPadding.left,
            y: paddingTop,
            width: contentView.frame.width - DefaultCellPadding.left - paddingRight,
            height: imageHeight
        )
    }
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        if let image = data as? UIImage {
            contentImageView?.image = image
        }
        else if let data = data as? Data {
            contentImageView?.image = UIImage(data: data)
        }
        else {
            contentImageView?.image = nil
        }
    }
    
    open override var textLabel: UILabel? { return nil }
    open override var detailTextLabel: UILabel? { return nil }
}

// MARK: - Cell: Strings

open class SizCellForStrings: SizCellForText {
    open override class var cellType: SizPropertyTableRow.CellType { .strings }
    
    public var nonSelectedMessage: String? = nil
    
    open override func updateContent(data: Any?, at row: SizPropertyTableRow) {
        // data is index
        guard
            let i = data as? Int,
            let items = row.selectionItems,
            (0..<items.count).contains(i)
        else {
            detailTextLabel?.text = nonSelectedMessage
            return
        }
        
        detailTextLabel?.text = items[i]
    }
}

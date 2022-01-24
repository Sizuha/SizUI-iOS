//
//  SizPopupPickerView.swift
//
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit

open class SizPopupPickerViewBase: UIView {
	public var pickerToolbar: UIToolbar!
	public var toolbarItems = [UIBarButtonItem]()
	private lazy var doneButtonItem: UIBarButtonItem = {
		return UIBarButtonItem(
			barButtonSystemItem: UIBarButtonItem.SystemItem.done,
			target: self,
			action: #selector(self.endPicker))
	}()
    
    public let PICKER_HEIGHT: CGFloat = 260
    public let TOOLBAR_HEIGHT: CGFloat = 44

	public var onHidden: (()->Void)? = nil
	
	public init() {
		super.init(frame: CGRect.zero)
		onInit()
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		onInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	private func onInit() {
		let screenSize = UIScreen.main.bounds.size
		self.backgroundColor = UIColor.black
		
		pickerToolbar = UIToolbar()
		pickerToolbar.isTranslucent = false
		pickerToolbar.backgroundColor = UIColor.clear
		
		self.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: PICKER_HEIGHT)
		self.frame = CGRect(x: 0, y: parentViewHeight(), width: screenSize.width, height: PICKER_HEIGHT)
		pickerToolbar.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: TOOLBAR_HEIGHT)
		pickerToolbar.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: TOOLBAR_HEIGHT)
		
		let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
		space.width = 12
		let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(SizPopupPickerViewBase.onCancel))
		let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
		toolbarItems = [space, cancelItem, flexSpaceItem, doneButtonItem, space]
		
		pickerToolbar.setItems(toolbarItems, animated: false)
		self.addSubview(pickerToolbar)
	}
	
	open func show() {}
	
	@objc func onCancel() {}
	
	@objc func endPicker() {}
	
	open func hide() {
		let screenSize = UIScreen.main.bounds.size
		UIView.animate(withDuration: 0.2, animations: {
            self.frame = CGRect(x: 0, y: self.parentViewHeight(), width: screenSize.width, height: self.PICKER_HEIGHT)
		}) { finished in
			if finished { self.onHidden?() }
		}
	}
	
	open func parentViewHeight() -> CGFloat {
		return superview?.frame.height ?? UIScreen.main.bounds.size.height
	}
}

@objc public protocol SizPopupPickerViewDelegate: UIPickerViewDelegate {
	@objc optional func pickerView(_ pickerView: UIPickerView, didSelect rows: [Int])
}

open class SizPopupPickerView: SizPopupPickerViewBase {
	private var pickerView: UIPickerView!
    
    public func getPickerView() -> UIPickerView { self.pickerView! }
	
	public var delegate: SizPopupPickerViewDelegate? {
		didSet {
			pickerView.delegate = delegate
		}
	}
    
    public var dataSource: UIPickerViewDataSource? {
        get {
            pickerView.dataSource
        }
        set {
            pickerView.dataSource = newValue
        }
    }
	
	public var selectedRows: [Int]?
	
	override public init() {
		super.init()
		onInit()
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		onInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	public init(selectedRows rows: [Int]) {
		super.init()
        onInit()
		selectedRows = rows
    }
	
	private func onInit() {
		let screenSize = UIScreen.main.bounds.size
		
		pickerView = UIPickerView()
		pickerView.showsSelectionIndicator = true
		if #available(iOS 13.0, *) {
			pickerView.backgroundColor = .systemBackground
		} else {
			pickerView.backgroundColor = .white
		}
        
        let height = PICKER_HEIGHT - TOOLBAR_HEIGHT
		pickerView.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: height)
		pickerView.frame = CGRect(x: 0, y: TOOLBAR_HEIGHT, width: screenSize.width, height: height)
		self.addSubview(pickerView)
	}
	
	public func setDataSource(_ source: UIPickerViewDataSource) {
		pickerView.dataSource = source
	}
	
	override open func show() {
		if selectedRows == nil {
			selectedRows = getSelectedRows()
		}
		if let selectedRows = selectedRows {
			for (component, row) in selectedRows.enumerated() {
				pickerView.selectRow(row, inComponent: component, animated: false)
			}
		}
		let screenSize = UIScreen.main.bounds.size
		UIView.animate(withDuration: 0.2) {
			self.frame = CGRect(
				x: 0,
                y: self.parentViewHeight() - (self.PICKER_HEIGHT),
				width: screenSize.width,
                height: self.PICKER_HEIGHT
			)
		}
	}
	
	override func onCancel() {
		hide()
		restoreSelectedRows()
		selectedRows = nil
	}
	
	override func endPicker() {
		hide()
		delegate?.pickerView?(pickerView, didSelect: getSelectedRows())
		selectedRows = nil
	}
	
	internal func getSelectedRows() -> [Int] {
		var selectedRows = [Int]()
		for i in 0..<pickerView.numberOfComponents {
			selectedRows.append(pickerView.selectedRow(inComponent: i))
		}
		return selectedRows
	}
	
	private func restoreSelectedRows() {
		guard let selectedRows = selectedRows else { return }
		for i in 0..<selectedRows.count {
			pickerView.selectRow(selectedRows[i], inComponent: i, animated: true)
		}
	}
}

// MARK: - SizStringPicker

public class SizStringPicker: SizPopupPickerView {
    
    private var strings: [String] = []
    public var onSelected: ((_ index: Int, _ text: String)->Void)? = nil
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(strings: [String], onSelected: ((_ index: Int, _ text: String)->Void)? = nil) {
        super.init()
        self.strings = strings
        self.onSelected = onSelected
        
        setDataSource(self)
        delegate = self
    }
    
}

extension SizStringPicker: UIPickerViewDataSource, SizPopupPickerViewDelegate {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        strings.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        strings[row]
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelect rows: [Int]) {
        let index = rows[0]
        let text = strings[index]
        onSelected?(index, text)
    }
    
}

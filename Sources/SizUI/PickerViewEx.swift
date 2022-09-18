//
//  PickerViewEx.swift
//
//  Created by Sizuha on 2022/09/17.
//

import UIKit

public class PickerViewEx: UIView {
    
    public var pickerToolbar: UIToolbar!
    public var toolbarItems = [UIBarButtonItem]()
    private lazy var doneButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.done,
            target: self,
            action: #selector(self.endPicker))
    }()
    
    public var pickerAreaHeight: CGFloat {
        self.options?.pickerHeight ?? 300
    }
    public let TOOLBAR_HEIGHT: CGFloat = 44
    
    private var pickerView: UIPickerView!
    public func getPickerView() -> UIPickerView { self.pickerView! }
    
    private var parentViewController: UIViewController?
    private var fadeView: UIView?
    private var fadeViewTap: UITapGestureRecognizer?
    
    public struct Options {
        public var pickerHeight: CGFloat = 300
        public var didSelect: ((_ component: Int, _ row: Int)->Void)?
        public var didHide: (()->Void)?
    }
    
    private var options: Options?
    private var didDone: ((_ selected: [Int], _ strings: [String?])->Void)?
    
    private var preSelectedRows: [Int] = []
    private var items: [[String]] = []

    
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
        if #available(iOS 13.0, *) {
            self.backgroundColor = .systemBackground
        }
        else {
            self.backgroundColor = .white
        }
        
        // MARK: Picker Toolbar
        self.pickerToolbar = UIToolbar()
        self.pickerToolbar.isTranslucent = false
        self.pickerToolbar.backgroundColor = UIColor.clear
        
        self.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: self.pickerAreaHeight)
        self.frame = CGRect(x: 0, y: parentViewHeight(), width: screenSize.width, height: self.pickerAreaHeight)
        self.pickerToolbar.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: TOOLBAR_HEIGHT)
        self.pickerToolbar.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: TOOLBAR_HEIGHT)
        
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 12
        
        let cancelItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel)
        )
        
        let flexSpaceItem = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: self,
            action: nil
        )
        
        self.toolbarItems = [space, cancelItem, flexSpaceItem, self.doneButtonItem, space]
        
        self.pickerToolbar.setItems(self.toolbarItems, animated: false)
        self.addSubview(self.pickerToolbar)
        
        // MARK: PickerView
        self.pickerView = UIPickerView()
        if #available(iOS 13.0, *) {
            self.pickerView.backgroundColor = .systemBackground
        }
        else {
            self.pickerView.backgroundColor = .white
        }
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.addSubview(self.pickerView)
        
        self.isHidden = true
    }
    
    public func show(
        from: UIViewController,
        items: [[String]],
        selected: [Int] = [],
        options: Options? = nil,
        didDone: ((_ selected: [Int], _ strings: [String?])->Void)? = nil
    ) {
        self.items.removeAll()
        self.items = items
        self.preSelectedRows = selected
        self.options = options
        self.didDone = didDone
        self.parentViewController = from
        
        if let tap = self.fadeViewTap {
            self.fadeView?.removeGestureRecognizer(tap)
        }
        self.fadeViewTap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        
        self.fadeView = from.fadeOut() { _ in
            self.fadeView?.addGestureRecognizer(self.fadeViewTap!)
        }
        
        self.superview?.removeFromSuperview()
        getKeyWindow()?.addSubview(self)
        self.superview?.bringSubviewToFront(self)
        
        self.isHidden = false
        let screenSize = UIScreen.main.bounds.size
        let paddingBottom = from.view.safeAreaInsets.bottom
        let realPickerHeight = self.pickerAreaHeight - TOOLBAR_HEIGHT - paddingBottom
        self.pickerView.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: realPickerHeight)
        self.pickerView.frame = CGRect(x: 0, y: TOOLBAR_HEIGHT, width: screenSize.width, height: realPickerHeight)
        let viewHeight = self.pickerView.frame.height + paddingBottom + 40
        
        var component = 0
        for selRow in selected {
            guard
                !items[component].isEmpty,
                (0..<items[component].count).contains(selRow)
            else {
                component += 1
                continue
            }
            
            self.pickerView.selectRow(selRow, inComponent: component, animated: false)
            component += 1
        }
        
        UIView.animate(withDuration: 0.2) {
            self.frame = CGRect(
                x: 0,
                y: self.parentViewHeight() - viewHeight,
                width: screenSize.width,
                height: viewHeight
            )
        }
    }
    
    @objc public func cancel() {
        hide()
    }
    
    @objc public func endPicker() {
        hide()
        
        let selRows = getSelectedRows()
        var selStrings: [String?] = []
        selStrings.reserveCapacity(selRows.count)
        
        var component = 0
        for selRow in selRows {
            selStrings.append(self.items[component][selRow])
            component += 1
        }
        
        self.didDone?(selRows, selStrings)
    }
    
    func hide() {
        if let tap = self.fadeViewTap {
            self.fadeView?.removeGestureRecognizer(tap)
        }
        
        self.parentViewController?.fadeIn()
        self.fadeView = nil
        
        let screenSize = UIScreen.main.bounds.size
        UIView.animate(withDuration: 0.2, animations: {
            self.frame = CGRect(
                x: 0,
                y: self.parentViewHeight(),
                width: screenSize.width,
                height: self.pickerAreaHeight
            )
        }) { finished in
            guard finished else { return }

            self.isHidden = true
            self.removeFromSuperview()
            self.options?.didHide?()
        }
    }
    
    func getSelectedRows() -> [Int] {
        var selectedRows = [Int]()
        for i in 0..<self.pickerView.numberOfComponents {
            selectedRows.append(self.pickerView.selectedRow(inComponent: i))
        }
        return selectedRows
    }
    
    public func parentViewHeight() -> CGFloat {
        UIScreen.main.bounds.size.height
    }
    
}

extension PickerViewEx: UIPickerViewDataSource, UIPickerViewDelegate {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        self.items.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        self.items[component].count
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.options?.didSelect?(component, row)
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        self.items[component][row]
    }
    
}

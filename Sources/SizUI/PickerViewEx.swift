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
    private var blurView: UIVisualEffectView?
    
    public struct Options {
        public var numberOfComponents: Int?
        public var numberOfRowsInComponent: ((_ component: Int)->Int)?
        public var titleForRow: ((_ component: Int, _ row: Int)->String)?
        
        public var pickerHeight: CGFloat = 300
        public var blurBackground = false
        public var backgorundColor: UIColor?
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
        //self.backgroundColor = .clear
        
        // MARK: Picker Toolbar
        self.pickerToolbar = UIToolbar()
        self.pickerToolbar.isTranslucent = false
        
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
        
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.addSubview(self.pickerView)
        
        self.isHidden = true
    }
    
    public func show(
        from: UIViewController,
        items: [[String]] = [],
        selected: [Int] = [],
        options: Options? = nil,
        didDone: ((_ selected: [Int], _ strings: [String?])->Void)? = nil
    ) {
        if items.isEmpty {
            guard
                let options = options,
                options.numberOfComponents ?? 0 > 0,
                let _ = options.titleForRow,
                let _ = options.numberOfRowsInComponent
            else {
                assert(false)
                return
            }
        }
        
        self.items.removeAll()
        self.items = items
        self.preSelectedRows = selected
        self.options = options
        self.didDone = didDone
        self.parentViewController = from
        
        doShow(keyWindow: self.superview == nil)
    }
    
    private func doShow(keyWindow: Bool = true) {
        guard let from = self.parentViewController else {
            assert(false)
            return
        }
        
        self.blurView?.removeFromSuperview()
        
        if keyWindow {
            self.superview?.removeFromSuperview()
            getKeyWindow()?.addSubview(self)
        }
        
        let isBlurBackground = self.options?.blurBackground == true
        if isBlurBackground {
            self.blurView = Blur(frame: self.frame, style: .regular)
            self.superview?.addSubview(self.blurView!)
            
            self.pickerToolbar.isTranslucent = true
            self.backgroundColor = .clear
        }
        else if let color = self.options?.backgorundColor {
            self.pickerToolbar.barTintColor = color
            self.backgroundColor = color
        }
        else {
            self.backgroundColor = .systemBackground
        }

        
        if let tap = self.fadeViewTap {
            self.fadeView?.removeGestureRecognizer(tap)
        }
        
        let screenSize = UIScreen.main.bounds.size
        let paddingBottom = from.view.safeAreaInsets.bottom
        let viewHeight = self.pickerView.frame.height + paddingBottom + 40
        
        if keyWindow {
            self.fadeViewTap = UITapGestureRecognizer(target: self, action: #selector(cancel))

            let fadeRect = isBlurBackground ? CGRect(
                x: 0,
                y: 0,
                width: from.view.frame.width,
                height: self.parentViewHeight() - viewHeight
            ) : nil
            
            self.fadeView = from.fadeOut(frame: fadeRect) { _ in
                self.fadeView?.addGestureRecognizer(self.fadeViewTap!)
            }
        }
        
        self.superview?.bringSubviewToFront(self)
        self.isHidden = false
        let realPickerHeight = self.pickerAreaHeight - TOOLBAR_HEIGHT - paddingBottom
        self.pickerView.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: realPickerHeight)
        self.pickerView.frame = CGRect(x: 0, y: TOOLBAR_HEIGHT, width: screenSize.width, height: realPickerHeight)
        
        var component = 0
        for selRow in self.preSelectedRows {
            guard
                !items[component].isEmpty,
                items[component].indices.contains(selRow)
            else {
                component += 1
                continue
            }
            
            self.pickerView.selectRow(selRow, inComponent: component, animated: false)
            component += 1
        }
        
        UIView.animate(withDuration: 0.2) {
            let rect = CGRect(
                x: 0,
                y: self.parentViewHeight() - viewHeight,
                width: screenSize.width,
                height: viewHeight
            )
            self.frame = rect
            self.blurView?.frame = rect
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
            let str = self.items.indices.contains(selRow)
                ? self.items[component][selRow]
                : nil
            
            selStrings.append(str)
            component += 1
        }
        
        self.didDone?(selRows, selStrings)
    }
    
    var superviewIsKeyWindow: Bool {
        (self.superview as? UIWindow)?.isKeyWindow == true
    }
    
    func hide() {
        if let tap = self.fadeViewTap {
            self.fadeView?.removeGestureRecognizer(tap)
        }
        
        if self.superviewIsKeyWindow {
            self.parentViewController?.fadeIn()
        }
        self.fadeView = nil
        
        let screenSize = UIScreen.main.bounds.size
        UIView.animate(withDuration: 0.2, animations: {
            let rect = CGRect(
                x: 0,
                y: self.parentViewHeight(),
                width: screenSize.width,
                height: self.pickerAreaHeight
            )
            self.frame = rect
            self.blurView?.frame = rect
        }) { finished in
            guard finished else { return }

            self.blurView?.removeFromSuperview()
            self.isHidden = true
            if self.superviewIsKeyWindow {
                self.removeFromSuperview()
            }
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

// MARK: - PickerView Deleages

extension PickerViewEx: UIPickerViewDataSource, UIPickerViewDelegate {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        self.options?.numberOfComponents ?? self.items.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        self.options?.numberOfRowsInComponent?(component) ?? self.items[component].count
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.options?.didSelect?(component, row)
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let titleForRow = self.options?.titleForRow {
            return titleForRow(component, row)
        }
        return self.items[component][row]
    }
    
}

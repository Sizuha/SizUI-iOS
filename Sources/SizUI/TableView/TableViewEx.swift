//
//  TableViewEx.swift
//  HBSCommon
//
//  Created by 黄一瓊 on 2022/09/07.
//

import Foundation
import UIKit

@available(iOS 14.0, *)
open class TableViewEx: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    public var sections: [TableSection] = []
    public var autoDeselect = true
    
    public required init?(coder: NSCoder) {
        fatalError("Not implement")
    }
    
    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        [
            TableCell.self,
            TableValueCell.self,
            TableSwitchCell.self,
            TableEditCell.self,
        ].forEach {
            register(UITableViewCell.self, forCellReuseIdentifier: $0.cellReuseID)
        }
        
        self.dataSource = self
        self.delegate = self
    }
    
    public func set(sections: [TableSection]) {
        self.sections.removeAll()
        self.sections = sections
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = self.sections[section]
        return section.title
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.sections[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellDef = self.sections[indexPath.section].cells[indexPath.row]
        
        let cell: UITableViewCell
        if let creator = cellDef.willCreate {
            cell = creator(indexPath)
        }
        else {
            let id = type(of: cellDef).cellReuseID
            cell = tableView.dequeueReusableCell(withIdentifier: id)!
        }
        
        cell.contentConfiguration = cell.defaultContentConfiguration()
        cell.accessoryType = tableView.allowsSelection && cellDef.didSelect != nil
            ? .disclosureIndicator
            : .none

        cellDef.afterWillCreate(cell: cell, indexPath: indexPath)
        cellDef.didCreate?(cell, indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 注意！
        // ここではViewの大きさを変更しないこと（-> cellForRowAtですること）
        // 表示する内容のみ更新すること
        
        let cellDef = self.sections[indexPath.section].cells[indexPath.row]
        
        cell.updateContent { content in
            content.text = cellDef.label
        }
        
        cellDef.beforeWillDsiplay(cell: cell, indexPath: indexPath)
        if let proc = cellDef.willDsiplay {
            proc(cell, indexPath)
            return
        }
    }
    
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cellDef = self.sections[indexPath.section].cells[indexPath.row]
        return cellDef.didSelect != nil ? indexPath : nil
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.autoDeselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let cellDef = self.sections[indexPath.section].cells[indexPath.row]
        cellDef.didSelect?(indexPath)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellDef = self.sections[indexPath.section].cells[indexPath.row]
        return cellDef.height > 0 ? cellDef.height : self.rowHeight
    }
    
}


@available(iOS 14.0, *)
public extension UITableViewCell {
    
    func getContent() -> UIListContentConfiguration {
        self.contentConfiguration as! UIListContentConfiguration
    }
    
    func updateContent(with: (_ content: inout UIListContentConfiguration)->Void) {
        var content = getContent()
        with(&content)
        self.contentConfiguration = content
    }
    
    func findSubview<T>(withTag tag: Int? = nil) -> Optional<T> where T: UIView {
        contentView.subviews.first(
            where: { $0 is T && (tag == nil || $0.tag == tag) }
        ) as? T
    }
    
}


public struct TableSection {
    
    public var title: String? = nil
    public var cells: [TableCell] = []
    
    public init(title: String? = nil, cells: [TableCell] = []) {
        self.title = title
        self.cells = cells
    }
    
}


public typealias TableCellCreator = (_ indexPath: IndexPath)->UITableViewCell
public typealias TableCellProc = (_ cell: UITableViewCell, _ indexPath: IndexPath)->Void
public typealias TableIndexProc = (_ indexPath: IndexPath)->Void
public typealias TableCellValueProc = ()->Any?


// MARK: - TableCell (Base)

open class TableCell {
    
    open class var cellReuseID: String { "TableViewEx_defaultCell" }
    open class var SUBVIEW_TAG: Int { 0 }

    public enum Define {
        case label(_ text: String?)
        case height(_ Value: CGFloat)
        
        case willCreate(_ creator: TableCellCreator)
        case didCreate(_ proc: TableCellProc)
        case willDisplay(_ proc: TableCellProc)
        case didSelect(_ proc: TableIndexProc)
        
        case value(_ proc: TableCellValueProc)
        case valueWidth(_ width: CGFloat)
        case hint(_ text: String?)
    }
    
    static let defaultPadding: CGFloat = 20
    
    public var label: String? = nil
    public var height: CGFloat = -1
    
    open func afterWillCreate(cell: UITableViewCell, indexPath: IndexPath) {}
    open func beforeWillDsiplay(cell: UITableViewCell, indexPath: IndexPath) {}
    
    public var willCreate: TableCellCreator? = nil
    public var didCreate: TableCellProc? = nil
    public var willDsiplay: TableCellProc? = nil
    public var didSelect: TableIndexProc? = nil
    
    public init(label: String? = nil, _ defines: [Define] = []) {
        self.label = label
        parse(defines: defines)
    }
    
    func parse(defines: [TableCell.Define]) {
        for define in defines {
            switch define {
            case .label(let text): self.label = text
            case .height(let height): self.height = height
            case .willCreate(let creator): self.willCreate = creator
            case .didCreate(let proc): self.didCreate = proc
            case .willDisplay(let proc): self.willDsiplay = proc
            case .didSelect(let proc): self.didSelect = proc
                
            default: break
            }
            
            didParse(define: define)
        }
    }
    
    open func didParse(define: TableCell.Define) {}
    
}


// MARK: - TableValueCell

@available(iOS 14.0, *)
open class TableValueCell: TableCell {
    
    public override class var cellReuseID: String { "TableViewEx_valueCell" }
    public override class var SUBVIEW_TAG: Int { 10000 }
    
    public var valueWidth: CGFloat = -1
    public var willReadValue: TableCellValueProc? = nil
    
    open override func didParse(define: TableCell.Define) {
        switch define {
        case .value(let valueProc): self.willReadValue = valueProc
        case .valueWidth(let width): self.valueWidth = width
        default: return
        }
    }
    
    open override func afterWillCreate(cell: UITableViewCell, indexPath: IndexPath) {
        let valueLabel = UILabel(frame: .zero)
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.textColor = .secondaryLabel
        valueLabel.tag = Self.SUBVIEW_TAG
        cell.contentView.addSubview(valueLabel)
    }
    
    open override func beforeWillDsiplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard let valueLabel = Self.getSubView(fromCell: cell) else {
            return
        }
        
        let paddingRight: CGFloat = cell.accessoryType == .none
            ? Self.defaultPadding
            : 8
        let width: CGFloat = self.valueWidth > 0 ? self.valueWidth : cell.contentView.frame.width
        
        valueLabel.frame = CGRect(
            x: cell.contentView.frame.size.width - width,
            y: 0,
            width: width - paddingRight,
            height: cell.contentView.frame.size.height
        )
        
        if let valueProc = self.willReadValue {
            let value = valueProc()
            if let value = value as? Int {
                valueLabel.text = "\(value)"
            }
            else if let value = value as? String {
                valueLabel.text = value
            }
        }
    }
    
    public static func getSubView(fromCell cell: UITableViewCell) -> UILabel? {
        cell.findSubview(withTag: Self.SUBVIEW_TAG)
    }
    
}


// MARK: - TableSwitchCell

open class TableSwitchCell: TableCell {

    public override class var cellReuseID: String { "TableViewEx_switchCell" }
    
    public var willReadValue: TableCellValueProc? = nil
    
    open override func didParse(define: TableCell.Define) {
        switch define {
        case .value(let valueProc): self.willReadValue = valueProc
        default: return
        }
    }
    
    open override func afterWillCreate(cell: UITableViewCell, indexPath: IndexPath) {
        let onOff = UISwitch(frame: .zero)
        cell.accessoryView = onOff
        
        self.didSelect = { _ in
            guard let switchCtrl = Self.getSubView(fromCell: cell) else {
                return
            }
            switchCtrl.setOn(!switchCtrl.isOn, animated: true)
        }
    }
    
    open override func beforeWillDsiplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard let onOff = Self.getSubView(fromCell: cell) else {
            return
        }
        
        cell.accessoryType = .none
        
        if let valueProc = self.willReadValue {
            onOff.isOn = valueProc() as? Bool == true
        }
    }
    
    public static func getSubView(fromCell cell: UITableViewCell) -> UISwitch? {
        cell.accessoryView as? UISwitch
    }
    
}


// MARK: - TableEditCell

@available(iOS 14.0, *)
open class TableEditCell: TableCell {
    
    public override class var cellReuseID: String { "TableViewEx_editCell" }
    public override class var SUBVIEW_TAG: Int { 10001 }
    
    public static let FULL_WIDTH: CGFloat = -1
    public static let HALF_WIDTH: CGFloat = -2
    
    public var valueWidth: CGFloat = FULL_WIDTH
    public var willReadValue: TableCellValueProc? = nil
    private var hintStr: String? = nil
    
    open override func didParse(define: TableCell.Define) {
        switch define {
        case .value(let valueProc): self.willReadValue = valueProc
        case .valueWidth(let width): self.valueWidth = width
        case .hint(let text): self.hintStr = text
        default: return
        }
    }
    
    open override func afterWillCreate(cell: UITableViewCell, indexPath: IndexPath) {
        let textField = UITextField(frame: .zero)
        textField.tag = Self.SUBVIEW_TAG
        textField.placeholder = self.hintStr
        cell.contentView.addSubview(textField)
    }
    
    open override func beforeWillDsiplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard let textField = Self.getSubView(fromCell: cell) else {
            return
        }
        
        let width: CGFloat
        let x: CGFloat
        let rightPadding = textField.clearButtonMode == .never
            ? Self.defaultPadding
            : Self.defaultPadding/2
        
        textField.textAlignment = self.label?.isEmpty == false ? .right : .left
        
        if self.label?.isEmpty ?? true {
            width = cell.contentView.frame.size.width - Self.defaultPadding - rightPadding
            x = Self.defaultPadding
        }
        else {
            switch self.valueWidth {
            case Self.HALF_WIDTH:
                width = cell.contentView.frame.size.width/2 - rightPadding
            default:
                width = (self.valueWidth > 0 ? self.valueWidth : cell.contentView.frame.size.width) - rightPadding
            }
            x = cell.contentView.frame.size.width - width - rightPadding
        }
        
        textField.frame = CGRect(
            x: x,
            y: 0,
            width: width,
            height: cell.contentView.frame.size.height
        )
        
        if let valueProc = self.willReadValue {
            let value = valueProc()
            if let value = value as? Int {
                textField.text = "\(value)"
            }
            else if let value = value as? String {
                textField.text = value
            }
        }
    }
    
    public static func getSubView(fromCell cell: UITableViewCell) -> UITextField? {
        cell.findSubview(withTag: Self.SUBVIEW_TAG)
    }
    
}

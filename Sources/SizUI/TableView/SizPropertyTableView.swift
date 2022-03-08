//
//  SizTableEditorView.swift
//
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit

public let AUTO_HEIGHT: CGFloat = -1
public let DEFAULT_HEIGHT: CGFloat = -1
public let FILL_WIDTH: CGFloat = -10
public let HALF_WIDTH: CGFloat = -2

open class SizPropertyTableSection {
	public var title: String? = nil
	public var rows: [SizPropertyTableRow]
	public var onCreateHeader: (()->UIView)? = nil
	public var headerHeight: CGFloat = DEFAULT_HEIGHT

	public init(
		title: String? = nil,
		onCreateHeader: (()->UIView)? = nil,
		headerHeight: CGFloat = DEFAULT_HEIGHT,
		rows: [SizPropertyTableRow] = [])
	{
		self.title = title
		self.rows = rows
		self.onCreateHeader = onCreateHeader
		self.headerHeight = headerHeight
	}
}

public typealias TableViewIndexProc = (_ index: IndexPath)->Void
public typealias TableViewCellProc = (UITableViewCell, IndexPath)->Void
public typealias TableSection = SizPropertyTableSection

open class SizPropertyTableRow {
	public enum CellType {
		case
		text,
		editText,
		onOff,
		picker,
		multiLine,
		button,
		stepper,
		custom,
		datetime,
        image,
        strings
	}
	
	let type: CellType
    let cellClass: UITableViewCell.Type

	var label: String = ""
	var dataSource: (()->Any?)? = nil
	var hint: String = ""
	var labelColor: UIColor? = nil
	var textColor: UIColor? = nil
	var tintColor: UIColor? = nil
	var height: (()->CGFloat)? = nil
	var selectionItems: [String]? = nil
	
	public var onSelect: TableViewIndexProc? = nil
	public var onCreate: TableViewCellProc? = nil
	public var onWillDisplay: TableViewCellProc? = nil
	public var onChanged: ((_ value: Any?)->Void)? = nil
	
	public init(
		type: CellType = .text,
		cellClass: UITableViewCell.Type? = nil,
		label: String = ""
    ) {
		self.type = type
		self.label = label
        
        switch type {
        case .text:
            self.cellClass = SizCellForText.self
        case .editText:
            self.cellClass = SizCellForEditText.self
        case .stepper:
            self.cellClass = SizCellForStepper.self
        case .onOff:
            self.cellClass = SizCellForOnOff.self
        case .multiLine:
            self.cellClass = SizCellForMultiLine.self
        case .button:
            self.cellClass = SizCellForButton.self
        case .picker:
            self.cellClass = SizCellForPicker.self
        case .datetime:
            self.cellClass = SizCellForDateTime.self
        case .image:
            self.cellClass = SizCellForImage.self

        default:
            guard cellClass != nil else {
                fatalError("Cell class is not defined")
            }
            self.cellClass = cellClass!
        }
	}
	
	public func onHeight(_ height: (()->CGFloat)? = nil) -> Self {
		self.height = height
		return self
	}
	public func label(_ text: String) -> Self {
		self.label = text
		return self
	}
	public func dataSource(_ sourceFrom: (()->Any?)? = nil) -> Self {
		self.dataSource = sourceFrom
		return self
	}
	public func selection(items: [String]) -> Self {
		self.selectionItems = items
		return self
	}
	public func hint(_ text: String) -> Self {
		self.hint = text
		return self
	}
	public func labelColor(_ color: UIColor) -> Self {
		self.labelColor = color
		return self
	}
	public func textColor(_ color: UIColor) -> Self {
		self.textColor = color
		return self
	}
	public func tintColor(_ color: UIColor) -> Self {
		self.tintColor = color
		return self
	}
	public func onSelect(_ handler: TableViewIndexProc? = nil) -> Self {
		self.onSelect = handler
		return self
	}
	public func onCreate(_ handler: TableViewCellProc? = nil) -> Self {
		self.onCreate = handler
		return self
	}
	public func willDisplay(_ handler: TableViewCellProc? = nil) -> Self {
		self.onWillDisplay = handler
		return self
	}
	public func onChanged(_ handler: ((_ value: Any?)->Void)? = nil) -> Self {
		self.onChanged = handler
		return self
	}
}

open class SizPropertyTableCell: UITableViewCell, SizViewUpdater {
	
	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
        if #available(iOS 14.0, *) {
            self.contentConfiguration = self.defaultContentConfiguration()
        }
		onInit()
	}
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	open func onInit() {}
	open func refreshViews() {}
    open func updateContent(data: Any?, at row: SizPropertyTableRow) {}
	
	open var onGetCellHieght: (()->CGFloat)? = nil
	open var onValueChanged: ((_ value: Any?)->Void)? = nil
	
	open class var cellType: SizPropertyTableRow.CellType { .custom }
}

open class SizPropertyTableView: SizTableView, UITableViewDataSource {
    
	public override init(frame: CGRect, style: UITableView.Style = .grouped) {
		super.init(frame: frame, style: style)
		onInit()
	}
    
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	private func onInit() {
		dataSource = self
		allowsMultipleSelection = false
		allowsSelection = true
	}
	
	public var autoEndEditing = true
    public var deselectAfterSelectedRow = false
	
	private var source: [SizPropertyTableSection]? = nil
	public func setDataSource(_ source: [SizPropertyTableSection]) {
		self.source = source
	}
	
	open override func willDisplayHeaderView(view: UIView, section: Int) {
		if let header = view as? UITableViewHeaderFooterView {
            let text = tableView(self, titleForHeaderInSection: section)
            
            if #available(iOS 14.0, *) {
                var content = header.defaultContentConfiguration()
                content.text = text
                header.contentConfiguration = content
            }
            else {
                header.textLabel?.text = text
            }
		}
	}
    
    override open func height(rowAt: IndexPath) -> CGFloat {
        if let cellItem = self.source?[rowAt.section].rows[rowAt.row] {
            let cellHieght = cellItem.height?() ?? DEFAULT_HEIGHT
            if cellHieght >= 0 {
                return cellHieght
            }
        }
        
        return rowHeight
    }
    
    override open func willDisplay(cell: UITableViewCell, rowAt: IndexPath) {
        if let cellItem = self.source?[rowAt.section].rows[rowAt.row] {
            (cell as? SizPropertyTableCell)?.updateContent(data: cellItem.dataSource?(), at: cellItem)
            
            if let onWillDisplay = cellItem.onWillDisplay {
                onWillDisplay(cell, rowAt)
                return
            }
        }
        
        (cell as? SizViewUpdater)?.refreshViews()
    }
    
    override open func willSelect(rowAt: IndexPath) -> IndexPath? {
        print("TableView: willSelect")
        if autoEndEditing {
            endEditing(true)
        }
        return rowAt
    }
    
    override open func didSelect(rowAt: IndexPath) {
        if let cellItem = self.source?[rowAt.section].rows[rowAt.row] {
            if self.deselectAfterSelectedRow {
                self.deselectRow(at: rowAt, animated: true)
            }
            cellItem.onSelect?(rowAt)
        }
    }
    
    override open func willDeselect(rowAt: IndexPath) -> IndexPath? {
        print("TableView: willDeselect")
        if autoEndEditing {
            endEditing(true)
        }
        return rowAt
    }
    override open func didDeselect(rowAt: IndexPath) {}
	
	//MARK: - UITableViewDataSource delegate
	
	open func numberOfSections(in tableView: UITableView) -> Int {
		return self.source?.count ?? 0
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.source?[section].rows.count ?? 0
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.source?[section].title
	}
	
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return self.source?[section].onCreateHeader?()
	}
	
	public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return self.source?[section].headerHeight ?? DEFAULT_HEIGHT
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cellItem = self.source?[indexPath.section].rows[indexPath.row] else {
			assertionFailure("Wrong Cell")
			return UITableViewCell()
		}
        
        let cellView = cellItem.cellClass.init() as UITableViewCell
        var labelColor: UIColor = cellItem.labelColor ?? UIColor.defaultText
        var labelText: String? = cellItem.label
		
		switch cellItem.type {
		case .picker:
			cellView.accessoryType = .disclosureIndicator
            guard let cell = cellView as? SizCellForPicker else { break }
            
			cell.selectionTitles = cellItem.selectionItems
            cell.placeholder = cellItem.hint
            if !cellItem.label.isEmpty {
                cell.textField.textAlignment = .right
                if let textColor = cellItem.textColor {
                    cell.textField.textColor = textColor
                }
            }

		case .editText:
            guard let cell = cellView as? SizCellForEditText else { break }
            labelText = nil
            cell.placeholder = cellItem.hint
			
		case .datetime:
            guard let cell = cellView as? SizCellForDateTime else { break }
            cell.placeholder = cellItem.hint
            
            if !cellItem.label.isEmpty {
                cell.textField.textAlignment = .right
                if let textColor = cellItem.textColor {
                    cell.textField.textColor = textColor
                }
            }

			
		case .stepper:
            guard let cell = cellView as? SizCellForStepper else { break }
            cell.placeholder = cellItem.hint
            
            cell.textField.textAlignment = .right
            if let textColor = cellItem.textColor {
                cell.textField.textColor = textColor
            }

            cell.stepper.tintColor = cellItem.tintColor ?? self.tintColor
			
			
		case .onOff:
            //guard let cell = cellView as? SizCellForOnOff else { break }
            break
			
		case .multiLine:
			cellView.accessoryType = cellItem.onSelect != nil
				? .disclosureIndicator
				: .none
            //guard let cell = cellView as? SizCellForMultiLine else { break }
			
		case .button:
            labelColor = cellItem.tintColor ?? self.tintColor
            
        case .image: fallthrough
        case .custom: fallthrough
		case .text: fallthrough
        case .strings: fallthrough
		default:
			cellView.accessoryType = cellItem.onSelect != nil
				? .disclosureIndicator
				: .none
            
            if let _ = cellView as? SizPropertyTableCell {
                // nothing
            }
            else {
                cellView.detailTextLabel?.text = cellItem.dataSource?() as? String ?? ""
                cellView.detailTextLabel?.textColor = cellItem.textColor
            }
		}
        
        if #available(iOS 14.0, *) {
            var content = (cellView.contentConfiguration ?? cellView.defaultContentConfiguration()) as! UIListContentConfiguration
            
            content.text = labelText
            content.textProperties.color = labelColor
            cellView.contentConfiguration = content
        }
        else {
            cellView.textLabel?.text = labelText
            cellView.textLabel?.textColor = labelColor
        }
        
        if let textCell = cellView as? SizCellForText {
            if let textColor = cellItem.textColor {
                textCell.valueLabel?.textColor = textColor
            }
        }

		cellView.selectionStyle = cellItem.onSelect != nil ? .default : .none
		if let sizCell = cellView as? SizPropertyTableCell {
			sizCell.onGetCellHieght = cellItem.height
			sizCell.onValueChanged = cellItem.onChanged
		}
		cellItem.onCreate?(cellView, indexPath)
		return cellView
	}

}

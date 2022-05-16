//
//  SizUI.swift
//  
//
//  Copyright © 2021 Sizuha. All rights reserved.
//

import Foundation
import UIKit

public enum ActionButton {
    case `default`(_ text: String, action: (()->Void)? = nil)
    case destrucive(_ text: String, action: (()->Void)? = nil)
    case cancel(_ text: String, action: (()->Void)? = nil)
}

func createActions(_ buttons: [ActionButton]) -> [UIAlertAction] {
    var actions: [UIAlertAction] = []
    for btn in buttons {
        var action: UIAlertAction? = nil
        
        switch btn {
        case .default(let text, action: let handler):
            action = UIAlertAction(title: text, style: .default, handler: { _ in handler?() })
            
        case .cancel(let text, action: let handler):
            action = UIAlertAction(title: text, style: .cancel, handler: { _ in handler?() })

        case .destrucive(let text, action: let handler):
            action = UIAlertAction(title: text, style: .destructive, handler: { _ in handler?() })
        }
        
        if let action = action {
            actions.append(action)
        }
    }
    return actions
}

// MARK: ActionSheet
public class ActionSheet {
    public let builder: SizAlertBuilder
    
    public init(title: String? = nil, message: String? = nil, buttons: [ActionButton] = []) {
        self.builder = SizAlertBuilder(
            title: title,
            message: message,
            style: .actionSheet
        )
        self.builder.actions = createActions(buttons)
    }
    
    /*public init(title: String? = nil, message: NSAttributedString, buttons: [ActionButton] = []) {
        self.builder = SizAlertBuilder(title: title, style: .actionSheet)
        _ = self.builder.setAttributed(message: message)
        self.builder.actions = createActions(buttons)
    }*/
    
    public func show(from vc: UIViewController, animate: Bool = true, completion: (()->Void)? = nil) {
        self.builder.show(parent: vc, animated: animate, completion: completion)
    }
}

// MARK: Alert
public class Alert {
    public let builder: SizAlertBuilder
    
    public init(title: String? = nil, message: String? = nil, buttons: [ActionButton] = []) {
        self.builder = SizAlertBuilder(
            title: title,
            message: message,
            style: .alert
        )
        self.builder.actions = createActions(buttons)
    }
    
    public init(title: String? = nil, message: NSAttributedString, buttons: [ActionButton] = []) {
        self.builder = SizAlertBuilder(title: title, style: .actionSheet)
        _ = self.builder.setAttributed(message: message)
        self.builder.actions = createActions(buttons)
    }
    
    public func show(from vc: UIViewController, animate: Bool = true, completion: (()->Void)? = nil) {
        self.builder.show(parent: vc, animated: animate, completion: completion)
    }
}

// MARK: SwipeAction
@available(iOS 11.0, *)
public enum SwipeAction {
    case normal(text: String? = nil, image: UIImage? = nil, bgColor: UIColor? = nil, action: UIContextualAction.Handler)
    case destructive(text: String? = nil, image: UIImage? = nil, bgColor: UIColor? = nil, action: UIContextualAction.Handler)
}

@available(iOS 11.0, *)
public func Swipe(
    firstActionWithFullSwipe enableFullSwipe: Bool = false,
    actions: [SwipeAction]
) -> UISwipeActionsConfiguration {
    let builder = SizSwipeActionBuilder()
    for action in actions {
        switch action {
        case .normal(let text, let image, let bgColor, let action):
            _ = builder.addAction(title: text, image: image, style: .normal, bgColor: bgColor, handler: action)

        case .destructive(let text, let image, let bgColor, let action):
            _ = builder.addAction(title: text, image: image, style: .destructive, bgColor: bgColor, handler: action)
        }
    }
    return builder.createConfig(enableFullSwipe: enableFullSwipe)
}

// MARK: PickerView
public func Picker(strings: [String], onSelected: @escaping (_ i: Int, _ text: String)->Void) -> SizStringPicker {
    SizStringPicker(strings: strings, onSelected: onSelected)
}

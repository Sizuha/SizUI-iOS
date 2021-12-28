//
//  SizUI.swift
//  
//
//  Created by ILKYOUNG HWANG on 2021/12/29.
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


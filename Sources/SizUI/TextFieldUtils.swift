//
//  TextFieldUtils.swift
//
//  Created by Sizuha on 2022/09/08.
//

import Foundation
import UIKit

public struct TextFieldValidation {
    public var maxLength: Int = 0
    public var pattern: String? = nil
    
    public init(maxLength: Int, pattern: String? = nil) {
        self.maxLength = maxLength
        self.pattern = pattern
    }
}

public extension UITextField {
    
    func check(
        validation: TextFieldValidation,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currStr = self.text! as NSString
        let changed = currStr.replacingCharacters(in: range, with: string)
        
        if validation.maxLength > 0 {
            guard changed.count <= validation.maxLength else {
                return false
            }
        }
        
        if let patternStr = validation.pattern {
            return changed.range(of: patternStr, options: .regularExpression) != nil
        }
        return true
    }
    
}

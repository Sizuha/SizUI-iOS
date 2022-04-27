//
//  SizTextFieldChecker.swift
//  
//  Copyright © 2022 Sizuha. All rights reserved.
//

import Foundation
import UIKit

open class SizTextFieldChecker {
    
    open class Field {
        public let textField: UITextField
        public var maxLength = 0
        public var pattern: String?
        
        public init(_ textField: UITextField, maxLength: Int = 0, pattern: String? = nil) {
            self.textField = textField
            self.maxLength = maxLength
            self.pattern = pattern
        }
        
        public func shouldChangeCharactersIn(range: NSRange, replacementString string: String) -> Bool {
            var result = true
            
            let currStr = (self.textField.text ?? "") as NSString
            let changed = currStr.replacingCharacters(in: range, with: string)
            let length = changed.count
            
            if self.maxLength > 0 {
                result = length <= self.maxLength
            }
            
            if result,
                let patternStr = self.pattern,
                let regx = try? NSRegularExpression(pattern: patternStr, options: [])
            {
                result = regx.numberOfMatches(in: changed, options: [], range: NSRange(location: 0, length: changed.count)) > 0
            }
            
            return result
        }
    }
    
    public var fields: [Field] = []
    
    open func bypassDelegate(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        for field in fields {
            guard field.textField == textField else { continue }
            return field.shouldChangeCharactersIn(range: range, replacementString: string)
        }
        return true
    }
    
}

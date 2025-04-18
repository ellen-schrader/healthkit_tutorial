//
//  Double+Ext.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import Foundation


extension Double {
    func formattedNumberString() -> String {
        let thousand = 1_000.0
        let million = 1_000_000.0
        let billion = 1_000_000_000.0
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        if self >= billion {
            let value = self / billion
            if let formattedNumber = formatter.string(from: NSNumber(value: value)) {
                return "\(formattedNumber)B"
            }
        } else if self >= million {
            let value = self / million
            if let formattedNumber = formatter.string(from: NSNumber(value: value)) {
                return "\(formattedNumber)M"
            }
        } else if self >= thousand {
            let value = self / thousand
            if value < 10 {
                if let formattedNumber = formatter.string(from: NSNumber(value: value)) {
                    return "\(formattedNumber)K"
                }
            } else {
                // No decimal needed for 10K+
                formatter.maximumFractionDigits = 0
                if let formattedNumber = formatter.string(from: NSNumber(value: value)) {
                    return "\(formattedNumber)K"
                }
            }
        }
        
        // Original formatting for smaller numbers
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

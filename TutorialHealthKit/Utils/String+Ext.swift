//
//  String+Ext.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import Foundation


extension String {
    func toDoubleFromFormattedNumber() -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: self)?.doubleValue
    }
}

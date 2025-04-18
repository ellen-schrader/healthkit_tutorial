//
//  Date+Ext.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 06/04/2025.
//
import Foundation
enum TimeUnit {
    case day
    case week
    case month
    case year
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
    
    func getStartAndEndDates(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        
        switch self {
        case .day:
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
            return (startOfDay, endOfDay)
            
        case .week:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            components.weekday = calendar.firstWeekday
            let startDate = calendar.date(from: components)!
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!.addingTimeInterval(-1)
            return (startDate, endDate)
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: date)
            let startOfMonth = calendar.date(from: components)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
            return (startOfMonth, endOfMonth)
            
        case .year:
            var components = calendar.dateComponents([.year], from: date)
            components.month = 1
            components.day = 1
            let startOfYear = calendar.date(from: components)!
            
            components.year! += 1
            let startOfNextYear = calendar.date(from: components)!
            let endOfYear = startOfNextYear.addingTimeInterval(-1)
            
            return (startOfYear, endOfYear)
        }
    }
}


// #Mark: - Date Extension
extension Date {
    
    static var startOfDay: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    static var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? Date()
    }
    
    // func fetchMonthStartAndEndDate() -> (Date, Date) {
    //     let calendar = Calendar.current
    //     let startDateComponent = calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: self))
    //     let startDate = calendar.date(from: startDateComponent) ?? self
        
    //     let endDate = calendar.date(byAdding: DateComponents(month:1, day:-1), to: startDate) ?? self
        
    //     return (startDate, endDate)
    // }

    func fetchStartAndEndDates(for timeUnit: TimeUnit) -> (Date, Date) {
        return timeUnit.getStartAndEndDates(for: self)
    }
    
    func fetchMonthStartAndEndDate() -> (Date, Date) {
        return TimeUnit.month.getStartAndEndDates(for: self)
    }
    
    func formatWorkoutDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: self)
    } 
}

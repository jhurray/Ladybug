//
//  DateFormatAdapter.swift
//  Ladybug iOS
//
//  Created by Jeff Hurray on 7/30/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

internal protocol DateFormatterProtocol {
    
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

fileprivate final class TimestampDateFormatter: DateFormatterProtocol {
    
    enum TimestampType {
        case secondsSince1970
        case millisecondsSince1970
    }
    
    private let type: TimestampType
    
    init(type: TimestampType) {
        self.type = type
    }
    
    func string(from date: Date) -> String {
        let seconds: TimeInterval
        switch type {
        case .secondsSince1970:
            seconds = date.timeIntervalSince1970
        case .millisecondsSince1970:
            seconds = date.timeIntervalSince1970 * 1000.0
        }
        return String(seconds).components(separatedBy: ".")[0]
    }
    
    func date(from string: String) -> Date? {
        guard var seconds = TimeInterval(string) else {
            return nil
        }
        switch type {
        case .secondsSince1970:
            break
        case .millisecondsSince1970:
            seconds /= 1000.0
        }
        return Date(timeIntervalSince1970: seconds)
    }
}

extension DateFormatter: DateFormatterProtocol {}

internal extension JSONDateKeyPath.DateFormat {
    
    internal var dateFormatter: DateFormatterProtocol {
        switch self {
        case .secondsSince1970:
            return TimestampDateFormatter(type: .secondsSince1970)
        case .millisecondsSince1970:
            return TimestampDateFormatter(type: .millisecondsSince1970)
        case .iso8601:
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .iso8601)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return dateFormatter
        case .custom(let format):
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            return dateFormatter
        }
    }
}

internal final class DateFormatAdapter {
    
    static let shared: DateFormatAdapter = DateFormatAdapter()
    
    private var storage: [JSONDateKeyPath.DateFormat: DateFormatterProtocol] = [:]
    
    func convert(_ dateString: String, fromFormat: JSONDateKeyPath.DateFormat, toFormat: JSONDateKeyPath.DateFormat) -> String? {
        
        guard let date = storage[fromFormat, default: fromFormat.dateFormatter].date(from: dateString) else {
            return nil
        }
        return storage[toFormat, default: toFormat.dateFormatter].string(from: date)
    }
}

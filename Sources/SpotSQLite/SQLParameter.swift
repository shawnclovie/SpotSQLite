//
//  SQLParameter.swift
//  Spot
//
//  Created by Shawn Clovie on 1/9/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation

public protocol SQLParameter {
}

extension String: SQLParameter {}
extension Substring: SQLParameter {}
extension Data: SQLParameter {}
extension Date: SQLParameter {}
extension Bool: SQLParameter {}
extension Double: SQLParameter {}
extension Float: SQLParameter {}
extension Int: SQLParameter {}
extension Int64: SQLParameter {}

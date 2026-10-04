//
//  DocString.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 12/1/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
public struct DocString: Hashable {
    public let rawLiteral: String
    public var literal: String
    public var contentType: String?
}

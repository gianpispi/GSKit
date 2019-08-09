//
//  Backend+Extension.swift
//  Example
//
//  Created by Gianpiero Spinelli on 09/08/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import Foundation

public struct GetAllChannels: RequestType {
    public typealias ResponseType = [String]
    public var data: RequestData
    
    public init(_ link: String) {
        data = RequestData(path: link)
    }
}

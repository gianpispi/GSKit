//
//  BackendManager.swift
//  GSKit
//
//  Created by Gianpiero Spinelli on 09/08/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import Foundation

public enum ConnError: Swift.Error {
    case invalidURL
    case noData
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public struct RequestData {
    public let path: String
    public let method: HTTPMethod
    public let params: [String: Any?]?
    public let headers: [String: String]?
    
    public init (
        path: String,
        method: HTTPMethod = .get,
        params: [String: Any?]? = nil,
        headers: [String: String]? = nil
        ) {
        self.path = path
        self.method = method
        self.params = params
        self.headers = headers
    }
}

public protocol RequestType {
    associatedtype ResponseType: Codable
    var data: RequestData { get }
}

extension RequestType {
    public func execute (
        dispatcher: NetworkDispatcher = URLSessionNetworkDispatcher.instance,
        onSuccess: @escaping (ResponseType) -> Void,
        onError: @escaping (Error) -> Void
        ) {
        dispatcher.dispatch(
            request: self.data,
            onSuccess: { (responseData: Data) in
                do {
                    let jsonDecoder = JSONDecoder()
                    let result = try jsonDecoder.decode(ResponseType.self, from: responseData)
                    DispatchQueue.main.async {
                        onSuccess(result)
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        onError(error)
                    }
                }
        },
            onError: { (error: Error) in
                DispatchQueue.main.async {
                    onError(error)
                }
        })
    }
}

public protocol NetworkDispatcher {
    func dispatch(request: RequestData, onSuccess: @escaping (Data) -> Void, onError: @escaping (Error) -> Void)
    func dispatch(withUrlValue value: String?, key: String?, request: RequestData, onSuccess: @escaping (Data) -> Void, onError: @escaping (Error) -> Void)
}

public struct URLSessionNetworkDispatcher: NetworkDispatcher {
    public static let instance = URLSessionNetworkDispatcher()
    private init() {}
    
    public func dispatch(request: RequestData, onSuccess: @escaping (Data) -> Void, onError: @escaping (Error) -> Void) {
        dispatch(withUrlValue: nil, key: nil, request: request, onSuccess: onSuccess, onError: onError)
    }
    
    public func dispatch(withUrlValue value: String?, key: String?, request: RequestData, onSuccess: @escaping (Data) -> Void, onError: @escaping (Error) -> Void) {
        
        guard let url = URL(string: request.path) else {
            onError(ConnError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        if let valueString = value, let keyString = key {
            urlRequest.setValue(valueString, forHTTPHeaderField: keyString)
        }
        
        if #available(iOS 12.0, *) {
            urlRequest.networkServiceType = .responsiveData
        }
        
        if let headers = request.headers {
            for header in headers {
                urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        do {
            if let params = request.params {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            }
        } catch let error {
            onError(error)
            return
        }
        
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                onError(error)
                return
            }
            
            guard let _data = data else {
                onError(ConnError.noData)
                return
            }
            
            onSuccess(_data)
            }.resume()
    }
}


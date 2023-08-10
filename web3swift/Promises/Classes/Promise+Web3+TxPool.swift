//
//  Promise+Web3+TxPool.swift
//  web3swift-iOS
//
//  Created by Jun Park on 10/10/2018.
//  Copyright © 2018 The Matter Inc. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit


extension web3.TxPool {
    public func getInspectPromise() -> Promise<[String:[String:[String:String]]]> {
        let request = JSONRPCRequestFabric.prepareRequest(.getTxPoolInspect, parameters: [])
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { response in
            guard let value: [String:[String:[String:String]]] = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(desc: response.error!.message)
                }
                throw Web3Error.nodeError(desc: "Invalid value from Ethereum node")
            }
            return value
        }
    }
    
    public func getStatusPromise() -> Promise<[String: Int]> {
        let request = JSONRPCRequestFabric.prepareRequest(.getTxPoolStatus, parameters: [])
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { response in
            guard let value: [String: String] = response.result as? [String: String] else {
                if response.error != nil {
                    throw Web3Error.nodeError(desc: response.error!.message)
                }
                throw Web3Error.nodeError(desc: "Invalid value from Ethereum node")
            }
            var result: [String: Int] = [:]
            for (k, v) in value {
                result[k] = Int.init(v.stripHexPrefix(), radix: 16)
            }
            return result
        }
    }
    
    public func getContentPromise() -> Promise<[String:[String:[String:[String:String?]]]]> {
        let request = JSONRPCRequestFabric.prepareRequest(.getTxPoolContent, parameters: [])
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { response in
            guard let value: [String:[String:[String:[String:String?]]]] = response.getValue() else {
                if response.error != nil {
                    throw Web3Error.nodeError(desc: response.error!.message)
                }
                throw Web3Error.nodeError(desc: "Invalid value from Ethereum node")
            }
            return value
        }
    }
}

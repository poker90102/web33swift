//
//  Promise+Web3+Eth+GetTransactionReceipt.swift
//  web3swift
//
//  Created by Alexander Vlasov on 17.06.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import PromiseKit

extension web3.Eth {
    public func getTransactionReceiptPromise(_ txhash: Data) -> Promise<TransactionReceipt> {
        let hashString = txhash.toHexString().addHexPrefix()
        return self.getTransactionReceiptPromise(hashString)
    }
    
    public func getTransactionReceiptPromise(_ txhash: String) -> Promise<TransactionReceipt> {
        let request = JSONRPCRequestFabric.prepareRequest(.getTransactionReceipt, parameters: [txhash])
        let rp = web3.dispatch(request)
        let queue = web3.requestDispatcher.queue
        return rp.map(on: queue ) { response in
            guard let value: TransactionReceipt = response.getValue() else {
                throw Web3Error.nodeError("Invalid value from Ethereum node")
            }
            return value
//            guard let details = TransactionReceipt(value) else {
//                throw Web3Error.processingError("Can not deserialize transaction details")
//            }
//            return details
//            let reencoded = try JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions(rawValue: 0))
//            let details = try JSONDecoder().decode(TransactionReceipt.self, from: reencoded)
//            return details
        }
    }
}

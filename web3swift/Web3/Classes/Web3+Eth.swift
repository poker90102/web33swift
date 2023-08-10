//
//  Web3+Eth.swift
//  web3swift
//
//  Created by Alexander Vlasov on 22.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import Foundation
import BigInt
import Result

extension web3.Eth {
    
    func sendRawTransaction(_ transaction: EthereumTransaction) -> Result<[String: String], Web3Error> {
        print(transaction)
        guard let request = EthereumTransaction.createRawTransaction(transaction: transaction) else {return Result.failure(Web3Error.transactionSerializationError)}
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultString = payload as? String else {
                return Result.failure(Web3Error.dataError)
            }
            let hash = resultString.addHexPrefix().lowercased()
            return Result(["txhash": hash, "txhashCalculated" : transaction.hash!.toHexString()] as [String: String])
        }
        
    }
    
    public func getTransactionCount(address: EthereumAddress, onBlock: String = "latest") -> Result<BigUInt, Web3Error> {
        guard address.isValid else {
            return Result.failure(Web3Error.inputError("Please check the supplied address"))
        }
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.getTransactionCount
        let params = [address.address.lowercased(), onBlock] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
            case .failure(let error):
                return Result.failure(error)
            case .success(let payload):
                guard let resultString = payload as? String else {
                    return Result.failure(Web3Error.dataError)
                }
                guard let biguint = BigUInt(resultString.stripHexPrefix().lowercased(), radix: 16) else {
                    return Result.failure(Web3Error.dataError)
                }
                return Result(biguint)
        }
    }
    
    public func getBalance(address: EthereumAddress, onBlock: String = "latest") -> Result<BigUInt, Web3Error> {
        guard address.isValid else {
            return Result.failure(Web3Error.inputError("Please check the supplied address"))
        }
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.getBalance
        let params = [address.address.lowercased(), onBlock] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultString = payload as? String else {
                return Result.failure(Web3Error.dataError)
            }
            guard let biguint = BigUInt(resultString.stripHexPrefix().lowercased(), radix: 16) else {
                return Result.failure(Web3Error.dataError)
            }
            return Result(biguint)
        }
    }
    
    public func getBlockNumber() -> Result<BigUInt, Web3Error> {
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.blockNumber
        let params = [] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultString = payload as? String else {
                return Result.failure(Web3Error.dataError)
            }
            guard let biguint = BigUInt(resultString.stripHexPrefix().lowercased(), radix: 16) else {
                return Result.failure(Web3Error.dataError)
            }
            return Result(biguint)
        }
    }
    
    public func getGasPrice() -> Result<BigUInt, Web3Error> {
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.gasPrice
        let params = [] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultString = payload as? String else {
                return Result.failure(Web3Error.dataError)
            }
            guard let biguint = BigUInt(resultString.stripHexPrefix().lowercased(), radix: 16) else {
                return Result.failure(Web3Error.dataError)
            }
            return Result(biguint)
        }
    }
    
    public func getTransactionDetails(_ txhash: String) -> Result<TransactionDetails, Web3Error> {
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.getTransactionByHash
        let params = [txhash] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultJSON = payload as? [String: Any] else {
                return Result.failure(Web3Error.dataError)
            }
            guard let details = TransactionDetails(resultJSON) else {
                return Result.failure(Web3Error.dataError)
            }
            return Result(details)
        }
    }
    
    public func getTransactionReceipt(_ txhash: String) -> Result<TransactionReceipt, Web3Error> {
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.getTransactionReceipt
        let params = [txhash] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultJSON = payload as? [String: Any] else {
                return Result.failure(Web3Error.dataError)
            }
            guard let details = TransactionReceipt(resultJSON) else {
                return Result.failure(Web3Error.dataError)
            }
            return Result(details)
        }
    }
    
    public func estimateGas(_ transaction: EthereumTransaction, options: Web3Options?) -> Result<BigUInt, Web3Error> {
        let mergedOptions = Web3Options.merge(Web3Options.defaultOptions(), with: options)
        guard let request = EthereumTransaction.createRequest(method: JSONRPCmethod.estimateGas, transaction: transaction, onBlock: nil, options: mergedOptions) else {
            return Result.failure(Web3Error.inputError("Transaction serialization failed"))
        }
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultString = payload as? String else {
                return Result.failure(Web3Error.dataError)
            }
            guard let biguint = BigUInt(resultString.stripHexPrefix().lowercased(), radix: 16) else {
                return Result.failure(Web3Error.dataError)
            }
            return Result(biguint)
        }
    }
    
    public func getAccounts() -> Result<[EthereumAddress],Web3Error> {
//        if (self.provider.attachedKeystoreManager != nil) {
//            return Result(self.provider.attachedKeystoreManager?.addresses)
//        }
        var request = JSONRPCrequest()
        request.method = JSONRPCmethod.getAccounts
        let params = [] as Array<Encodable>
        let pars = JSONRPCparams(params: params)
        request.params = pars
        let response = self.provider.send(request: request)
        let result = ResultUnwrapper.getResponse(response)
        switch result {
        case .failure(let error):
            return Result.failure(error)
        case .success(let payload):
            guard let resultArray = payload as? [String] else {
                return Result.failure(Web3Error.dataError)
                }
            var toReturn = [EthereumAddress]()
            for addrString in resultArray {
                let addr = EthereumAddress(addrString)
                if (addr.isValid) {
                    toReturn.append(addr)
                }
            }
            return Result(toReturn)
        }
    }
    
}

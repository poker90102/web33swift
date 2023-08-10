//
//  Web3+TransactionIntermediate.swift
//  web3swift-iOS
//
//  Created by Alexander Vlasov on 26.02.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import Result
import BigInt

@available(*, deprecated)
public struct EventParser {
    public struct EventParsingResult {
        public var event: ABIElement
        public var receipt: TransactionReceipt
        public var decodedResult: [String:Any]
    }

    public var contract: ContractProtocol
    public var contractAddress: EthereumAddress?
    public var event: ABIElement
    public var filter: EventFilter?
    var web3: web3
    public init? (web3 web3Instance: web3, event: ABIElement, contract: ContractProtocol, filter: EventFilter? = nil, forAddress: EthereumAddress? = nil) {
        guard case .event(_) = event else {return nil}
        self.event = event
        self.web3 = web3Instance
        self.contract = contract
        self.filter = filter
        self.contractAddress = forAddress
    }
    
    
    public func parseBlock(_ block: Block) -> Result<[EventParsingResult], Web3Error> {
        guard case .event(let ev) = event else {return Result.failure(Web3Error.dataError)}
        guard let eventOfSuchTypeIsPresent = block.logsBloom?.test(topic: ev.topic) else {return Result.failure(Web3Error.dataError)}
        if (!eventOfSuchTypeIsPresent) {
            return Result([])
        }
        var allResults = [EventParsingResult]()
        if (self.contractAddress == nil) {
            for transaction in block.transactions {
                switch transaction {
                case .null:
                    return Result.failure(Web3Error.dataError)
                case .transaction(let tx):
                    guard let hash = tx.hash else {return Result.failure(Web3Error.dataError)}
                    let subresult = parseTransactionByHash(hash)
                    switch subresult {
                    case .failure(let error):
                        return Result.failure(error)
                    case .success(let subsetOfEvents):
                        allResults += subsetOfEvents
                    }
                case .hash(let hash):
                    let subresult = parseTransactionByHash(hash)
                    switch subresult {
                    case .failure(let error):
                        return Result.failure(error)
                    case .success(let subsetOfEvents):
                        allResults += subsetOfEvents
                    }
                }
            }
        } else {
            for transaction in block.transactions {
                switch transaction {
                case .null:
                    return Result.failure(Web3Error.dataError)
                case .transaction(let tx):
                    guard let hash = tx.hash else {return Result.failure(Web3Error.dataError)}
                    if (tx.to != self.contractAddress) {
                        continue
                    }
                    let subresult = parseTransactionByHash(hash)
                    switch subresult {
                    case .failure(let error):
                        return Result.failure(error)
                    case .success(let subsetOfEvents):
                        allResults += subsetOfEvents
                    }
                case .hash(let hash):
                    let response = self.web3.eth.getTransactionDetails(hash)
                    switch response {
                    case .failure(let error):
                        return Result.failure(error)
                    case .success(let details):
                        guard let hash = details.transaction.hash else {return Result.failure(Web3Error.dataError)}
                        let to = details.transaction.to
                        if (to != self.contractAddress) {
                            continue
                        }
                        let subresult = parseTransactionByHash(hash)
                        switch subresult {
                        case .failure(let error):
                            return Result.failure(error)
                        case .success(let subsetOfEvents):
                            allResults += subsetOfEvents
                        }
                    }
                }
            }
        }
        return Result(allResults)
    }
    
    public func parseTransactionByHash(_ hash: Data) -> Result<[EventParsingResult], Web3Error> {
        let response = web3.eth.getTransactionReceipt(hash)
        switch response {
        case .failure(let error):
            return Result.failure(error)
        case .success(let receipt):
            guard case .event(let ev) = event else {return Result.failure(Web3Error.dataError)}
            guard let eventOfSuchTypeIsPresent = receipt.logsBloom?.test(topic: ev.topic) else {return Result.failure(Web3Error.dataError)}
            if (!eventOfSuchTypeIsPresent) {
                return Result([])
            }
            let decodedLogs = receipt.logs.flatMap({ (log) -> [String:Any]? in
                self.event.decodeReturnedLogs(log)
            })
            var allResults = [EventParsingResult]()
            if (self.filter != nil) {
                for log in decodedLogs {
                    let parsingResult = EventParsingResult(event: self.event, receipt: receipt, decodedResult: log)
                    allResults.append(parsingResult)
                }
            } else {
                for log in decodedLogs {
                    let parsingResult = EventParsingResult(event: self.event, receipt: receipt, decodedResult: log)
                    allResults.append(parsingResult)
                }
            }
            return Result(allResults)
        }
    }
    
    public func parseTransaction(_ transaction: EthereumTransaction) -> Result<[EventParsingResult], Web3Error> {
        guard let hash = transaction.hash else {return Result.failure(Web3Error.dataError)}
        return self.parseTransactionByHash(hash)
    }
}


extension web3.web3contract {
    public struct EventParser: EventParserProtocol {
        public struct EventParserResult:EventParserResultProtocol {
            public var eventName: String
            public var transactionReceipt: TransactionReceipt
            public var contractAddress: EthereumAddress
            public var decodedResult: [String:Any]
        }
        
        public var contract: ContractProtocol
        public var eventName: String
        public var filter: EventFilter?
        var web3: web3
        public init? (web3 web3Instance: web3, eventName: String, contract: ContractProtocol, filter: EventFilter? = nil) {
            guard let _ = contract.allEvents.index(of: eventName) else {return nil}
            self.eventName = eventName
            self.web3 = web3Instance
            self.contract = contract
            self.filter = filter
        }
        
        public func parseBlockByNumber(_ blockNumber: UInt64) -> Result<[EventParserResultProtocol], Web3Error> {
            let response = web3.eth.getBlockByNumber(blockNumber)
            switch response {
            case .success(let block):
                return parseBlock(block)
            case .failure(let error):
                return Result.failure(error)
            }
        }
        
        public func parseBlock(_ block: Block) -> Result<[EventParserResultProtocol], Web3Error> {
            guard let bloom = block.logsBloom else {return Result.failure(Web3Error.dataError)}
            if self.contract.address != nil {
                let addressPresent = block.logsBloom?.test(topic: self.contract.address!.addressData)
                if (addressPresent != true) {
                    return Result([EventParserResultProtocol]())
                }
            }
            guard let eventOfSuchTypeIsPresent = self.contract.testBloomForEventPrecence(eventName: self.eventName, bloom: bloom) else {return Result.failure(Web3Error.dataError)}
            if (!eventOfSuchTypeIsPresent) {
                return Result([EventParserResultProtocol]())
            }
            var allResults = [EventParserResultProtocol]()
            for transaction in block.transactions {
                switch transaction {
                case .null:
                    return Result.failure(Web3Error.dataError)
                case .transaction(let tx):
                    guard let hash = tx.hash else {return Result.failure(Web3Error.dataError)}
                    let subresult = parseTransactionByHash(hash)
                    switch subresult {
                    case .failure(let error):
                        return Result.failure(error)
                    case .success(let subsetOfEvents):
                        allResults += subsetOfEvents
                    }
                case .hash(let hash):
                    let subresult = parseTransactionByHash(hash)
                    switch subresult {
                    case .failure(let error):
                        return Result.failure(error)
                    case .success(let subsetOfEvents):
                        allResults += subsetOfEvents
                    }
                }
            }
            return Result(allResults)
        }
        
        public func parseTransactionByHash(_ hash: Data) -> Result<[EventParserResultProtocol], Web3Error> {
            let response = web3.eth.getTransactionReceipt(hash)
            switch response {
            case .failure(let error):
                return Result.failure(error)
            case .success(let receipt):
                guard let bloom = receipt.logsBloom else {return Result.failure(Web3Error.dataError)}
                if self.contract.address != nil {
                    let addressPresent = bloom.test(topic: self.contract.address!.addressData)
                    if (addressPresent != true) {
                        return Result([EventParserResultProtocol]())
                    }
                }
                guard let eventOfSuchTypeIsPresent = self.contract.testBloomForEventPrecence(eventName: self.eventName, bloom: bloom) else {return Result.failure(Web3Error.dataError)}
                if (!eventOfSuchTypeIsPresent) {
                    return Result([EventParserResultProtocol]())
                }
                var allLogs = receipt.logs
                if (self.contract.address != nil) {
                    allLogs = receipt.logs.filter({ (log) -> Bool in
                        log.address == self.contract.address
                    })
                }
                let decodedLogs = allLogs.flatMap({ (log) -> EventParserResultProtocol? in
                    let (n, d) = contract.parseEvent(log)
                    guard let evName = n, let evData = d else {return nil}
                    return EventParserResult(eventName: evName, transactionReceipt: receipt, contractAddress: log.address, decodedResult: evData)
                }).filter { (res) -> Bool in
                    return res != nil && res.eventName == self.eventName
                }
                var allResults = [EventParserResultProtocol]()
                if (self.filter != nil) {
                    // TODO NYI
                    allResults = decodedLogs
//                    for log in decodedLogs {
//                        let parsingResult = EventParserResult(eventName: self.eventName, transactionReceipt: receipt, decodedResult: log)
//                        allResults.append(parsingResult)
//                    }
                } else {
                    allResults = decodedLogs
                }
                return Result(allResults)
            }
        }
        
        public func parseTransaction(_ transaction: EthereumTransaction) -> Result<[EventParserResultProtocol], Web3Error> {
            guard let hash = transaction.hash else {return Result.failure(Web3Error.dataError)}
            return self.parseTransactionByHash(hash)
        }
    }
}


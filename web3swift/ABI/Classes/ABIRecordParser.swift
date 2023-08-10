//
//  ABIRecordParser.swift
//  web3swift
//
//  Created by Alexander Vlasov on 06.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import Foundation

//fileprivate typealias ParameterType = ABIElement.ParameterType

public enum ParsingError: Error {
    case invalidJsonFile
    case elementTypeInvalid
    case elementNameInvalid
    case functionInputInvalid
    case functionOutputInvalid
    case eventInputInvalid
    case parameterTypeInvalid
    case parameterTypeNotFound
    case abiInvalid
}

enum TypeMatchingExpressions {
    static var typeRegex = "^(?<type>[^0-9\\s]*?)(?<typeLength>[1-9][0-9]*)?$"
    static var arrayRegex = "^(?<type>[^0-9\\s]*?)(?<typeLength>[1-9][0-9]*)?\\[(?<arrayLength>[1-9][0-9]*)?\\]$"
}


fileprivate enum ElementType: String {
    case function
    case constructor
    case fallback
    case event
}



extension ABIRecord {
    public func parse() throws -> ABIElement {
        let typeString = self.type != nil ? self.type! : "function"
        guard let type = ElementType(rawValue: typeString) else {
            throw ParsingError.elementTypeInvalid
        }
        return try parseToElement(from: self, type: type)
    }
}

fileprivate func parseToElement(from abiRecord: ABIRecord, type: ElementType) throws -> ABIElement {
    switch type {
        case .function:
            let function = try parseFunction(abiRecord: abiRecord)
            return ABIElement.function(function)
        case .constructor:
            let constructor = try parseConstructor(abiRecord: abiRecord)
            return ABIElement.constructor(constructor)
        case .fallback:
            let fallback = try parseFallback(abiRecord: abiRecord)
            return ABIElement.fallback(fallback)
        case .event:
            let event = try parseEvent(abiRecord: abiRecord)
            return ABIElement.event(event)
    }
}

fileprivate func parseFunction(abiRecord:ABIRecord) throws -> ABIElement.Function {
    let inputs = try abiRecord.inputs?.map({ (input:ABIInput) throws -> ABIElement.Function.Input in
        let name = input.name != nil ? input.name! : ""
        let parameterType = try parseType(from: input.type)
        let nativeInput = ABIElement.Function.Input(name: name, type: parameterType)
        return nativeInput
    })
    let abiInputs = inputs != nil ? inputs! : [ABIElement.Function.Input]()
    let outputs = try abiRecord.outputs?.map({ (output:ABIOutput) throws -> ABIElement.Function.Output in
        let name = output.name != nil ? output.name! : ""
        let parameterType = try parseType(from: output.type)
        let nativeOutput = ABIElement.Function.Output(name: name, type: parameterType)
        return nativeOutput
    })
    let abiOutputs = outputs != nil ? outputs! : [ABIElement.Function.Output]()
    let name = abiRecord.name != nil ? abiRecord.name! : ""
    let payable = abiRecord.stateMutability != nil ?
        (abiRecord.stateMutability == "payable" || abiRecord.payable!) : false
    let constant = (abiRecord.constant! || abiRecord.stateMutability == "view" || abiRecord.stateMutability == "pure")
    let functionElement = ABIElement.Function(name: name, inputs: abiInputs, outputs: abiOutputs, constant: constant, payable: payable)
    return functionElement
}

fileprivate func parseFallback(abiRecord:ABIRecord) throws -> ABIElement.Fallback {
    let payable = (abiRecord.stateMutability == "payable" || abiRecord.payable!)
    var constant = false
    if (abiRecord.constant != nil) {
        constant = abiRecord.constant!
    }
    if (abiRecord.stateMutability == "view" || abiRecord.stateMutability == "pure") {
        constant = true
    }
    let functionElement = ABIElement.Fallback(constant: constant, payable: payable)
    return functionElement
}

fileprivate func parseConstructor(abiRecord:ABIRecord) throws -> ABIElement.Constructor {
    let inputs = try abiRecord.inputs?.map({ (input:ABIInput) throws -> ABIElement.Function.Input in
        let name = input.name != nil ? input.name! : ""
        let parameterType = try parseType(from: input.type)
        let nativeInput = ABIElement.Function.Input(name: name, type: parameterType)
        return nativeInput
    })
    let abiInputs = inputs != nil ? inputs! : [ABIElement.Function.Input]()
    var payable = false
    if (abiRecord.payable != nil) {
        payable = abiRecord.payable!
    }
    if (abiRecord.stateMutability == "payable") {
        payable = true
    }
    let constant = false
    let functionElement = ABIElement.Constructor(inputs: abiInputs, constant: constant, payable: payable)
    return functionElement
}

fileprivate func parseEvent(abiRecord:ABIRecord) throws -> ABIElement.Event {
    let inputs = try abiRecord.inputs?.map({ (input:ABIInput) throws -> ABIElement.Event.Input in
        let name = input.name != nil ? input.name! : ""
        let parameterType = try parseType(from: input.type)
        let indexed = input.indexed != nil ? input.indexed! : false
        let nativeInput = ABIElement.Event.Input(name: name, type: parameterType, indexed: indexed)
        return nativeInput
    })
    let abiInputs = inputs != nil ? inputs! : [ABIElement.Event.Input]()
    let name = abiRecord.name != nil ? abiRecord.name! : ""
    let anonymous = abiRecord.anonymous != nil ? abiRecord.anonymous! : false
    let functionElement = ABIElement.Event(name: name, inputs: abiInputs, anonymous: anonymous)
    return functionElement
}

extension ABIInput {
    func parse() throws -> ABIElement.Function.Input{
        let name = self.name != nil ? self.name! : ""
        let paramType = try parseType(from: self.type)
        return ABIElement.Function.Input(name:name, type: paramType)
    }
    
    func parseForEvent() throws -> ABIElement.Event.Input{
        let name = self.name != nil ? self.name! : ""
        let paramType = try parseType(from: self.type)
        let indexed = self.indexed != nil ? self.indexed! : false
        return ABIElement.Event.Input(name:name, type: paramType, indexed: indexed)
    }
}


fileprivate func parseType(from string: String) throws -> ABIElement.ParameterType {
    let possibleType = try typeMatch(from: string) ?? arrayMatch(from: string)
    guard let foundType = possibleType else {
        throw ParsingError.parameterTypeInvalid
    }
    guard foundType.isValid else {
            throw ParsingError.parameterTypeInvalid
    }
    return foundType
}

/// Types that are "atomic" can be matched exactly to these strings
fileprivate enum ExactMatchParameterType: String {
    // Static Types
    case address
    case uint
    case int
    case bool
    case function
    
    // Dynamic Types
    case bytes
    case string
}

fileprivate func exactMatchType(from string: String, length:Int? = nil, staticArrayLength:Int? = nil) -> ABIElement.ParameterType? {
    // Check all the exact matches by trying to create a ParameterTypeKey from it.
    switch ExactMatchParameterType(rawValue: string) {
        
    // Static Types
    case .address?:
        return .staticABIType(.address)
    case .uint?:
        return .staticABIType(.uint(bits: length != nil ? UInt64(length!) : 256))
    case .int?:
        return .staticABIType(.int(bits: length != nil ? UInt64(length!) : 256))
    case .bool?:
        return .staticABIType(.bool)
//    case .function?:
//        return .staticABIType(.function)
        
    // Dynamic Types
    case .bytes?:
        if (length != nil) { return .staticABIType(.bytes(length: UInt64(length!))) }
        return .dynamicABIType(.bytes)
    case .string?:
        return .dynamicABIType(.string)
    default:
        guard let arrayLen = staticArrayLength else {return nil}
        guard let baseType = exactMatchType(from: string, length: length) else {return nil}
        switch baseType{
        case .staticABIType(let unwrappedType):
            if (staticArrayLength == 0) {
                return .dynamicABIType(.dynamicArray(unwrappedType))
            }
            return .staticABIType(.array(unwrappedType, length: UInt64(arrayLen)))
        case .dynamicABIType(let unwrappedType):
            if (staticArrayLength == 0) {
                return .dynamicABIType(.arrayOfDynamicTypes(unwrappedType, length: UInt64(arrayLen)))
            }
            return nil
        }
    }
}

fileprivate func typeMatch(from string: String) throws -> ABIElement.ParameterType?{
    let matcher = try NSRegularExpression(pattern: TypeMatchingExpressions.typeRegex, options: NSRegularExpression.Options.dotMatchesLineSeparators)
    let match = matcher.captureGroups(string: string, options: NSRegularExpression.MatchingOptions.anchored)
    guard let typeString = match["type"] else {return nil}
    guard let type = exactMatchType(from: typeString) else {return nil}
    if (match.keys.contains("typeLength")) {
        guard let typeLength = Int(match["typeLength"]!) else {throw ParsingError.parameterTypeInvalid}
        guard let canonicalType = exactMatchType(from: typeString, length: typeLength) else {throw ParsingError.parameterTypeInvalid}
        return canonicalType
    }
    return type
}

fileprivate func arrayMatch(from string: String) throws -> ABIElement.ParameterType?{
    let matcher = try NSRegularExpression(pattern: TypeMatchingExpressions.arrayRegex, options: [])
    let match = matcher.captureGroups(string: string, options: NSRegularExpression.MatchingOptions.anchored)
    if match.keys.contains("arrayLength") {
        guard let typeString = match["type"] else {return nil}
        guard let arrayLength = Int(match["arrayLength"]!) else {throw ParsingError.parameterTypeInvalid}
        guard var type = exactMatchType(from: typeString, staticArrayLength: arrayLength) else {return nil}
        guard case .staticABIType(_) = type else {throw ParsingError.parameterTypeInvalid}
        if (match.keys.contains("typeLength")) {
            guard let typeLength = Int(match["typeLength"]!) else {throw ParsingError.parameterTypeInvalid}
            guard let canonicalType = exactMatchType(from: typeString, length: typeLength, staticArrayLength: arrayLength) else {throw ParsingError.parameterTypeInvalid}
            type = canonicalType
        }
        return type
    } else {
        guard let typeString = match["type"] else {return nil}
        var typeLength: Int? = nil
        if let typeLengthString = match["typeLength"] {
            typeLength = Int(typeLengthString)
        }
        guard var type = exactMatchType(from: typeString, length: typeLength, staticArrayLength: 0) else {throw ParsingError.parameterTypeInvalid}
        guard case .staticABIType(_) = type else {return nil}
        if (match.keys.contains("typeLength")) {
            guard let typeLength = Int(match["typeLength"]!) else {throw ParsingError.parameterTypeInvalid}
            guard let canonicalType = exactMatchType(from: typeString, length: typeLength, staticArrayLength: 0) else {throw ParsingError.parameterTypeInvalid}
            type = canonicalType
        }
        return type
    }
}


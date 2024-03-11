//
//  main.swift
//  ELEC374 Instruction Generator
//
//  Created by Noah Wilder on 2023-03-29.
//

import Foundation



struct Instruction {
    
    var kind: Kind
    var code: String

    init(_ input: String) {
        let allArgs = input.lowercased().split(separator: /[\s,]+/).map { String($0) }
        let name = allArgs[0]
        let args = Array(allArgs.dropFirst())
        let instructionKind = Kind(name)!
        var instrCode = instructionKind.opcode
        
        guard args.count == instructionKind.argCount else {
            fatalError("Invalid number of arguments")
        }
        
        
        
        switch instructionKind {
        case .ld, .ldi:
            let ra = Register(args[0])!
            let r = RegisterWithOffset(args[1])!
            instrCode += ra.binaryValue
            instrCode += r.register.binaryValue
            instrCode += r.binaryOffset
        case .st:
            let r = RegisterWithOffset(args[0])!
            let ra = Register(args[1])!
            instrCode += ra.binaryValue
            instrCode += r.register.binaryValue
            instrCode += r.binaryOffset
        
        case .xor, .add, .sub, .and, .or, .shr, .shra, .shl, .ror, .rol:
            let ra = Register(args[0])!
            let rb = Register(args[1])!
            let rc = Register(args[2])!
            instrCode += ra.binaryValue
            instrCode += rb.binaryValue
            instrCode += rc.binaryValue
            instrCode += String(repeating: "0", count: 15)
            
        case .xori, .addi, .andi, .ori:
            let ra = Register(args[0])!
            let rb = Register(args[1])!
            let c = RegisterWithOffset(args[2])!
            instrCode += ra.binaryValue
            instrCode += rb.binaryValue
            instrCode += c.binaryOffset
        case .mul, .div, .neg, .not:
            let ra = Register(args[0])!
            let rb = Register(args[1])!
            instrCode += ra.binaryValue
            instrCode += rb.binaryValue
            instrCode += String(repeating: "0", count: 19)
            
        case .brzr, .brnz, .brmi, .brpl:
            var c2 = ""
            if instructionKind == .brzr {
                c2 = "0000"
            } else if instructionKind == .brnz {
                c2 = "0001"
            } else if instructionKind == .brpl {
                c2 = "0010"
            } else if instructionKind == .brnz {
                c2 = "0011"
            }
            let ra = Register(args[0])!
            let c = RegisterWithOffset(args[1])!
            instrCode += ra.binaryValue
            instrCode += c2
            instrCode += c.binaryOffset
            
            
        case .jr, .jal, .in, .out, .mfhi, .mflo:
            let ra = Register(args[0])!
            instrCode += ra.binaryValue
            instrCode += String(repeating: "0", count: 23)
        case .nop, .halt:
            instrCode += String(repeating: "0", count: 27)
        }
        
        let hexCode = String(Int(instrCode, radix: 2)!, radix: 16)
        code = String(repeating: "0", count: 8 - hexCode.count) + hexCode
        
        kind = instructionKind
    }
    struct RegisterWithOffset {
        var register: Register
        var binaryOffset: String
        
        init? (_ input: String) {
            guard let match = input.firstMatch(of: /^(?<offset>[\$-]?[A-Fa-f0-9]+)(\((?<reg>[Rr]([0-9]|1[1-5]))\))?$/) else {
                fatalError("Invalid format")
            }
            
            if let reg = match.output.reg {
                register = Register(String(reg))!
            } else {
                register = .r0
            }
            let offset = String(match.output.offset)
            var binOffset = ""
            if offset.first == "$" {
                let n = Int(offset.dropFirst(), radix: 16)!
                binOffset = String(n, radix: 2)
                binOffset = String(repeating: "0", count: 19 - binOffset.count) + binOffset
            } else if offset.first == "-" {
                let n = Int(offset.dropFirst())!
                binOffset = String(n, radix: 2)
                binOffset = String(repeating: "0", count: 19 - binOffset.count) + binOffset
                var arr = binOffset.map { $0 == "0" ? "1" : "0" }
                for (index, b) in arr.enumerated().reversed() {
                    if b == "1" {
                        arr[index] = "0"
                    } else {
                        arr[index] = "1"
                        break
                    }
                }
                binOffset = arr.joined()
            } else {
                let n = Int(offset)!
                binOffset = String(n, radix: 2)
                binOffset = String(repeating: "0", count: 19 - binOffset.count) + binOffset
            }
            binaryOffset = binOffset
        }
        
        
    }
    
    enum Register: String, CaseIterable {
        case r0,  r1,  r2,  r3
        case r4,  r5,  r6,  r7
        case r8,  r9,  r10, r11
        case r12, r13, r14, r15
        
        init? (_ name: String) {
            for reg in Register.allCases {
                if reg.rawValue == name.lowercased() {
                    self = reg
                    return
                }
            }
            return nil
        }
        
        var binaryValue: String {
            switch self {
            case .r0: return "0000"
            case .r1: return "0001"
            case .r2: return "0010"
            case .r3: return "0011"
            case .r4: return "0100"
            case .r5: return "0101"
            case .r6: return "0110"
            case .r7: return "0111"
            case .r8: return "1000"
            case .r9: return "1001"
            case .r10: return "1010"
            case .r11: return "1011"
            case .r12: return "1100"
            case .r13: return "1101"
            case .r14: return "1110"
            case .r15: return "1111"
            }
        }
    }
    
    enum Kind: CaseIterable {
        case ld, ldi, st
        case add, sub, and, or, shr, shra, shl, ror, rol
        case addi, andi, ori
        case mul, div, neg, not
        case brzr, brnz, brmi, brpl
        case jr, jal
        case `in`, out, mfhi, mflo
        case nop, halt
        case xor, xori
        
        init?(_ name: String) {
            for instruction in Instruction.Kind.allCases {
                if instruction.name == name.lowercased() {
                    self = instruction
                    return
                }
            }
            return nil
        }
        
        var name: String {
            switch self {
            case .ld: return "ld"
            case .ldi: return "ldi"
            case .st: return "st"
            case .add: return "add"
            case .sub: return "sub"
            case .and: return "and"
            case .or: return "or"
            case .shr: return "shr"
            case .shra: return "shra"
            case .shl: return "shl"
            case .ror: return "ror"
            case .rol: return "rol"
            case .addi: return "addi"
            case .andi: return "andi"
            case .ori: return "ori"
            case .mul: return "mul"
            case .div: return "div"
            case .neg: return "neg"
            case .not: return "not"
            case .brzr: return "brzr"
            case .brnz: return "brnz"
            case .brmi: return "brmi"
            case .brpl: return "brpl"
            case .jr: return "jr"
            case .jal: return "jal"
            case .in: return "in"
            case .out: return "out"
            case .mfhi: return "mfhi"
            case .mflo: return "mflo"
            case .nop: return "nop"
            case .halt: return "halt"
            case .xor: return "xor"
            case .xori: return "xori"
            }
        }
        
        var opcode: String {
            switch self {
            case .ld: return "00000"
            case .ldi: return "00001"
            case .st: return "00010"
            case .add: return "00011"
            case .sub: return "00100"
            case .and: return "00101"
            case .or: return "00110"
            case .shr: return "00111"
            case .shra: return "01000"
            case .shl: return "01001"
            case .ror: return "01010"
            case .rol: return "01011"
            case .addi: return "01100"
            case .andi: return "01101"
            case .ori: return "01110"
            case .mul: return "01111"
            case .div: return "10000"
            case .neg: return "10001"
            case .not: return "10010"
            case .brzr, .brnz, .brmi, .brpl: return "10011"
            case .jr: return "10100"
            case .jal: return "10101"
            case .in: return "10110"
            case .out: return "10111"
            case .mfhi: return "11000"
            case .mflo: return "11001"
            case .nop: return "11010"
            case .halt: return "11011"
            case .xor: return "11100"
            case .xori: return "11101"
            }
        }
        
        var argCount: Int {
            switch self {
            case .xor, .xori, .add, .sub, .and, .or, .shr, .shra, .shl, .ror, .rol, .addi, .andi, .ori: return 3
            case .ld, .ldi, .st, .mul, .div, .neg, .not: return 2
            case .brzr, .brnz, .brmi, .brpl: return 2
            case .jr, .jal, .in, .out, .mfhi, .mflo: return 1
            case .nop, .halt: return 0
            }
        }
    }
    
    
    
    
    
}

//let input = """
//ORG 0
//ldi R1, 2
//ldi R0, 0(R1)
//ld R2, $68
//ldi R2, -4(R2)
//ld R1, 1(R2)
//ldi R3, $69
//brmi R3, 4
//ldi R3, 2(R3)
//ld R7, -3(R3)
//nop
//brpl R7, 2
//ldi R2, 5(R0)
//ldi R3, 2(R1)
//add R3, R2, R3
//addi R7, R7, 2
//neg R7, R7
//not R7, R7
//andi R7, R7, $0F
//ror R1, R1, R0
//ori R7, R1, $1C
//shra R7, R7, R0
//shr R2, R3, R0
//st $52, R2
//rol R2, R2, R0
//or R2, R3, R0
//and R1, R2, R1
//st $60(R1), R3
//sub R3, R2, R3
//shl R1, R2, R0
//ldi R4, 6
//ldi R5, $32
//mul R5, R4
//mfhi R7
//mflo R6
//div R5, R4
//ldi R8, -1(R4)
//ldi R9, -19(R5)
//ldi R10, 0(R6)
//ldi R11, 0(R7)
//jal R10
//in R4
//st $95, R4
//ldi R1, $2D
//ldi R7, 1
//ldi R5, 40
//out R4
//ldi R5, -1(R5)
//brzr R5, 8
//ld R6, $F0
//ldi R6, -1(R6)
//nop
//brnz R6, -3
//shr R4, R4, R7
//brnz R4, -9
//ld R4, $95
//jr R1
//ldi R4, $A5
//out R4
//halt
//ORG $12C
//add R13, R8, R10
//sub R12, R9, R11
//sub R13, R13, R12
//jr R15
//"""


//var input = """
//ldi R1, 2
//ld R2, $68
//ldi R2, -4(R2)
//ld R1, 1(R2)
//ldi R3, $69
//brmi R3, 4
//ldi R3, 2(R3)
//ld R7, -3(R3)
//nop
//brpl R7, 2
//ldi R2, 5(R0)
//ldi R3, 2(R1)
//add R3, R2, R3
//addi R7, R7, 2
//neg R7, R7
//not R7, R7
//andi R7, R7, $0F
//ror R1, R1, R0
//ori R7, R1, $1C
//shra R7, R7, R0
//shr R2, R3, R0
//st $52, R2
//rol R2, R2, R0
//or R2, R3, R0
//and R1, R2, R1
//st $60(R1), R3
//sub R3, R2, R3
//shl R1, R2, R0
//ldi R4, 6
//ldi R5, $32
//mul R5, R4
//mfhi R7
//mflo R6
//div R5, R4
//ldi  R8, -1(R4)
//ldi R9, -19(R5)
//ldi R10, 0(R6)
//ldi R11, 0(R7)
//jal R10
//halt
//ORG $12C
//add R13, R8, R10
//sub R12, R9, R11
//sub R13, R13, R12
//jr R15
//"""
var input = """
ldi R2, 2
ldi R1, 1
xor R3, R1, R2
xori R4, R2, 1
halt
"""
var output = ""


let lines = input.split(separator: /[\s\n]*\n[\s\n]*/)
var memCounter = 0
print()
for line in lines {
    if let match = line.firstMatch(of: /^ORG[\s]+(?<location>\$?[0-9A-F]+)$/) {
        let loc = String(match.output.location)
        output += "// ORG " + loc + "\n"
        if loc.first == "$" {
            memCounter = Int(loc.dropFirst(), radix: 16)!
        } else {
            memCounter = Int(loc)!
        }
        continue
    }
    let instruction = Instruction(String(line))
    output += "memory[\(memCounter)] = 32'h" + instruction.code.uppercased() + "; // " + String(line) + "\n"
    memCounter += 1
}

print(output)


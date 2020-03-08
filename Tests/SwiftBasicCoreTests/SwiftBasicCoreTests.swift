import XCTest
@testable import SwiftBasicCore

final class SwiftBasicCoreTests: XCTestCase {
    
    static var allTests = [
        ("testArithmetic", testArithmetic),
        ("testEndFunction", testEndFunction),
        ("testEndKeyword", testEndKeyword),
        ("testAssigningDoubles", testAssigningDoubles),
        ("testAssigningStrings", testAssigningStrings),
        ("testStringOperators", testStringOperators),
        ("testDictionary", testDictionary),
        ("testRand", testRand),
        ("testStringSubscript", testStringSubscript),
        ("testTrigFuncs", testTrigFuncs),
        ("testBitwise", testBitwise),
        ("testDictionaryLiteral", testDictionaryLiteral)
    ]
    
    /// Tests the arithmetic operators. This also tests INPUT and PRINT.
    func testArithmetic() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        let a = Int.random(in: 0...10)
        let b = Int.random(in: 0...10)
        testConsole.inputBuffer = ["\(a)", "\(b)"]
        let code = """
        INPUT A, B
        PRINT A, " + ", B, " == ", A + B
        PRINT A, " - ", B, " == ", A - B
        PRINT A, " * ", B, " == ", A * B
        IF B == 0 THEN GOTO SkipDivision
        PRINT A, " / ", B, " == ", A / B
        PRINT A, " % ", B, " == ", A % B
        SkipDivision
        PRINT A, " ** ", B, " == ", A ** B
        """
        
        var expectedOutput = """
        \(a) + \(b) == \(a + b)
        \(a) - \(b) == \(a - b)
        \(a) * \(b) == \(a * b)\n
        """
        if b != 0 {
            expectedOutput += """
            \(a) / \(b) == \(a / b)
            \(a) % \(b) == \(a % b)\n
            """
        }
        expectedOutput += """
        \(a) ** \(b) == \(a ** b)
        
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        
        XCTAssert(testConsole.output == expectedOutput)
    }
    
    /// Test BasicParser.endProgram(), meant to be called by another function on another thread.
    func testEndFunction(){
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        let code = """
        10 GOTO 20
        20 GOTO 10
        """
        try! parser.loadCode(fromString: code)
        DispatchQueue.main.async {
            try! parser.run()
        }
        usleep(1000)
        parser.endProgram()
    }
    
    /// Test the END Basic keyword, which should terminate the program.
    func testEndKeyword(){
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        let code = """
        END
        PRINT "This shouldn't be printed"
        """
        try! parser.loadCode(fromString: code)
        try! parser.run()
        XCTAssert(testConsole.output == "")
    }
    
    /// Test the assignment of doubles (to symbols) in Basic.
    func testAssigningDoubles() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        let code = """
        I = .123
        J = 0.234
        K = 456.789
        PRINT I, " ", J, " ", K
        """
        try! parser.loadCode(fromString: code)
        try! parser.run()
        // print(testConsole.output)
        XCTAssert(testConsole.output == "0.123 0.234 456.789\n")
    }
    
    /// Test the assignment of strings (to symbols) in Basic.
    func testAssigningStrings() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let myName = "Zac"
        testConsole.inputBuffer = [myName]
        
        let code = """
        PRINT "What's your name?"
        INPUT A
        PRINT "Hello, ", A, "!"
        LET stringLiteral = "Welcome to SwiftBasicCore!"
        PRINT stringLiteral
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        print(testConsole.output)
        XCTAssert(testConsole.output == "What's your name?\nHello, \(myName)!\nWelcome to SwiftBasicCore!\n")
    }
    
    /// Tests the string operators (plus and multiply) in Basic.
    func testStringOperators() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let code = """
        string = "We like " + 2
        string += " eat "
        dessert = "🍪" * 5
        string += dessert
        print string + " ", 4.0 + " ever!"
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        XCTAssert(testConsole.output == "We like 2 eat 🍪🍪🍪🍪🍪 4.0 ever!\n")
        
        testConsole.handleClear()
        
        let code2 = """
        dessert = "🍪"
        dessert *= 5
        print dessert
        dessert = 5
        dessert *= "🎂"
        print dessert
        print "🧁" * 5
        """
        
        try! parser.loadCode(fromString: code2)
        try! parser.run()
        XCTAssert(testConsole.output == "🍪🍪🍪🍪🍪\n🎂🎂🎂🎂🎂\n🧁🧁🧁🧁🧁\n")
        
    }

    /// Tests the functionality of dictionaries.
    func testDictionary() {
        typealias Symbol = SymbolMap.Symbol
               
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let random = Int.random(in: 0...1)
        
        let code = """
        let symbol = \(random)
        b[0] = "Woah"
        b[1] = "These aren't quite arrays..."
        b["🎂"] = b[1]
        b["3 * 3"] = 3
        b["3 * 3"] *= 3
        b["3 * 3"] += 50
        b["3 * 3"] -= 50
        b["3 * 3"] /= 1
        b["3 * 3"] %= 10
        b["0"] = b
        b[symbol] = "🍪"
        print b
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        print(testConsole.output)
        
        let dict = parser.symbolMap.get(symbolNamed: "b")!.value as! SymbolMap.SymbolDictionary
        XCTAssert(try dict[Symbol(type: .integer, value: random)]!.asString() == "🍪")
        XCTAssert(dict[Symbol(type: .string, value: "3 * 3")]!.value as! Int == 9)
        
    }
    
    /// Tests the rand() function (to at least make sure it doesn't crashy).
    func testRand() {

        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let code = """
        print rand(0, 20)
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        
    }
    
    /// Tests acessing individual characters in a string using a numeric subscript.
    func testStringSubscript() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let code = """
        let string = "Swift🌀Basic"
        print string[0], string[1], string[2], string[3], string[4]
        print string[5]
        print string[6], string[7], string[8], string[9], string[10]
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        XCTAssert(testConsole.output == "Swift\n🌀\nBasic\n")
    }
    
    /// Tests the trigonometric functions.
    func testTrigFuncs() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let code = """
        print "sin(pi) = ", sin(pi)
        print "cos(pi) = ", cos(pi)
        print "tan(pi) = ", tan(pi)
        print "sec(pi) = ", sec(pi)
        print "csc(pi) = ", csc(pi)
        print "cot(pi) = ", cot(pi)
        print "cos(pi/2) = ", cos(pi/2)
        print "asin(1) = ", asin(1)
        print "acos(1) = ", acos(1)
        print "atan(1) = ", atan(1)
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        // print(testConsole.output)
    }
    
    /// Tests the bitwise operators.
    func testBitwise() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let a = Int.random(in: 32...256)
        let b = Int.random(in: 1...5)
        let c = Int.random(in: 1...5)
        
        let code = """
        let a = \(a)
        let b = \(b)
        let c = \(c)
        print a << b
        print a >> b
        print a >> c
        print a << c
        print b & c
        print b | c
        print b ^ c
        print b & b
        print b | b
        print b ^ b
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        
        XCTAssert(testConsole.output == "\(a << b)\n\(a >> b)\n\(a >> c)\n\(a << c)\n\(b & c)\n\(b | c)\n\(b ^ c)\n\(b & b)\n\(b | b)\n\(b ^ b)\n")
        
    }
    
    /// Tests dictionary literals.
    func testDictionaryLiteral() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let code = """
        print [0:"Wow"]
        b = [0:"Wow",1:"This",2:"is",3:"cool!"]
        print b[3]
        print []
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        XCTAssert(testConsole.output == "[0 = \"Wow\"]\ncool!\n[]\n")
    }
    
    /// Tests the size functions (count, length).
    func testSizeFunctions() {
        let parser = BasicParser()
        let testConsole = TestConsole()
        parser.delegate = testConsole
        
        let code = """
        let string = "This"
        print len(string)
        let dictionary = []
        print count(dictionary)
        dictionary["a"] = "b"
        print count(dictionary)
        """
        
        try! parser.loadCode(fromString: code)
        try! parser.run()
        print(testConsole.output)
        
        XCTAssert(testConsole.output == "4\n0\n1\n")
    }
    
}

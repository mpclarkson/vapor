extension String: ErrorProtocol {}

// MARK:

public protocol Validator {
    associatedtype InputType: Validatable
    func test(input value: InputType) -> Bool
}

public protocol ValidationSuite: Validator {
    associatedtype InputType: Validatable
    static func test(input value: InputType) -> Bool
}

extension ValidationSuite {
    public func test(input value: InputType) -> Bool {
        return self.dynamicType.test(input: value)
    }
}

// MARK: Validated

class ContainsEmoji: ValidationSuite {
    static func test(input value: String) -> Bool {
        return true
    }
}
class AlreadyTaken: ValidationSuite {
    static func test(input value: String) -> Bool {
        return true
    }
}
class OwnedBy: Validator {
    init(user: String) {}
    func test(input value: String) -> Bool {
        return true
    }
}

let user = ""

let available = !AlreadyTaken.self || OwnedBy(user: user)
let appropriateLength = StringLength.min(5) + StringLength.max(20)
let blename = try! "new name".validated(by: !ContainsEmoji.self + appropriateLength + available)

// MARK: And

public struct And<
    V: Validator,
    U: Validator where V.InputType == U.InputType> {
    private typealias Closure = (input: V.InputType) -> Bool
    private let _test: Closure

    /**
     CONVENIENCE ONLY.

     MUST STAY PRIVATE
     */
    private init(_ lhs: Closure, _ rhs: Closure) {
        _test = { value in
            return lhs(input: value) && rhs(input: value)
        }
    }
}

extension And {
    public init(_ lhs: V, _ rhs: U) {
        self.init(lhs.test, rhs.test)
    }
}

extension And: Validator {
    public func test(input value: V.InputType) -> Bool {
        return _test(input: value)
    }
}

extension And where V: ValidationSuite {
    public init(_ lhs: V.Type = V.self, _ rhs: U) {
        self.init(lhs.test, rhs.test)
    }
}

extension And where U: ValidationSuite {
    public init(_ lhs: V, _ rhs: U.Type = U.self) {
        self.init(lhs.test, rhs.test)
    }
}

extension And where V: ValidationSuite, U: ValidationSuite {
    public init(_ lhs: V.Type = V.self, _ rhs: U.Type = U.self) {
        self.init(lhs.test, rhs.test)
    }
}

// MARK: Or

public struct Or<
    V: Validator,
    U: Validator where V.InputType == U.InputType> {

    private typealias Closure = (input: V.InputType) -> Bool
    private let _test: Closure

    /**
     CONVENIENCE ONLY.
     
     MUST STAY PRIVATE
     */
    private init(_ lhs: Closure, _ rhs: Closure) {
        _test = { value in
            return lhs(input: value) || rhs(input: value)
        }
    }
}

extension Or: Validator {
    public func test(input value: V.InputType) -> Bool {
        return _test(input: value)
    }
}

extension Or {
    public init(_ lhs: V, _ rhs: U) {
        self.init(lhs.test, rhs.test)
    }
}

extension Or where V: ValidationSuite {
    public init(_ lhs: V.Type = V.self, _ rhs: U) {
        self.init(lhs.test, rhs.test)
    }
}

extension Or where U: ValidationSuite {
    public init(_ lhs: V, _ rhs: U.Type = U.self) {
        self.init(lhs.test, rhs.test)
    }
}

extension Or where V: ValidationSuite, U: ValidationSuite {
    public init(_ lhs: V.Type = V.self, _ rhs: U.Type = U.self) {
        self.init(lhs.test, rhs.test)
    }
}

// MARK: Not

public struct Not<V: Validator> {
    private typealias Closure = (input: V.InputType) -> Bool
    private let _test: Closure

    /**
     CONVENIENCE ONLY.

     MUST STAY PRIVATE
     */
    private init(_ v1: Closure) {
        _test = { value in !v1(input: value) }
    }
}

extension Not: Validator {
    public func test(input value: V.InputType) -> Bool {
        return _test(input: value)
    }
}

extension Not {
    public init(_ lhs: V) {
        self.init(lhs.test)
    }
}


extension Not where V: ValidationSuite {
    public init(_ lhs: V.Type = V.self) {
        self.init(lhs.test)
    }
}

// MARK: Composition
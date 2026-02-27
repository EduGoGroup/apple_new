import Testing
import Foundation
import Synchronization
@testable import FormsSDK

// MARK: - Test Helpers

actor FlagBox {
    private(set) var value = false
    func set() { value = true }
}

final class CounterBox: Sendable {
    private let storage = Mutex(0)
    var count: Int { storage.withLock { $0 } }
    func increment() { storage.withLock { $0 += 1 } }
}

// MARK: - ValidationResult Tests

@Suite struct ValidationResultTests {

    @Test func testValidResult() {
        let result = ValidationResult.valid()
        #expect(result.isValid)
        #expect(result.errorMessage == nil)
    }

    @Test func testInvalidResult() {
        let result = ValidationResult.invalid("Error message")
        #expect(!result.isValid)
        #expect(result.errorMessage == "Error message")
    }

    @Test func testEquatable() {
        let a = ValidationResult.valid()
        let b = ValidationResult.valid()
        #expect(a == b)

        let c = ValidationResult.invalid("err")
        let d = ValidationResult.invalid("err")
        #expect(c == d)

        #expect(a != c)
    }
}

// MARK: - Validators Tests

@Suite struct ValidatorsEmailTests {

    @Test func testValidEmail() {
        let validator = Validators.email()
        let result = validator("test@example.com")
        #expect(result.isValid)
    }

    @Test func testInvalidEmail() {
        let validator = Validators.email()
        let result = validator("not-an-email")
        #expect(!result.isValid)
    }

    @Test func testEmptyEmail() {
        let validator = Validators.email()
        let result = validator("")
        #expect(!result.isValid)
    }
}

@Suite struct ValidatorsPasswordTests {

    @Test func testValidPassword() {
        let validator = Validators.password(minLength: 8)
        let result = validator("password123")
        #expect(result.isValid)
    }

    @Test func testShortPassword() {
        let validator = Validators.password(minLength: 8)
        let result = validator("short")
        #expect(!result.isValid)
    }

    @Test func testEmptyPassword() {
        let validator = Validators.password()
        let result = validator("")
        #expect(!result.isValid)
    }

    @Test func testPasswordRequiresUppercase() {
        let validator = Validators.password(minLength: 8, requireUppercase: true)
        #expect(!validator("lowercase1").isValid)
        #expect(validator("Uppercase1").isValid)
    }

    @Test func testPasswordRequiresNumbers() {
        let validator = Validators.password(minLength: 8, requireNumbers: true)
        #expect(!validator("NoNumbers!").isValid)
        #expect(validator("HasNumber1").isValid)
    }

    @Test func testPasswordRequiresSymbols() {
        let validator = Validators.password(minLength: 8, requireSymbols: true)
        #expect(!validator("NoSymbols1").isValid)
        #expect(validator("Symbol1!!").isValid)
    }
}

@Suite struct ValidatorsStringTests {

    @Test func testNonEmpty() {
        let validator = Validators.nonEmpty(fieldName: "Name")
        #expect(validator("hello").isValid)
        #expect(!validator("").isValid)
        #expect(!validator("   ").isValid)
    }

    @Test func testMinLength() {
        let validator = Validators.minLength(5)
        #expect(validator("12345").isValid)
        #expect(!validator("1234").isValid)
    }

    @Test func testMaxLength() {
        let validator = Validators.maxLength(5)
        #expect(validator("12345").isValid)
        #expect(!validator("123456").isValid)
    }

    @Test func testPattern() {
        let validator = Validators.pattern("^[0-9]+$", errorMessage: "Only digits")
        #expect(validator("12345").isValid)
        #expect(!validator("abc").isValid)
    }
}

@Suite struct ValidatorsNumericTests {

    @Test func testRange() {
        let validator = Validators.range(1...10, fieldName: "Age")
        #expect(validator(5).isValid)
        #expect(!validator(0).isValid)
        #expect(!validator(11).isValid)
    }

    @Test func testMin() {
        let validator = Validators.min(0, fieldName: "Score")
        #expect(validator(0).isValid)
        #expect(validator(100).isValid)
        #expect(!validator(-1).isValid)
    }

    @Test func testMax() {
        let validator = Validators.max(100, fieldName: "Score")
        #expect(validator(100).isValid)
        #expect(!validator(101).isValid)
    }
}

@Suite struct ValidatorsCompositionTests {

    @Test func testAllPassesWhenAllValid() {
        let validator = Validators.all([
            Validators.nonEmpty(),
            Validators.minLength(3)
        ])
        #expect(validator("hello").isValid)
    }

    @Test func testAllFailsOnFirstInvalid() {
        let validator = Validators.all([
            Validators.nonEmpty(),
            Validators.minLength(10)
        ])
        let result = validator("hi")
        #expect(!result.isValid)
    }

    @Test func testWhenConditionTrue() {
        let validator = Validators.when(
            { (s: String) in !s.isEmpty },
            then: Validators.minLength(5)
        )
        #expect(!validator("hi").isValid)
        #expect(validator("hello").isValid)
    }

    @Test func testWhenConditionFalse() {
        let validator = Validators.when(
            { (s: String) in !s.isEmpty },
            then: Validators.minLength(5)
        )
        #expect(validator("").isValid)
    }
}

// MARK: - CrossValidators Tests

@Suite struct CrossValidatorsTests {

    @Test func testPasswordMatch() {
        #expect(CrossValidators.passwordMatch("abc", "abc").isValid)
        #expect(!CrossValidators.passwordMatch("abc", "def").isValid)
    }

    @Test func testDateRange() {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        #expect(CrossValidators.dateRange(start: now, end: later).isValid)
        #expect(!CrossValidators.dateRange(start: later, end: now).isValid)
        #expect(!CrossValidators.dateRange(start: nil, end: nil).isValid)
    }

    @Test func testOptionalDateRange() {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        #expect(CrossValidators.optionalDateRange(start: nil, end: nil).isValid)
        #expect(CrossValidators.optionalDateRange(start: now, end: later).isValid)
        #expect(!CrossValidators.optionalDateRange(start: now, end: nil).isValid)
        #expect(!CrossValidators.optionalDateRange(start: later, end: now).isValid)
    }

    @Test func testNotInPast() {
        let future = Date().addingTimeInterval(86400 * 2)
        #expect(CrossValidators.notInPast(future).isValid)

        let past = Date().addingTimeInterval(-86400 * 2)
        #expect(!CrossValidators.notInPast(past).isValid)

        #expect(!CrossValidators.notInPast(nil).isValid)
    }

    @Test func testAtLeastOneSelectedSet() {
        #expect(CrossValidators.atLeastOneSelected(Set(["a"])).isValid)
        #expect(!CrossValidators.atLeastOneSelected(Set<String>()).isValid)
    }

    @Test func testAtLeastOneSelectedArray() {
        #expect(CrossValidators.atLeastOneSelected(["a"]).isValid)
        #expect(!CrossValidators.atLeastOneSelected([String]()).isValid)
    }

    @Test func testExactCount() {
        #expect(CrossValidators.exactCount([1, 2, 3], count: 3).isValid)
        #expect(!CrossValidators.exactCount([1, 2], count: 3).isValid)
    }

    @Test func testCountInRange() {
        #expect(CrossValidators.countInRange([1, 2], range: 1...3).isValid)
        #expect(!CrossValidators.countInRange([Int](), range: 1...3).isValid)
    }

    @Test func testConditionalRequired() {
        #expect(CrossValidators.conditionalRequired(condition: true, value: "val", fieldName: "F").isValid)
        #expect(!CrossValidators.conditionalRequired(condition: true, value: "", fieldName: "F").isValid)
        #expect(CrossValidators.conditionalRequired(condition: false, value: "", fieldName: "F").isValid)
    }

    @Test func testRequiredWhenPresent() {
        #expect(!CrossValidators.requiredWhenPresent(dependsOn: "val", value: "", fieldName: "F").isValid)
        #expect(CrossValidators.requiredWhenPresent(dependsOn: "val", value: "ok", fieldName: "F").isValid)
        #expect(CrossValidators.requiredWhenPresent(dependsOn: "", value: "", fieldName: "F").isValid)
    }

    @Test func testEqual() {
        #expect(CrossValidators.equal(1, 1, errorMessage: "err").isValid)
        #expect(!CrossValidators.equal(1, 2, errorMessage: "err").isValid)
    }

    @Test func testNotEqual() {
        #expect(CrossValidators.notEqual(1, 2, errorMessage: "err").isValid)
        #expect(!CrossValidators.notEqual(1, 1, errorMessage: "err").isValid)
    }

    @Test func testLessThan() {
        #expect(CrossValidators.lessThan(5, 10).isValid)
        #expect(!CrossValidators.lessThan(10, 10).isValid)
    }

    @Test func testGreaterThan() {
        #expect(CrossValidators.greaterThan(10, 5).isValid)
        #expect(!CrossValidators.greaterThan(5, 5).isValid)
    }

    @Test func testAllComposition() {
        let result = CrossValidators.all([
            { CrossValidators.passwordMatch("a", "a") },
            { CrossValidators.equal(1, 1, errorMessage: "err") }
        ])
        #expect(result.isValid)
    }

    @Test func testAllCollectingErrors() {
        let result = CrossValidators.allCollectingErrors([
            { CrossValidators.passwordMatch("a", "b") },
            { CrossValidators.equal(1, 2, errorMessage: "not equal") }
        ])
        #expect(!result.isValid)
        #expect(result.errorMessage?.contains("no coinciden") ?? false)
        #expect(result.errorMessage?.contains("not equal") ?? false)
    }
}

// MARK: - FormState Tests

@MainActor @Suite struct FormStateTests {

    @Test func testInitialState() {
        let state = FormState()
        #expect(!state.isValid)
        #expect(!state.isSubmitting)
        #expect(state.errors.isEmpty)
    }

    @Test func testRegisterAndValidateField() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("Required")
        }
        state.validate()
        #expect(!state.isValid)
        #expect(state.error(for: "name") == "Required")
    }

    @Test func testValidatePassesWhenAllValid() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.valid()
        }
        state.validate()
        #expect(state.isValid)
    }

    @Test func testUnregisterField() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("err")
        }
        state.unregisterField("name")
        state.validate()
        #expect(state.isValid)
    }

    @Test func testCrossValidator() {
        let state = FormState()
        state.registerCrossValidator {
            ValidationResult.invalid("Cross error")
        }
        state.validate()
        #expect(!state.isValid)
        #expect(state.error(for: "form") == "Cross error")
    }

    @Test func testClearCrossValidators() {
        let state = FormState()
        state.registerCrossValidator {
            ValidationResult.invalid("err")
        }
        state.clearCrossValidators()
        state.validate()
        #expect(state.isValid)
    }

    @Test func testValidateField() {
        let state = FormState()
        state.registerField("email") {
            ValidationResult.invalid("Bad email")
        }
        let result = state.validateField("email")
        #expect(!result.isValid)
        #expect(state.error(for: "email") == "Bad email")
    }

    @Test func testValidateFieldUnregistered() {
        let state = FormState()
        let result = state.validateField("unknown")
        #expect(result.isValid)
    }

    @Test func testClearError() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("err")
        }
        state.validate()
        #expect(state.error(for: "name") != nil)
        state.clearError(for: "name")
        #expect(state.error(for: "name") == nil)
    }

    @Test func testReset() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("err")
        }
        state.validate()
        state.reset()
        #expect(!state.isValid)
        #expect(!state.isSubmitting)
        #expect(state.errors.isEmpty)
    }

    @Test func testSubmitValid() async {
        let state = FormState()
        state.registerField("ok") {
            ValidationResult.valid()
        }
        let flag = FlagBox()
        let result = await state.submit {
            await flag.set()
        }
        #expect(result)
        let wasExecuted = await flag.value
        #expect(wasExecuted)
    }

    @Test func testSubmitInvalid() async {
        let state = FormState()
        state.registerField("bad") {
            ValidationResult.invalid("err")
        }
        let flag = FlagBox()
        let result = await state.submit {
            await flag.set()
        }
        #expect(!result)
        let wasExecuted = await flag.value
        #expect(!wasExecuted)
    }

    @Test func testSubmitCatchesError() async {
        let state = FormState()
        state.registerField("ok") {
            ValidationResult.valid()
        }
        let result = await state.submit {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fail"])
        }
        #expect(!result)
        #expect(state.error(for: "form") != nil)
    }
}

// MARK: - BindableProperty Tests

@MainActor @Suite struct BindablePropertyTests {

    @Test func testInitialValue() {
        @BindableProperty var name: String = "hello"
        #expect(name == "hello")
    }

    @Test func testSetValue() {
        @BindableProperty var name: String = ""
        name = "world"
        #expect(name == "world")
    }

    @Test func testValidationOnSet() {
        @BindableProperty(validation: Validators.nonEmpty(fieldName: "Name"))
        var name: String = ""

        name = ""
        #expect(!$name.validationState.isValid)

        name = "hello"
        #expect($name.validationState.isValid)
    }

    @Test func testResetValidation() {
        @BindableProperty(validation: Validators.nonEmpty())
        var name: String = ""

        name = ""
        #expect(!$name.validationState.isValid)

        $name.resetValidation()
        #expect($name.validationState.isValid)
        #expect($name.validationState.errorMessage == nil)
    }

    @Test func testManualValidate() {
        var prop = BindableProperty(wrappedValue: "", validation: Validators.nonEmpty())

        // Initially valid (no validation run yet)
        #expect(prop.validationState.isValid)

        prop.validate()
        #expect(!prop.validationState.isValid)
    }

    @Test func testOnChange() {
        let counter = CounterBox()
        @BindableProperty(onChange: { @Sendable _ in counter.increment() })
        var name: String = ""

        name = "a"
        name = "b"
        #expect(counter.count == 2)
    }
}

// MARK: - DebouncedProperty Tests

@MainActor @Suite struct DebouncedPropertyTests {

    @Test func testInitialValue() {
        @DebouncedProperty(debounceInterval: 0.1) var query: String = "initial"
        #expect(query == "initial")
    }

    @Test func testSetValue() {
        @DebouncedProperty(debounceInterval: 0.1) var query: String = ""
        query = "test"
        #expect(query == "test")
    }

    @Test func testDefaultInterval() {
        @DebouncedProperty var query: String = "default"
        #expect(query == "default")
    }
}

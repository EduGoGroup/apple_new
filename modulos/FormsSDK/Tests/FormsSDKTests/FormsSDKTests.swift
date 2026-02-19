import XCTest
@testable import FormsSDK

// MARK: - Test Helpers

actor FlagBox {
    private(set) var value = false
    func set() { value = true }
}

final class CounterBox: @unchecked Sendable {
    private(set) var count = 0
    func increment() { count += 1 }
}

// MARK: - ValidationResult Tests

final class ValidationResultTests: XCTestCase {

    func testValidResult() {
        let result = ValidationResult.valid()
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testInvalidResult() {
        let result = ValidationResult.invalid("Error message")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Error message")
    }

    func testEquatable() {
        let a = ValidationResult.valid()
        let b = ValidationResult.valid()
        XCTAssertEqual(a, b)

        let c = ValidationResult.invalid("err")
        let d = ValidationResult.invalid("err")
        XCTAssertEqual(c, d)

        XCTAssertNotEqual(a, c)
    }
}

// MARK: - Validators Tests

final class ValidatorsEmailTests: XCTestCase {

    func testValidEmail() {
        let validator = Validators.email()
        let result = validator("test@example.com")
        XCTAssertTrue(result.isValid)
    }

    func testInvalidEmail() {
        let validator = Validators.email()
        let result = validator("not-an-email")
        XCTAssertFalse(result.isValid)
    }

    func testEmptyEmail() {
        let validator = Validators.email()
        let result = validator("")
        XCTAssertFalse(result.isValid)
    }
}

final class ValidatorsPasswordTests: XCTestCase {

    func testValidPassword() {
        let validator = Validators.password(minLength: 8)
        let result = validator("password123")
        XCTAssertTrue(result.isValid)
    }

    func testShortPassword() {
        let validator = Validators.password(minLength: 8)
        let result = validator("short")
        XCTAssertFalse(result.isValid)
    }

    func testEmptyPassword() {
        let validator = Validators.password()
        let result = validator("")
        XCTAssertFalse(result.isValid)
    }

    func testPasswordRequiresUppercase() {
        let validator = Validators.password(minLength: 8, requireUppercase: true)
        XCTAssertFalse(validator("lowercase1").isValid)
        XCTAssertTrue(validator("Uppercase1").isValid)
    }

    func testPasswordRequiresNumbers() {
        let validator = Validators.password(minLength: 8, requireNumbers: true)
        XCTAssertFalse(validator("NoNumbers!").isValid)
        XCTAssertTrue(validator("HasNumber1").isValid)
    }

    func testPasswordRequiresSymbols() {
        let validator = Validators.password(minLength: 8, requireSymbols: true)
        XCTAssertFalse(validator("NoSymbols1").isValid)
        XCTAssertTrue(validator("Symbol1!!").isValid)
    }
}

final class ValidatorsStringTests: XCTestCase {

    func testNonEmpty() {
        let validator = Validators.nonEmpty(fieldName: "Name")
        XCTAssertTrue(validator("hello").isValid)
        XCTAssertFalse(validator("").isValid)
        XCTAssertFalse(validator("   ").isValid)
    }

    func testMinLength() {
        let validator = Validators.minLength(5)
        XCTAssertTrue(validator("12345").isValid)
        XCTAssertFalse(validator("1234").isValid)
    }

    func testMaxLength() {
        let validator = Validators.maxLength(5)
        XCTAssertTrue(validator("12345").isValid)
        XCTAssertFalse(validator("123456").isValid)
    }

    func testPattern() {
        let validator = Validators.pattern("^[0-9]+$", errorMessage: "Only digits")
        XCTAssertTrue(validator("12345").isValid)
        XCTAssertFalse(validator("abc").isValid)
    }
}

final class ValidatorsNumericTests: XCTestCase {

    func testRange() {
        let validator = Validators.range(1...10, fieldName: "Age")
        XCTAssertTrue(validator(5).isValid)
        XCTAssertFalse(validator(0).isValid)
        XCTAssertFalse(validator(11).isValid)
    }

    func testMin() {
        let validator = Validators.min(0, fieldName: "Score")
        XCTAssertTrue(validator(0).isValid)
        XCTAssertTrue(validator(100).isValid)
        XCTAssertFalse(validator(-1).isValid)
    }

    func testMax() {
        let validator = Validators.max(100, fieldName: "Score")
        XCTAssertTrue(validator(100).isValid)
        XCTAssertFalse(validator(101).isValid)
    }
}

final class ValidatorsCompositionTests: XCTestCase {

    func testAllPassesWhenAllValid() {
        let validator = Validators.all([
            Validators.nonEmpty(),
            Validators.minLength(3)
        ])
        XCTAssertTrue(validator("hello").isValid)
    }

    func testAllFailsOnFirstInvalid() {
        let validator = Validators.all([
            Validators.nonEmpty(),
            Validators.minLength(10)
        ])
        let result = validator("hi")
        XCTAssertFalse(result.isValid)
    }

    func testWhenConditionTrue() {
        let validator = Validators.when(
            { (s: String) in !s.isEmpty },
            then: Validators.minLength(5)
        )
        XCTAssertFalse(validator("hi").isValid)
        XCTAssertTrue(validator("hello").isValid)
    }

    func testWhenConditionFalse() {
        let validator = Validators.when(
            { (s: String) in !s.isEmpty },
            then: Validators.minLength(5)
        )
        XCTAssertTrue(validator("").isValid)
    }
}

// MARK: - CrossValidators Tests

final class CrossValidatorsTests: XCTestCase {

    func testPasswordMatch() {
        XCTAssertTrue(CrossValidators.passwordMatch("abc", "abc").isValid)
        XCTAssertFalse(CrossValidators.passwordMatch("abc", "def").isValid)
    }

    func testDateRange() {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        XCTAssertTrue(CrossValidators.dateRange(start: now, end: later).isValid)
        XCTAssertFalse(CrossValidators.dateRange(start: later, end: now).isValid)
        XCTAssertFalse(CrossValidators.dateRange(start: nil, end: nil).isValid)
    }

    func testOptionalDateRange() {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        XCTAssertTrue(CrossValidators.optionalDateRange(start: nil, end: nil).isValid)
        XCTAssertTrue(CrossValidators.optionalDateRange(start: now, end: later).isValid)
        XCTAssertFalse(CrossValidators.optionalDateRange(start: now, end: nil).isValid)
        XCTAssertFalse(CrossValidators.optionalDateRange(start: later, end: now).isValid)
    }

    func testNotInPast() {
        let future = Date().addingTimeInterval(86400 * 2)
        XCTAssertTrue(CrossValidators.notInPast(future).isValid)

        let past = Date().addingTimeInterval(-86400 * 2)
        XCTAssertFalse(CrossValidators.notInPast(past).isValid)

        XCTAssertFalse(CrossValidators.notInPast(nil).isValid)
    }

    func testAtLeastOneSelectedSet() {
        XCTAssertTrue(CrossValidators.atLeastOneSelected(Set(["a"])).isValid)
        XCTAssertFalse(CrossValidators.atLeastOneSelected(Set<String>()).isValid)
    }

    func testAtLeastOneSelectedArray() {
        XCTAssertTrue(CrossValidators.atLeastOneSelected(["a"]).isValid)
        XCTAssertFalse(CrossValidators.atLeastOneSelected([String]()).isValid)
    }

    func testExactCount() {
        XCTAssertTrue(CrossValidators.exactCount([1, 2, 3], count: 3).isValid)
        XCTAssertFalse(CrossValidators.exactCount([1, 2], count: 3).isValid)
    }

    func testCountInRange() {
        XCTAssertTrue(CrossValidators.countInRange([1, 2], range: 1...3).isValid)
        XCTAssertFalse(CrossValidators.countInRange([Int](), range: 1...3).isValid)
    }

    func testConditionalRequired() {
        XCTAssertTrue(CrossValidators.conditionalRequired(condition: true, value: "val", fieldName: "F").isValid)
        XCTAssertFalse(CrossValidators.conditionalRequired(condition: true, value: "", fieldName: "F").isValid)
        XCTAssertTrue(CrossValidators.conditionalRequired(condition: false, value: "", fieldName: "F").isValid)
    }

    func testRequiredWhenPresent() {
        XCTAssertFalse(CrossValidators.requiredWhenPresent(dependsOn: "val", value: "", fieldName: "F").isValid)
        XCTAssertTrue(CrossValidators.requiredWhenPresent(dependsOn: "val", value: "ok", fieldName: "F").isValid)
        XCTAssertTrue(CrossValidators.requiredWhenPresent(dependsOn: "", value: "", fieldName: "F").isValid)
    }

    func testEqual() {
        XCTAssertTrue(CrossValidators.equal(1, 1, errorMessage: "err").isValid)
        XCTAssertFalse(CrossValidators.equal(1, 2, errorMessage: "err").isValid)
    }

    func testNotEqual() {
        XCTAssertTrue(CrossValidators.notEqual(1, 2, errorMessage: "err").isValid)
        XCTAssertFalse(CrossValidators.notEqual(1, 1, errorMessage: "err").isValid)
    }

    func testLessThan() {
        XCTAssertTrue(CrossValidators.lessThan(5, 10).isValid)
        XCTAssertFalse(CrossValidators.lessThan(10, 10).isValid)
    }

    func testGreaterThan() {
        XCTAssertTrue(CrossValidators.greaterThan(10, 5).isValid)
        XCTAssertFalse(CrossValidators.greaterThan(5, 5).isValid)
    }

    func testAllComposition() {
        let result = CrossValidators.all([
            { CrossValidators.passwordMatch("a", "a") },
            { CrossValidators.equal(1, 1, errorMessage: "err") }
        ])
        XCTAssertTrue(result.isValid)
    }

    func testAllCollectingErrors() {
        let result = CrossValidators.allCollectingErrors([
            { CrossValidators.passwordMatch("a", "b") },
            { CrossValidators.equal(1, 2, errorMessage: "not equal") }
        ])
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("no coinciden") ?? false)
        XCTAssertTrue(result.errorMessage?.contains("not equal") ?? false)
    }
}

// MARK: - FormState Tests

@MainActor
final class FormStateTests: XCTestCase {

    func testInitialState() {
        let state = FormState()
        XCTAssertFalse(state.isValid)
        XCTAssertFalse(state.isSubmitting)
        XCTAssertTrue(state.errors.isEmpty)
    }

    func testRegisterAndValidateField() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("Required")
        }
        state.validate()
        XCTAssertFalse(state.isValid)
        XCTAssertEqual(state.error(for: "name"), "Required")
    }

    func testValidatePassesWhenAllValid() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.valid()
        }
        state.validate()
        XCTAssertTrue(state.isValid)
    }

    func testUnregisterField() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("err")
        }
        state.unregisterField("name")
        state.validate()
        XCTAssertTrue(state.isValid)
    }

    func testCrossValidator() {
        let state = FormState()
        state.registerCrossValidator {
            ValidationResult.invalid("Cross error")
        }
        state.validate()
        XCTAssertFalse(state.isValid)
        XCTAssertEqual(state.error(for: "form"), "Cross error")
    }

    func testClearCrossValidators() {
        let state = FormState()
        state.registerCrossValidator {
            ValidationResult.invalid("err")
        }
        state.clearCrossValidators()
        state.validate()
        XCTAssertTrue(state.isValid)
    }

    func testValidateField() {
        let state = FormState()
        state.registerField("email") {
            ValidationResult.invalid("Bad email")
        }
        let result = state.validateField("email")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(state.error(for: "email"), "Bad email")
    }

    func testValidateFieldUnregistered() {
        let state = FormState()
        let result = state.validateField("unknown")
        XCTAssertTrue(result.isValid)
    }

    func testClearError() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("err")
        }
        state.validate()
        XCTAssertNotNil(state.error(for: "name"))
        state.clearError(for: "name")
        XCTAssertNil(state.error(for: "name"))
    }

    func testReset() {
        let state = FormState()
        state.registerField("name") {
            ValidationResult.invalid("err")
        }
        state.validate()
        state.reset()
        XCTAssertFalse(state.isValid)
        XCTAssertFalse(state.isSubmitting)
        XCTAssertTrue(state.errors.isEmpty)
    }

    func testSubmitValid() async {
        let state = FormState()
        state.registerField("ok") {
            ValidationResult.valid()
        }
        let flag = FlagBox()
        let result = await state.submit {
            await flag.set()
        }
        XCTAssertTrue(result)
        let wasExecuted = await flag.value
        XCTAssertTrue(wasExecuted)
    }

    func testSubmitInvalid() async {
        let state = FormState()
        state.registerField("bad") {
            ValidationResult.invalid("err")
        }
        let flag = FlagBox()
        let result = await state.submit {
            await flag.set()
        }
        XCTAssertFalse(result)
        let wasExecuted = await flag.value
        XCTAssertFalse(wasExecuted)
    }

    func testSubmitCatchesError() async {
        let state = FormState()
        state.registerField("ok") {
            ValidationResult.valid()
        }
        let result = await state.submit {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fail"])
        }
        XCTAssertFalse(result)
        XCTAssertNotNil(state.error(for: "form"))
    }
}

// MARK: - BindableProperty Tests

@MainActor
final class BindablePropertyTests: XCTestCase {

    func testInitialValue() {
        @BindableProperty var name: String = "hello"
        XCTAssertEqual(name, "hello")
    }

    func testSetValue() {
        @BindableProperty var name: String = ""
        name = "world"
        XCTAssertEqual(name, "world")
    }

    func testValidationOnSet() {
        @BindableProperty(validation: Validators.nonEmpty(fieldName: "Name"))
        var name: String = ""

        name = ""
        XCTAssertFalse($name.validationState.isValid)

        name = "hello"
        XCTAssertTrue($name.validationState.isValid)
    }

    func testResetValidation() {
        @BindableProperty(validation: Validators.nonEmpty())
        var name: String = ""

        name = ""
        XCTAssertFalse($name.validationState.isValid)

        $name.resetValidation()
        XCTAssertTrue($name.validationState.isValid)
        XCTAssertNil($name.validationState.errorMessage)
    }

    func testManualValidate() {
        var prop = BindableProperty(wrappedValue: "", validation: Validators.nonEmpty())

        // Initially valid (no validation run yet)
        XCTAssertTrue(prop.validationState.isValid)

        prop.validate()
        XCTAssertFalse(prop.validationState.isValid)
    }

    func testOnChange() {
        let counter = CounterBox()
        @BindableProperty(onChange: { @Sendable _ in counter.increment() })
        var name: String = ""

        name = "a"
        name = "b"
        XCTAssertEqual(counter.count, 2)
    }
}

// MARK: - DebouncedProperty Tests

@MainActor
final class DebouncedPropertyTests: XCTestCase {

    func testInitialValue() {
        @DebouncedProperty(debounceInterval: 0.1) var query: String = "initial"
        XCTAssertEqual(query, "initial")
    }

    func testSetValue() {
        @DebouncedProperty(debounceInterval: 0.1) var query: String = ""
        query = "test"
        XCTAssertEqual(query, "test")
    }

    func testDefaultInterval() {
        @DebouncedProperty var query: String = "default"
        XCTAssertEqual(query, "default")
    }
}

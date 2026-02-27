import Testing
import EduModels
@testable import EduDynamicUI

@Suite("FieldMapper Tests")
struct FieldMapperTests {
    let mapper = FieldMapper()

    @Test("Returns original data when fieldMapping is nil")
    func noMapping() {
        let data: [String: JSONValue] = [
            "name": .string("School A"),
            "code": .string("SCH-001")
        ]

        let result = mapper.map(data: data, fieldMapping: nil)

        #expect(result["name"] == .string("School A"))
        #expect(result["code"] == .string("SCH-001"))
        #expect(result.count == 2)
    }

    @Test("Maps API fields to template fields")
    func basicMapping() {
        let data: [String: JSONValue] = [
            "full_name": .string("School A"),
            "code": .string("SCH-001"),
            "student_count": .integer(150)
        ]

        let mapping = [
            "full_name": "title",
            "code": "subtitle"
        ]

        let result = mapper.map(data: data, fieldMapping: mapping)

        #expect(result["title"] == .string("School A"))
        #expect(result["subtitle"] == .string("SCH-001"))
        #expect(result["full_name"] == .string("School A"))
        #expect(result["code"] == .string("SCH-001"))
        #expect(result["student_count"] == .integer(150))
    }

    @Test("Preserves original keys alongside mapped keys")
    func preservesOriginalKeys() {
        let data: [String: JSONValue] = [
            "api_field": .string("value")
        ]

        let mapping = ["api_field": "template_field"]
        let result = mapper.map(data: data, fieldMapping: mapping)

        #expect(result["api_field"] == .string("value"))
        #expect(result["template_field"] == .string("value"))
    }

    @Test("Ignores mapping entries for missing API fields")
    func missingApiField() {
        let data: [String: JSONValue] = [
            "name": .string("Test")
        ]

        let mapping = [
            "name": "title",
            "missing_field": "subtitle"
        ]

        let result = mapper.map(data: data, fieldMapping: mapping)

        #expect(result["title"] == .string("Test"))
        #expect(result["subtitle"] == nil)
    }

    @Test("Handles empty mapping dictionary")
    func emptyMapping() {
        let data: [String: JSONValue] = [
            "name": .string("Test")
        ]

        let result = mapper.map(data: data, fieldMapping: [:])

        #expect(result.count == 1)
        #expect(result["name"] == .string("Test"))
    }

    @Test("Handles empty data dictionary")
    func emptyData() {
        let mapping = ["field": "mapped"]
        let result = mapper.map(data: [:], fieldMapping: mapping)

        #expect(result.isEmpty)
    }

    @Test("Maps all JSONValue types correctly")
    func allValueTypes() {
        let data: [String: JSONValue] = [
            "str": .string("hello"),
            "num": .integer(42),
            "dbl": .double(3.14),
            "flag": .bool(true),
            "nil_val": .null
        ]

        let mapping = [
            "str": "mapped_str",
            "num": "mapped_num",
            "dbl": "mapped_dbl",
            "flag": "mapped_flag",
            "nil_val": "mapped_nil"
        ]

        let result = mapper.map(data: data, fieldMapping: mapping)

        #expect(result["mapped_str"] == .string("hello"))
        #expect(result["mapped_num"] == .integer(42))
        #expect(result["mapped_dbl"] == .double(3.14))
        #expect(result["mapped_flag"] == .bool(true))
        #expect(result["mapped_nil"] == .null)
    }

    @Test("Maps array of items")
    func mapItems() {
        let items: [[String: JSONValue]] = [
            ["full_name": .string("School A"), "code": .string("A")],
            ["full_name": .string("School B"), "code": .string("B")]
        ]

        let mapping = ["full_name": "title"]
        let result = mapper.mapItems(items: items, fieldMapping: mapping)

        #expect(result.count == 2)
        #expect(result[0]["title"] == .string("School A"))
        #expect(result[1]["title"] == .string("School B"))
        #expect(result[0]["full_name"] == .string("School A"))
    }

    @Test("Returns original items when mapping is nil")
    func mapItemsNoMapping() {
        let items: [[String: JSONValue]] = [
            ["name": .string("Test")]
        ]

        let result = mapper.mapItems(items: items, fieldMapping: nil)

        #expect(result.count == 1)
        #expect(result[0]["name"] == .string("Test"))
    }

    @Test("Creates reverse mapping")
    func reverseMapping() {
        let mapping = [
            "full_name": "title",
            "code": "subtitle"
        ]

        let reversed = FieldMapper.reverseMapping(mapping)

        #expect(reversed["title"] == "full_name")
        #expect(reversed["subtitle"] == "code")
    }
}

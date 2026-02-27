// IconMapperTests.swift
// EduPresentationTests

import Testing
@testable import EduPresentation

@Suite("IconMapper Tests")
struct IconMapperTests {

    @Test("Maps known Material Icons to SF Symbols correctly")
    func mapsKnownIcons() {
        #expect(IconMapper.sfSymbol(from: "home") == "house.fill")
        #expect(IconMapper.sfSymbol(from: "school") == "building.columns.fill")
        #expect(IconMapper.sfSymbol(from: "people") == "person.2.fill")
        #expect(IconMapper.sfSymbol(from: "person") == "person.fill")
        #expect(IconMapper.sfSymbol(from: "settings") == "gearshape.fill")
        #expect(IconMapper.sfSymbol(from: "assessment") == "checkmark.circle.fill")
        #expect(IconMapper.sfSymbol(from: "book") == "book.fill")
        #expect(IconMapper.sfSymbol(from: "folder") == "folder.fill")
        #expect(IconMapper.sfSymbol(from: "dashboard") == "chart.bar.fill")
        #expect(IconMapper.sfSymbol(from: "menu_book") == "text.book.closed.fill")
        #expect(IconMapper.sfSymbol(from: "assignment") == "doc.text.fill")
        #expect(IconMapper.sfSymbol(from: "group") == "person.3.fill")
        #expect(IconMapper.sfSymbol(from: "admin_panel_settings") == "wrench.and.screwdriver.fill")
        #expect(IconMapper.sfSymbol(from: "security") == "lock.shield.fill")
        #expect(IconMapper.sfSymbol(from: "supervisor_account") == "person.badge.shield.checkmark.fill")
    }

    @Test("Returns fallback for unknown icons")
    func returnsFallbackForUnknown() {
        #expect(IconMapper.sfSymbol(from: "unknown_icon") == "questionmark.circle")
        #expect(IconMapper.sfSymbol(from: "") == "questionmark.circle")
        #expect(IconMapper.sfSymbol(from: "nonexistent") == "questionmark.circle")
    }
}

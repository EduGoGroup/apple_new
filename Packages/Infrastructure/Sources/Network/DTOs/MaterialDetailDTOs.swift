import Foundation

// MARK: - MaterialSummaryDTO

/// DTO for the AI-generated summary of a material.
///
/// Maps to the backend response from `GET /v1/materials/{id}/summary`.
public struct MaterialSummaryDTO: Codable, Sendable, Equatable {
    /// AI-generated summary text.
    public let summary: String

    /// Key points extracted from the material.
    public let keyPoints: [String]

    /// Detected language of the material content.
    public let language: String

    /// Approximate word count of the original material.
    public let wordCount: Int

    enum CodingKeys: String, CodingKey {
        case summary, language
        case keyPoints = "key_points"
        case wordCount = "word_count"
    }

    public init(
        summary: String,
        keyPoints: [String],
        language: String,
        wordCount: Int
    ) {
        self.summary = summary
        self.keyPoints = keyPoints
        self.language = language
        self.wordCount = wordCount
    }
}

// MARK: - MaterialSectionsDTO

/// DTO for the extracted sections of a material.
///
/// Maps to the backend response from `GET /v1/materials/{id}/sections`.
public struct MaterialSectionsDTO: Codable, Sendable, Equatable {
    /// Array of sections extracted from the material.
    public let sections: [SectionDTO]

    public init(sections: [SectionDTO]) {
        self.sections = sections
    }
}

// MARK: - SectionDTO

/// DTO representing a single section extracted from a material.
public struct SectionDTO: Codable, Sendable, Equatable, Identifiable {
    /// Section index (1-based).
    public let index: Int

    /// Section title.
    public let title: String

    /// Short preview of the section content.
    public let preview: String

    public var id: Int { index }

    public init(index: Int, title: String, preview: String) {
        self.index = index
        self.title = title
        self.preview = preview
    }
}

// MARK: - PresignedURLDTO

/// DTO for a presigned download URL.
///
/// Maps to the backend response from `GET /v1/materials/{id}/download-url`.
public struct PresignedURLDTO: Codable, Sendable, Equatable {
    /// The presigned URL string.
    public let url: String

    /// Expiration timestamp in ISO 8601 format.
    public let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case url
        case expiresAt = "expires_at"
    }

    public init(url: String, expiresAt: String) {
        self.url = url
        self.expiresAt = expiresAt
    }
}

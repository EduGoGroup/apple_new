import Testing
@testable import EduPresentation

@Suite("Pattern-Specific Skeleton Loaders")
struct SkeletonTests {

    // MARK: - EduListSkeleton

    @Test("EduListSkeleton initializes with default row count")
    @MainActor
    func listSkeletonDefault() {
        let skeleton = EduListSkeleton()
        #expect(skeleton != nil)
    }

    @Test("EduListSkeleton initializes with custom row count")
    @MainActor
    func listSkeletonCustom() {
        let skeleton = EduListSkeleton(rowCount: 3)
        #expect(skeleton != nil)
    }

    // MARK: - EduFormSkeleton

    @Test("EduFormSkeleton initializes with default field count")
    @MainActor
    func formSkeletonDefault() {
        let skeleton = EduFormSkeleton()
        #expect(skeleton != nil)
    }

    @Test("EduFormSkeleton initializes with custom field count")
    @MainActor
    func formSkeletonCustom() {
        let skeleton = EduFormSkeleton(fieldCount: 3)
        #expect(skeleton != nil)
    }

    // MARK: - EduDashboardSkeleton

    @Test("EduDashboardSkeleton initializes with default params")
    @MainActor
    func dashboardSkeletonDefault() {
        let skeleton = EduDashboardSkeleton()
        #expect(skeleton != nil)
    }

    @Test("EduDashboardSkeleton initializes with 3 columns")
    @MainActor
    func dashboardSkeletonThreeColumns() {
        let skeleton = EduDashboardSkeleton(cardCount: 6, columns: 3)
        #expect(skeleton != nil)
    }

    // MARK: - EduDetailSkeleton

    @Test("EduDetailSkeleton initializes with default row count")
    @MainActor
    func detailSkeletonDefault() {
        let skeleton = EduDetailSkeleton()
        #expect(skeleton != nil)
    }

    @Test("EduDetailSkeleton initializes with custom row count")
    @MainActor
    func detailSkeletonCustom() {
        let skeleton = EduDetailSkeleton(rowCount: 3)
        #expect(skeleton != nil)
    }

    // MARK: - Existing Skeleton Components

    @Test("EduSkeletonLoader initializes with different shapes")
    @MainActor
    func skeletonLoaderShapes() {
        let rectangle = EduSkeletonLoader(shape: .rectangle)
        let rounded = EduSkeletonLoader(shape: .roundedRectangle(8))
        let circle = EduSkeletonLoader(shape: .circle)
        let capsule = EduSkeletonLoader(shape: .capsule)

        #expect(rectangle != nil)
        #expect(rounded != nil)
        #expect(circle != nil)
        #expect(capsule != nil)
    }

    @Test("EduSkeletonText initializes with line count")
    @MainActor
    func skeletonText() {
        let single = EduSkeletonText(lines: 1)
        let multi = EduSkeletonText(lines: 5, spacing: 10)

        #expect(single != nil)
        #expect(multi != nil)
    }

    @Test("EduSkeletonCard initializes with options")
    @MainActor
    func skeletonCard() {
        let withImage = EduSkeletonCard(showImage: true, lines: 3)
        let withoutImage = EduSkeletonCard(showImage: false, lines: 2)

        #expect(withImage != nil)
        #expect(withoutImage != nil)
    }

    @Test("EduSkeletonList initializes with count")
    @MainActor
    func skeletonList() {
        let list = EduSkeletonList(count: 5)
        #expect(list != nil)
    }
}

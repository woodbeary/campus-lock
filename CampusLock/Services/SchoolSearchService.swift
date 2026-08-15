import CampusLockCore
import Foundation
import MapKit

enum SchoolSearchService {
    static let suggestedSchools: [CampusSchoolSelection] = [
        CampusSchoolSelection(
            name: "University High School",
            address: "Irvine, CA",
            coordinate: Coordinate(latitude: 33.6463, longitude: -117.7779)
        ),
        CampusSchoolSelection(
            name: "Woodbridge High School",
            address: "Irvine, CA",
            coordinate: Coordinate(latitude: 33.6784, longitude: -117.7986)
        ),
        CampusSchoolSelection(
            name: "Irvine High School",
            address: "Irvine, CA",
            coordinate: Coordinate(latitude: 33.7068, longitude: -117.7877)
        ),
        CampusSchoolSelection(
            name: "Mater Dei High School",
            address: "Santa Ana, CA",
            coordinate: Coordinate(latitude: 33.7305, longitude: -117.9011)
        ),
        CampusSchoolSelection(
            name: "Orange Coast College",
            address: "Costa Mesa, CA",
            coordinate: Coordinate(latitude: 33.6705, longitude: -117.9090)
        ),
        CampusSchoolSelection(
            name: "University of California, Irvine",
            address: "Irvine, CA",
            coordinate: Coordinate(latitude: 33.6405, longitude: -117.8443)
        )
    ]

    @MainActor
    static func searchSchools(matching query: String) async -> [CampusSchoolSelection] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else { return suggestedSchools }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(trimmedQuery) school Orange County CA"
        request.region = orangeCountyRegion
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()
            let results = response.mapItems.compactMap(makeSchoolSelection)
            let schoolLikeResults = results.filter(isSchoolLike)
            return deduped(Array((schoolLikeResults.isEmpty ? results : schoolLikeResults).prefix(8)))
        } catch {
            return fallbackSchools(matching: trimmedQuery)
        }
    }

    private static var orangeCountyRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7175, longitude: -117.8311),
            latitudinalMeters: 72_000,
            longitudinalMeters: 72_000
        )
    }

    private static func makeSchoolSelection(_ item: MKMapItem) -> CampusSchoolSelection? {
        guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        let placemark = item.placemark
        let address = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
        return CampusSchoolSelection(
            name: name,
            address: address,
            coordinate: Coordinate(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
        )
    }

    private static func isSchoolLike(_ school: CampusSchoolSelection) -> Bool {
        let value = "\(school.name) \(school.address)".lowercased()
        return ["school", "academy", "college", "university", "campus"].contains { value.contains($0) }
    }

    private static func fallbackSchools(matching query: String) -> [CampusSchoolSelection] {
        let normalizedQuery = query.lowercased()
        let filtered = suggestedSchools.filter { school in
            "\(school.name) \(school.address)".lowercased().contains(normalizedQuery)
        }
        return filtered.isEmpty ? suggestedSchools : filtered
    }

    private static func deduped(_ schools: [CampusSchoolSelection]) -> [CampusSchoolSelection] {
        var seen = Set<String>()
        return schools.filter { school in
            let key = "\(school.name)-\(school.address)".lowercased()
            return seen.insert(key).inserted
        }
    }
}

import Foundation
import MapKit

struct ParkingSpot: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let name: String
    let type: ParkingType
    let capacity: Int?
    let fee: Bool?
    let access: String?

    enum ParkingType: String, CaseIterable {
        case surface = "Surface"
        case underground = "Underground"
        case multistorey = "Multi-Storey"
        case street = "Street"
        case unknown = "Parking"

        var icon: String {
            switch self {
            case .surface:      return "car.fill"
            case .underground:  return "arrow.down.to.line"
            case .multistorey:  return "building.2.fill"
            case .street:       return "road.lanes"
            case .unknown:      return "parkingsign"
            }
        }

        var color: String {
            switch self {
            case .surface:      return "blue"
            case .underground:  return "purple"
            case .multistorey:  return "orange"
            case .street:       return "green"
            case .unknown:      return "gray"
            }
        }

        init(from tags: [String: String]) {
            switch tags["parking"] ?? tags["amenity"] {
            case "underground":  self = .underground
            case "multi-storey": self = .multistorey
            case "surface":      self = .surface
            case "street_side":  self = .street
            default:             self = .unknown
            }
        }
    }
}

// MARK: - Overpass API Response Models
struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?

    var coordinate: CLLocationCoordinate2D? {
        if let lat = lat, let lon = lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let center = center {
            return CLLocationCoordinate2D(latitude: center.lat, longitude: center.lon)
        }
        return nil
    }
}

struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

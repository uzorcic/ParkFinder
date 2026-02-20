import Foundation
import CoreLocation
import Combine

class ParkingManager: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var lastFetchLocation: CLLocation?
    private let minimumDistanceForRefetch: CLLocationDistance = 300 // meters

    // Overpass API endpoint (uses a public instance)
    private let overpassURL = "https://overpass-api.de/api/interpreter"

    // Radius in meters to search for parking
    private let searchRadius: Int = 1000

    func fetchParkingSpots(near location: CLLocation) {
        // Avoid re-fetching if we haven't moved much
        if let last = lastFetchLocation,
           location.distance(from: last) < minimumDistanceForRefetch,
           !parkingSpots.isEmpty {
            return
        }

        isLoading = true
        errorMessage = nil
        lastFetchLocation = location

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="parking"](around:\(searchRadius),\(lat),\(lon));
          way["amenity"="parking"](around:\(searchRadius),\(lat),\(lon));
          relation["amenity"="parking"](around:\(searchRadius),\(lat),\(lon));
        );
        out center;
        """

        guard let url = URL(string: overpassURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")".data(using: .utf8)
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Failed to load parking data: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received."
                    return
                }

                do {
                    let response = try JSONDecoder().decode(OverpassResponse.self, from: data)
                    self?.parkingSpots = response.elements.compactMap { element in
                        guard let coordinate = element.coordinate else { return nil }
                        let tags = element.tags ?? [:]
                        let name = tags["name"] ?? tags["operator"] ?? "Parking"
                        let capacity = tags["capacity"].flatMap { Int($0) }
                        let fee = tags["fee"].map { $0 != "no" }
                        let access = tags["access"]
                        let type = ParkingSpot.ParkingType(from: tags)
                        return ParkingSpot(
                            id: "\(element.id)",
                            coordinate: coordinate,
                            name: name,
                            type: type,
                            capacity: capacity,
                            fee: fee,
                            access: access
                        )
                    }
                } catch {
                    self?.errorMessage = "Failed to parse parking data."
                }
            }
        }.resume()
    }
}

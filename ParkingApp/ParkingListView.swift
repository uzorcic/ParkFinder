import SwiftUI
import CoreLocation

struct ParkingListView: View {
    let spots: [ParkingSpot]
    let userLocation: CLLocation?
    let onSelect: (ParkingSpot) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var sortByDistance = true

    var filteredSpots: [ParkingSpot] {
        let base = searchText.isEmpty ? spots : spots.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }

        if sortByDistance, let userLoc = userLocation {
            return base.sorted {
                let a = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                let b = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                return a.distance(from: userLoc) < b.distance(from: userLoc)
            }
        }
        return base
    }

    var body: some View {
        NavigationView {
            List(filteredSpots) { spot in
                Button(action: { onSelect(spot) }) {
                    ParkingRowView(spot: spot, userLocation: userLocation)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search parking…")
            .navigationTitle("Nearby Parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { sortByDistance.toggle() }) {
                        Label(
                            sortByDistance ? "Sort: Distance" : "Sort: Name",
                            systemImage: sortByDistance ? "location.north.line.fill" : "textformat.abc"
                        )
                        .font(.caption)
                    }
                }
            }
            .overlay {
                if filteredSpots.isEmpty {
                    ContentUnavailableView(
                        "No Parking Found",
                        systemImage: "parkingsign",
                        description: Text("Try searching something else or zoom out on the map.")
                    )
                }
            }
        }
    }
}

struct ParkingRowView: View {
    let spot: ParkingSpot
    let userLocation: CLLocation?

    var distance: String? {
        guard let userLoc = userLocation else { return nil }
        let spotLoc = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)
        let meters = spotLoc.distance(from: userLoc)
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    var annotationColor: Color {
        switch spot.type {
        case .surface:      return .blue
        case .underground:  return .purple
        case .multistorey:  return .orange
        case .street:       return .green
        case .unknown:      return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(annotationColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: spot.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(annotationColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(spot.name)
                    .font(.body.bold())
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(spot.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let capacity = spot.capacity {
                        Text("·")
                            .foregroundColor(.secondary)
                        Label("\(capacity)", systemImage: "car.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    if let fee = spot.fee {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(fee ? "Paid" : "Free")
                            .font(.caption)
                            .foregroundColor(fee ? .orange : .green)
                    }
                }
            }

            Spacer()

            if let dist = distance {
                VStack {
                    Text(dist)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

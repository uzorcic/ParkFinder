import SwiftUI

struct ParkingAnnotationView: View {
    let spot: ParkingSpot
    @State private var showDetails = false

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
        VStack(spacing: 0) {
            Button(action: { showDetails.toggle() }) {
                ZStack {
                    Circle()
                        .fill(annotationColor)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 3)
                    Image(systemName: spot.type.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Callout bubble
            if showDetails {
                ParkingCalloutView(spot: spot)
                    .offset(y: -4)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.3), value: showDetails)
    }
}

struct ParkingCalloutView: View {
    let spot: ParkingSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .font(.caption.bold())
                .lineLimit(2)

            Text(spot.type.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)

            if let capacity = spot.capacity {
                Label("\(capacity) spaces", systemImage: "car.2.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }

            if let fee = spot.fee {
                Label(fee ? "Paid" : "Free", systemImage: fee ? "eurosign.circle" : "checkmark.circle")
                    .font(.caption2)
                    .foregroundColor(fee ? .orange : .green)
            }

            if let access = spot.access, access != "yes" {
                Label(access.capitalized, systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(radius: 4)
        .frame(maxWidth: 160)
    }
}

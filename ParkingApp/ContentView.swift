import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var parkingManager = ParkingManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058), // Ljubljana default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var trackingUser = true
    @State private var showList = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Map
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: trackingUser ? .constant(.follow) : .constant(.none),
                annotationItems: parkingManager.parkingSpots) { spot in
                MapAnnotation(coordinate: spot.coordinate) {
                    ParkingAnnotationView(spot: spot)
                }
            }
            .ignoresSafeArea()
            .onChange(of: locationManager.location) { newLocation in
                guard let loc = newLocation else { return }
                if trackingUser {
                    withAnimation {
                        region.center = loc.coordinate
                    }
                }
                parkingManager.fetchParkingSpots(near: loc)
            }

            // MARK: - Top bar
            VStack {
                HStack {
                    // App title
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🅿 ParkFinder")
                            .font(.headline.bold())
                        if parkingManager.isLoading {
                            Label("Loading parking…", systemImage: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(parkingManager.parkingSpots.count) spots nearby")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Spacer()

                    // Refresh button
                    Button(action: {
                        if let loc = locationManager.location {
                            parkingManager.fetchParkingSpots(near: loc)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(parkingManager.isLoading)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }

            // MARK: - Bottom controls
            VStack(spacing: 12) {
                // Error banner
                if let error = parkingManager.errorMessage ?? locationManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }

                // Legend + list toggle
                HStack(spacing: 12) {
                    // Spot type legend
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ParkingSpot.ParkingType.allCases, id: \.self) { type in
                                LegendBadge(type: type)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // List button
                    Button(action: { showList.toggle() }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)

                // Recenter button
                HStack {
                    Spacer()
                    Button(action: {
                        trackingUser = true
                        if let loc = locationManager.location {
                            withAnimation {
                                region.center = loc.coordinate
                                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            }
                        }
                    }) {
                        Image(systemName: trackingUser ? "location.fill" : "location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(trackingUser ? .blue : .primary)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showList) {
            ParkingListView(spots: parkingManager.parkingSpots, userLocation: locationManager.location) { spot in
                withAnimation {
                    region.center = spot.coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                    trackingUser = false
                }
                showList = false
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        // Detect when user drags the map
        .simultaneousGesture(
            DragGesture().onChanged { _ in trackingUser = false }
        )
    }
}

// MARK: - Legend Badge
struct LegendBadge: View {
    let type: ParkingSpot.ParkingType

    var color: Color {
        switch type {
        case .surface:      return .blue
        case .underground:  return .purple
        case .multistorey:  return .orange
        case .street:       return .green
        case .unknown:      return .gray
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption2.bold())
                .foregroundColor(color)
            Text(type.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
    }
}


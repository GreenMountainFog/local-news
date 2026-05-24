import Foundation

/// Fetches Burlington, VT forecast from the NWS JSON API (no key required).
struct WeatherService {
    private static let pointURL = URL(string: "https://api.weather.gov/points/44.4774048,-73.2110569")!

    static func fetch() async throws -> WeatherData {
        // Step 1: resolve forecast URLs from the /points endpoint
        let pointData = try await get(pointURL)
        let point = try JSONDecoder().decode(NWSPoint.self, from: pointData)

        // Step 2: fetch forecast + observation in parallel
        async let forecastData = get(URL(string: point.properties.forecast)!)
        async let obsData = get(URL(string: point.properties.observationStations)!)

        let forecast = try await NWSForecast(data: try forecastData)
        let stations = try await NWSStations(data: try obsData)

        // Step 3: latest observation from the first station
        var current: WeatherData.CurrentConditions?
        if let stationURL = stations.firstObservationURL {
            let obsItemData = try await get(stationURL)
            current = NWSObservation(data: obsItemData)?.toConditions()
        }

        return WeatherData(
            location: "\(point.properties.relativeLocation.properties.city), \(point.properties.relativeLocation.properties.state)",
            current: current ?? forecast.periods.first.map {
                .init(temperature: $0.temperature, textDescription: $0.shortForecast, icon: $0.iconURL, windSpeed: $0.windSpeed, relativeHumidity: nil)
            } ?? .init(temperature: 0, textDescription: "Unavailable", icon: nil, windSpeed: "", relativeHumidity: nil),
            periods: forecast.periods,
            fetchedAt: .now
        )
    }

    private static func get(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("LocalNews/1.0 (sirnoahduncan@gmail.com)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }
}

// MARK: - NWS response shapes (minimal)

private struct NWSPoint: Decodable {
    struct Properties: Decodable {
        let forecast: String
        let forecastHourly: String
        let observationStations: String
        let relativeLocation: RelativeLocation
    }
    struct RelativeLocation: Decodable {
        struct LocationProperties: Decodable { let city: String; let state: String }
        let properties: LocationProperties
    }
    let properties: Properties
}

private struct NWSForecast {
    let periods: [WeatherData.ForecastPeriod]

    init(data: Data) throws {
        struct Root: Decodable {
            struct Props: Decodable { let periods: [Period] }
            struct Period: Decodable {
                let number: Int; let name: String; let isDaytime: Bool
                let temperature: Int; let temperatureUnit: String
                let windSpeed: String; let windDirection: String
                let shortForecast: String; let detailedForecast: String
                let icon: String
            }
            let properties: Props
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        periods = root.properties.periods.map {
            .init(id: $0.number, name: $0.name, temperature: $0.temperature,
                  temperatureUnit: $0.temperatureUnit, windSpeed: $0.windSpeed,
                  windDirection: $0.windDirection, shortForecast: $0.shortForecast,
                  detailedForecast: $0.detailedForecast, icon: URL(string: $0.icon),
                  isDaytime: $0.isDaytime)
        }
    }
}

private struct NWSStations {
    let firstObservationURL: URL?

    init(data: Data) throws {
        struct Root: Decodable {
            struct Feature: Decodable { let id: String }
            let features: [Feature]
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        if let first = root.features.first {
            firstObservationURL = URL(string: "\(first.id)/observations/latest")
        } else {
            firstObservationURL = nil
        }
    }
}

private struct NWSObservation {
    let conditions: WeatherData.CurrentConditions

    init?(data: Data) {
        struct Root: Decodable {
            struct Props: Decodable {
                struct Val: Decodable { let value: Double? }
                let temperature: Val; let textDescription: String?
                let icon: String?; let windSpeed: Val; let relativeHumidity: Val?
            }
            let properties: Props
        }
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else { return nil }
        let p = root.properties
        let tempF = p.temperature.value.map { Int($0 * 9/5 + 32) } ?? 0
        let windMph = p.windSpeed.value.map { "\(Int($0 * 0.621371)) mph" } ?? ""
        conditions = .init(temperature: tempF,
                           textDescription: p.textDescription ?? "",
                           icon: p.icon.flatMap(URL.init),
                           windSpeed: windMph,
                           relativeHumidity: p.relativeHumidity?.value.map(Int.init))
    }

    func toConditions() -> WeatherData.CurrentConditions { conditions }
}

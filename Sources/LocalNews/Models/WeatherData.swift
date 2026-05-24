import Foundation

struct WeatherData: Codable {
    let location: String
    let current: CurrentConditions
    let periods: [ForecastPeriod]
    let fetchedAt: Date

    struct CurrentConditions: Codable {
        let temperature: Int       // °F
        let textDescription: String
        let icon: URL?
        let windSpeed: String
        let relativeHumidity: Int?
    }

    struct ForecastPeriod: Identifiable, Codable {
        let id: Int
        let name: String           // "Tonight", "Thursday", etc.
        let temperature: Int
        let temperatureUnit: String
        let windSpeed: String
        let windDirection: String
        let shortForecast: String
        let detailedForecast: String
        let icon: URL?
        let isDaytime: Bool
    }
}

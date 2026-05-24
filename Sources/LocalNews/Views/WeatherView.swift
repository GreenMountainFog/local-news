import SwiftUI

struct WeatherView: View {
    let data: WeatherData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current conditions
                GroupBox {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(data.location).font(.headline)
                            Text("\(data.current.temperature)°F")
                                .font(.system(size: 52, weight: .thin, design: .rounded))
                            Text(data.current.textDescription)
                                .foregroundStyle(.secondary)
                            Text("Wind: \(data.current.windSpeed)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let icon = data.current.icon {
                            AsyncImage(url: icon) { img in img.resizable().scaledToFit() } placeholder: { Color.clear }
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding(4)
                } label: {
                    Label("Current Conditions", systemImage: "thermometer.sun")
                }

                // Forecast
                GroupBox {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                        ForEach(data.periods.prefix(8)) { period in
                            ForecastCard(period: period)
                        }
                    }
                } label: {
                    Label("7-Day Forecast", systemImage: "calendar")
                }

                Text("Updated \(data.fetchedAt, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .navigationTitle("Burlington Weather")
    }
}

struct ForecastCard: View {
    let period: WeatherData.ForecastPeriod

    var body: some View {
        VStack(spacing: 6) {
            Text(period.name).font(.caption).foregroundStyle(.secondary)
            if let icon = period.icon {
                AsyncImage(url: icon) { img in img.resizable().scaledToFit() } placeholder: { Color.clear }
                    .frame(width: 40, height: 40)
            }
            Text("\(period.temperature)°\(period.temperatureUnit)")
                .font(.title3.bold())
            Text(period.shortForecast)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

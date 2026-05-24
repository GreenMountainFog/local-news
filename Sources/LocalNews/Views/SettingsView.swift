import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            SourcesSettingsTab()
                .tabItem { Label("Sources", systemImage: "antenna.radiowaves.left.and.right") }

            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 520, height: 400)
    }
}

struct SourcesSettingsTab: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        List($store.sources) { $source in
            HStack {
                Toggle(isOn: $source.isEnabled) { EmptyView() }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                VStack(alignment: .leading) {
                    Text(source.name).font(.body)
                    Text(source.category.displayName).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(methodLabel(source.fetchMethod))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }

    private func methodLabel(_ method: FetchMethod) -> String {
        switch method {
        case .rss: return "RSS"
        case .scrape: return "Scraped"
        case .redditJSON: return "Reddit"
        case .nwsWeather: return "NWS API"
        }
    }
}

struct GeneralSettingsTab: View {
    @AppStorage("refreshIntervalMinutes") private var refreshInterval = 15
    @AppStorage("maxArticles") private var maxArticles = 500

    var body: some View {
        Form {
            Picker("Auto-refresh every", selection: $refreshInterval) {
                Text("5 minutes").tag(5)
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("60 minutes").tag(60)
            }
            .pickerStyle(.menu)

            Picker("Keep articles", selection: $maxArticles) {
                Text("200 articles").tag(200)
                Text("500 articles").tag(500)
                Text("1000 articles").tag(1000)
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
        .padding()
    }
}

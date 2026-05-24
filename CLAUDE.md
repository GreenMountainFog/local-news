# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Local News** — native macOS SwiftUI app (macOS 14+) that aggregates Burlington, VT local news, events, and weather. Built with Swift Package Manager; open `Package.swift` in Xcode to get the full IDE experience.

## Build & Run

```sh
# Build
swift build

# Run
swift run

# Open in Xcode (recommended for UI work)
open Package.swift
```

> The app requires network access and macOS 14 Sonoma or later.

## Architecture

### Data flow

`AppStore` (ObservableObject, `@MainActor`) is the single source of state injected via `.environmentObject`. Views read from it; services write into it. `AppStore` owns refresh, persistence, bookmarks, snippets, and reading lists.

```
AppStore
  ├── refreshAll()              ← parallel TaskGroup across all enabled sources
  │     ├── RSSService          ← feeds that publish RSS/Atom
  │     ├── ScraperService      ← HTML scraping via SwiftSoup
  │     ├── RedditService       ← r/burlington public JSON API
  │     └── WeatherService      ← NWS JSON API (no key required)
  └── PersistenceService        ← JSON files in ~/Library/Application Support/LocalNews/
```

### Source configuration

All news sources live in `NewsSource.defaults` ([NewsSource.swift](Sources/LocalNews/Models/NewsSource.swift)). Each source has a `FetchMethod`:
- `.rss(URL)` — RSS/Atom parsed by `RSSService`
- `.scrape(ScrapeStrategy)` — HTML parsed by `ScraperService` + SwiftSoup
- `.redditJSON(URL)` — Reddit public `.json` endpoint
- `.nwsWeather` — National Weather Service API, hardcoded to Burlington lat/lon

To add a new source: add a case to `ScrapeStrategy` (if scraping), implement the corresponding scrape function in `ScraperService`, then add the source to `NewsSource.defaults`.

### Views (three-column NavigationSplitView)

| Column | View | Purpose |
|---|---|---|
| Sidebar | `SidebarView` | Category filter, saved sections, reading lists, weather summary |
| Content | `FeedView` | Scrollable article list with search |
| Detail | `ArticleDetailView` | WKWebView rendering the article URL |

Bookmarks, snippets, and reading list detail views replace the content+detail columns via `NavigationLink` from the sidebar.

### Key models

- `FeedItem` — immutable; `id` is the article URL string (deduplication key)
- `NewsSource` — `isEnabled` flag is user-toggleable in Settings
- `SaveData` in the Mistwalker sibling project is unrelated; `PersistenceService` here saves each collection to a separate JSON file keyed by collection name
- `ReadingList` stores both `itemIDs` (strings) and a full `items` snapshot so articles are readable offline after the feed cache is pruned

### Scraper brittleness

`ScraperService` CSS selectors are best-effort and will break when sites redesign. When a scraper stops returning results, inspect the live HTML and update the `select()` calls in the relevant `scrape*` function. The scrapers for Higher Ground, Hello Burlington, and Bands In Town are the most likely to need periodic maintenance.

### Weather

`WeatherService` follows the NWS two-step pattern: hit `/points/{lat},{lon}` to get forecast + observation station URLs, then fetch both in parallel. The `User-Agent` header must include a contact email per NWS API policy.

## Dependencies

- **SwiftSoup** (`scinfu/SwiftSoup`) — HTML parsing for scraped sources. Declared in `Package.swift`.

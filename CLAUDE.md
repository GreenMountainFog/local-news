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

> Requires macOS 14 Sonoma or later and network access.

## Known Issues / In Progress

- **WKWebView sandbox errors** — SPM apps need an entitlements file to host WKWebView. `Sources/LocalNews/LocalNews.entitlements` exists with sandbox disabled, but SPM has no native way to embed it. Until the project is converted to a full `.xcodeproj`, WKWebView may log sandbox errors. Workaround: after building, run `codesign --force --sign - --entitlements Sources/LocalNews/LocalNews.entitlements .build/debug/LocalNews`, then launch `.build/debug/LocalNews` directly instead of via Xcode.
- **`linkd.autoShortcut` console spam** — harmless macOS 15 Sequoia noise logged for any app without a bundle ID. Does not affect functionality.
- **RSS feed URLs** — several URLs (WCAX, NBC5, Burlington Free Press, Vermont.gov) have not been verified against live feeds. If a source shows an error in the sidebar "Source Errors" section, check its URL in `NewsSource.defaults`.
- **Scrapers are best-effort** — Higher Ground, Hello Burlington, Bands In Town CSS selectors will break when sites redesign. Inspect live HTML and update `select()` calls in `ScraperService`.

## Architecture

### Data flow

`AppStore` (ObservableObject, `@MainActor`) is the single source of state injected via `.environmentObject`. Views read from it; services write into it.

```
AppStore
  ├── refreshAll()         ← parallel TaskGroup; errors tracked per source in fetchErrors
  │     ├── RSSService     ← RSS/Atom via XMLParser
  │     ├── ScraperService ← HTML scraping via SwiftSoup
  │     ├── RedditService  ← r/burlington public .json endpoint
  │     └── WeatherService ← NWS JSON API (no key required)
  └── PersistenceService   ← JSON files in ~/Library/Application Support/LocalNews/
```

`AppStore.scheduleAutoRefresh()` fires immediately (50ms delay to clear first SwiftUI render) then every 15 minutes. Failed sources are surfaced in `fetchErrors: [String: String]` and shown in the sidebar "Source Errors" section.

### Navigation

Three-column `NavigationSplitView`. Sidebar selection drives the content column via a `SidebarDestination?` binding — **must be Optional** (`SidebarDestination?`, not `SidebarDestination`) or `List(selection:)` only registers the initial default value.

```
SidebarDestination enum
  .allFeed / .category(Category) → FeedView(category:)
  .bookmarks                     → BookmarksView
  .snippets                      → SnippetsView
  .readingList(UUID)             → ReadingListDetailView
  .weather                       → WeatherView
```

Content column switch unwraps the optional before switching (`destination ?? .allFeed`) — `@ViewBuilder` handles Optional switches with compound patterns (`case .foo, nil:`) unreliably.

### Source configuration

All sources live in `NewsSource.defaults` in [NewsSource.swift](Sources/LocalNews/Models/NewsSource.swift). Each has a `FetchMethod`:
- `.rss(URL)` — RSS/Atom
- `.scrape(ScrapeStrategy)` — HTML via SwiftSoup
- `.redditJSON(URL)` — Reddit JSON
- `.nwsWeather` — National Weather Service, hardcoded to Burlington (44.4774048, -73.2110569)

To add a source: add a `ScrapeStrategy` case if needed, implement it in `ScraperService`, add to `NewsSource.defaults`.

### Key models

- `FeedItem.id` = article URL string — deduplication key, must be stable
- `Category` — must be `Hashable` (explicit conformance in `FeedItem.swift`) for `SidebarDestination` synthesis
- `ReadingList` stores full `items` snapshots (not just IDs) so articles are readable after cache pruning
- `SaveData` schema is append-only — renaming or removing fields breaks saved files

### Persistence

JSON files in `~/Library/Application Support/LocalNews/`. Up to 500 most-recent items cached. Bookmarks, snippets, and reading lists stored separately and never pruned.

## Dependencies

- **SwiftSoup** (`scinfu/SwiftSoup`) — HTML parsing for scraped sources.

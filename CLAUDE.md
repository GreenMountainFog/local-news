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

## Design System

### Philosophy
Content-first, Vermont-rooted. Clean editorial typography with nature-inspired color. Native macOS conventions throughout — no skeuomorphism, no web-app imitations. The app should feel like it belongs on a Mac and was crafted by someone who loves Burlington.

### Color Palette

**Brand accent — Champlain Blue**
`Color(red: 0.17, green: 0.48, blue: 0.55)` — deep teal inspired by Lake Champlain.
Use for: links, selected states, unread indicators, interactive elements, progress.
Set as the global `.accentColor` on the root view.

**Category colors** — use full opacity for icons/labels; 12% opacity for background fills.
Add a `var color: Color` computed property to the `Category` enum:
- `.news` → `.blue`
- `.events` → `Color(red: 0.24, green: 0.48, blue: 0.35)` — forest green
- `.weather` → `Color(red: 0.05, green: 0.65, blue: 0.79)` — sky blue
- `.sports` → `Color(red: 0.83, green: 0.38, blue: 0.16)` — maple orange
- `.arts` → `Color(red: 0.55, green: 0.35, blue: 0.80)` — twilight purple

**Backgrounds** — always use system adaptive, never hardcode:
- Primary: `.background`
- Secondary: `.secondarySystemBackground`
- Floating panels / sidesheets: `.regularMaterial`
- Overlays: `.ultraThinMaterial`

**Text:**
- Read articles: full row at `.opacity(0.48)`, not just the title
- Unread dot: 7pt filled circle in Champlain Blue, left gutter of feed rows

### Typography (SF Pro only — never set a custom font family)

| Role                  | Modifier                                             |
|-----------------------|------------------------------------------------------|
| Screen title          | `.title2.weight(.semibold)`                          |
| Article headline      | `.headline` (semibold by default)                    |
| Source name           | `.caption.weight(.medium)`                           |
| Summary               | `.subheadline`                                       |
| Timestamps            | `.caption2`                                          |
| Section headers       | `.caption.weight(.semibold)` + `.uppercased()`       |
| Large weather temp    | `.system(size: 52, weight: .thin, design: .rounded)` |

### Spacing (strict 8pt grid)

| Token | pt  | Use                                      |
|-------|-----|------------------------------------------|
| xs    | 4   | Icon-to-label gap, tight pairs           |
| sm    | 8   | Within a component                       |
| md    | 12  | Card internal padding                    |
| lg    | 16  | Between rows / cards                     |
| xl    | 20  | Section spacing, scroll content padding  |
| xxl   | 32  | Major section breaks                     |

Never use arbitrary values like 6, 10, 14, 18 — round to the nearest grid step.

### Corner Radius

| Context                  | Radius |
|--------------------------|--------|
| Cards, GroupBox fills    | 10pt   |
| Category pills / tags    | 6pt    |
| Thumbnails               | 8pt    |
| Tooltips / popovers      | 12pt   |

### Feed Row Design

Target for `FeedRowView`:
- **Left gutter**: 7pt Champlain Blue circle when unread; nothing when read
- **Top line**: source name (`.caption.medium`, category color) · spacer · relative timestamp (`.caption2`, `.tertiary`)
- **Title**: `.headline`, 2-line limit, full opacity when unread / `.opacity(0.48)` when read
- **Summary**: `.subheadline`, `.secondary`, 2-line limit
- **Thumbnail**: if `imageURL` is present, 56×56pt image, `cornerRadius: 8`, trailing
- **Row padding**: 10pt vertical, no extra horizontal (List provides it)

### Sidebar Design

- Category labels: icon tinted with `cat.color`, label `.primary`
- Unread badges: Champlain Blue background, white `.caption2.bold()` text
- Source Errors: orange `.foregroundStyle`, collapsed by default with a disclosure group

### Animations

| Context              | Value                                                            |
|----------------------|------------------------------------------------------------------|
| State changes        | `.spring(response: 0.3, dampingFraction: 0.8)`                  |
| List row appear      | `.transition(.opacity.combined(with: .move(edge: .trailing)))`  |
| Detail pane appear   | `.transition(.opacity)`                                          |
| Never animate layout | Avoid `.animation(.default)` — always bind to a specific value  |

### macOS Conventions (non-negotiable)

- Never use `UIColor` or `UIFont` — this is macOS
- All icon-only toolbar buttons must have `.help("…")` — already doing this
- Use `ContentUnavailableView` for all empty states — already doing this
- Never hardcode light-only colors — always test mental model in dark mode
- `List(selection:)` drives navigation — never use `.onTapGesture` for primary navigation
- Keyboard shortcuts on all primary actions (`⌘R` refresh already done — continue this pattern)
- Use `.contextMenu` for secondary/destructive actions — already doing this

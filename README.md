# Bricks

**Bricks** is a lightweight Swift library for building composable data loading and caching services. It provides a set of building blocks — *entities* and *decorators* — that chain together through a fluent dot-notation API to form complex data pipelines from simple, testable pieces.

![237940157-f9e1d753-fed9-47c8-90b2-abc127e5c7d4](https://github.com/aniramskaya/bricks/assets/108326429/6688c16f-d99a-4f43-9c14-5f0fc5a13e78)

## Requirements

- iOS 10.0+
- macOS 10.12+
- Swift 5+

## Installation

### CocoaPods

```ruby
pod 'Bricks', '~> 1.0'
```

## Core Concepts

The library is built on two base protocols. Every component implements one of them.

**`Query`** — any asynchronous operation that produces a result:

```swift
public protocol Query {
    associatedtype Result
    func load(completion: @escaping (Result) -> Void)
}
```

**`FailableQuery`** — extends `Query` for operations that can fail:

```swift
public protocol FailableQuery: Query
    where Result == Swift.Result<Success, Failure>
{
    associatedtype Success
    associatedtype Failure: Error
}
```

Each component exposes extension methods on these protocols, making it possible to build sophisticated pipelines by chaining calls:

```swift
cache
    .expiring(validationPolicy: policy)
    .fallback(networkLoader.map(with: mapper).store(into: cache))
```

## Components

| Category | Component | API |
|---|---|---|
| **Storage** | `InMemoryStorage` | `.asQuery()` |
| | `SynchronousStorageAdapter` | `.asAsyncStorage()` |
| | `ExpiringCache` | `.expiring(validationPolicy:)` |
| **Transformation** | `Converter` | `.convert(map:)` |
| | `FailableConverter` | `.map(with:)` |
| **Persistence** | `StoringQuery` | `.store(into:)` |
| **Error handling** | `Fallback` | `.fallback(_:)` |
| | `SecondChance` | `.secondChance(_:)` |
| **Concurrency** | `Synchronizer` | `.synchronize(with:)` |
| | `DemultiplyingQuery` | `.serial()` |
| **Observation** | `NotifyingQuery` | `.notify(onSuccess:onFailure:)` |
| **Parallel loading** | `ParallelPriorityLoader` | `.loadMandatory(mandatoryPriority:timeout:)` |
| **Pagination** | `Paginator` | `load()` / `loadMore()` |
| **Commands** | `Command` | `execute(_:completion:)` |

## Usage Examples

### Transformation

Map a loaded value to another type:

```swift
let loader = networkLoader
    .map(with: { dto in Article(dto: dto) })

loader.load { result in
    switch result {
    case .success(let article): display(article)
    case .failure(let error): showError(error)
    }
}
```

---

### Caching with expiration and network fallback

Read from an in-memory cache first. On a miss or stale data, fetch from the network, transform the result, and repopulate the cache:

```swift
let cache = InMemoryStorage<[Article]>()
let asyncCache = cache.asAsyncStorage()

let loader = asyncCache
    .expiring(validationPolicy: TimeIntervalValidationPolicy())
    .fallback(
        networkLoader
            .map(with: { dtos in dtos.map(Article.init) })
            .store(into: asyncCache)
    )
```

Pipeline steps:
1. Read from `InMemoryStorage`
2. Check timestamp against `TimeIntervalValidationPolicy`
3. Cache valid → return immediately
4. Cache expired → run the fallback branch:
   - Fetch DTOs from the network
   - Map to `Article` objects
   - Save to cache for the next call
   - Return the fresh data

---

### `fallback` vs `secondChance`

Both decorators execute a secondary query when the primary fails. The difference is which error surfaces when *both* fail:

```swift
// On double failure — returns the secondary query's error
primary.fallback(secondary)

// On double failure — returns the primary query's error
primary.secondChance(secondary)
```

Use `.fallback()` when you treat the secondary as the authoritative source.  
Use `.secondChance()` when the primary error is the one that matters to the caller.

---

### Deduplicating concurrent requests

`.serial()` ensures that simultaneous `load()` calls result in only one underlying request. All callers waiting at the time the request completes receive the same result:

```swift
let loader = networkLoader.serial()

// These two concurrent calls produce a single network request
loader.load { result in /* caller A */ }
loader.load { result in /* caller B — gets the same result as A */ }
```

---

### Side-effect notifications

Execute side effects on success or failure without modifying the query's result or altering the pipeline:

```swift
let loader = networkLoader
    .notify(
        onSuccess: { articles in Analytics.track("loaded", count: articles.count) },
        onFailure: { error in Logger.error(error) }
    )
```

---

### Synchronizing two queries

Run two independent queries in parallel and receive both results in a single callback:

```swift
userLoader
    .synchronize(with: settingsLoader)
    .load { userResult, settingsResult in
        guard
            case .success(let user) = userResult,
            case .success(let settings) = settingsResult
        else { return }
        configure(user: user, settings: settings)
    }
```

---

### Parallel loading with priorities

Load multiple resources concurrently. Mark items as `.required` or `.optional` — the loader succeeds as soon as all required items complete. Optional items are included if they finish within the timeout:

```swift
struct SectionLoader: PriorityLoadingItem {
    typealias Success = [Post]
    typealias Failure = Error

    let sectionId: String
    let priority: ParallelPriority

    func load(completion: @escaping (Result<[Post], Error>) -> Void) { ... }
}

let items = [
    SectionLoader(sectionId: "main",        priority: .required),
    SectionLoader(sectionId: "recommended", priority: .optional),
    SectionLoader(sectionId: "trending",    priority: .optional)
].map { $0.eraseToAnyPriorityLoadingItem() }

ParallelPriorityLoader(items, mandatoryPriority: .required, timeout: 5.0)
    .load { result in
        switch result {
        case .success(let sections):      // [[Post]?] — nil for items that didn't complete in time
            render(sections)
        case .failure(.timeout):
            showTimeout()
        case .failure(.mandatoryFailed):
            showError()
        }
    }
```

---

### Pagination

`Paginator` manages page state and accumulates results across calls. Concurrent `load()` / `loadMore()` calls are automatically deduplicated:

```swift
let paginator = Paginator { page in
    ArticlePageRequest(page: page)  // returns a FailableQuery<[Article], Error>
}

// Load the first page
paginator.load { result in
    switch result {
    case .success(let page): display(page)
    case .failure(let error): showError(error)
    }
}

// Load the next page, appending to paginator.data
paginator.loadMore { result in ... }

// All accumulated items
let allArticles: [Article] = paginator.data

// Reset page counter and clear data
paginator.reset()
```

---

## License

Bricks is available under the [MIT license](LICENSE).

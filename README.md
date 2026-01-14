# Bricks
![237940157-f9e1d753-fed9-47c8-90b2-abc127e5c7d4](https://github.com/aniramskaya/bricks/assets/108326429/6688c16f-d99a-4f43-9c14-5f0fc5a13e78)

Эта библиотечка состоит из набора сущностей и декораторов (кирпичиков), с помощью которых можно строить различную логику загркзыи и кэширования данных.
В ее основе лежат два протокола: Query и FailableQuery. Остальные компоненты библиотеки реализуют один из них и предоставляют расширения этих протоколов для того чтобы можно было выстраивать сложные сервисы используя непрерывную dot-нотацию

Простой пример:
```swift
    static func simpleModelLoader() -> any FailableQuery {
        let dto = DTO(value: UUID())
        // Загрузить DTO используя DTOLoader и выполнить маппинг DTO на модель 
        return DTOLoader(dto: dto).map(with: DTO.toModel)
    }
```

Чуть сложнее:
```swift
    static func modelLoaderWithInMemoryCache() -> any FailableQuery {
        let dto = DTO(value: UUID())
        
        let storage = InMemoryStorage<Model>().asQuery()
        
        // Начинаем с получения данных из кэша в памяти (storage)
        return storage
        // Применяем к нему политику валидации TimeIntervalValidationPolicy
        .expiring(validationPolicy: TimeIntervalValidationPolicy())
        // Если кэш невалиден, запускается вторая ветка
        .fallback(
            // Загружается DTO
            DTOLoader(dto: dto)
            // DTO маппится в модель
            .map(with: DTO.toModel)
            // модель сохраняется в InMemoryStorage
            .store(into: storage)
        )
    }
```

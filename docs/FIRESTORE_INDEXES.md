# Firestore Composite Indexes (properties)

Current queries now fetch with minimal Firestore filters (order by `createdAt` for base list, or price range + order by `price`), and apply `isDeleted/status/location/rooms/hasPool` client-side to avoid composite index prompts. With this approach, **no composite indexes are required** for the properties list/filters.

If you later reintroduce server-side equality filters (e.g., `isDeleted == false`, `status == active`, `locationAreaId == X`) alongside `orderBy`, you will need composite indexes matching those fields. Use the Firebase console prompt or add definitions to `firestore.indexes.json` as needed.

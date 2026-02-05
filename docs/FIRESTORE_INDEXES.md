# Firestore Composite Indexes (properties)

Current queries now fetch with minimal Firestore filters (order by `createdAt` for base list, or price range + order by `price`), and apply `isDeleted/status/location/rooms/hasPool` client-side to avoid composite index prompts. With this approach, **no composite indexes are required** for the properties list/filters.

If you later reintroduce server-side equality filters (e.g., `isDeleted == false`, `status == active`, `locationAreaId == X`) alongside `orderBy`, you will need composite indexes matching those fields. Use the Firebase console prompt or add definitions to `firestore.indexes.json` as needed.

## SubLocations + OwnerName Notes
- `sub_locations` collection:
  - Fields: `areaId` (String), `nameAr` (String), `nameEn` (String), `imageUrl` (String?), `isActive` (bool), `createdAt` (Timestamp).
  - Query used: `where(areaId == ...)` + `where(isActive == true)` + `orderBy(createdAt)`.
  - Required composite index if Firestore prompts: `(areaId ASC, isActive ASC, createdAt ASC)`.
- `properties` documents:
  - New fields: `subLocationId` (String?), `ownerNameEncryptedOrHiddenStored` (String?).
  - `subLocationId` is optional for backward compatibility; missing values are treated as "unassigned" and excluded when filtering by sublocation.
  - `ownerNameEncryptedOrHiddenStored` is optional; if missing/empty, UI hides the owner name section.
  - No new composite index required beyond existing property list filters unless you add extra `orderBy` + `where` combinations on `subLocationId`.

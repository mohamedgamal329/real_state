# Firestore Composite Indexes (properties)

Properties queries use server-side equality filters for scope and soft-delete:
- Base list: `where(ownerScope == ...)`, optional `where(brokerId == ...)`, `where(isDeleted == false)`, optional `where(subLocationId == ...)`, `orderBy(createdAt desc)`.
- Price range list: same equality filters + `where(price >= ...)` / `where(price <= ...)`, `orderBy(price)`.

Firestore may require composite indexes when equality filters are combined with `orderBy`. If prompted, create composite indexes matching the exact field combinations in the console or `firestore.indexes.json`.

## SubLocations + OwnerName Notes
- `sub_locations` collection:
  - Fields: `areaId` (String), `nameAr` (String), `nameEn` (String), `imageUrl` (String?), `isActive` (bool), `createdAt` (Timestamp).
  - Query used: `where(areaId == ...)` + `where(isActive == true)` + `orderBy(createdAt)`.
  - Required composite index if Firestore prompts: `(areaId ASC, isActive ASC, createdAt ASC)`.
- `properties` documents:
  - New fields: `subLocationId` (String?), `ownerNameEncryptedOrHiddenStored` (String?).
  - `subLocationId` is optional for backward compatibility; missing values are treated as "unassigned" and excluded when filtering by sublocation.
  - `ownerNameEncryptedOrHiddenStored` is optional; if missing/empty, UI hides the owner name section.
  - When filtering by `subLocationId`, Firestore may require a composite index that includes `subLocationId` plus any other `where` fields and the active `orderBy` field (`createdAt` or `price`).

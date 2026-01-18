# Full App Report - Phase 2 Release Candidate

## 1. Routes + Entry Points

The application uses `go_router` for navigation. Key routes defined in `lib/core/routes/app_router.dart`:

| Route | Page | Purpose |
|-------|------|---------|
| `/main` | `MainShellPage` | Main entry point with tabs (Home, Brokers, Categories, My Properties). |
| `/notifications` | `NotificationsPage` | List of system and access request notifications. |
| `/property/:id` | `PropertyPage` | Detailed view of a single property. |
| `/filters/results` | `FilteredPropertiesPage` | Displays property search results based on a filter. |
| `/filters/categories` | `CategoriesFilterPage`| Specialized filter UI for the Categories tab. |

**Entry Points:**
- **MainShell Tabs**: Home, Brokers, Categories (triggering filter), Settings.
- **Notification Page**: Accessible from an icon button in the AppBar.

## 2. PDF Pipeline

### Single Property Share
- **Path**: `PropertyShareService.sharePdf` (`lib/features/properties/domain/services/property_share_service.dart`)
- **Process**:
  1. `buildPdfBytes` generates the PDF data as `Uint8List`.
  2. PDF bytes are written to a **real temporary file** in `${tempDir}/share_pdfs/`.
  3. The file is named using the property title.
  4. `Share.shareXFiles` is called with the `XFile` pointing to the real file path.

### Multi Property Share
- **Path**: `shareMultiplePropertyPdfs` (`lib/core/utils/multi_pdf_share.dart`)
- **Process**:
  1. Iterates through the list of properties.
  2. For each, `service.buildPdfBytes` is called.
  3. Each PDF is written to a **real temporary file** in `${tempDir}/share_pdfs/`.
  4. Filenames are generated using `buildSharePdfFileName`, which handles duplicates with numeric suffixes (e.g., `Title.pdf`, `Title (2).pdf`).
  5. One single call to `Share.shareXFiles` is made with the list of created `XFile` objects.

**Android/Gmail Risks:**
- `XFile.fromData` is **unreliable** for Gmail as it often ignores the `name` parameter and uses a UUID.
- **Rule**: Always write to a real file on disk before sharing to ensure the filename is preserved.

## 3. Permissions & Roles

Defined in `lib/features/properties/domain/property_permissions.dart`.

### Roles
- `UserRole.owner`: Can manage everything (users, locations, any company property).
- `UserRole.broker`: Can manage locations and their own properties.
- `UserRole.collector`: Restricted to creating and viewing company-scoped properties they created.

### Creator Full Access (Absolute Rule)
- Function: `isCreatorWithFullAccess`
- Rule: If `property.createdBy == userId`, the user has full access to hidden details (images, phone, security number).
- UI Impact: The user should **never** see "Request" buttons or locked placeholders for their own properties.

## 4. Notifications / Access Request Flow

### Target User ID
- Access requests include a `targetUserId` (usually the property owner or the assigned broker).
- Only the `targetUserId` or the property creator (if applicable) can act on the request.

### Visibility Logic (`NotificationsView`)
- Buttons (Accept/Reject) are shown if:
  1. `canAcceptRejectAccessRequests(role)` is true (Owner or Broker).
  2. `currentUserId == notification.targetUserId`.
  3. `currentUserId != notification.requesterId` (Cannot accept own requests).

### Access Flow End-to-End
1. User A requests access to Property B (owned by User B).
2. User B receives a notification with `targetUserId == User B`.
3. User B sees Accept/Reject buttons.
4. User B clicks Accept -> Access request status in Firestore updates to `accepted`.
5. User A opens Property B detail -> Hidden fields (phone, images, etc.) are now unlocked via `canView...` checks.

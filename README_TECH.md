# README (Technical)

## 1) Tech Stack
- Flutter (mobile UI)
- Clean Architecture
- flutter_bloc (Cubit) for state management
- Firebase: Auth, Firestore, Storage, Messaging
- GoRouter for navigation/routing
- pull_to_refresh (SmartRefresher) for pagination/refresh
- liquid_glass_renderer for glass effects

## 2) Architecture Overview
- Feature-based structure to keep related data/domain/presentation code together.
- `core/` holds cross-cutting pieces (theme, routing, auth wiring, loaders, shared widgets).
- Layers per feature: data (remote sources, DTOs, repositories), domain (entities, rules, interfaces), presentation (widgets, cubits).
- Clean Architecture chosen to keep business rules testable, isolate Firebase concerns, and allow future platform changes without rewriting UI or rules.

## 3) Folder Structure
- `core/`: shared UI components, routing, theme, auth glue, loader, animations, utilities.
- `features/`: each feature owns its data/domain/presentation code (auth, properties, categories, notifications, settings, users, location, access_requests).
- Shared logic: `core/` (components, loaders, animations, theme) and feature-level domain/repository interfaces.
- Business logic lives in domain/repository layers; UI lives in presentation widgets/pages and cubits.

## 4) State Management
- BLoC/Cubit chosen for predictable streams, testability, and separation from widgets.
- Cubits emit loading/error/success states; views react via `BlocBuilder`/`BlocConsumer`.
- Use `LoadingDialog.show(context, future)` for blocking async flows (auth, uploads, requests, PDF, archive/delete).

## 5) Navigation
- GoRouter configured in `core/routes/app_router.dart`.
- Auth guard via `AuthRepository` notifier; redirects unauthenticated users to login.
- Role-based access enforced at feature level (e.g., owner-only settings/actions).
- Shell navigation with bottom navigation (Home/Properties, Categories, Settings).

## 6) Data & Cost Optimization
- Firestore pagination uses cursor-based queries (`startAfterDocument`) and `limit`; no offset queries.
- Lazy loading of list data; image lists use incremental reveal.
- Images compressed and resized before upload to reduce transfer/storage.
- Avoid unnecessary real-time listeners; listeners are scoped (e.g., single access-request streams).

## 7) Security & Permissions (Logic Level)
- Role-based permissions (owner, collector, broker) enforced in repositories/domain helpers.
- Property assignment rules: owner can assign to all or specific; others can modify when creator or assigned.
- Temporary access for phone/images via request/approve flow; status checked before reveal.
- Logic-level checks back UI checks so permissions are not bypassable by UI-only changes.

## 8) Notifications System
- Access request flow: employees/brokers request; owner accepts/rejects.
- Accept/Reject handled in notifications page with blocking loaders and optimistic state update.
- Foreground notification dialog for owners; notifications page lists requests with pagination.

## 9) Coding Standards
- Naming: meaningful, feature-scoped; avoid abbreviations.
- No business logic in UI widgets; keep it in cubits/domain/repositories.
- Use clear abstractions; avoid duplication of widgets/components.
- Errors surfaced via Failure/Exception mapping; user messaging handled in UI layer.
- No hard-coded strings or colors in logic; prefer theme/config.

## 10) Running the Project
- Prereqs: Flutter SDK installed; platform toolchains set up.
- Firebase init: configure platform Firebase apps (Android/iOS/web) with proper `google-services`/`GoogleService-Info` and options; keep keys/secrets out of source control.
- Install dependencies: `flutter pub get`.
- Run: `flutter run` (choose platform); ensure Firebase configs are present for the target.

## 11) Notes for Future Developers
- Add new features under `features/<new_feature>/` with data/domain/presentation layers.
- New filters: extend filter models and queries in repositories; update UI sheets/pages that consume filters.
- New notification types: extend notification models and cubit handling; add UI rendering and actions as needed.
- Firebase services in use: Auth, Firestore, Storage, Messaging. App Distribution is for internal testers only; no production store release expected.
- User management is client-only: owners create users via `FirebaseAuth.createUserWithEmailAndPassword`, then the client signs the new user out and re-signs the owner with cached credentials while writing `users/{uid}` (email, name, role, phone, active, createdAt, updatedAt) in Firestore.
- No backend Cloud Functions are required/used in this codebase; keep client-only Firebase usage aligned with current services.

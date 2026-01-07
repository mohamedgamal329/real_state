# Real State App (Non-Technical Guide)

## 1) Project Overview
- A secure internal app for the company owner and employees to track and manage properties found on the ground.
- Not for the public or guests.
- Keeps property details, photos, and access requests in one place to speed up decisions.

## 2) User Roles
- Owner: Full control. Adds, edits, archives, or removes properties, decides who can see phone numbers or images, and approves or rejects requests.
- Collector: Finds and records properties. Can add details and photos, and update properties they created or were assigned.
- Broker: Works with listed properties. Can update properties they created or were assigned. (Same behavior as collectors for now, but roles stay separate.)

## 3) Main Features
- Add and manage properties with rooms, kitchens, floors, pools, price, and area.
- Upload multiple images and choose a cover image.
- Hide owner phone number and images when needed.
- Request access to phone numbers or images with an optional message.
- Owner can approve or reject requests.
- Notifications with quick actions.
- Browse by categories and filter by area, price, rooms, and pool.
- Share property details as a PDF without revealing phone numbers.

## 4) Property Lifecycle
- Active: Visible and available for work.
- Archived: Hidden from normal lists but kept for reference.
- Deleted: Soft-deleted; kept out of sight while preserving a record.

## 5) Security & Privacy
- Phone numbers stay hidden by default.
- Images can be hidden until permission is granted.
- Access is temporary and controlled by the owner; leaving the page hides protected data again.

## 6) Application Flow
- Splash screen on launch.
- Login for authorized staff.
- Main app tabs: Home (properties), Categories (filters), Settings (owner tools).

## 7) Future Scalability
- Designed to grow with the business.
- New roles, approvals, and property features can be added safely as needs expand.

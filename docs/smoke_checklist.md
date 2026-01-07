# Smoke Test Checklist

- Login/logout: owner, broker, collector.
- Create company property, edit, archive, delete; counts refresh on Home and area pages.
- Access requests: requester sends phone/images/location; target gets notification & dialog (fg/bg); accept/reject updates; requester gains persistent access.
- Share PDF/images/details from property detail (owner bypass, others per permissions).
- Filters: open bottom sheet, apply filter, results page paginates correctly.
- Broker navigation: Home brokers list → broker areas → broker area properties (pagination).
- Notifications: list loads/refreshes, accept/reject actions work for target, no dialogs for collector.
- Company areas: Home shows areas only, navigation to CompanyAreaPropertiesPage.
- Settings: manage users/locations only visible to owner; collector blocked.

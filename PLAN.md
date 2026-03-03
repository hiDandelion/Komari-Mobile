# Missing Admin Features: komari-web vs Komari Mobile

## Investigation Summary

Compared every admin feature in **komari-web** (`/Volumes/Work/komari-web/src/pages/admin/`) against **Komari Mobile** (`/Volumes/Work/Komari-Mobile/Komari Mobile/`). Features are listed by priority tier (mobile-appropriate first, then desktop-oriented).

---

## Legend

- **In Mobile**: Feature exists in Komari Mobile
- **API Ready**: AdminHandler.swift already has the API call but no UI
- **Missing**: Neither API nor UI exists

---

## 1. Add Server/Node — MISSING

**Web:** `/admin` index page, "Add" button
**API:** `POST /api/admin/client/add` with `{ name: string }`
**Web details:** Simple dialog with name input, creates new node and generates installation command.

**What to implement:**
- Add button in ServerListView toolbar
- Sheet/dialog with name input
- On success, show the new node's token for agent installation
- Generate installation commands for Linux/Windows/macOS (with options: disable web SSH, disable auto-update, ignore unsafe certs, memory include cache, GitHub proxy, custom install dir, custom service name, NIC include/exclude, mount points, monthly network reset)

**API to add:** `AdminHandler.addClient(name:)` → `POST /api/admin/client/add`
**Models needed:** Response returns newly created `NodeData` with token

---

## 2. Edit Server/Node — API READY, NO UI

**Web:** `/admin` index page, edit dialog per node
**API:** `POST /api/admin/client/{uuid}/edit` — already in `AdminHandler.editClient(uuid:changes:)`
**Web details:** Full edit form with fields:
- Name
- Token (read-only display)
- Tags (comma-separated)
- Group
- Private Remark
- Public Remark
- Hidden toggle
- Traffic Limit (bytes) + Traffic Limit Type (sum/max/min/up/down)
- Billing: Price, Billing Cycle (monthly/quarterly/semi-annual/annual/biennial/triennial/quinquennial/one-time), Currency, Expiration Date, Auto-renewal toggle

**What to implement:**
- Edit button/context menu in server detail view or server card
- Sheet with form fields matching the web edit dialog
- Save calls existing `AdminHandler.editClient(uuid:changes:)`

---

## 3. Reorder Servers — API READY, NO UI

**Web:** Drag-and-drop reorder on `/admin` index
**API:** `POST /api/admin/client/order` — already in `AdminHandler.reorderClients(uuids:)`
**Web details:** Drag nodes to reorder, sends `{ uuid: index }` mapping.

**What to implement:**
- Edit mode in ServerListView with drag handles
- Use SwiftUI `onMove` or `EditButton` pattern
- On reorder, call `AdminHandler.reorderClients(uuids:)`

---

## 4. Ping Task Management — MISSING

**Web:** `/admin/ping` — full CRUD for ping monitoring tasks
**API endpoints:**
- `POST /api/admin/ping/add` — `{ name, type, target, clients: [uuid...], interval }`
- `POST /api/admin/ping/edit` — same params + `{ id }`
- `POST /api/admin/ping/delete` — `{ id }`

**Web details:**
- Dual view: Task View (organized by task) and Server View (organized by server)
- Ping types: ICMP, TCP, HTTP
- Target: IP/hostname/URL depending on type
- Interval: seconds between pings
- Client selection: multi-select which nodes perform the ping
- Disk usage estimation calculator

**What to implement:**
- New "Ping Tasks" section (in settings or as admin tab)
- List all ping tasks with name, type, target, interval, assigned clients
- Add task sheet: name, type picker, target, interval, multi-select clients
- Edit task sheet (same form, pre-filled)
- Swipe-to-delete
- Models: `PingTask` struct for CRUD
- API: `AdminHandler.addPingTask(...)`, `AdminHandler.editPingTask(...)`, `AdminHandler.deletePingTask(...)`

---

## 5. Load Alert Notifications — MISSING

**Web:** `/admin/notification/load` — alert rules for CPU/Memory/Disk thresholds
**API endpoints:**
- `POST /api/admin/notification/load/add` — `{ name, metric, threshold, ratio, interval, uuid (node) }`
- `POST /api/admin/notification/load/edit` — same params + `{ id }`
- `POST /api/admin/notification/load/delete` — `{ id }`

**Web details:**
- Table of alert rules with: Name, Server, Metric (cpu/memory/disk), Threshold (%), Ratio, Interval
- Add/edit dialog with all fields + node selector
- Delete with confirmation

**What to implement:**
- New "Load Alerts" section (in notification settings)
- List existing alerts
- Add/edit sheet with: name, metric picker, threshold slider/field, ratio, interval, node selector
- Swipe-to-delete
- Models: `LoadAlert` struct
- API: `AdminHandler.addLoadAlert(...)`, `AdminHandler.editLoadAlert(...)`, `AdminHandler.deleteLoadAlert(...)`

---

## 6. Offline Notification Settings — MISSING

**Web:** `/admin/notification/offline` — configures notifications when servers go offline
**API:** `POST /api/admin/notification/offline/edit` — `{ enable, cooldown, grace_period }`

**Web details:**
- Enable/disable toggle
- Grace period (seconds before triggering notification)
- Cooldown (milliseconds between repeated notifications, default 3000)
- Per-node configuration toggles

**What to implement:**
- "Offline Notifications" section in settings
- Toggle, grace period field, cooldown field
- Per-node enable/disable list
- API: `AdminHandler.editOfflineNotification(...)`

---

## 7. Notification Provider Settings — MISSING

**Web:** `/admin/settings/notification` — configure how notifications are sent
**API endpoints:**
- `GET /api/admin/settings/message-sender` — list available providers
- `GET /api/admin/settings/message-sender?provider={name}` — get provider config
- `POST /api/admin/settings/message-sender` — save provider config
- `POST /api/admin/test/sendMessage` — test message

**Web details:**
- Provider selector (e.g., Telegram, Discord, email, webhook, etc.)
- Dynamic form fields based on selected provider
- Enable/disable toggle
- Custom notification template
- Test message button

**What to implement:**
- "Notification Provider" section in settings
- Provider picker
- Dynamic form (each provider has different fields)
- Test button
- API: `AdminHandler.getMessageSenders()`, `AdminHandler.saveMessageSender(...)`, `AdminHandler.testMessage()`

---

## 8. Remote Command Execution — MISSING

**Web:** `/admin/exec` — execute shell commands on selected nodes
**API endpoints:**
- `POST /api/admin/task/exec` — `{ command, clients: [uuid...] }`
- `GET /api/admin/task/{taskId}/result` — poll for results

**Web details:**
- Command input field
- Multi-select node picker
- Execute button
- Real-time result polling (every 2s, timeout 60s)
- Per-node status display: running/success/failed/timeout
- Exit code + output display per node
- Copy output to clipboard

**What to implement:**
- New "Remote Exec" view (admin section)
- Command text field
- Node multi-selector
- Execute with progress
- Poll results with timer
- Display output per node with exit status
- Models: `ExecTask`, `ExecResult`
- API: `AdminHandler.execTask(command:clients:)`, `AdminHandler.getTaskResult(taskId:)`

---

## 9. Session Management — MISSING

**Web:** `/admin/sessions` — view and manage login sessions
**API endpoints:**
- `GET /api/admin/session/get` — returns `{ current, data: [...] }`
- `POST /api/admin/session/remove` — `{ session: id }`
- `POST /api/admin/session/remove/all`

**Web details:**
- List of all active sessions with: session ID, user agent (parsed), IP, latest IP, login method, created time, last online, expiration
- Highlight current session
- Delete individual session
- "Logout everywhere" button to remove all other sessions
- Auto-logout if current session is deleted

**What to implement:**
- New "Sessions" view (in settings/account)
- Session list with details
- Swipe-to-delete individual sessions
- "Revoke all" button
- Models: `SessionInfo` struct
- API: `AdminHandler.getSessions()`, `AdminHandler.removeSession(id:)`, `AdminHandler.removeAllSessions()`

---

## 10. Account Management — MISSING

**Web:** `/admin/account` — manage admin account
**API endpoints:**
- `POST /api/admin/update/user` — `{ uuid, username }` or `{ uuid, password }`
- `GET /api/admin/2fa/generate` — get QR code for TOTP setup
- `GET /api/admin/2fa/enable?code={code}` — verify and enable 2FA
- `POST /api/admin/2fa/disable` — disable 2FA
- `GET /api/admin/oauth2/bind` — initiate OAuth2 binding (redirect)
- `POST /api/admin/oauth2/unbind` — unbind OAuth2 provider

**Web details:**
- Update Username section with save button
- Change Password section (min 8 chars, must contain uppercase+lowercase+digits, confirm match, auto-logout on change)
- 2FA section: generate QR code, enter code to enable, disable button
- OAuth2 section: bind/unbind SSO providers (GitHub, Google, GitLab, Discord, etc.)

**What to implement:**
- "Account" view in settings
- Username edit
- Password change form with validation
- 2FA toggle with QR code display and code verification
- OAuth2 bind/unbind (open in Safari)
- API: `AdminHandler.updateUser(...)`, `AdminHandler.generate2FA()`, `AdminHandler.enable2FA(code:)`, `AdminHandler.disable2FA()`, `AdminHandler.unbindOAuth2()`

---

## 11. Activity/Audit Logs — MISSING

**Web:** `/admin/logs` — paginated audit log viewer
**API:** `GET /api/admin/logs?limit={limit}&page={page}` — returns `{ data: { logs: [...], total } }`

**Web details:**
- Paginated table: ID, IP, UUID, Message Type, Message, Timestamp
- Click on ID to view full log entry details
- Configurable page size (1-100)

**What to implement:**
- "Logs" view (in settings/admin section)
- Paginated list with pull-to-refresh
- Log entry detail view
- Models: `AuditLog` struct
- API: `AdminHandler.getLogs(limit:page:)`

---

## 12. General Settings — MISSING

**Web:** `/admin/settings/general`
**API endpoints:**
- `POST /api/admin/update/mmdb` — update GeoIP database
- `GET /api/admin/test/geoip?ip={ip}` — test GeoIP lookup

**Web details:**
- GeoIP: enable/disable, provider selection (MaxMind MMDB, ip-api.com, geojs.io, ipinfo.io), update database, test IP lookup
- Recording: enable/disable record collection, load record preserve time (hours), ping record preserve time (hours), expected disk usage calculator

**What to implement:**
- "General Settings" view
- GeoIP toggle + provider picker + update button + test field
- Recording toggle + preserve time inputs
- API: `AdminHandler.updateMMDB()`, `AdminHandler.testGeoIP(ip:)`, plus settings save endpoint

---

## 13. Site Settings — MISSING (Low priority for mobile)

**Web:** `/admin/settings/site`
**API endpoints:**
- `GET /api/admin/download/backup` — download backup
- `POST /api/admin/upload/backup` — upload/restore backup (.zip)
- `PUT /api/admin/update/favicon` — upload favicon
- `POST /api/admin/update/favicon` — reset favicon

**Web details:**
- Site name, description, CORS toggle, private site toggle, send IP to guest toggle, script domain
- Custom header/body HTML injection
- Favicon management (upload/reset)
- Backup download/restore

**Mobile considerations:** HTML editing is awkward on mobile. Backup download/upload feasible via Files.app. Basic fields (name, description, toggles) are straightforward.

---

## 14. SSO/OIDC Settings — MISSING (Low priority for mobile)

**Web:** `/admin/settings/sign-on`
**API endpoints:**
- `GET /api/admin/settings/oidc` — get available providers
- `GET /api/admin/settings/oidc?provider={name}` — get provider config
- `POST /api/admin/settings/oidc` — save provider config

**Web details:**
- Disable password login toggle
- SSO provider selection, enable/disable
- Dynamic provider config fields (client ID, secret, scopes, URLs)
- Callback URL display

**Mobile considerations:** Complex configuration forms. Useful for initial setup but rarely changed. Could be simplified version.

---

## 15. Theme Management — MISSING (Low priority for mobile)

**Web:** `/admin/settings/theme`
**API endpoints:**
- `GET /api/admin/theme/list`
- `PUT /api/admin/theme/upload` (.zip)
- `GET /api/admin/theme/set?theme={short}`
- `POST /api/admin/theme/update`
- `POST /api/admin/theme/delete`

**Mobile considerations:** Theme upload requires .zip file handling. Could implement list + set active + delete. Upload less practical on mobile.

---

## Priority Summary

| # | Feature | Priority | Complexity |
|---|---------|----------|------------|
| 1 | Add Server | High | Medium |
| 2 | Edit Server | High | Medium |
| 3 | Reorder Servers | High | Low |
| 4 | Ping Task Management | High | Medium |
| 5 | Load Alert Notifications | High | Medium |
| 6 | Offline Notification Settings | Medium | Low |
| 7 | Notification Provider Settings | Medium | High |
| 8 | Remote Command Execution | Medium | Medium |
| 9 | Session Management | Medium | Low |
| 10 | Account Management | Medium | Medium |
| 11 | Activity Logs | Low | Low |
| 12 | General Settings | Low | Medium |
| 13 | Site Settings | Low | High |
| 14 | SSO/OIDC Settings | Low | High |
| 15 | Theme Management | Low | Medium |

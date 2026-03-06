# Komari Mobile — Admin Feature Parity with komari-web

## Overview

This document maps every admin page in **komari-web** (sidebar menu structure from `menuConfig.json`) to its implementation status in **Komari Mobile**. The goal is to replicate komari-web's admin structure in the mobile app's Settings tab.

---

## komari-web Admin Sidebar Structure

```
Server (/admin)                         → Servers tab (fully implemented)

Settings (/admin/settings)
├── Site Settings (/settings/site)
├── Theme (/settings/theme)
├── Sign-On / SSO (/settings/sign-on)
├── Notification Provider (/settings/notification)
└── General Settings (/settings/general)

Notifications (/admin/notification)
├── Offline Notifications (/notification/offline)
├── Load Notifications (/notification/load)
└── General Notifications (/notification/general)

Exec (/admin/exec)
Ping Task (/admin/ping)
Sessions (/admin/sessions)
Account (/admin/account)
Logs (/admin/logs)
```

---

## Current Komari Mobile Settings Structure

```
Settings tab
├── App Settings
│   └── Dashboard Settings              ✅ Implemented
├── Dashboard Administration
│   ├── Ping Tasks                      ✅ Implemented
│   ├── Load Alerts                     ✅ Implemented
│   └── Offline Notifications           ✅ Implemented
└── About
    ├── User Guide (link)               ✅ Implemented
    └── Acknowledgments                 ✅ Implemented
```

---

## Proposed Komari Mobile Settings Structure (matching komari-web)

```
Settings tab
├── App Settings
│   └── Dashboard Settings              ✅ Implemented
│
├── Settings (mirrors /admin/settings)
│   ├── Site Settings                   ❌ Missing (#13)
│   ├── Theme                           ❌ Missing (#15) — Low priority
│   ├── Sign-On / SSO                   ❌ Missing (#14) — Low priority
│   ├── Notification Provider           ❌ Missing (#7)
│   └── General Settings                ❌ Missing (#12)
│
├── Notifications (mirrors /admin/notification)
│   ├── Offline Notifications           ✅ Implemented
│   ├── Load Alerts                     ✅ Implemented
│   └── General Notifications           ✅ Implemented
│
├── Administration
│   ├── Ping Tasks                      ✅ Implemented
│   ├── Remote Exec                     ✅ Implemented
│   ├── Sessions                        ✅ Implemented
│   ├── Account                         ✅ Implemented
│   └── Logs                            ✅ Implemented
│
└── About
    ├── User Guide (link)               ✅ Implemented
    └── Acknowledgments                 ✅ Implemented
```

---

## Feature Details

### ✅ IMPLEMENTED

#### Ping Tasks
- **View:** `PingTasksView.swift`
- **API:** `AdminHandler.getPingTasks()`, `addPingTask()`, `editPingTask()`, `deletePingTasks()`
- **Model:** `PingTask` in `PingTaskResponse.swift`
- Full CRUD with ICMP/TCP/HTTP types, client selector, swipe actions

#### Load Alerts
- **View:** `LoadAlertsView.swift`
- **API:** `AdminHandler.getLoadAlerts()`, `addLoadAlert()`, `editLoadAlert()`, `deleteLoadAlerts()`
- **Model:** `LoadAlert` in `LoadAlertResponse.swift`
- Full CRUD with 5 metrics (CPU/RAM/Disk/Net In/Net Out), threshold, ratio, interval

#### Offline Notifications
- **View:** `OfflineNotificationsView.swift`
- **API:** `AdminHandler.getOfflineNotifications()`, `editOfflineNotifications()`
- **Model:** `OfflineNotification` in `OfflineNotificationResponse.swift`
- Per-node enable/disable + grace period configuration

#### General Notifications
- **View:** `GeneralNotificationsView.swift`
- **API:** `AdminHandler.getSettings()`, `AdminHandler.updateSettings(changes:)`
- **Model:** `DashboardSettings` in `SettingsResponse.swift`
- Expiration notification toggle + lead days, login notification toggle, traffic alert percentage

#### Sessions
- **View:** `SessionsView.swift`
- **API:** `AdminHandler.getSessions()`, `AdminHandler.removeSession(session:)`, `AdminHandler.removeAllSessions()`
- **Model:** `SessionInfo` in `SessionResponse.swift`
- Session list with current session badge, IP addresses, login method, timestamps
- Swipe-to-delete individual sessions, "Revoke All" toolbar button with confirmation

#### Server Management (Servers tab, not Settings)
- Add Server + install command generation
- Edit Server (name, tags, group, remarks, billing, traffic limit)
- Delete Server
- Reorder Servers

---

### ❌ MISSING FEATURES

---

#### #6b. General Notifications — IMPLEMENTED

**Web:** `/admin/notification/general` — global notification toggles
**API:** `GET /api/admin/settings` + `POST /api/admin/settings` (shared settings endpoint)

**Web details:**
- Expiration Notification: enable/disable toggle + lead days (how many days before expiration to notify)
- Login Notification: enable/disable toggle (notify on admin login)
- Traffic Alert: threshold percentage (notify when traffic reaches X% of limit)

**What to implement:**
- New "General" item in Notifications section
- Toggle for expiration notification + lead days number field
- Toggle for login notification
- Number field for traffic alert percentage
- API: `AdminHandler.getSettings()` (shared), `AdminHandler.updateSettings(changes:)` (shared)

**Complexity:** Low

---

#### #7. Notification Provider Settings — MISSING

**Web:** `/admin/settings/notification` — configure how notifications are delivered
**API:**
- `GET /api/admin/settings/message-sender` — list available providers
- `GET /api/admin/settings/message-sender?provider={name}` — get provider config
- `POST /api/admin/settings/message-sender` — save provider config
- `POST /api/admin/test/sendMessage` — test notification delivery

**Web details:**
- Provider selector (e.g., Telegram, Discord, email, webhook, Bark, Gotify, etc.)
- Dynamic form fields based on selected provider (each has different config: bot token, chat ID, webhook URL, etc.)
- Enable/disable toggle
- Custom notification template
- Test message button

**What to implement:**
- New "Notification Provider" item in Settings section
- Provider picker
- Dynamic form fields per provider
- Enable/disable toggle
- Test message button
- API: `AdminHandler.getMessageSenders()`, `AdminHandler.getMessageSenderConfig(provider:)`, `AdminHandler.saveMessageSender(config:)`, `AdminHandler.testMessage()`

**Complexity:** High (dynamic forms per provider)

---

#### #8. Remote Command Execution — IMPLEMENTED

**View:** `RemoteExecView.swift`
**API:** `AdminHandler.execTask(command:clients:)`, `AdminHandler.getTaskResult(taskId:)`
**Model:** `ExecTaskData`, `ExecResult`, `ExecClientInfo` in `ExecResponse.swift`
- Command input field (monospaced, multi-line)
- Multi-select node picker with Select All/Deselect All
- Execute button in toolbar with progress indicator
- Real-time result polling (every 2s, 60s timeout)
- Per-node result display with color-coded status badges (running/success/failed/timeout)
- Exit code + monospaced output display with text selection
- Controls disabled during execution/polling
- Polling auto-cancels on view disappear

**Complexity:** Medium

---

#### #9. Session Management — IMPLEMENTED

**Web:** `/admin/sessions` — view and manage login sessions
**API:**
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
- "Sessions" item in Administration section
- Session list with details (IP, login method, timestamps)
- Current session badge
- Swipe-to-delete individual sessions
- "Revoke All" button
- Models: `SessionInfo`
- API: `AdminHandler.getSessions()`, `AdminHandler.removeSession(id:)`, `AdminHandler.removeAllSessions()`

**Complexity:** Low

---

#### #10. Account Management — IMPLEMENTED

**View:** `AccountView.swift`
**API:** `AdminHandler.updateUsername(uuid:username:)`, `AdminHandler.updatePassword(uuid:password:)`, `AdminHandler.generate2FA()`, `AdminHandler.enable2FA(code:)`, `AdminHandler.disable2FA()`, `AdminHandler.unbindOAuth2()`
**Model:** Uses `MeResponseData` from `MeResponse.swift`
- Username section: edit + save with min 3 chars validation
- Password section: change form with validation (min 8 chars, uppercase+lowercase+digits, confirm match)
- 2FA section: status badge, enable via QR code sheet (scan + 6-digit OTP), disable with confirmation alert
- OAuth2 section: shows bound provider name + ID, unbind with confirmation alert
- Success/error inline messages per section
- Auto-refreshes account data after each change

**Complexity:** Medium

---

#### #11. Activity/Audit Logs — IMPLEMENTED

**View:** `LogsView.swift`
**API:** `AdminHandler.getLogs(limit:page:)`
**Model:** `AuditLog`, `LogsData` in `LogResponse.swift`
- Paginated list with prev/next controls (20 per page)
- Log rows show type badge, message (2-line truncated), IP, timestamp
- Tap row to open detail sheet with full log info (ID, IP, UUID, Type, Message, Time)
- Text selection enabled in detail view
- Color-coded type badges (login=blue, error=red, warning=orange)

**Complexity:** Low

---

#### #12. General Settings — MISSING

**Web:** `/admin/settings/general`
**API:**
- `POST /api/admin/update/mmdb` — update GeoIP database
- `GET /api/admin/test/geoip?ip={ip}` — test GeoIP lookup
- `GET/POST /api/admin/settings` — shared settings (recording toggles, preserve times)

**Web details:**
- GeoIP: enable/disable, provider selection (MaxMind MMDB, ip-api.com, geojs.io, ipinfo.io), update database, test IP lookup
- Recording: enable/disable record collection, load record preserve time (hours), ping record preserve time (hours)

**What to implement:**
- "General" item in Settings section
- GeoIP toggle + provider picker + update button + test field
- Recording toggle + preserve time inputs
- API: `AdminHandler.updateMMDB()`, `AdminHandler.testGeoIP(ip:)`, plus shared settings

**Complexity:** Medium

---

#### #13. Site Settings — MISSING

**Web:** `/admin/settings/site`
**API:**
- `GET/POST /api/admin/settings` — shared settings
- `GET /api/admin/download/backup` — download backup
- `POST /api/admin/upload/backup` — upload/restore backup (.zip)
- `PUT /api/admin/update/favicon` — upload favicon
- `POST /api/admin/update/favicon` — reset favicon

**Web details:**
- Site name, description
- CORS toggle, private site toggle, send IP to guest toggle, script domain
- Custom header/body HTML injection
- Favicon management (upload/reset)
- Backup download/restore

**Mobile considerations:** HTML editing (custom head/body) is awkward on mobile. Backup download/upload feasible via Files.app. Basic fields (name, description, toggles) are straightforward.

**What to implement:**
- "Site Settings" item in Settings section
- Basic fields: site name, description, toggles (CORS, private, send IP)
- Script domain field
- Backup download/restore (share sheet for download, document picker for upload)
- Favicon: skip or simple upload from photo library
- Skip custom HTML fields or provide basic text editor

**Complexity:** High (backup handling, favicon, HTML fields)

---

#### #14. SSO/OIDC Settings — MISSING (Low priority)

**Web:** `/admin/settings/sign-on`
**API:**
- `GET /api/admin/settings/oidc` — get available providers
- `GET /api/admin/settings/oidc?provider={name}` — get provider config
- `POST /api/admin/settings/oidc` — save provider config

**Web details:**
- Disable password login toggle
- SSO provider selection, enable/disable
- Dynamic provider config fields (client ID, secret, scopes, URLs)
- Callback URL display

**Mobile considerations:** Complex configuration forms, rarely changed after initial setup.

**Complexity:** High

---

#### #15. Theme Management — MISSING (Low priority)

**Web:** `/admin/settings/theme`
**API:**
- `GET /api/admin/theme/list`
- `PUT /api/admin/theme/upload` (.zip)
- `GET /api/admin/theme/set?theme={short}`
- `POST /api/admin/theme/update`
- `POST /api/admin/theme/delete`

**Mobile considerations:** Theme upload requires .zip file handling. Only affects the web dashboard, not the mobile app. Very low priority.

**Complexity:** Medium

---

## Implementation Priority

| # | Feature | Section | Priority | Complexity | Status |
|---|---------|---------|----------|------------|--------|
| — | Ping Tasks | Administration | — | — | ✅ Done |
| — | Load Alerts | Notifications | — | — | ✅ Done |
| — | Offline Notifications | Notifications | — | — | ✅ Done |
| 6b | General Notifications | Notifications | High | Low | ✅ Done |
| 9 | Sessions | Administration | High | Low | ✅ Done |
| 11 | Logs | Administration | High | Low | ✅ Done |
| 8 | Remote Exec | Administration | High | Medium | ✅ Done |
| 10 | Account | Administration | Medium | Medium | ✅ Done |
| 12 | General Settings | Settings | Medium | Medium | ❌ Missing |
| 7 | Notification Provider | Settings | Medium | High | ❌ Missing |
| 13 | Site Settings | Settings | Low | High | ❌ Missing |
| 14 | SSO/OIDC | Settings | Low | High | ❌ Missing |
| 15 | Theme | Settings | Low | Medium | ❌ Missing |

---

## Shared API: Settings Endpoint

Several features (#6b, #12, #13) share the same settings API:
- `GET /api/admin/settings` → returns all dashboard settings as a flat object
- `POST /api/admin/settings` → partial update, merge changed keys

Settings keys used across features:
- **General Notifications (#6b):** `expire_notification_enabled`, `expire_notification_lead_days`, `login_notification`, `traffic_limit_percentage`
- **General Settings (#12):** `geo_ip_enabled`, `geo_ip_provider`, `record_enabled`, `load_record_preserve_time`, `ping_record_preserve_time`
- **Site Settings (#13):** `sitename`, `description`, `allow_cors`, `private_site`, `send_ip_to_guest`, `script_domain`, `custom_head`, `custom_body`

Implement `AdminHandler.getSettings()` and `AdminHandler.updateSettings(changes:)` once, reuse across all three views.

# RFQ Marketplace Client (Flutter)

Flutter client for the RFQ Marketplace module:
- Users create requests
- Companies browse requests and submit quotations
- Users accept/reject quotations
- Notifications list + unread/read
- Realtime banner notifications via WebSocket (Centrifugo)

> This repo contains the Flutter client. Backend is in a separate Yii2 service repo.

---

## Tech Stack
- **Flutter** (Web + Android APK)
- **State Management / Navigation:** GetX (`GetMaterialApp`)
- **REST:** HTTP client
- **Auth:** JWT (stored in secure storage)
- **Realtime:** WebSocket (Centrifugo)
- **Architecture:** Clean-ish structure (`app/`, `core/`, `features/`, `requests/`, `notifications/`, `quotations/`, `shared/`)

---

## Features
### Landing
- Landing page is the first screen (Pinterest-style)
- Category cards open Explore page
- Top-right buttons: login user/company, sign up
- After login/register, user returns to landing and can navigate to actions (My Requests / Create Request / Browse Requests)

### Auth (User / Company)
- Register as user/company (role toggle inside sign up form)
- Login with role enforcement (company login vs user login)
- JWT saved to secure storage
- Session state stored in `Session` (userId, role, name)

### Requests
- Users: create request, list “My Requests”, view details
- Companies: browse available open requests (based on server rules)

### Quotations
- Companies: submit quotation
- Users: view quotations for their requests, accept/reject (server-controlled)
- “Quote” flow from Explore redirects to Company login if needed

### Notifications
- List notifications
- Unread toggle
- Mark as read
- Badge-style behavior: unread list changes after marking read

### Realtime (WebSocket banners)
- WebSocket connection to Centrifugo
- In-app banner when events arrive (request/quotation notifications)

---

## Project Structure

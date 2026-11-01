# 💰 Chindi (चिंदी) - Doston Ke Beech Har Sikke Ka Saaf Hisaab

> **"Doston ke beech har sikke ka saaf hisaab"**  
> A full-stack, chat-first expense splitting mobile app built with **Flutter** and **Node.js / Express / Socket.io / MongoDB**, featuring **30-Day Hisaab Cycles**, **Zero-Sum Integer Paise Precision**, **Minimum Transaction Settlements**, and **Firebase Cloud Messaging (FCM)** push notifications.

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Project Architecture](#-project-architecture)
- [Calculation & Settlement Engine](#-calculation--settlement-engine)
- [Push Notifications & Firebase Setup](#-push-notifications--firebase-setup)
- [Error Handling & Resilience](#-error-handling--resilience)
- [Quick Start Guide](#-quick-start-guide)
  - [Backend Setup](#1-backend-server-setup)
  - [Demo User Credentials](#2-demo-user-credentials)
  - [Flutter App Setup](#3-flutter-mobile-app-setup)
- [API Reference](#-api-reference)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Design System & Theme](#-design-system--theme)

---

## 🌟 Overview

Traditional expense splitting apps feel like sterile accounting spreadsheets. **Chindi** reinvents group finances around the natural way friends interact: **chat**.

Whether you're sharing a flat, planning a Goa trip, or splitting daily chai and lunch:
1. Create or join a group with a quick 6-character code (e.g. `FLAT02`).
2. Chat, send messages, and log expenses directly in the stream with interactive expense cards.
3. Track active 30-day billing cycles with live "Kul Lena Baaki" and "Kul Dena Baaki" balances.
4. Auto-settle at the end of 30 days (or close early) with minimum debt transactions between friends.

---

## ✨ Key Features

* **💬 Chat-First Expense Logging**: Expenses appear as rich cards inline with messages. Members can see who paid, total amount, and their personal share.
* **🚫 Flexible Exclusion Chips**: Exclude specific friends from an expense (e.g., non-drinkers from dinner, vegetarian lunch) with a single tap.
* **🪙 Exact Integer Paise Math (No Floating-Point Errors)**: All finances operate on whole integer paise ($1 = 100\text{ paise}$). Indivisible amounts (e.g., ₹145 among 3 people) distribute remaining paise without a single paisa lost.
* **⚖️ Strict Zero-Sum Guarantee**: In any cycle, the sum of all net balances across all group members is mathematically guaranteed to equal zero ($\sum \text{netPaise} \equiv 0$).
* **🤝 Minimum Transactions Debt Settlement**: Uses a greedy two-pointer debtor-creditor algorithm to settle all group debts with the fewest possible money transfers.
* **📅 30-Day Hisaab Cycles**: Automatic cycle tracking (`Din X / 30`) with automated midnight rollover via `node-cron`, early cycle closure by admin, and past cycle history archive.
* **🔔 Push & Heads-Up Notifications**: Integrated with **Firebase Cloud Messaging (FCM)** and **Flutter Local Notifications**. Group members receive instant push notifications when an expense is added or a message is sent.
* **🛡️ Bulletproof Error Handling**: Clear, human-readable error messages for wrong email ("Email not found"), incorrect password ("Email and password is incorrect"), duplicate accounts, validation issues, and offline network connection errors.

---

## 🏗️ Project Architecture

```
app/
├── app/                          # Flutter Mobile Client (Dart 3, Material 3)
│   ├── android/                  # Android native project & Gradle config
│   │   ├── app/
│   │   │   ├── google-services.json # Firebase Android client configuration
│   │   │   └── build.gradle.kts  # App Gradle build (package: com.company.chindi)
│   │   └── settings.gradle.kts   # Plugin management (Google Services 4.4.2)
│   ├── lib/
│   │   ├── core/                 # App configuration, theme, formatters, state views
│   │   │   ├── config/           # AppConfig (API & Socket URLs, dynamic host)
│   │   │   ├── theme/            # Luxury Dark theme (Playfair Display + Inter + Gold)
│   │   │   ├── utils/            # CurrencyFormatter (Indian currency), DateFormatter
│   │   │   └── widgets/          # ChindiLogo, GoldButton, MonogramAvatar, StateViews
│   │   ├── data/                 # Networking, models, and repositories
│   │   │   ├── api/              # ApiClient (Dio with robust error extraction)
│   │   │   ├── models/           # UserModel, GroupModel, ExpenseModel, CycleModel
│   │   │   ├── repositories/     # Auth, Group, Chat, and Cycle repositories
│   │   │   └── services/         # SocketService (WebSockets), NotificationService (FCM)
│   │   ├── features/             # App feature screens & Riverpod state notifiers
│   │   │   ├── auth/             # LoginScreen, SignupScreen, AuthProvider
│   │   │   ├── chat/             # GroupChatScreen, ChatProvider, AddExpenseBar, EditExpense
│   │   │   ├── groups/           # GroupsListScreen, GroupDetailScreen
│   │   │   ├── home/             # HomeScreen, HomeProvider, CreateGroup, JoinGroup
│   │   │   └── report/           # CycleReportScreen, PastCyclesScreen, CycleProvider
│   │   ├── router/               # AppRouter (GoRouter with reactive session guard)
│   │   ├── firebase_options.dart # Generated Firebase options for Android/Web/iOS
│   │   └── main.dart             # App entry point with Firebase initialization
│   ├── test/                     # Unit & widget tests (Currency, ApiClient, Widgets)
│   ├── .gitignore                # Flutter & Android build artifacts exclusions
│   └── pubspec.yaml              # Flutter dependencies and assets
│
└── server/                       # Node.js REST API & Real-time Socket Server
    ├── src/
    │   ├── config/               # Database (Mongoose) & Environment (dotenv)
    │   ├── controllers/          # Auth, Group, Chat, Expense, Cycle controllers
    │   ├── jobs/                 # cycleCron (midnight 30-day auto-closer)
    │   ├── middleware/           # JWT auth, Zod validation, ErrorHandler, GroupMember check
    │   ├── models/               # User, Group, Cycle, Expense, Message schemas
    │   ├── routes/               # Express routes (/auth, /groups, /expenses, /cycles)
    │   ├── seeds/                # Seed script with demo dataset (Ramesh, Suresh, Amit, Priya)
    │   ├── services/             # BalanceService, CycleService, ExpenseService, NotificationService
    │   ├── sockets/              # Socket.io room handlers & real-time broadcasting
    │   ├── tests/                # Jest tests (Calculation suite, Auth suite, Money suite)
    │   └── utils/                # splitPaise, computeSettlements, formatPaise, apiResponse
    ├── .env.example              # Sample environment configuration
    ├── .gitignore                # Node.js node_modules, keys, and logs exclusions
    └── package.json              # Server dependencies and scripts
```

---

## 🪙 Calculation & Settlement Engine

All calculations strictly execute on **integer paise** ($1\text{ Rupee} = 100\text{ Paise}$) to prevent IEEE 754 floating-point errors.

### 1. Equal Split with Exact Penny Conservation
For an expense of $\text{totalPaise}$ split among $n$ participants:
$$\text{baseShare} = \left\lfloor \frac{\text{totalPaise}}{n} \right\rfloor$$
$$\text{remainder} = \text{totalPaise} \pmod n$$

The first $\text{remainder}$ members receive $\text{baseShare} + 1$, and all others receive $\text{baseShare}$.
$$\sum_{i=1}^{n} \text{share}_i \equiv \text{totalPaise}$$

*Example: ₹145 (14500 paise) split among 3 people $\rightarrow$ Shares are ₹48.34, ₹48.33, ₹48.33 (Sum = exactly ₹145.00).*

### 2. Multi-Expense Zero-Sum Balance
For every member in a group cycle:
$$\text{netPaise}_i = \text{paidPaise}_i - \text{sharePaise}_i$$

Because total paid strictly equals total shared across the group:
$$\sum_{i=1}^{m} \text{paidPaise}_i = \sum_{i=1}^{m} \text{sharePaise}_i \implies \sum_{i=1}^{m} \text{netPaise}_i = 0$$

### 3. Minimum Transactions Settlement Algorithm
Settling $m$ members' balances with $m(m-1)$ transfers is inefficient. Chindi matches creditors ($\text{net} > 0$) with debtors ($\text{net} < 0$) using a greedy two-pointer algorithm:
1. Sort creditors descending by amount.
2. Sort debtors descending by absolute debt.
3. In each step, transfer $\min(\text{debtor.amount}, \text{creditor.amount})$.
4. Decrement the settled party and advance the pointer until all balances are zero.

---

## 🔔 Push Notifications & Firebase Setup

The application features full push notification support:

### Client Setup (`app/android/app/google-services.json`):
* Package Name: `com.company.chindi`
* Project ID: `chindi-90259`
* Android Gradle configuration connects via `com.google.gms.google-services` plugin.
* [`DefaultFirebaseOptions`](file:///C:/Users/mohit%20sahu/OneDrive/Desktop/app/app/lib/firebase_options.dart) provides auto-initialization across platforms.

### Notification Flow:
1. **Token Registration**: When a user logs in, their device FCM token is retrieved via `FirebaseMessaging.instance.getToken()` and sent to `POST /api/auth/fcm-token`.
2. **Push Delivery**: When an expense is added or a message is posted, [`notificationService.js`](file:///C:/Users/mohit%20sahu/OneDrive/Desktop/app/server/src/services/notificationService.js) sends a multicast message to all other group members.
3. **Foreground Alert**: If the app is open, an instant high-priority local notification with sound, vibration, and gold coin icon pops up.
4. **Background / Terminated**: Tapping the notification opens the app directly into that group's chat (`/chat/:groupId`).
5. **Token Removal**: On logout, the token is automatically removed from the backend to ensure privacy.

---

## 🛡️ Error Handling & Resilience

Errors are handled cleanly at both the backend and client layers:

| Scenario | Server Response | Client User Feedback |
|---|---|---|
| User email not registered | `404 Not Found` | Error banner: **"Email not found"** |
| Wrong password entered | `401 Unauthorized` | Error banner: **"Email and password is incorrect"** |
| Email already registered on signup | `409 Conflict` | Error banner: **"User with this email or mobile already exists"** |
| Short password (< 6 chars) | `400 Bad Request` | Form message: **"Password must be at least 6 characters"** |
| Backend server unreachable | Connection error | Error view: **"Server se connect nahi ho paya. Kripya check karein ki backend server chal raha hai."** |
| Token expired on auth requests | `401 Unauthorized` | Seamless redirect to login screen without app crash |
| Expense creation error | API Error | In-chat floating SnackBar alert explaining the issue |

---

## 🚀 Quick Start Guide

### Prerequisites
* **Node.js** (v18 or higher) & **npm**
* **Flutter SDK** (v3.13 or higher)
* **MongoDB** (Local instance or MongoDB Atlas cluster)

---

### 1. Backend Server Setup

```bash
# 1. Navigate to the server folder
cd server

# 2. Install dependencies
npm install

# 3. Configure environment
# Copy .env.example to .env and configure your Mongo connection
cp .env.example .env

# 4. Seed demo dataset (Ramesh, Suresh, Amit, Priya with sample groups)
npm run seed

# 5. Run tests to verify setup
npm test

# 6. Start server in development mode
npm run dev
```

*Server will run at: `http://localhost:5000` (Health check: `http://localhost:5000/api/health`).*

---

### 2. Demo User Credentials

The database seeder pre-populates 4 test accounts:

| Name | Email / Identifier | Password | Default Groups |
|---|---|---|---|
| **Ramesh Kumar** | `ramesh@hisaab.app` | `password123` | Flat 302 Roommates (Admin) |
| **Suresh Sharma** | `suresh@hisaab.app` | `password123` | Flat 302, Goa Trip |
| **Amit Verma** | `amit@hisaab.app` | `password123` | Goa Trip (Admin) |
| **Priya Singh** | `priya@hisaab.app` | `password123` | Flat 302 Roommates |

*(💡 Tip: Use any of these demo credentials to log in or create a fresh account from the Signup screen.)*

---

### 3. In-App Update System (Pushing Updates to Users)

Chindi includes an automated In-App Update checking engine:
1. When you release a new app build or APK, simply bump `LATEST_APP_VERSION` and `LATEST_VERSION_CODE` in `server/.env`:
   ```env
   LATEST_APP_VERSION=1.0.1
   LATEST_VERSION_CODE=2
   APP_UPDATE_URL=https://your-domain.com/downloads/chindi-latest.apk
   APP_RELEASE_NOTES=Naye features aur calculations me sudhar kiya gaya hai.
   FORCE_UPDATE=false
   ```
2. Any user opening the app will automatically see an update popup dialog displaying:
   - Version details (e.g. `Aapka: v1.0.0 → Naya: v1.0.1`)
   - Release notes explaining what's new
   - **"ABHI UPDATE KAREIN"** button which immediately opens the download link or new APK.
   - If `FORCE_UPDATE=true` or user's version is below `MIN_REQUIRED_VERSION_CODE`, the dialog is mandatory and prevents using outdated builds until updated.
3. You can also update the version dynamically at runtime via `POST /api/version`.

---

### 4. Flutter Mobile App Setup

```bash
# 1. Navigate to app folder
cd app

# 2. Get packages
flutter pub get

# 3. Run Flutter unit & widget tests
flutter test

# 4. Launch on Android Emulator or Device
flutter run
```

#### Running on Android Emulator:
The emulator automatically maps to host localhost via `http://10.0.2.2:5000/api`.

#### Running on a Physical Phone:
Find your machine's Wi-Fi IP address (e.g. `192.168.1.10`) and launch with:
```bash
flutter run --dart-define=API_URL=http://192.168.1.10:5000/api --dart-define=SOCKET_URL=http://192.168.1.10:5000
```

#### Building Release APK:
```bash
cd app
flutter build apk --release
```
Output: `app/build/app/outputs/flutter-apk/app-release.apk`

---

## 📡 API Reference

### Authentication (`/api/auth`)
* `POST /api/auth/signup` - Register a new user (`name`, `emailOrMobile`, `password`).
* `POST /api/auth/login` - Login (`emailOrMobile`, `password`) $\rightarrow$ returns JWT token & user.
* `GET /api/auth/me` - Get current user profile (requires `Bearer <token>`).
* `POST /api/auth/fcm-token` - Register device push notification token.
* `DELETE /api/auth/fcm-token` - Unregister device push notification token.

### Groups (`/api/groups`)
* `GET /api/groups` - Get user summary across all groups ("Kul lena/dena baaki").
* `POST /api/groups` - Create a new group (`name`) $\rightarrow$ generates 6-character invite code.
* `POST /api/groups/join` - Join an existing group by invite code (`inviteCode`).
* `GET /api/groups/:id` - Get group details, member list, and live balance overview.
* `POST /api/groups/:id/leave` - Leave a group.

### Chat & Expenses (`/api/groups/:id/...`)
* `GET /api/groups/:id/messages` - Paginated chat messages and expense cards.
* `POST /api/groups/:id/messages` - Send a text message.
* `POST /api/groups/:id/expenses` - Create a split expense (`amountPaise`, `description`, `excludedMembers`).
* `PUT /api/groups/:id/expenses/:expenseId` - Edit an expense (amount, description, exclusions).
* `DELETE /api/groups/:id/expenses/:expenseId` - Soft-delete an expense and recalculate cycle balances.

### 30-Day Cycles (`/api/groups/:id/cycles/...`)
* `GET /api/groups/:id/cycles/current` - Live balances, day progress, and settlements for current cycle.
* `GET /api/groups/:id/cycles` - History of all past completed cycles.
* `GET /api/groups/:id/cycles/:cycleId` - Snapshot detail of a specific past cycle.
* `POST /api/groups/:id/cycles/close` - Manually close active cycle early (Admin only).

---

## 🧪 Testing & Quality Assurance

### Server Tests (Jest)
Runs 27 test cases covering the entire money and authentication engine:
```bash
cd server
npm test
```
* `src/tests/calculation.test.js` - Tests indivisible splits, penny conservation, multi-expense cycles, zero-sum guarantees, and settlement minimization.
* `src/tests/auth.test.js` - Tests 404 Email not found, 401 Incorrect password, 409 Duplicate user, and Zod validation messages.
* `src/tests/money.test.js` - Tests low-level integer paise division and formatting.

### Flutter Tests
Runs 11 test cases covering API error conversion, currency formatting, and UI widgets:
```bash
cd app
flutter test
```
* `test/api_client_error_test.dart` - Tests 404, 401, 400 validation error extractions, and network offline exceptions.
* `test/currency_formatter_test.dart` - Tests Indian rupee formatting, sign rendering, and lakh grouping.
* `test/widgets/chip_selector_test.dart` - Tests member exclusion toggles.
* `test/widgets/expense_card_test.dart` - Tests expense card rendering and calculations.

---

## 🎨 Design System & Theme

Chindi is crafted with a bespoke **Luxury Dark Theme**:
* **Background**: `#0C0B09` with a subtle golden radial glow (`#C9A45C` at 12% opacity).
* **Surface**: `#1C1915` (elevated cards: `#25211B`).
* **Gold Accent**: Metallic gold gradient (`#DDBB74` to `#B58E45`).
* **Borders**: Thin hairline dividers (`rgba(201, 164, 92, 0.18)`).
* **Typography**:
  - **Headings & Amounts**: *Playfair Display* serif for classic elegance.
  - **Body & Labels**: *Inter* sans-serif for sharp readability.
* **Status Colors**: Positive credit green (`#8FBF8F`) and Negative debt red (`#D98A7A`).

---

## 📄 License
This project is licensed under the ISC License.

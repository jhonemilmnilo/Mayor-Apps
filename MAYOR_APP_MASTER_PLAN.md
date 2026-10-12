# 🏛️ E-Mapandan Mayor Mobile App: 100% Dashboard Replication Master Plan

> **Objective:** Build a dedicated, executive-grade Flutter mobile app for the Municipal Mayor that **100% matches** the features, data metrics, filters, and layout of the existing Web Mayor Dashboard (`app/mayor/dashboard/page.tsx`).

---

## 📐 System Architecture Overview

```
┌────────────────────────────────────────────────────────┐
│           EMapandan Mayor Mobile App (Flutter)         │
│  - Riverpod State Management                           │
│  - Dio HTTP Client with JWT Interceptors               │
│  - Biometric (FaceID / Fingerprint) Quick Unlock       │
│  - fl_chart for Revenue & Transaction Trends           │
└──────────────────────────┬─────────────────────────────┘
                           │ HTTPS + Bearer JWT + x-app-key
                           ▼
┌────────────────────────────────────────────────────────┐
│             Next.js Mobile API Gateway                 │
│  c:\Website Project\EMapandan_V2\EMapandan             │
│  - POST /api/mobile/auth/login                         │
│  - GET  /api/mobile/mayor/dashboard                    │
│  - GET  /api/mobile/mayor/barangays                    │
└──────────────────────────┬─────────────────────────────┘
                           │ Prisma ORM
                           ▼
┌────────────────────────────────────────────────────────┐
│         Supabase / PostgreSQL Live Database            │
│  - User, Resident, Payment, Transaction, Report        │
│  - Project, Announcement, News, Event, StaffActivity   │
└────────────────────────────────────────────────────────┘
```

---

## 🧩 100% Data & Feature Parity Breakdown

To ensure the Flutter app is an exact mirror of the web dashboard, the app must replicate these exact modules:

### 1. 🎛️ Header & Global Scope
- **Mayor Greeting & Quick Timestamp**: Shows official LGU greeting and real-time date/time in Asia/Manila.
- **Barangay Scope Filter**: Global dropdown selector (All Barangays vs specific barangay: Poblacion, Licsi, Nilombot, etc.).
- **Date Range Presets**: Filter data by *Today, This Week, This Month, This Year, or Custom Date*.

---

### 2. 🔢 Core Metric KPI Cards (Top Row)
Mirroring `ConfigurableMetricCardsSection.tsx`:
| Metric Card | Data Source (Prisma Model) | Description |
| :--- | :--- | :--- |
| 👥 **Total Residents** | `prisma.resident.count` | Approved registered residents in the municipality/barangay. |
| 💼 **Available Jobs** | `prisma.job.count` | Active employment listings published by LGU/PESO. |
| ⚠️ **Incident Reports** | `prisma.report.count` | Pending community and incident complaints requiring LGU action. |
| 🔨 **Active Projects** | `prisma.project.count` | Ongoing infrastructure and municipal development projects. |

---

### 3. 📈 Strategic Operations & Analytics (Tabs / Segmented View)
Mirroring `ConfigurableAnalyticsSection.tsx`:

#### A. 💳 Payment & Treasury Dashboard View (`PaymentDashboardView.tsx`)
- **Total Revenue Collected (₱)** within selected date range.
- Breakdown by **Category** (RPT, Business Permits, Market, Community Tax / Cedula).
- Breakdown by **Payment Method** (Cash over-the-counter vs Online via PayMongo).
- Interactive Revenue Trend Curve (Line / Bar Chart via `fl_chart`).

#### B. 📑 Transaction Dashboard View (`TransactionDashboardView.tsx`)
- Total Municipal Transactions Processed.
- Transaction volume by Category & Status (Completed, Pending, Under Review).
- Daily transaction volume bar graph.

#### C. 👥 Resident Demographics View (`ResidentDashboardView.tsx`)
- Sector Filter Breakdown:
  - 🧓 **Senior Citizens** (`isSenior: true`)
  - ♿ **Persons with Disabilities (PWD)** (`isPWD: true`)
  - 🧑‍👧 **Solo Parents** (`isSoloParent: true`)
  - 📦 **4Ps Beneficiaries** (`is4Ps: true`)
- Gender and Civil Status distribution charts.

---

### 4. 📢 Community Pulse & Public Feeds
Mirroring `ConfigurableCommunitySection.tsx`:
- 📢 **Recent Announcements** (`RecentAnnouncementsCard.tsx`): Priority badges (Urgent, High, Normal) with date and category.
- 📰 **Latest News** (`LatestNewsCard.tsx`): Image thumbnails, author name, category, and publish date.
- 📅 **Upcoming & Ongoing Events** (`UpcomingEventsCard.tsx`): Venue location, start/end dates.
- 🏗️ **LGU Projects List** (`LGUProjectsCard.tsx`): Status (Planning, Ongoing, Completed), target completion date.

---

### 5. 🛡️ Operational Oversight & Geospatial Map
- 📋 **Staff Activity Logs** (`StaffActivityLogsCard.tsx`): Real-time audit trail of actions taken by department personnel.
- 🗺️ **Mayor Map Places** (`MayorMapPlacesSection.tsx`): Interactive map showing Mapandan critical facilities, evacuation centers, barangay halls, and health posts.

---

## 🛠️ Step-by-Step Implementation Roadmap

### Phase 1: Next.js Backend Aggregator API
1. **Endpoint:** `POST /api/mobile/auth/login`
   - Validates email + password with bcrypt.
   - Enforces role gate: user must be `MAYOR` or `ADMIN`.
   - Issues signed JWT token.
2. **Endpoint:** `GET /api/mobile/mayor/dashboard`
   - Accepts queries: `?barangay=&from=&to=&payCategory=&payMethod=&resSector=`
   - Executes parallel Prisma queries matching `app/mayor/dashboard/page.tsx`.
   - Returns a consolidated, fast, type-safe JSON payload.
3. **Endpoint:** `GET /api/mobile/mayor/barangays`
   - Returns the list of all Mapandan barangays for the dropdown.

---

### Phase 2: Flutter App Scaffolding & Setup
1. **Directory:** Sibling project at `c:\Website Project\EMapandan_Mayor_App`.
2. **Core Dependencies (`pubspec.yaml`)**:
   - `flutter_riverpod`: Reactive, testable state management.
   - `dio`: HTTP network requests with error handling & retry.
   - `flutter_secure_storage`: Encrypted storage for JWT token.
   - `local_auth`: FaceID and Fingerprint biometric authentication.
   - `fl_chart`: Professional charts for revenue curves and demographics.
   - `flutter_map` / `latlong2`: Geospatial interactive map for Mapandan places.
   - `intl`: Philippine Peso currency and Philippine date formatting.
3. **Theme & Tokens**:
   - Primary: `#FF003C` (Official EMapandan Red).
   - Surface Dark: `#0B1120` & `#1E293B`.
   - Typography: Clean executive sans-serif font.

---

### Phase 3: Screen-by-Screen Replication
1. **Splash & Biometric Screen**: Instant FaceID/Fingerprint check to bypass typing password every time.
2. **Login Screen**: Executive branded login matching web credentials.
3. **Main Dashboard (Scrollable Executive View)**:
   - Sticky Header with Barangay Selector.
   - 4 Top Metric KPI Cards with real-time counters.
   - Tabbed Analytics Carousel (Treasury Revenue, Transactions, Demographics).
   - Community Section (Announcements, News, Events, Projects).
   - Staff Audit Trail & Map View.

---

### Phase 4: Polish, Testing & APK Compilation
1. Pull-to-refresh (`RefreshIndicator`) for instant data syncing.
2. Offline/Error banners with graceful retry.
3. Build and test release APK for Android / iOS testing.

---

## 🔒 Security & Safety Guarantees
- 🚫 **Database Safety:** Zero migrations or schema alterations. Read-only queries using the existing Prisma schema.
- 🛡️ **API Guard:** Mobile requests require `x-app-key: process.env.INTERNAL_API_KEY` header to block rogue crawlers.
- 🔐 **Token Lifecycle:** Short-lived JWT with secure hardware storage.

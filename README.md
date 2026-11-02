# 🌾 Digital Krishi Officer (டிஜிட்டல் கிருஷி அதிகாரி / डिजिटल कृषि अधिकारी)
> **Your AI-Powered Agricultural Assistant**
> *AI-Based Farmer Query Support and Advisory System*


Demo Link: "https://digital-krishi-officer-a647.onrender.com"
---

## 📖 Project Overview

**Digital Krishi Officer** is a comprehensive, production-grade agricultural advisory ecosystem designed to serve as an always-available **"Digital Krishi Officer"** for Indian farmers. The platform brings state-of-the-art multimodal Artificial Intelligence (Google Gemini), real-time meteorological advisories, live APMC Mandi rates, smart crop recommendation algorithms, and authentic government scheme databases right into the farmer's pocket—in their native languages and dialects (including Tanglish and Hinglish).

The project is architected as a complete **Full-Stack Agricultural Platform**:
- 📱 **Frontend:** A cross-platform **Flutter** (Dart) mobile and web application with voice-first audio playback (TTS), offline fallback databases, and guest access.
- ☕ **Backend:** A robust, enterprise-grade **Java Spring Boot 3** REST API backend built on textbook **Object-Oriented Programming (OOP)** principles, Hibernate/JPA, and H2 database with interactive Swagger/OpenAPI documentation.

---

## 🌟 Key Features

### 1. 🤖 AI Krishi Officer (Multilingual Chatbot)
- **Natural Language Interaction:** Farmers can ask agricultural questions in English, Tamil, Hindi, Telugu, Kannada, or Malayalam.
- **Multimodal Inputs:** Supports text typing, microphone voice input (speech-to-text with preview & editing), photo attachments (camera/gallery), and video attachments with frame extraction.
- **Farmer-Context Injected Prompts:** AI prompts automatically inject the farmer's location, soil type, main crops, land area, and season to produce tailored advice.
- **Audio Output (Text-to-Speech):** AI answers can be read aloud in regional Indian accents so farmers with low literacy can easily listen to recommendations.
- **Action Toolbar:** Copy advice, save to bookmarks, share via WhatsApp/SMS, retry, or clear chat history.

### 2. 🔬 Multimodal Crop Disease Detection
- **Visual Symptoms Inspection:** Farmers photograph or upload infected plant leaves or stems.
- **Video Inspection:** Video uploads are processed with frame extraction for pattern analysis.
- **Structured Diagnosis:**
  - Crop Name & Identified Issue
  - AI Confidence Score (%) *(Never claims 100% certainty)*
  - Observed Symptoms & Possible Causes
  - Recommended Remedies (Organic + Safe Chemical dosages)
  - Long-term Prevention & Cultural Practices
  - When to Seek Qualified Extension Officer Help
- **Diagnosis History:** Past reports are automatically saved on-device for tracking treatment progress.

### 3. 🌱 Smart Crop Recommendation
- Recommends 3 to 5 optimal crops based on:
  - Farm Agro-Climatic Zone (State & District)
  - Sowing Season (Kharif, Rabi, Zaid, Year-Round)
  - Soil Type (Alluvial, Black, Red, Laterite, Clay, Loam)
  - Irrigation Source (Canal, Borewell, Rainfed, Drip)
  - Previous Crop & Live Weather Forecast
- Displays detailed cultivation tips, water requirements, duration, and economic market prospects.

### 4. 🌦️ Weather Advisory & Impact Alerts
- **Real Meteorological Data:** Integrated with Open-Meteo REST API (free, zero API key required, reliable worldwide and across all Indian districts) and OpenWeatherMap.
- **Live Metrics:** Temperature, condition, humidity, wind speed, rain probability, and 7-day forecast.
- **Farming Operation Guidance:**
  - Rain expected? -> Advises postponing irrigation and foliar chemical spraying.
  - High humidity? -> Alerts farmer about fungal disease risks.
  - Extreme heat? -> Advises evening irrigation and mulching.

### 5. 🏛️ Government Agricultural Schemes Directory
- Curated database of major Indian Government Agricultural schemes:
  - **PM-KISAN** (Pradhan Mantri Kisan Samman Nidhi - ₹6,000/yr income support)
  - **PMFBY** (Pradhan Mantri Fasal Bima Yojana - Comprehensive crop insurance)
  - **KCC** (Kisan Credit Card - 4% concessional credit)
  - **PMKSY** (Per Drop More Crop - 55% micro-irrigation subsidy)
  - **Soil Health Card Scheme** (Periodic nutrient testing)
  - **PKVY** (Paramparagat Krishi Vikas Yojana - Organic farming clusters)
  - **SMAM** (Sub-Mission on Agricultural Mechanization - Tractor & machinery subsidies)
  - **PM-KUSUM** (Solar agricultural pump subsidy up to 60%)
- Includes detailed eligibility, benefits, required documents, step-by-step application instructions, and official government portal URLs.

### 6. 🌾 My Crops Portfolio Management
- Full CRUD: Add, edit, delete, and inspect registered farm crops.
- Tracks sowing date, expected harvest date, and live harvest countdown progress bar.
- Quick shortcut: **"Ask AI About This Crop"** automatically feeds the crop's variety and stage into the AI Krishi Officer.

### 7. 🔔 Personalized Farm Alerts
- Automated alerts categorized by Weather, Disease Risk, Irrigation, and Government Schemes.
- Unread badge counters, mark as read, delete, and clear-all capabilities.

### 8. 🛡️ Expert Escalation & Helplines
- When AI confidence is low or severe symptoms are detected, the app directs the farmer to:
  - **National Kisan Call Center (KCC):** `1800-180-1551` (Toll-Free, 22 local languages)
  - **Krishi Vigyan Kendra (KVK)** district research centers
  - State Agricultural Extension Officers & mKisan portal

### 9. 🌐 6-Language Localization
- Complete translations across:
  - English (`en`)
  - Tamil (`ta` - தமிழ்)
  - Hindi (`hi` - हिन्दी)
  - Telugu (`te` - తెలుగు)
  - Kannada (`kn` - ಕನ್ನಡ)
  - Malayalam (`ml` - മലയാളം)
- Translates navigation, forms, alerts, headers, dialogs, empty states, and instructs Gemini to respond in the selected language.

---

### 📱 Frontend (Mobile & Web)
| Component | Technology |
|---|---|
| **Framework** | Flutter (v3.3+) |
| **Language** | Dart (v3.3+) |
| **Design System** | Material 3 (Responsive Android & Web UI) |
| **State Management** | Provider |
| **AI Integration** | Google Gemini API (Multimodal Vision & Dialect Mirroring) |
| **Audio & Speech** | `flutter_tts` (Voice-first advisory) & `speech_to_text` |
| **Weather Engine** | Open-Meteo REST API + OpenWeatherMap |
| **Market Rates** | APMC Mandi Service (e-NAM rates with daily timestamps) |
| **Social Sharing** | `share_plus` (WhatsApp prescription slip generator) |
| **Local Storage** | SharedPreferences & Offline Fallback Database |

### ☕ Backend (Enterprise REST API & OOP Engine)
| Component | Technology |
|---|---|
| **Language** | Java 17 (LTS) |
| **Framework** | Spring Boot 3.3.4 |
| **Data Layer** | Spring Data JPA, Hibernate ORM |
| **Database** | In-Memory H2 Database (with browser-based console) |
| **API Documentation** | SpringDoc OpenAPI 3 / Swagger UI |
| **Validation** | Jakarta Bean Validation (`@NotNull`, `@NotBlank`) |
| **Testing** | JUnit 5, Mockito |
| **Build Tool** | Apache Maven |

---

## ☕ Java Spring Boot Backend & OOP Architecture

The `backend/` directory provides a clean, modular Java Spring Boot service designed as a showcase of core **Object-Oriented Programming (OOP)** principles:

### 🧩 OOP Principles in Action
1. **Encapsulation:** All model entities (`Farmer`, `Crop`, `DiseaseRecord`) protect internal state using `private` variables, accessor/mutator methods, and Data Transfer Objects (DTOs) separating the database layer from client requests.
2. **Inheritance:** Common auditing attributes (`id`, `createdAt`, `updatedAt`) are inherited cleanly from `@MappedSuperclass public abstract class BaseEntity`.
3. **Polymorphism & Abstraction:** Strict separation of contracts through interfaces (`AiAdvisoryService`, `CropService`, `FarmerService`, `WeatherService`) and runtime implementations (`GeminiAdvisoryServiceImpl`, `CropServiceImpl`), allowing flexible swapping of advisory engines.
4. **Exception Handling:** Centralized `@ControllerAdvice` (`GlobalExceptionHandler`) intercepts domain exceptions and delivers standardized, farmer-friendly JSON error structures.
5. **Collections & Stream API:** Used throughout service logic for filtering crops, mapping entities to response DTOs, and computing agronomic metrics.

### 🌐 Running the Java Backend
```powershell
cd backend
mvn spring-boot:run
```
Once started (Port `8080`):
- **Interactive Swagger UI:** [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
- **H2 Database Console:** [http://localhost:8080/h2-console](http://localhost:8080/h2-console) (JDBC URL: `jdbc:h2:mem:krishidb`)
- **Health Endpoint:** [http://localhost:8080/api/health](http://localhost:8080/api/health)

---

## 📂 Project Architecture

```text
digital_krishi_officer/
├── .env.example                      # Template for configuration
├── .gitignore                        # Git exclusion rules
├── analysis_options.yaml             # Dart lint rules
├── pubspec.yaml                      # Flutter dependencies and assets
├── README.md                         # Project documentation
├── android/                          # Native Android configuration & permissions
├── web/                              # Flutter web runner & deployment files
├── test/                             # 36 Flutter unit and widget tests
├── backend/                          # ☕ Java Spring Boot Backend (OOP)
│   ├── pom.xml                       # Maven build configuration
│   ├── run-backend.bat               # Windows 1-click runner
│   └── src/
│       ├── main/java/com/krishiofficer/
│       │   ├── controller/           # Spring REST Controllers
│       │   ├── dto/                  # Data Transfer Objects
│       │   ├── entity/               # JPA Entities (OOP hierarchy)
│       │   ├── exception/            # Custom exceptions & Global Handler
│       │   ├── repository/           # Spring Data JPA Repositories
│       │   └── service/              # Service interfaces & implementations
│       └── main/resources/
│           └── application.properties # App config & H2 DB setup
├── digital_krishi_officer.zip        # Pre-packaged, clean source archive
├── assets/                           # Image and icon assets
├── lib/
│   ├── main.dart                     # App entry point & initialization
│   ├── app/
│   │   ├── app.dart                  # MultiProvider & MaterialApp root
│   │   ├── routes.dart               # Navigation routing table
│   │   └── theme.dart                # Material 3 light & dark agricultural themes
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart    # Languages, crops, soils, helplines
│   │   │   └── api_constants.dart    # Endpoints & timeouts
│   │   ├── utils/
│   │   │   ├── date_formatter.dart   # Date & time formatting
│   │   │   └── image_helper.dart     # Image size & validation checks
│   │   ├── services/
│   │   │   ├── gemini_service.dart   # Real Gemini API integration & fallbacks
│   │   │   ├── weather_service.dart  # Open-Meteo live API & advisory logic
│   │   │   ├── speech_service.dart   # Speech-to-text recognition
│   │   │   ├── tts_service.dart      # Text-to-speech regional audio
│   │   │   └── scheme_service.dart   # Authentic government schemes dataset
│   │   └── storage/
│   │       └── local_storage_service.dart # Local device JSON persistence
│   ├── models/                       # Strongly typed data models
│   │   ├── farmer_profile.dart
│   │   ├── crop.dart
│   │   ├── chat_message.dart
│   │   ├── conversation.dart
│   │   ├── disease_analysis.dart
│   │   ├── crop_recommendation.dart
│   │   ├── weather_data.dart
│   │   ├── government_scheme.dart
│   │   ├── farmer_alert.dart
│   │   ├── saved_item.dart
│   │   └── app_settings.dart
│   ├── l10n/
│   │   ├── app_localizations.dart    # Localizations delegate & extension
│   │   └── translations.dart         # Full 6-language translation dictionary
│   ├── providers/                    # State management layer
│   │   ├── auth_provider.dart
│   │   ├── language_provider.dart
│   │   ├── theme_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── disease_provider.dart
│   │   ├── crop_provider.dart
│   │   ├── weather_provider.dart
│   │   ├── scheme_provider.dart
│   │   ├── alert_provider.dart
│   │   └── saved_provider.dart
│   ├── features/                     # Feature modules
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── language/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── ai_chat/
│   │   ├── disease_detection/
│   │   ├── crop_recommendation/
│   │   ├── weather/
│   │   ├── schemes/
│   │   ├── crops/
│   │   ├── alerts/
│   │   ├── saved/
│   │   ├── profile/
│   │   └── settings/
│   └── widgets/                      # Reusable UI widgets
└── test/                             # Unit & widget tests
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.3.0 or higher).
- Android Studio / VS Code with Flutter and Dart extensions.
- Android device or emulator running Android 8.0+ (API level 26+).

### 2. Environment Setup
Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Open `.env` and insert your API keys:
```env
# Google Gemini API Key
# Obtain free from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY=your_actual_gemini_api_key_here

# OpenWeatherMap Key (Optional: Open-Meteo works automatically out-of-the-box)
WEATHER_API_KEY=your_weather_api_key_if_any

# Model selector
GEMINI_MODEL=gemini-1.5-flash
```

> **Note:** The weather module uses **Open-Meteo** by default, which requires **NO API key** and functions immediately. If no Gemini API key is configured, the application automatically uses intelligent offline agricultural heuristics for testing.

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the Application
Connect an Android device or start an Android emulator, then run:
```bash
flutter run
```

---

## 🔒 Security & Architectural Disclosures

1. **Client-Only Architecture:**
   - Because this application is built without a backend server, all API requests are dispatched directly from the client.
   - For educational and submission purposes, API keys are loaded via `.env`.
   - In a distributed commercial release, API keys should be proxied through an intermediate backend gateway (such as Cloud Functions or a lightweight API proxy) to prevent key extraction via APK decompilation.
2. **Local Authentication:**
   - Account creation and login authenticate against local device storage.
   - It provides session isolation on the farmer's phone without requiring internet access or server synchronization.

---

## 🔮 Future Roadmap (Backend Migration)
When transitioning this product to a centralized multi-farmer cloud platform:
1. Replace `LocalStorageService` calls with REST / GraphQL API endpoints.
2. Replace local authentication with OAuth2 / Phone OTP verification (e.g. Firebase Auth or Auth0).
3. Introduce a proxy backend (FastAPI / Node.js) to manage Gemini rate-limits and safely store API keys.
4. Add push notifications via FCM for emergency flood and hailstorm alerts.

---

## 👩‍💻 Developer & Credits

- **Developer:** **Bhargavi N** (2nd Year Computer Science & Engineering (CSE) Student)
- **Project:** Digital Krishi Officer — Full-Stack AI & Agricultural Advisory System
- **GitHub:** [@bhargavi2048-boop](https://github.com/bhargavi2048-boop)

Developed with ❤️ for the Indian agricultural community.  
© 2026 Bhargavi N. All rights reserved.

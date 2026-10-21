# Telecaller App

A Flutter-based telecaller management application for handling leads, follow-ups, bookings, and customer interactions.

## Project Structure

```
telecaller_app/
├── frontend/
│   ├── lib/
│   │   ├── controller/          # Business logic & state management
│   │   ├── model/               # Data models
│   │   ├── services/            # API & external services
│   │   ├── utils/               # Constants, helpers, formatters
│   │   ├── view/                # UI screens
│   │   ├── widgets.dart/        # Reusable UI components
│   │   └── main.dart            # App entry point
│   ├── pubspec.yaml             # Dependencies
│   └── ...
├── docs/                        # Documentation
│   └── implementation-notes/    # Implementation details & fixes
├── README.md                    # This file
└── ...
```

## Architecture Overview

### Layers

**1. View Layer** (`lib/view/`)
- Screens and UI pages
- Handles user interactions
- Delegates business logic to controllers

**2. Controller Layer** (`lib/controller/`)
- State management using ChangeNotifier
- Business logic and data processing
- Communicates with repositories and services

**3. Repository Layer** (`lib/controller/lead_repository.dart`)
- Centralized data management
- Local storage persistence
- Data synchronization

**4. Service Layer** (`lib/services/`)
- API communication
- External service integration
- Authentication

**5. Model Layer** (`lib/model/`)
- Data structures
- Serialization/deserialization

**6. Utils Layer** (`lib/utils/`)
- Constants and configurations
- Helper functions
- Formatters and validators

## Key Features

### Lead Management
- Create and manage leads
- Track lead status and call history
- Support for multiple lead types:
  - Booking Confirmation
  - Return/Feedback
  - JustDial
  - Follow-ups
  - Complaints

### Call Tracking
- Automatic call duration tracking
- Call status management
- Call history logging

### Reporting
- Completed leads reports
- Performance metrics
- Date range filtering
- Store-based filtering

### Follow-ups
- Schedule follow-ups
- Track overdue, today, and upcoming follow-ups
- Follow-up status management

## API Integration

### Base URL
```
https://rootstele-imrn.onrender.com
```

### Key Endpoints
- `POST /api/auth/telecaller-login` - User authentication
- `GET /api/leads/justdial` - Fetch JustDial leads
- `GET /api/leads/justdial/{id}` - Fetch JustDial lead details
- `GET /api/leads/booking-confirmation` - Fetch booking confirmation leads
- `GET /api/leads/returns` - Fetch return/feedback leads
- `GET /api/leads/followups` - Fetch follow-up leads
- `GET /api/leads/complaints` - Fetch complaints
- `GET /api/leads/completed` - Fetch completed leads (reports)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd telecaller_app
```

2. Install dependencies
```bash
cd frontend
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Project Standards

### Code Organization
- One widget/class per file
- Clear separation of concerns
- Meaningful file and variable names

### State Management
- ChangeNotifier for state management
- Provider for dependency injection
- Repository pattern for data access

### Error Handling
- Try-catch blocks for API calls
- User-friendly error messages
- Firebase Crashlytics for error tracking

### Data Persistence
- SharedPreferences for local storage
- Automatic sync with backend

## Documentation

Detailed implementation notes and fixes are available in `docs/implementation-notes/`

## Contributing

1. Follow the existing code structure
2. Use meaningful commit messages
3. Test changes before committing
4. Update documentation as needed

## License

Proprietary - All rights reserved

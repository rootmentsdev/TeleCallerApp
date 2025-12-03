# TeleCaller App

A telecaller management application with Flutter frontend and Node.js/Express backend.

## Project Structure

```
telecaller_app/
├── frontend/          # Flutter mobile application
│   ├── lib/          # Dart source code
│   ├── android/      # Android platform files
│   ├── ios/          # iOS platform files
│   ├── web/          # Web platform files
│   └── pubspec.yaml  # Flutter dependencies
│
└── backend/          # Node.js/Express backend API
    ├── controllers/  # Route controllers
    ├── models/       # MongoDB models
    ├── routes/       # API routes
    ├── middlewares/  # Express middlewares
    ├── validators/   # Input validators
    ├── config/       # Configuration files
    ├── sync/         # Data synchronization scripts
    └── server.js     # Main server file
```

## Getting Started

### Frontend (Flutter)

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Backend (Node.js)

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables (create a `.env` file):
   ```env
   MONGODB_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret
   PORT=3000
   ```

4. Start the server:
   ```bash
   npm start
   # or for development with auto-reload:
   npm run dev
   ```

## Features

- Lead management
- Call logging and tracking
- Follow-up scheduling
- CSV data import
- User authentication
- Store management

## Technologies

- **Frontend**: Flutter, Dart
- **Backend**: Node.js, Express, MongoDB, Mongoose
- **Authentication**: JWT

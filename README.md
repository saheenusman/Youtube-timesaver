# 🎬 YouTube TimeSaver - AI-Powered Video Analysis Platform

> **An intelligent Flutter + Django application that analyzes YouTube videos using Google Gemini AI to provide instant highlights, summaries, and bookmarks for time-efficient learning.**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev/)
[![Django](https://img.shields.io/badge/Django-5.2.7-092E20?logo=django)](https://djangoproject.com/)
[![Gemini AI](https://img.shields.io/badge/Google_Gemini-AI_Powered-4285F4?logo=google)](https://ai.google.dev/)
## 🚀 Features

- **AI-Powered Analysis**: Uses Google Gemini AI to analyze YouTube video transcripts
- **Smart Highlights**: Automatically extracts key points, learning objectives, and important timestamps
- **Device-Based Authentication**: Secure device-specific data storage without user registration
- **Bookmark System**: Save and organize your favorite video analyses
- **Analysis History**: Track all your analyzed videos with search functionality
- **Rate Limiting**: Intelligent API usage management to prevent abuse
- **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux

## 📱 Application Screenshots

<table>
  <tr>
    <td align="center">
      <img src="docs/images/app1-home-screen.jpg" alt="Home Screen" width="200"/><br/>
      <b>Home Screen</b><br/>
      Clean URL input interface
    </td>
    <td align="center">
      <img src="docs/images/app2-analysis-screen.jpg" alt="Analysis Screen" width="200"/><br/>
      <b>Analysis Process</b><br/>
      AI analysis
    </td>
    <td align="center">
      <img src="docs/images/app3-results-view.jpg" alt="Results View" width="200"/><br/>
      <b>Analysis Results</b><br/>
      AI-generated highlights & insights
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="docs/images/app4-bookmarks.jpg" alt="Bookmarks" width="200"/><br/>
      <b>Highlights</b><br/>
      Detailed Highlight View
    </td>
    <td align="center">
      <img src="docs/images/app5-history.jpg" alt="History" width="200"/><br/>
      <b>Analysis History</b><br/>
      Track all analyzed videos
    </td>
    <td align="center">
      <img src="docs/images/app6-settings.jpg" alt="Settings" width="200"/><br/>
      <b>Bookmarked Analysis</b><br/>
      Bookmarks
    </td>
  </tr>
</table>

## 🏗️ System Architecture

![Architecture Diagram](docs/images/architecture-diagram.png)

The application follows a clean microservices architecture:

- **Frontend**: Flutter app with device-based authentication
- **Backend**: Django REST API with middleware-based security
- **AI Engine**: Google Gemini integration for video analysis
- **Database**: SQLite (development) with migration-ready design
- **Caching**: In-memory rate limiting and analysis caching

## 📁 Project Structure

```
├── 📱 lib/                          # Flutter Frontend
│   ├── core/
│   │   ├── constants/               # App constants & configurations
│   │   ├── services/
│   │   │   ├── api_service.dart     # Backend API communication
│   │   │   └── device_id_service.dart # Device UUID management
│   │   ├── theme/                   # App theming & styles
│   │   ├── utils/                   # Utility functions
│   │   │   └── youtube_utils.dart   # YouTube URL & timestamp handling
│   │   └── widgets/                 # Reusable UI components
│   ├── features/
│   │   ├── analysis/
│   │   │   └── screens/
│   │   │       └── analysis_screen.dart # Video analysis UI
│   │   ├── bookmarks/
│   │   │   └── screens/
│   │   │       └── bookmarks_screen.dart # Bookmarks management
│   │   └── home/
│   │       └── screens/
│   │           └── home_screen.dart  # Main URL input screen
│   └── main.dart                    # Flutter app entry point
│
├── 🐍 timesaver_backend/            # Django Backend
│   ├── analysis_api/
│   │   ├── models.py               # Database models (VideoAnalysis, Bookmarks)
│   │   ├── views.py                # REST API endpoints
│   │   ├── analysis_core.py        # AI analysis orchestration
│   │   ├── middleware.py           # Device authentication middleware
│   │   ├── rate_limiting.py        # API rate limiting logic
│   │   └── migrations/             # Database migrations
│   ├── timesaver_backend/
│   │   ├── settings.py             # Django configuration
│   │   └── urls.py                 # URL routing
│   ├── manage.py                   # Django management script
│   ├── requirements.txt            # Python dependencies
│   └── .env.example               # Environment variables template
│
├── 📊 docs/                         # Documentation & Assets
│   ├── images/                     # Screenshots & diagrams
│   ├── ARCHITECTURE_DIAGRAM.md     # Technical architecture details
│   ├── DATABASE_SCHEMA.md          # Database structure documentation
│   └── REPORT.md                   # Complete project analysis report
│
├── 🔧 Configuration Files
│   ├── pubspec.yaml               # Flutter dependencies
│   ├── analysis_options.yaml      # Dart code analysis rules
│   └── .gitignore                 # Git exclusion rules (protects API keys)
│
└── 📋 Platform-Specific Builds
    ├── android/                   # Android build configuration
    ├── ios/                      # iOS build configuration
    ├── web/                      # Web build configuration
    ├── windows/                  # Windows build configuration
    ├── macos/                    # macOS build configuration
    └── linux/                    # Linux build configuration
```

## 🛠️ Tech Stack

### Frontend (Flutter/Dart)

- **Flutter SDK 3.0+**: Cross-platform UI framework
- **http**: REST API communication
- **shared_preferences**: Local device storage
- **url_launcher**: External URL handling
- **uuid**: Unique device identifier generation
- **shimmer**: Loading state animations

### Backend (Python/Django)

- **Django 5.2.7**: Web framework & REST API
- **Django REST Framework**: API serialization
- **google-generativeai**: Gemini AI integration
- **youtube-transcript-api**: Video transcript extraction
- **pytube**: YouTube metadata fetching (with fallback)
- **requests**: HTTP client for external APIs
- **python-dotenv**: Environment configuration

### AI & Data Processing

- **Google Gemini AI**: Multi-role AI agent orchestration
- **Transcript Sampling**: Strategic content extraction for token optimization
- **JSON Response Parsing**: Structured AI output processing

## ⚡ Quick Start

### Prerequisites

- **Flutter SDK 3.0+** ([Install Guide](https://flutter.dev/docs/get-started/install))
- **Python 3.8+** ([Download](https://python.org/downloads/))
- **Google Gemini API Key** ([Get API Key](https://ai.google.dev/))

### 1. Clone Repository

```bash
git clone https://github.com/saheenusman/Youtube-timesaver.git
cd Youtube-timesaver
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd timesaver_backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\\Scripts\\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create environment file
copy .env.example .env
# Edit .env and add your GEMINI_API_KEY=your_actual_api_key_here

# Run migrations
python manage.py migrate

# Start Django server
python manage.py runserver
```

### 3. Frontend Setup

```bash
# Navigate back to project root
cd ..

# Get Flutter dependencies
flutter pub get

# Run on your preferred platform
flutter run

# Or build for specific platforms:
flutter build apk          # Android APK
flutter build ios          # iOS (macOS only)
flutter build web          # Web application
flutter build windows      # Windows executable
```

### 4. Environment Configuration

Create `timesaver_backend/.env` with:

```env
GEMINI_API_KEY=your_google_gemini_api_key_here
DEBUG=True
SECRET_KEY=your-secret-key-for-production
```

> ⚠️ **Security Note**: The `.env` file is automatically excluded from Git commits. Never commit API keys!

## 🔧 Development Workflow

### Running in Development

1. **Start Backend** (Terminal 1):

   ```bash
   cd timesaver_backend
   python manage.py runserver
   ```

2. **Start Frontend** (Terminal 2):

   ```bash
   flutter run
   ```

3. **Test the Flow**:
   - Enter a YouTube URL in the app
   - Watch real-time AI analysis
   - Explore highlights, bookmarks, and history

### API Endpoints

| Method   | Endpoint                | Description           |
| -------- | ----------------------- | --------------------- |
| `POST`   | `/api/analyze/`         | Analyze YouTube video |
| `GET`    | `/api/history/`         | Get analysis history  |
| `GET`    | `/api/search/`          | Search analyses       |
| `POST`   | `/api/bookmark/toggle/` | Toggle bookmark       |
| `GET`    | `/api/bookmarks/`       | Get bookmarks         |
| `DELETE` | `/api/analysis/{id}/`   | Delete analysis       |
| `GET`    | `/api/stats/`           | Get usage statistics  |

### Device Authentication

The app uses **device-based authentication** with UUID v4:

- Each device generates a unique identifier on first launch
- Stored in `SharedPreferences` (persists across app sessions)
- Sent as `X-Device-ID` header in all API requests
- Backend uses this for data scoping and rate limiting

## 🚀 Production Deployment

### Environment Variables

```env
GEMINI_API_KEY=your_production_api_key
DEBUG=False
SECRET_KEY=your_strong_secret_key
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
DATABASE_URL=postgresql://user:pass@host:port/dbname  # Optional
REDIS_URL=redis://host:port/db  # For production rate limiting
```

### Recommended Production Setup

1. **Database**: Migrate from SQLite to PostgreSQL
2. **Caching**: Use Redis for distributed rate limiting
3. **Security**: Implement signed device tokens
4. **Monitoring**: Add logging and error tracking
5. **Scaling**: Use Docker containers and load balancers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request


## 🙏 Acknowledgments

- **Google Gemini AI** for powerful video analysis capabilities
- **Flutter Team** for the excellent cross-platform framework
- **Django Community** for robust backend infrastructure
- **YouTube API** for transcript and metadata access


---


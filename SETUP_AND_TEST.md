# Setup and Testing Guide

## Frontend to Backend Integration Verification

### Prerequisites

1. **Flutter Setup**: Ensure Flutter is installed and configured
2. **Python Setup**: Ensure Python 3.8+ is installed
3. **API Key**: Valid Gemini API key in backend/.env file

### Backend Setup Steps

1. **Navigate to backend directory:**

   ```bash
   cd timesaver_backend
   ```

2. **Create virtual environment:**

   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   # source venv/bin/activate  # macOS/Linux
   ```

3. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Run migrations:**

   ```bash
   python manage.py migrate
   ```

5. **Start Django server:**
   ```bash
   python manage.py runserver 127.0.0.1:8000
   ```

### Frontend Setup Steps

1. **Navigate to project root:**

   ```bash
   cd ..  # Back to project root
   ```

2. **Get Flutter dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run Flutter app:**
   ```bash
   flutter run
   ```

### Integration Test Endpoints

#### Backend Test (Manual)

```bash
curl -X POST http://127.0.0.1:8000/api/v1/analyze/ \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

Expected Response Structure:

```json
{
  "title": "Video Title",
  "duration": "3:35",
  "thumbnailUrl": "https://...",
  "highlights": [
    {
      "agent": "The Teacher",
      "timestamp": "1:23",
      "title": "Key Concept",
      "description": "Important learning moment..."
    }
  ],
  "agents": [
    { "name": "The Teacher", "status": "Conceptual findings integrated." }
  ],
  "status": "Success"
}
```

### Potential Issues and Solutions

#### 1. CORS Issues

- **Symptom**: Flutter app can't connect to backend
- **Solution**: Check Django CORS settings in settings.py

#### 2. API Key Issues

- **Symptom**: "Authentication Error" in backend logs
- **Solution**: Verify GEMINI_API_KEY in .env file

#### 3. Port Conflicts

- **Symptom**: Backend won't start on port 8000
- **Solution**: Change port in both backend and Flutter ApiService

#### 4. YouTube API Issues

- **Symptom**: "Failed to fetch transcript" errors
- **Solution**: Test with videos that have English captions

### Data Flow Verification

1. **User Input**: YouTube URL entered in Flutter app
2. **Navigation**: App navigates to AnalysisScreen with URL as argument
3. **API Call**: Flutter calls Django backend at `/api/v1/analyze/`
4. **Video Processing**: Backend extracts transcript and metadata
5. **AI Analysis**: Gemini processes content and returns highlights
6. **Response**: Structured JSON returned to Flutter
7. **UI Update**: Flutter displays results with proper animations

### Key Files Modified for Integration

#### Frontend:

- `lib/services/api_service.dart` - Real HTTP calls
- `lib/features/analysis/screens/analysis_screen.dart` - Data structure fixes
- `lib/core/constants/mock_data.dart` - Added missing fields

#### Backend:

- `analysis_api/analysis_core.py` - Field name consistency
- `timesaver_backend/settings.py` - CORS and environment setup
- `requirements.txt` - All needed dependencies

### Success Indicators

✅ **Backend**: Server starts without errors on port 8000
✅ **API**: Manual curl request returns valid JSON
✅ **Frontend**: App builds and runs without errors
✅ **Integration**: YouTube URL analysis completes successfully
✅ **UI**: Results display with animations and proper formatting

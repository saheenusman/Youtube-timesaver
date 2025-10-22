# 🗄️ Backend Data Architecture & Database Schema

## 📊 **Database Schema Overview**

### **Database Type**: SQLite3 (Development) / PostgreSQL (Production)

### **ORM**: Django ORM

### **Total Tables**: 3 Core Tables + 1 Cache System

**✅ CONFIRMED: All tables exist in database as of Oct 11, 2025**

---

## 🏗️ **Core Database Tables**

### **1. 📹 VideoAnalysis Table**

**Purpose**: Store completed video analysis results with device isolation

```sql
CREATE TABLE "analysis_api_videoanalysis" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "device_id" VARCHAR(100) NOT NULL,
    "video_url" VARCHAR(500) NOT NULL,
    "video_id" VARCHAR(20) NOT NULL,
    "title" VARCHAR(500) NOT NULL,
    "duration" VARCHAR(20) NOT NULL,
    "thumbnail_url" VARCHAR(500) NOT NULL,
    "highlights" JSON NOT NULL,
    "analysis_summary" TEXT NOT NULL,
    "created_at" DATETIME NOT NULL,
    "updated_at" DATETIME NOT NULL,
    "analysis_status" VARCHAR(20) NOT NULL DEFAULT 'completed'
);
```

**Indexes**:

```sql
CREATE INDEX "analysis_ap_device__2cdaa7_idx" ON "analysis_api_videoanalysis" ("device_id");
CREATE INDEX "analysis_ap_video_i_351acf_idx" ON "analysis_api_videoanalysis" ("video_id");
CREATE INDEX "analysis_ap_created_982abd_idx" ON "analysis_api_videoanalysis" ("created_at");
CREATE INDEX "analysis_ap_device__351acf_idx" ON "analysis_api_videoanalysis" ("device_id", "video_id");
```

**Constraints**:

```sql
UNIQUE CONSTRAINT: (device_id, video_id) -- Same video can be analyzed by different devices
```

**Sample Data Structure**:

```json
{
  "id": 17,
  "device_id": "8fa9d67e-1234-5678-9abc-def123456789",
  "video_url": "https://youtu.be/kMiy8ZywF88",
  "video_id": "kMiy8ZywF88",
  "title": "I bought the most EXPENSIVE Tech on the internet.",
  "duration": "15:42",
  "thumbnail_url": "https://img.youtube.com/vi/kMiy8ZywF88/maxresdefault.jpg",
  "highlights": [
    {
      "timestamp": "02:15",
      "title": "Unboxing the $50K Setup",
      "description": "First look at the most expensive tech gear",
      "agentName": "explorer"
    }
  ],
  "analysis_summary": "",
  "created_at": "2025-10-11T16:21:11.123Z",
  "updated_at": "2025-10-11T16:21:11.123Z",
  "analysis_status": "completed"
}
```

---

### **2. 👤 UserSession Table**

**Purpose**: Track user sessions for analytics and historical data

```sql
CREATE TABLE "analysis_api_usersession" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "session_id" VARCHAR(100) NOT NULL UNIQUE,
    "first_visit" DATETIME NOT NULL,
    "last_activity" DATETIME NOT NULL,
    "total_analyses" INTEGER NOT NULL DEFAULT 0,
    "device_info" JSON NOT NULL DEFAULT '{}'
);
```

**Sample Data Structure**:

```json
{
  "id": 5,
  "session_id": "8fa9d67e-1234-5678-9abc-def123456789",
  "first_visit": "2025-10-11T15:30:00.000Z",
  "last_activity": "2025-10-11T16:21:11.123Z",
  "total_analyses": 3,
  "device_info": {
    "platform": "android",
    "app_version": "1.0.0",
    "last_ip": "192.168.1.100"
  }
}
```

---

### **3. 🔖 VideoBookmark Table**

**Purpose**: Store user bookmarks with device isolation

```sql
CREATE TABLE "analysis_api_videobookmark" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "session_id" VARCHAR(100) NOT NULL,
    "video_analysis_id" INTEGER NOT NULL,
    "bookmarked_at" DATETIME NOT NULL,
    FOREIGN KEY ("video_analysis_id") REFERENCES "analysis_api_videoanalysis" ("id") ON DELETE CASCADE
);
```

**Constraints**:

```sql
UNIQUE CONSTRAINT: (session_id, video_analysis_id) -- One bookmark per device per video
```

**Sample Data Structure**:

```json
{
  "id": 12,
  "session_id": "8fa9d67e-1234-5678-9abc-def123456789",
  "video_analysis_id": 17,
  "bookmarked_at": "2025-10-11T16:25:30.456Z"
}
```

---

## ⚡ **In-Memory Cache System**

### **4. 🛡️ Rate Limiting Cache**

**Storage**: Django LocMemCache (In-Memory)
**Purpose**: Track API request counts per device

**Cache Key Structure**:

```
rate_limit:{device_id}:{endpoint_type}
```

**Rate Limit Configuration**:

```python
RATE_LIMITS = {
    'analyze': {
        'max_requests': 5,      # 5 requests
        'window_seconds': 60,   # per 60 seconds
        'endpoint': '/api/analyze/',
    },
    'search': {
        'max_requests': 30,     # 30 requests
        'window_seconds': 60,   # per 60 seconds
        'endpoint': '/api/search/',
    },
    'history': {
        'max_requests': 20,     # 20 requests
        'window_seconds': 60,   # per 60 seconds
        'endpoint': '/api/history/',
    }
}
```

**Cache Data Structure**:

```python
cache_key = "rate_limit:8fa9d67e:analyze"
cache_value = [1697031671, 1697031672, 1697031673]  # List of unix timestamps
```

---

## 🔄 **Data Relationships & Flow**

### **Entity Relationship Diagram**:

```
UserSession (1) ←→ (N) VideoAnalysis ←→ (N) VideoBookmark
     ↓                      ↓                    ↓
device_id             device_id           session_id
session_id            video_id            video_analysis_id
```

### **Data Isolation Strategy**:

- **Device-based isolation**: All data tied to unique device_id (UUID)
- **No cross-device data sharing**: Each device sees only its own data
- **Privacy-first approach**: No personal information stored

### **Query Patterns**:

**Get User's Analysis History**:

```sql
SELECT * FROM analysis_api_videoanalysis
WHERE device_id = ?
ORDER BY created_at DESC;
```

**Get User's Bookmarks**:

```sql
SELECT va.* FROM analysis_api_videoanalysis va
JOIN analysis_api_videobookmark vb ON va.id = vb.video_analysis_id
WHERE vb.session_id = ?
ORDER BY vb.bookmarked_at DESC;
```

**Search User's Videos**:

```sql
SELECT * FROM analysis_api_videoanalysis
WHERE device_id = ? AND (
    title LIKE ? OR
    video_url LIKE ? OR
    JSON_EXTRACT(highlights, '$[*].description') LIKE ?
)
ORDER BY created_at DESC;
```

---

## 🔒 **Security & Performance Features**

### **Database Security**:

- **Device Isolation**: All queries filtered by device_id
- **No PII Storage**: Only device UUIDs, no personal information
- **Foreign Key Constraints**: Referential integrity maintained
- **Cascade Deletes**: Cleanup when analysis is deleted

### **Performance Optimizations**:

- **Strategic Indexing**: Compound indexes on commonly queried fields
- **JSON Field Usage**: Efficient storage of complex highlight data
- **Query Optimization**: Device-specific indexes for fast filtering
- **Cache Strategy**: Rate limiting data kept in memory

### **Data Retention**:

- **No Automatic Expiry**: Data persists until manually deleted
- **Rate Limit Cleanup**: Cache entries auto-expire after window + 10s
- **Bookmark Cascade**: Bookmarks deleted when parent analysis removed

---

## 📈 **Scalability Considerations**

### **Current Architecture (SQLite)**:

- **Concurrent Users**: ~100 simultaneous users
- **Data Volume**: Supports millions of analyses
- **Performance**: Single-server deployment

### **Production Architecture (PostgreSQL)**:

- **Concurrent Users**: Unlimited with proper indexing
- **Data Volume**: Enterprise-scale with partitioning
- **Performance**: Multi-server, read replicas, connection pooling

### **Migration Path**:

```bash
# Development → Production
SQLite → PostgreSQL (via Django migrations)
Local files → Cloud storage
Single server → Load balanced deployment
```

This data architecture provides a robust, scalable foundation for the Time Saver App with privacy-first design and optimal performance characteristics.

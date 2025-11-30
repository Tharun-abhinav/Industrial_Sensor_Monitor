# Fermenter Monitoring System

A complete end-to-end system for simulating, ingesting, storing, and monitoring fermenter sensor data with real-time anomaly detection.

## 🏗️ System Architecture

This system consists of the following components:

1. **Data Simulator** (`backend/simulator.py`) - Generates realistic time-series fermenter sensor data once per second
2. **Database Layer** (`backend/models.py`) - Simple `measurements` table with SQLAlchemy ORM
3. **Anomaly Detection** (`backend/anomaly_detector.py`) - Uses rolling mean ± 3σ and threshold rules
4. **REST API** (`backend/api.py`) - FastAPI backend with endpoints: `/tags`, `/data`, `/anomalies`
5. **Ingestion Service** (`backend/ingestion_service.py`) - Continuously runs simulator and pushes data to API
6. **Frontend Dashboard** (`frontend/dashboard.html`) - Simple single-page app with time-series visualization

## 📋 Features

- **Real-time Data Simulation**: Simulates 3 fermenter sensors with realistic patterns
  - `fermenter_temp`: 35-40°C with occasional noise
  - `fermenter_ph`: 6.5-7.5 pH
  - `agitator_rpm`: 300-600 RPM
- **Data Validation**: Validates values within reasonable bounds, non-empty timestamps
- **Anomaly Detection**: 
  - Rolling mean ± 3 standard deviations per tag
  - Simple threshold rules (e.g., fermenter_temp > 45°C)
  - Clearly separated in dedicated module
- **Reliability & Fault Tolerance**: 
  - **Retry Queue**: Failed database operations are automatically retried
  - **Dead Letter Queue**: Persistent backup ensures no data loss during outages
  - **Startup Recovery**: Failed measurements recovered on restart
  - See [RELIABILITY.md](RELIABILITY.md) for detailed architecture
- **REST API**: 
  - `GET /tags` - Returns list of available tags
  - `GET /data?tag=<name>&from=<time>&to=<time>` - Query time-series data
  - `GET /anomalies?tag=<name>&from=<time>&to=<time>` - Query anomalies only
  - `GET /health` - System health check with retry queue status
- **Interactive Dashboard**: 
  - Tag selection via dropdown
  - Time-series chart with Chart.js
  - Anomalies highlighted as red triangles
  - Auto-refresh every 5 seconds

## 🚀 Getting Started

### Prerequisites

- **Python 3.9+** (recommended: 3.9, 3.10, 3.11)
  - **Note**: Python 3.13 is NOT recommended due to NumPy compatibility issues
- **Git** (for cloning the repository)
- **pip** (Python package manager)

### 1️⃣ Set Up Environment

**Clone the repository:**
```bash
git clone https://github.com/prathyushapeddi25/INDUSTRIAL-SENSOR-MONITOR.git
cd INDUSTRIAL-SENSOR-MONITOR
```

**Create and activate virtual environment:**
```bash
# Create virtual environment
python3.9 -m venv .venv

# Activate it (macOS/Linux)
source .venv/bin/activate

# On Windows, use:
# .venv\Scripts\activate
```

**Install dependencies:**
```bash
pip install -r requirements.txt
```

**Verify installation:**
```bash
pip list
# Should show: fastapi, uvicorn, sqlalchemy, pydantic, numpy, requests
```

---

### 2️⃣ Start the System

**Option A: Automated Startup (Recommended) - macOS/Linux**

Run the startup script that handles everything:
```bash
chmod +x start.sh  # Make executable (first time only)
./start.sh
```

This will:
1. Activate the virtual environment
2. Start the API server on `http://localhost:8000`
3. Start the data simulator (ingestion service)
4. Display process IDs and log file locations

**Option B: Manual Startup**

If you prefer to run components separately:

**Terminal 1 - Start Backend API:**
```bash
source .venv/bin/activate
cd backend
python api.py
```

The API will start on `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`
- Dashboard: `http://localhost:8000/dashboard`

**Terminal 2 - Start Data Simulator:**
```bash
source .venv/bin/activate
cd backend
python ingestion_service.py
```

This will:
1. Generate simulated sensor readings once per second
2. Push data to the ingestion API
3. Automatically detect and flag anomalies
4. Display ingestion statistics in real-time

---

### 3️⃣ Access the Frontend

Once the services are running:

1. **Open your web browser**
2. **Navigate to:** `http://localhost:8000/dashboard`
3. **The dashboard will display:**
   - Real-time sensor readings (auto-refreshes every 5 seconds)
   - Three charts for: Fermenter Temperature, pH Level, Agitator RPM
   - Anomaly indicators (red triangles on charts)
   - Statistics panel showing total measurements and anomaly count
   - List of recent anomalies with timestamps

---

### 4️⃣ Verify Everything is Working

**Check API Health:**
```bash
curl http://localhost:8000/health
```

**View API Documentation:**
- Open `http://localhost:8000/docs` in your browser
- Interactive Swagger UI for testing endpoints

**Check Logs:**
```bash
# API server logs
tail -f api.log

# Data simulator logs
tail -f ingestion.log
```

## 📊 Simulated Sensors

The system simulates 3 fermenter process tags:

1. **fermenter_temp**: Temperature around 35-40°C with occasional noise
2. **fermenter_ph**: pH level around 6.5-7.5
3. **agitator_rpm**: Rotation speed around 300-600 RPM

Each sensor generates realistic data with:
- Sinusoidal patterns
- Random noise
- Occasional anomalies (5% probability per reading)

## 🔍 API Endpoints

### GET /tags
Returns a list of available tags.

**Response:**
```json
{
  "tags": ["fermenter_temp", "fermenter_ph", "agitator_rpm"]
}
```

### GET /data
Query time-series data points for a given tag and optional time range.

**Parameters:**
- `tag` (required): Tag name
- `from` (optional): Start timestamp (ISO format)
- `to` (optional): End timestamp (ISO format)

**Example:**
```
GET /data?tag=fermenter_temp&from=2025-11-22T10:00:00
```

**Response:**
```json
[
  {
    "id": 1,
    "timestamp": "2025-11-22T10:05:30",
    "tag": "fermenter_temp",
    "value": 37.5,
    "is_anomaly": false
  }
]
```

### GET /anomalies
Returns only records flagged as anomalies for the given tag and time range.

**Parameters:**
- `tag` (required): Tag name
- `from` (optional): Start timestamp (ISO format)
- `to` (optional): End timestamp (ISO format)

**Example:**
```
GET /anomalies?tag=fermenter_temp
```

### POST /ingest
Accept incoming readings from the simulator.

**Request Body:**
```json
{
  "timestamp": "2025-11-22T10:05:30",
  "tag": "fermenter_temp",
  "value": 37.5
}
```

### POST /ingest/batch
Ingest multiple readings at once.

**Request Body:**
```json
[
  {
    "timestamp": "2025-11-22T10:05:30",
    "tag": "fermenter_temp",
    "value": 37.5
  }
]
```

Full API documentation available at: `http://localhost:8000/docs`

## 🧪 Testing Components Individually

### Test the Simulator
```bash
source .venv/bin/activate
python backend/simulator.py
```

### Test the Anomaly Detector
```bash
source .venv/bin/activate
python backend/anomaly_detector.py
```

Output will show:
- Normal readings being processed
- Threshold anomalies detected (e.g., temp > 45°C)
- Statistical anomalies detected (unusual patterns)

## 📁 Project Structure

```
industrial-sensor-monitor/
├── backend/
│   ├── api.py                    # FastAPI application
│   ├── models.py                 # Database models (measurements table)
│   ├── simulator.py              # Data simulator
│   ├── anomaly_detector.py       # Anomaly detection logic (separate module)
│   ├── ingestion_service.py      # Data ingestion service
│   ├── retry_handler.py          # Failure recovery and retry logic
│   ├── sensor_data.db            # SQLite database (created on first run)
│   └── failed_measurements.jsonl # Dead letter queue (created if DB fails)
├── frontend/
│   └── dashboard.html            # Single-page dashboard
├── requirements.txt              # Python dependencies
├── README.md                     # This file
├── RELIABILITY.md                # Detailed reliability architecture
├── start.bat                     # Windows quick start script
└── start.sh                      # Linux/Mac quick start script
```

## 🗄️ Database Schema

### measurements table
```sql
CREATE TABLE measurements (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    tag VARCHAR(100) NOT NULL,
    value FLOAT NOT NULL,
    is_anomaly BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_tag ON measurements(tag);
CREATE INDEX idx_timestamp ON measurements(timestamp);
```

## 🛠️ Technology Stack

- **Backend**: Python 3.8+, FastAPI, SQLAlchemy
- **Database**: SQLite (simple, embedded, easy to run)
- **Analytics**: NumPy for statistical calculations
- **Frontend**: HTML, CSS, JavaScript, Chart.js
- **API**: RESTful with automatic OpenAPI documentation

## 🎯 Design Decisions & Architecture

1. **Simple Schema**: Single `measurements` table with `is_anomaly` boolean field
   - Anomaly flag stored directly in each record (no separate table needed)
   - Enables efficient querying of anomalies with indexed columns
2. **FastAPI**: Chosen for automatic API documentation and type validation
3. **SQLite**: Simple, embedded database - no setup required
4. **Anomaly Detection**: 
   - **Clearly separated** into dedicated `anomaly_detector.py` module
   - **Dual-method approach**:
     - **Method 1**: Threshold rules (e.g., fermenter_temp: 35-45°C)
     - **Method 2**: Rolling mean ± 3σ (statistical outlier detection)
   - Anomaly flagged if **EITHER** method detects it
   - Maintains 50-reading sliding window per sensor
5. **Push-based Ingestion**: Simulator pushes data to API endpoint
6. **Single-page Dashboard**: Simple HTML/JS with Chart.js for visualization
7. **Clear Separation**: Simulator, ingestion, storage, analytics, and presentation are separate modules
8. **Fault Tolerance**: 
   - Failed DB operations queued in memory + persisted to `.jsonl` file
   - Background retry worker attempts up to 3 retries
   - Original timestamps preserved during recovery

## 🛑 Stopping the System

**If using start.sh:**
The script will display process IDs (PIDs) when starting. To stop:
```bash
kill <API_PID> <SIMULATOR_PID>
```

Example:
```bash
kill 19807 19845
```

**If running manually:**
Press `Ctrl+C` in each terminal window to stop the services.

## 📋 Assumptions & Shortcuts

### Assumptions Made:
1. **Single Server Deployment**: System runs on localhost, not designed for distributed setup
2. **SQLite Database**: Sufficient for demo; production would use PostgreSQL/MySQL
3. **In-Memory History**: Anomaly detector loses rolling statistics on restart (not persisted)
4. **No Authentication**: API endpoints are open (would need auth in production)
5. **Fixed Sensor Tags**: Three predefined tags (extensible but hardcoded in validation)
6. **UTC Timestamps**: All times stored and displayed in UTC

### Shortcuts Taken:
1. **Simulated Data**: `ingestion_service.py` generates synthetic sensor readings instead of real hardware integration
2. **Simple Retry Logic**: Max 3 retries with fixed 5-second intervals (production would use exponential backoff)
3. **Limited Dashboard**: Basic visualization only; no advanced features like:
   - Historical playback controls
   - Email/SMS alert notifications
   - User authentication or preferences
   - Mobile-responsive design
4. **No Unit Tests**: Time constraint (production would have comprehensive test suite)
5. **Basic Error Handling**: Minimal validation and user-friendly error messages
6. **Single File Logs**: Production would use proper log rotation and centralized logging
7. **No Data Aggregation**: Dashboard shows raw data (production would downsample for long time ranges)

### Known Limitations:
- Dashboard doesn't handle very large datasets efficiently (only shows last 100 points)
- No concurrent request handling optimization
- Anomaly detector state is not persisted across restarts
- Frontend uses polling (5s interval) instead of WebSockets for real-time updates
- No data backup or export functionality
- Retry queue size grows unbounded if database is down for extended period

---

## 📝 Notes

- The database file `sensor_data.db` is created automatically in the root directory on first run
- Anomaly detection becomes more accurate as more data is collected (needs ~10 readings minimum for statistical method)
- The system is designed for clarity and ease of understanding, not production-scale performance
- All timestamps are in UTC
- Data is generated once per second as specified in requirements
- Failed measurements are stored in `backend/failed_measurements.jsonl` and automatically recovered on restart

## 🔧 Troubleshooting

**Port 8000 already in use:**
```bash
# Find and kill the process (macOS/Linux)
lsof -ti:8000 | xargs kill -9

# On Windows:
# netstat -ano | findstr :8000
# taskkill /PID <PID> /F
```

**Database locked errors:**
```bash
# Remove database and restart
rm sensor_data.db
./start.sh
```

**Import errors / ModuleNotFoundError:**
```bash
# Ensure virtual environment is activated
source .venv/bin/activate
pip install -r requirements.txt
```

**Dashboard not loading:**
- Verify API server is running: `curl http://localhost:8000/health`
- Check browser console for errors (F12 → Console tab)
- Ensure CORS is enabled in `api.py` (already configured)

**NumPy installation fails:**
- Use Python 3.9, 3.10, or 3.11 (NOT 3.13)
- If issues persist, try: `pip install --upgrade pip setuptools wheel`

---

## 🚀 Future Enhancements

Possible improvements for a production system:
- Switch to PostgreSQL for better concurrency and performance
- Add authentication and authorization (OAuth2/JWT)
- Implement more sophisticated ML-based anomaly detection (Isolation Forest, LSTM)
- Add real-time alert notifications (email/SMS/Slack)
- Containerization with Docker and Docker Compose
- Horizontal scaling with load balancer and distributed queue (Redis/RabbitMQ)
- Time-series optimized database (InfluxDB/TimescaleDB)
- WebSocket support for real-time dashboard updates
- Comprehensive unit and integration tests (pytest)
- CI/CD pipeline with automated testing and deployment

## 📄 License

This is a demonstration project for educational purposes.


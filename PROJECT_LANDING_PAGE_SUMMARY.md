# 🌾 AgriBase - AI-Powered Agricultural Intelligence Platform

## Project Overview

**AgriBase** is a comprehensive mobile application designed for Bangladeshi farmers and agricultural stakeholders, combining real-time environmental data, machine learning predictions, and AI-powered assistance to optimize farming decisions. Built with Flutter for cross-platform deployment, the app delivers actionable insights based on 100+ crops across all 64 districts of Bangladesh.

---

## 🚀 Core Features

### 1. 🤖 AI Hub - Intelligent Agricultural Assistant

**RAG-Enhanced Conversational AI**
- Natural language Q&A powered by Google Gemini AI
- Retrieval-Augmented Generation (RAG) for accurate crop-specific answers
- SQL-powered database queries for real-time statistics
- Bilingual support (English & Bangla)

**Ask anything:**
- "Which crop did best in 2023-24?"
- "What are the yield statistics for Boro rice?"
- "Best irrigation practices for Aman rice?"

### 2. 📊 ML-Powered Yield Predictions

**Machine Learning Models Used:**
- **ARIMA** (AutoRegressive Integrated Moving Average) - Time series forecasting
- **Bayesian Ridge Regression** - Probabilistic predictions with uncertainty estimates
- **Grey Model GM(1,1)** - Optimized background value forecasting
- **Holt's Linear Trend** - Exponential smoothing for trend analysis
- **Damped Holt's Method** - Best for small datasets with confidence intervals

**Prediction Outputs:**
- Area (Hectares) predictions per district
- Production (Metric Tons) forecasts
- 95% confidence intervals
- District-wise yield rankings

### 3. 🔬 Disease Scanner

**AI-Powered Plant Disease Detection**
- Camera integration for real-time scanning
- Image recognition for disease identification
- Treatment recommendations
- Disease severity assessment
- 6+ crop diseases supported

### 4. 🌤️ Real-Time Environmental Intelligence

**Weather Integration (Open-Meteo API)**
- Current temperature and conditions
- 7-day weather forecasts
- Precipitation probability
- Wind speed alerts
- Weather-based farming recommendations

**Soil Analysis (SoilGrids API)**
- pH level monitoring with interpretations
- Organic carbon content
- Clay/Sand/Silt composition
- Soil type classification
- Fertilizer recommendations based on soil data

### 5. 📈 Data Analytics & Visualization

**Interactive Charts (Syncfusion)**
- Pie charts for crop distribution
- Bar charts for yield comparisons
- Time series trends
- District-wise performance analysis

**Analytics Categories:**
- Rice varieties (Aman, Boro, Aus)
- Pulses & Oilseeds
- Fibre crops
- Spices & Condiments
- Fruits & Vegetables
- Sugar crops

### 6. 🗺️ Interactive Bangladesh Map

**Geographic Data Visualization**
- All 64 districts mapped
- Color-coded production heatmaps
- District-level crop statistics
- Tap-to-explore functionality
- Year-wise data filtering

### 7. 🧮 Agricultural Calculators

**Fertilizer Calculator**
- NPK ratio recommendations
- Application schedules
- Crop-specific guidance
- Area-based calculations

**Seed Calculator**
- Seed rate per hectare
- Germination adjustments
- Cost estimations
- Multi-unit support (Hectare, Bigha, Acre, Decimal)

### 8. 🔄 Crop Rotation Planner

**Smart Rotation Planning**
- AI-suggested rotation sequences
- Soil health impact analysis
- Multi-year planning (1-5 years)
- Nitrogen fixation optimization
- Disease break cycles

---

## 📱 App Screens & Navigation

### Main Navigation (Bottom Bar)
1. **🏠 Home** - Dashboard with personalized insights
2. **🧠 AI Hub** - Central AI features hub
3. **📊 Insights** - Analytics, Maps, Historical Data
4. **🔧 Tools** - Calculators, Rotation Planner, Settings

### Screen Breakdown

| Screen | Description |
|--------|-------------|
| **Home Dashboard** | Real-time weather, soil status, pest risk, dynamic insights carousel |
| **AI Hub** | Hero AI assistant card, Disease Scanner, Yield Predictor shortcuts |
| **Assistant** | Modern chat interface with RAG-enhanced responses |
| **Disease Scanner** | Camera/gallery image analysis with treatment recommendations |
| **Insights > Historical** | Year-wise crop data with district rankings |
| **Insights > Analytics** | Pie charts for crop categories distribution |
| **Insights > Map** | Interactive Bangladesh map with production heatmaps |
| **Insights > My Region** | District-specific top crops analysis |
| **Prediction** | ML-based next year forecasts by district |
| **Fertilizer Calculator** | NPK recommendations by crop |
| **Seed Calculator** | Seed rate calculations |
| **Crop Rotation** | Multi-year rotation planning |
| **Settings** | Theme, Language, Font size, Account management |

---

## 🛠️ Technical Architecture

### Frontend
- **Framework:** Flutter (Dart)
- **State Management:** Provider pattern
- **UI Components:** Material Design 3
- **Charts:** Syncfusion Flutter Charts
- **Maps:** Custom SVG-based Bangladesh map

### Backend Services
- **AI Engine:** Google Gemini 2.5 (Generative AI)
- **Weather API:** Open-Meteo (Free, no API key required)
- **Soil API:** SoilGrids REST API (250m resolution)
- **Location:** Geolocator + Nominatim reverse geocoding

### Database
- **Local:** SQLite with 4 databases
  - `crops.db` - Main crop data
  - `predictions.db` - ML predictions
  - `attempt.db` - Historical yearbook data
  - `agri-base.db` - App data

### ML Pipeline (Python)
- **Data Source:** Bangladesh Agricultural Yearbooks (PDF scraped)
- **Processing:** Pandas, NumPy
- **Models:** statsmodels, scikit-learn
- **Output:** CSV predictions imported to SQLite

---

## 📊 Data Coverage

### Crops Database
- **Total Crops:** 155+ varieties
- **Districts:** 64 (All of Bangladesh)
- **Time Range:** 2016-2024 historical data
- **Predictions:** 2025 forecasts for all crops

### Crop Categories
| Category | Examples |
|----------|----------|
| **Rice** | Aman (HYV, Bona, Ropa), Boro (HYV, Hybrid, Local), Aus |
| **Cereals** | Wheat, Maize, Barley, Millet |
| **Pulses** | Lentil, Chickpea, Mung Bean, Black Gram |
| **Oilseeds** | Mustard, Groundnut, Sesame, Soybean, Sunflower |
| **Vegetables** | Potato, Tomato, Brinjal, Cabbage, Cauliflower |
| **Fruits** | Mango, Banana, Litchi, Guava, Jackfruit |
| **Spices** | Onion, Garlic, Ginger, Turmeric, Chili |
| **Fibre** | Jute, Cotton |
| **Others** | Sugarcane, Tea, Tobacco, Flowers |

---

## 🔧 Development Journey

### Phase 1: Data Collection & Processing
1. Scraped Bangladesh Agricultural Yearbooks (2016-2024)
2. Extracted district-wise crop data from PDF tables
3. Cleaned and validated data using pandas
4. Created normalized CSV files for 155+ crops

### Phase 2: Machine Learning Model Development
1. **Exploratory Analysis** - Identified trends in crop production
2. **Model Selection** - Tested ARIMA, Bayesian Ridge, Grey Model, Holt's
3. **Model Optimization** - Tuned hyperparameters, added confidence intervals
4. **Batch Prediction** - Generated forecasts for all crops × all districts
5. **Validation** - Cross-validated with historical holdout data

### Phase 3: Mobile App Development
1. **Architecture Design** - Provider pattern, service layers
2. **Database Integration** - SQLite with asset bundling
3. **UI/UX Design** - Material Design 3 with dark mode
4. **API Integration** - Weather, Soil, and AI services
5. **Localization** - Full Bangla translation support

### Phase 4: AI Integration
1. **Gemini Integration** - Natural language processing
2. **RAG Implementation** - Document retrieval for enhanced answers
3. **SQL Generation** - AI-to-database query translation
4. **Disease Detection** - Image classification pipeline

### Phase 5: Production & Testing
1. **Real Device Testing** - GPS, camera, performance optimization
2. **Error Handling** - Graceful degradation for offline mode
3. **Documentation** - Comprehensive guides and summaries

---

## 🎯 Key Differentiators

| Feature | AgriBase | Traditional Apps |
|---------|----------|------------------|
| **AI Assistant** | RAG-enhanced Gemini with database access | Basic chatbot or none |
| **Predictions** | ML models with confidence intervals | Static data only |
| **Real-time Data** | Live weather + soil from APIs | Manual entry |
| **Coverage** | 155+ crops, 64 districts | Limited crops |
| **Language** | Full Bangla support | English only |
| **Offline** | Works with cached data | Online required |

---

## 📱 Platform Support

- ✅ Android (Primary target)
- ✅ iOS (Supported)
- ⚠️ Web (Limited - no SQLite FFI)
- ✅ Windows (Desktop)
- ✅ macOS (Desktop)
- ✅ Linux (Desktop)

---

## 🎨 Design Philosophy

### Theme Colors
- **Primary:** Deep Teal (`#004D40`)
- **AI Accent:** Deep Indigo (`#1A237E`) to Purple (`#4A148C`)
- **Success:** Green shades
- **Warning:** Orange/Amber
- **Background:** Clean white with subtle gradients

### UI Principles
- **Glassmorphism** - Frosted glass effects for modern look
- **Card-based Layout** - Information in digestible chunks
- **Progressive Disclosure** - Complex features revealed gradually
- **Accessibility** - Font size controls, high contrast support

---

## 📈 Impact & Use Cases

### For Farmers
- Make informed planting decisions based on predictions
- Get real-time weather alerts for field operations
- Identify crop diseases early for treatment
- Optimize fertilizer usage based on soil analysis

### For Agricultural Officers
- Access district-level statistics instantly
- Track crop performance trends over years
- Generate reports from comprehensive database
- Plan regional agricultural strategies

### For Researchers
- Analyze historical crop patterns
- Validate ML prediction models
- Study climate impact on agriculture
- Compare regional productivity

---

## 🔮 Future Roadmap

1. **TensorFlow Lite Integration** - On-device disease detection
2. **Satellite Imagery** - NDVI crop health monitoring
3. **Market Prices** - Real-time commodity pricing
4. **Community Features** - Farmer-to-farmer knowledge sharing
5. **IoT Integration** - Sensor data from smart farms
6. **Offline AI** - Local LLM for areas without internet

---

## 📞 Quick Facts

| Metric | Value |
|--------|-------|
| **Lines of Code** | 15,000+ (Dart) |
| **Database Records** | 100,000+ |
| **ML Predictions** | 10,000+ district×crop combinations |
| **API Integrations** | 4 (Gemini, Open-Meteo, SoilGrids, Nominatim) |
| **Supported Languages** | 2 (English, Bangla) |
| **App Size** | ~50MB (with all databases) |

---

## 🏆 Technology Stack Summary

```
┌─────────────────────────────────────────────────────────────┐
│                        AgriBase                             │
├─────────────────────────────────────────────────────────────┤
│  Frontend: Flutter/Dart + Material Design 3 + Syncfusion    │
├─────────────────────────────────────────────────────────────┤
│  State: Provider Pattern (8 providers)                      │
├─────────────────────────────────────────────────────────────┤
│  AI: Google Gemini 2.5 + Custom RAG Service                 │
├─────────────────────────────────────────────────────────────┤
│  ML: ARIMA, Bayesian Ridge, Grey Model, Holt's (Python)     │
├─────────────────────────────────────────────────────────────┤
│  Data: SQLite (4 DBs) + Open-Meteo + SoilGrids              │
├─────────────────────────────────────────────────────────────┤
│  Auth: Firebase Authentication                              │
└─────────────────────────────────────────────────────────────┘
```

---

**AgriBase** — *Empowering Bangladesh's Agriculture with AI*

🌱 From soil to statistics, from weather to wisdom — all in one app.

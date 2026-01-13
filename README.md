# 🌱 AgriBase: Data-Driven Agriculture

**Video Demo:** [Youtube](https://youtu.be/_6chsW2x7uo)

AgriBase is a comprehensive digital platform designed to democratize access to agricultural data in Bangladesh. Originally a web application, AgriBase has evolved into a feature-rich Flutter app, serving as a bridge between complex statistical data and the farmers, stakeholders, and researchers who need it most.

## What's New in the Flutter version:
We have transitioned from a Flask web backend to a robust Flutter Application to ensure mobile accessibility for users in the field.

- Mobile-First Flutter Architecture: A seamless, cross-platform mobile experience.

- Integrated AI Agent: A smart assistant that helps users query the database, answering questions like "Which district produces the most rice?" or "What is the yield trend for wheat?".

- Statistical Forecasting: Implementation of Damped Holt's Linear Trend to predict crop production for the upcoming year.

- Bilingual Support: Full localization in Bangla and English, ensuring the app is accessible to local farmers and international researchers alike.

- Dark Mode: Modern UI support for better visibility in different lighting conditions.

## The Data Journey: From PDF to Database
The backbone of AgriBase is its data. The official agricultural statistics for Bangladesh are locked away in the National Yearbook of Agricultural Statistics—a massive 696-page PDF containing hundreds of static tables and charts.

**The Challenge:** Searching for specific yield data or historical trends in a 700-page document is nearly impossible for the average user.

**Our Solution (The Extraction Process):**

1. Sourcing: We retrieved the official yearbook from the Bangladesh Government Statistics Website: [BBS](https://bbs.gov.bd/site/page/3e838eb6-30a2-4709-be85-40484b0c16c6/Yearbook-of-Agricultural-Statistics)

2. Extraction: We undertook the painstaking process of extracting tables and charts from the PDF.

3. Cleaning: Each dataset was converted into individual CSV files, cleaned of formatting errors, and normalized.

4. Structuring: The data was organized hierarchically into branch folders and then imported into a structured SQLite database.

This rigorous data engineering process allows AgriBase to serve instant, queryable data that was previously buried in digital paperwork.

## Key Features
1. AI & Predictive Analytics
Production Forecasting: We utilize Damped Holt's Linear Trend method, a robust time-series forecasting technique, to predict the production volume of all crops for the next year based on historical patterns.

The AI Consultant: An intelligent chatbot powered by LLMs that acts as an agricultural consultant, guiding users through data interpretation and app navigation.

2. Deep Data Analysis
- Area Summary: View production and area allocation for crops over multiple years.

- Yield Summary: Analyze per-acre yield amounts for specific crop varieties.

- Top Producers: Instantly identify which districts are top performers for specific crops, or conversely, which crops thrive in a specific district.

- Visual Insights: Interactive pie charts showing area distribution for better visualization of crop dominance.

3. Crop Analysis
Detailed breakdowns for major cereals (and expanding to all crops), allowing users to filter by district and crop type to get granular production metrics.

## Tech Stack & Tools
- Framework: Flutter (Dart)

- Database: SQLite

- Data Science: Python (Pandas), Statsmodels (Holt's Linear Trend)

- AI/LLM Integration: [Specify the API used, e.g., Gemini API, OpenAI, etc.]

**Built with the help of:**

- Github Copilot & Cursor: For rapid code generation and refactoring.

- Google Gemini: For debugging complex logic, internal server error resolution, and brainstorming data structure optimization.

## Future Roadmap
We are committed to making AgriBase the standard for agricultural intelligence in Bangladesh.

1. Expanded Crop Database: Inputting high-yielding and hybrid varieties with pros/cons for specific geographic locations.

2. Satellite Intelligence: Implementing Google Earth Engine to predict yields based on satellite imagery.

3. Computer Vision: Pest detection and disease identification via phone camera.

4. Introduce more variables: We will try to include more features in our data from official sources, which will help the farmers more.

5. Educational Hub: AI-guided tutoring for modern farming methods (Aquaponics, Hydroponics).

## Installation & Setup

You can install the apk in the release or to set up the project:

1. Clone the repository:



```{bash}
git clone https://github.com/jawatalsovon/MXB2026-Dhaka-AgriBase-AgriBase.git
```

2. Navigate to the project directory:

```{bash}
cd MXB2026-Dhaka-AgriBase-AgriBase/app
```
3. Install dependencies:

```{bash}
flutter pub get
```
4. Run the app:

```{bash}
flutter run
```
*"AgriBase is not just a project; it is a tool for agricultural decision-making, dedicated to farmers and stakeholders to ensure food security through data."*
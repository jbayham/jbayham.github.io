# Arches National Park Visitation Forecasting

A comprehensive teaching example demonstrating multiple forecasting methods for time series data using R.

## 📋 Overview

This project analyzes historical visitation data from Arches National Park and demonstrates three different forecasting approaches:

1. **Basic Trend Extrapolation** - Linear regression with seasonal dummies
2. **Time Series Methods** - ARIMA and ETS models
3. **Machine Learning** - Random Forest with engineered features

## 📁 Project Structure

```
forecast/
├── data/
│   └── arches.csv                    # Historical visitation data
├── arches_forecasting.R              # Main analysis script
├── FORECASTING_METHODS_GUIDE.md      # Detailed explanation of methods
└── README.md                         # This file
```

## 🚀 Getting Started

### Prerequisites

You'll need R (version 4.0 or higher recommended) and the following packages:

```r
install.packages(c(
  "tidyverse",      # Data manipulation and visualization
  "lubridate",      # Date/time handling
  "forecast",       # Time series forecasting
  "randomForest",   # Machine learning
  "zoo",            # Time series utilities
  "scales"          # Pretty number formatting
))
```

### Running the Analysis

1. **Open R or RStudio**

2. **Set your working directory** to the forecast folder:
   ```r
   setwd("/Users/judebayham/Library/CloudStorage/OneDrive-Colostate/teaching/arec_346/forecast")
   ```

3. **Run the main script**:
   ```r
   source("arches_forecasting.R")
   ```

The script will:
- Load and clean the data
- Perform exploratory data analysis
- Train all three types of models
- Compare model performance
- Generate visualizations
- Create future forecasts

## 📊 What the Analysis Does

### Data Preparation
- Loads monthly visitation data (1979-present)
- Creates proper date formatting
- Generates time indices and features

### Exploratory Analysis
- Time series plots showing overall trends
- Seasonal decomposition (monthly patterns)
- Annual visitation trends
- Boxplots by month

### Model Training & Evaluation
- **Train/Test Split**: 24-month holdout for testing
- **Linear Model**: Trend + seasonal dummies
- **ARIMA**: Auto-selected seasonal ARIMA
- **ETS**: Exponential smoothing
- **Random Forest**: With lag features, moving averages, and calendar variables

### Performance Metrics
All models evaluated using:
- **MAE**: Mean Absolute Error
- **RMSE**: Root Mean Squared Error  
- **MAPE**: Mean Absolute Percentage Error

### Visualizations Generated
1. Raw time series with trend line
2. Seasonal patterns (boxplots by month)
3. Annual visitation trends
4. Forecast comparison across all models
5. Forecasts in context (with recent historical data)
6. Residual diagnostics for ARIMA
7. Variable importance for Random Forest
8. Future 24-month forecast with confidence intervals

## 📈 Expected Results

Based on the analysis:

- **Best performing model**: Typically ARIMA or ETS (lowest MAPE)
- **Seasonal pattern**: Peak in summer (June-August), low in winter (December-February)
- **Long-term trend**: Generally increasing visitation over time
- **Forecast accuracy**: MAPE typically 5-15% for 24-month horizon

## 🎓 Teaching Notes

### Learning Objectives
Students will learn to:
- Prepare time series data for analysis
- Implement multiple forecasting techniques
- Compare model performance objectively
- Interpret forecast results and uncertainty
- Communicate findings effectively

### Key Concepts Covered
- Time series decomposition (trend, seasonality, residuals)
- Stationarity and differencing
- Autocorrelation and partial autocorrelation
- Feature engineering for ML models
- Cross-validation for time series
- Forecast evaluation metrics

### Discussion Questions
1. Why do different methods produce different forecasts?
2. What are the trade-offs between model complexity and interpretability?
3. How would external factors (e.g., gas prices, COVID-19) affect forecasts?
4. When would you choose one method over another?
5. How should park managers use these forecasts for planning?

## 📚 Additional Resources

- **FORECASTING_METHODS_GUIDE.md**: Detailed explanations of each method
- **Recommended reading**: "Forecasting: Principles and Practice" by Hyndman & Athanasopoulos
- **Online textbook**: https://otexts.com/fpp3/

## 🔧 Customization

### Changing the Forecast Horizon
Modify the train/test split:
```r
# Change 24 to desired number of months
train_size <- nrow(arches_clean) - 24  # Currently 24 months
```

### Adding External Variables
To incorporate external predictors (e.g., economic data):
```r
# Example: Add unemployment rate
external_data <- read_csv("external_variables.csv")
model_data <- train_data %>%
  left_join(external_data, by = "Date")

# Then include in models, e.g.:
lm_model <- lm(RecreationVisits ~ TimeIndex + MonthFactor + UnemploymentRate, 
               data = model_data)
```

### Trying Different ML Models
Replace Random Forest with other algorithms:
```r
# Gradient Boosting (install xgboost package)
library(xgboost)
# ... implementation here

# Support Vector Machine (install e1071 package)
library(e1071)
svm_model <- svm(RecreationVisits ~ ., data = train_rf)
```

## 📊 Sample Output

```
=== MODEL COMPARISON ===
             Model      MAE     RMSE   MAPE
1 Linear Regression 45231.21 56789.45  12.34
2            ARIMA 42103.56 53241.78  11.21
3              ETS 43567.89 54321.12  11.45
4    Random Forest 44890.23 55678.90  11.98

Best performing model (by MAPE): ARIMA
```

## 🐛 Troubleshooting

### Common Issues

**Problem**: Package installation fails
- **Solution**: Update R to the latest version, or install packages one at a time

**Problem**: "Object not found" errors
- **Solution**: Make sure you run the entire script from the beginning

**Problem**: Plots not displaying
- **Solution**: If using RStudio, check the Plots pane. If using base R, plots should open in a new window

**Problem**: ARIMA takes a long time
- **Solution**: Set `stepwise = TRUE` and `approximation = TRUE` in `auto.arima()` for faster (but less optimal) results

**Problem**: Random Forest predictions missing
- **Solution**: This is expected due to lag features requiring historical data. The model only predicts for dates where all features are available.

## 📝 Assignment Ideas

### Basic (Undergraduate)
1. Run the analysis and interpret the results
2. Create a presentation explaining which model performs best and why
3. Forecast the next 12 months and discuss uncertainty

### Intermediate
1. Add external variables (temperature, gas prices, etc.)
2. Compare different forecast horizons (6, 12, 24 months)
3. Implement model ensembles combining multiple forecasts

### Advanced (Graduate)
1. Implement hierarchical forecasting (monthly → quarterly → annual)
2. Add Bayesian methods with uncertainty quantification
3. Develop a Shiny app for interactive forecasting
4. Apply methods to other national parks and compare patterns

## 📧 Contact

For questions about this teaching example, contact:
- **Instructor**: Jude Bayham
- **Course**: AREC 346
- **Institution**: Colorado State University

## 📄 License

This educational material is provided for teaching purposes.

## 🙏 Acknowledgments

- Data source: National Park Service (NPS) Visitor Use Statistics
- Forecasting methods based on Hyndman & Athanasopoulos textbook
- R packages developed by the open-source community

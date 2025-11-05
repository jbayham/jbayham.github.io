# Forecasting Methods Guide: Arches National Park Visitation

## Overview
This guide explains the three main forecasting approaches demonstrated in the Arches NP analysis:

1. **Basic Trend Extrapolation** (Linear Regression)
2. **Time Series Methods** (ARIMA and ETS)
3. **Machine Learning** (Random Forest)

---

## Method 1: Linear Trend Extrapolation

### What it is
Linear regression with time trend and seasonal dummy variables. This is the simplest approach to forecasting.

### How it works
The model takes the form:
```
Visits_t = β₀ + β₁×Time + β₂×Feb + β₃×Mar + ... + β₁₂×Dec + ε_t
```

Where:

- **Time**: A sequential index (1, 2, 3, ...) representing the passage of time
- **Month dummies**: Binary variables (0 or 1) for each month to capture seasonality
- **β coefficients**: Estimated parameters that capture the trend and seasonal effects

### Strengths

- ✅ **Simple and interpretable**: Easy to explain to stakeholders
- ✅ **Fast to compute**: Runs quickly even on large datasets
- ✅ **Transparent**: Clear understanding of what drives the forecast
- ✅ **Baseline model**: Good starting point for comparison

### Weaknesses

- ❌ **Linear assumption**: Assumes a constant rate of change over time
- ❌ **No autocorrelation**: Ignores the fact that adjacent time points are related
- ❌ **Fixed seasonality**: Seasonal patterns assumed constant over time
- ❌ **Limited complexity**: Cannot capture nonlinear patterns or changing trends

### When to use

- Quick exploratory analysis
- When you need a simple, explainable baseline
- When the data shows a relatively stable linear trend
- For communication with non-technical audiences

---

## Method 2: Time Series Methods (ARIMA & ETS)

### 2A: ARIMA (AutoRegressive Integrated Moving Average)

#### What it is
A sophisticated statistical model that captures patterns in the correlation structure of time series data.

#### How it works

ARIMA models have three components (p, d, q):

- **AR (p)**: AutoRegressive - uses past values to predict future
- **I (d)**: Integrated - differencing to make the series stationary
- **MA (q)**: Moving Average - uses past forecast errors

For seasonal data, we add seasonal components (P, D, Q, m):
```
ARIMA(p,d,q)(P,D,Q)[m]
```

**Example**: ARIMA(1,1,1)(1,1,1)[12]

- Non-seasonal: AR(1), I(1), MA(1)
- Seasonal: seasonal AR(1), seasonal I(1), seasonal MA(1), with period 12 (monthly)

#### Key concepts

1. **Stationarity**: The statistical properties (mean, variance) don't change over time
2. **Differencing**: Subtracting previous values to remove trends
3. **ACF/PACF**: Tools to identify the appropriate p and q values
4. **Information Criteria**: AIC/BIC to select the best model

#### Strengths

- ✅ **Captures autocorrelation**: Leverages the relationship between time points
- ✅ **Flexible**: Can model many different patterns
- ✅ **Statistically rigorous**: Based on solid mathematical foundation
- ✅ **Confidence intervals**: Provides uncertainty estimates
- ✅ **Auto-selection**: `auto.arima()` finds optimal parameters

#### Weaknesses

- ❌ **Black box**: Can be hard to interpret for non-statisticians
- ❌ **Requires stationarity**: May need data transformations
- ❌ **Computationally intensive**: Especially for model selection
- ❌ **Sensitive to outliers**: Extreme values can distort forecasts

### 2B: ETS (Error, Trend, Seasonal)

#### What it is
An alternative time series approach based on exponential smoothing, which weights recent observations more heavily.

#### How it works
ETS decomposes the series into three components:

- **Error**: How errors are added (additive 'A' or multiplicative 'M')
- **Trend**: Type of trend (none 'N', additive 'A', or multiplicative 'M')
- **Seasonal**: Type of seasonality (none 'N', additive 'A', or multiplicative 'M')

**Example**: ETS(M,Ad,M)
- Multiplicative errors
- Additive damped trend
- Multiplicative seasonality

#### Key concepts
1. **Smoothing parameters**: α (level), β (trend), γ (seasonal)
2. **State space framework**: Modern statistical representation
3. **Additive vs. Multiplicative**: Choose based on whether variation is constant or proportional

#### Strengths
- ✅ **Intuitive**: Based on weighted averages
- ✅ **Automatic selection**: Chooses best model structure
- ✅ **Handles seasonality well**: Particularly multiplicative patterns
- ✅ **Fast**: Generally quicker than ARIMA
- ✅ **Robust**: Often performs well without tuning

#### Weaknesses
- ❌ **Less flexible**: Fewer model variations than ARIMA
- ❌ **Limited for complex patterns**: May underperform on irregular series
- ❌ **Parameter interpretation**: Less intuitive than regression

### When to use Time Series Methods
- Data shows clear temporal dependencies
- Regular seasonal patterns exist
- Need probabilistic forecasts with confidence intervals
- Medium to long-term forecasting
- Have sufficient historical data (typically 2+ years)

---

## Method 3: Machine Learning (Random Forest)

### What it is
An ensemble machine learning algorithm that creates multiple decision trees and averages their predictions.

### How it works
1. **Bootstrap samples**: Create many random samples of the data
2. **Build trees**: Train a decision tree on each sample
3. **Random features**: At each split, consider only a random subset of features
4. **Average predictions**: Combine all tree predictions (voting or averaging)

#### Feature Engineering for Time Series
Since ML algorithms don't inherently understand time, we create features:

**Temporal features**:
- Time index (sequential numbering)
- Month, quarter, year
- Day of week, day of month

**Lag features**:
- Previous values: Lag12 (same month last year)
- Multiple lags: Lag1, Lag2, Lag3, etc.

**Rolling statistics**:
- Moving averages: MA3 (3-month), MA12 (12-month)
- Rolling standard deviations
- Min/max over windows

**Trend components**:
- Linear or polynomial time trends
- Difference from previous period

#### Strengths
- ✅ **Handles nonlinearity**: Captures complex, non-linear relationships
- ✅ **Feature interactions**: Automatically identifies important combinations
- ✅ **Robust to outliers**: Tree-based methods are less sensitive
- ✅ **No distributional assumptions**: Works without normality assumptions
- ✅ **Variable importance**: Shows which features matter most
- ✅ **Handles multiple predictors**: Can incorporate external variables easily

#### Weaknesses
- ❌ **Requires feature engineering**: Must manually create time-based features
- ❌ **No confidence intervals**: Doesn't naturally provide prediction intervals
- ❌ **Data hungry**: Needs more data than statistical methods
- ❌ **Extrapolation issues**: May not forecast beyond historical range well
- ❌ **Less interpretable**: Harder to explain why a forecast was made
- ❌ **Tuning required**: Multiple hyperparameters to optimize

### When to use Machine Learning
- You have external predictors (weather, economics, marketing, etc.)
- The relationship is highly nonlinear
- You have large amounts of data
- Pattern is complex and irregular
- Short-term forecasting
- When interpretability is less critical than accuracy

---

## Model Selection Guidelines

### Decision Framework

```
START
  ↓
Need simple, explainable model? → YES → Linear Regression
  ↓ NO
  ↓
Have regular seasonal patterns? → YES → ARIMA or ETS
  ↓ NO
  ↓
Have external predictors? → YES → Random Forest or other ML
  ↓ NO
  ↓
Nonlinear, complex patterns? → YES → Random Forest
  ↓ NO
  ↓
DEFAULT → Try all methods and compare
```

### Evaluation Metrics

**MAE (Mean Absolute Error)**
- Average absolute difference between forecast and actual
- Easy to interpret (in original units)
- Formula: `MAE = mean(|actual - forecast|)`

**RMSE (Root Mean Squared Error)**
- Square root of average squared errors
- Penalizes large errors more than MAE
- Formula: `RMSE = sqrt(mean((actual - forecast)²))`

**MAPE (Mean Absolute Percentage Error)**
- Average absolute percentage error
- Scale-independent (good for comparing across datasets)
- Formula: `MAPE = mean(|actual - forecast| / |actual|) × 100`

### Best Practices

1. **Always create a holdout test set**
   - Reserve 10-20% of recent data for testing
   - Never train on test data
   - Test set should reflect the forecasting horizon

2. **Compare multiple methods**
   - No single method is always best
   - Context and data characteristics matter
   - Consider ensemble approaches

3. **Check residuals**
   - Should be random (white noise)
   - No patterns should remain
   - Use ACF plots and statistical tests

4. **Consider forecast horizon**
   - Short-term: ML often works well
   - Medium-term: Time series methods excel
   - Long-term: Simple methods may be more robust

5. **Retrain regularly**
   - Update models with new data
   - Monitor forecast accuracy
   - Adjust methods if performance degrades

6. **Communicate uncertainty**
   - Always provide confidence/prediction intervals
   - Explain limitations to stakeholders
   - Update forecasts as new information arrives

---

## Advanced Topics (Optional Extensions)

### Ensemble Methods
Combine multiple forecasts for better accuracy:
```r
ensemble_forecast = 0.4×ARIMA + 0.4×ETS + 0.2×RF
```

### Prophet (Facebook's Time Series Tool)
- Handles multiple seasonality
- Robust to missing data
- Easy to incorporate holidays

### Neural Networks
- LSTM for sequence modeling
- Deep learning for complex patterns
- Requires substantial data

### External Regressors
Include additional variables:
- Economic indicators (GDP, unemployment)
- Weather data (temperature, precipitation)
- Marketing spend
- Competitor actions
- Special events

### Hierarchical Forecasting
Forecast at different aggregation levels:
- Total park visitation
- By region/section
- By visitor type
- Reconcile forecasts for consistency

---

## Common Pitfalls to Avoid

1. **Overfitting**: Model too complex for the data
2. **Data leakage**: Using future information in training
3. **Ignoring seasonality**: Missing obvious patterns
4. **Not checking assumptions**: Violating model requirements
5. **Extrapolating too far**: Forecasts become unreliable
6. **Ignoring structural breaks**: Major events change patterns
7. **Using wrong metrics**: Choosing inappropriate evaluation criteria

---

## Recommended Reading

### Books
- **"Forecasting: Principles and Practice"** by Hyndman & Athanasopoulos (free online)
- **"Time Series Analysis and Its Applications"** by Shumway & Stoffer
- **"The Elements of Statistical Learning"** by Hastie, Tibshirani & Friedman

### R Packages
- `forecast`: Comprehensive time series forecasting
- `fable`: Tidy time series forecasting
- `prophet`: Facebook's forecasting tool
- `tidymodels`: Unified ML framework
- `tsibble`: Tidy temporal data

### Online Resources
- [OTexts Forecasting Book](https://otexts.com/fpp3/)
- [Kaggle Time Series Tutorials](https://www.kaggle.com/learn/time-series)
- [Cross Validated](https://stats.stackexchange.com/questions/tagged/forecasting)

---

## Summary Table

| Method | Complexity | Interpretability | Data Needs | Best For |
|--------|-----------|------------------|------------|----------|
| Linear Regression | Low | High | Low | Baseline, simple trends |
| ARIMA | Medium | Medium | Medium | Regular patterns, statistical rigor |
| ETS | Medium | Medium | Medium | Strong seasonality, quick results |
| Random Forest | High | Low | High | Complex patterns, many predictors |

---

## Questions for Class Discussion

1. Why might a simpler model sometimes outperform a complex one?
2. How would you decide between ARIMA and ETS for a new dataset?
3. What external variables could improve the Arches NP forecast?
4. How would you communicate forecast uncertainty to park managers?
5. What are the ethical considerations in forecasting visitor numbers?

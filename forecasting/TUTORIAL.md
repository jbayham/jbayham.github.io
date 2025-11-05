# Step-by-Step Tutorial: Forecasting Arches NP Visitation

This tutorial walks you through the forecasting analysis step by step, explaining what each section does.

## Step 1: Load Required Libraries

```r
library(tidyverse)    # For data manipulation (dplyr, ggplot2, etc.)
library(lubridate)    # For working with dates
library(forecast)     # For ARIMA and ETS models
library(randomForest) # For machine learning
library(zoo)          # For rolling statistics
library(scales)       # For pretty number formatting
```

**What this does**: Loads the tools we need for the analysis.

---

## Step 2: Load and Prepare the Data

```r
# Load data
arches_data <- read_csv("data/arches.csv")

# Clean the data
arches_clean <- arches_data %>%
  # Remove commas and convert to numbers
  mutate(RecreationVisits = as.numeric(gsub(",", "", RecreationVisits)),
         Year = as.numeric(Year),
         Month = as.numeric(Month)) %>%
  # Create a proper date column
  mutate(Date = make_date(Year, Month, 1)) %>%
  # Keep only what we need
  select(Date, Year, Month, RecreationVisits) %>%
  # Sort by date
  arrange(Date) %>%
  # Add row numbers for time index
  mutate(TimeIndex = row_number())
```

**What this does**: 
- Reads the CSV file
- Removes commas from numbers like "2,970" → 2970
- Creates a proper date column from Year and Month
- Adds a TimeIndex (1, 2, 3, ...) to track time progression

**Look at the data**:
```r
head(arches_clean)
summary(arches_clean)
```

---

## Step 3: Visualize the Data

### Overall Trend

```r
ggplot(arches_clean, aes(x = Date, y = RecreationVisits)) +
  geom_line(color = "steelblue") +
  labs(title = "Arches NP Monthly Visitation",
       x = "Date",
       y = "Visits") +
  theme_minimal()
```

**What to look for**:
- Overall trend (increasing, decreasing, stable?)
- Seasonal patterns (repeating cycles?)
- Outliers or unusual points

### Seasonal Pattern

```r
arches_clean %>%
  mutate(MonthName = month(Date, label = TRUE)) %>%
  ggplot(aes(x = MonthName, y = RecreationVisits)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Visitation by Month",
       x = "Month",
       y = "Visits") +
  theme_minimal()
```

**What to look for**:
- Which months have highest visitation?
- How much does it vary month to month?
- Are there outliers in certain months?

---

## Step 4: Split into Training and Test Sets

```r
# Keep last 24 months for testing
train_size <- nrow(arches_clean) - 24
train_data <- arches_clean[1:train_size, ]
test_data <- arches_clean[(train_size + 1):nrow(arches_clean), ]
```

**Why?** 
- Train models on older data
- Test how well they predict recent (known) data
- This simulates real forecasting: using past to predict future

---

## Step 5: Method 1 - Linear Regression

### Fit the Model

```r
train_data <- train_data %>%
  mutate(MonthFactor = factor(Month))

lm_model <- lm(RecreationVisits ~ TimeIndex + MonthFactor, 
               data = train_data)

summary(lm_model)
```

**What this means**:
- `TimeIndex`: Captures the overall trend (going up or down over time)
- `MonthFactor`: Captures seasonal patterns (Jan vs Feb vs Mar, etc.)
- The model learns how much each month differs from the baseline

### Make Predictions

```r
test_data <- test_data %>%
  mutate(MonthFactor = factor(Month))

lm_predictions <- predict(lm_model, newdata = test_data)
```

### Evaluate Accuracy

```r
lm_mae <- mean(abs(test_data$RecreationVisits - lm_predictions))
lm_rmse <- sqrt(mean((test_data$RecreationVisits - lm_predictions)^2))
lm_mape <- mean(abs((test_data$RecreationVisits - lm_predictions) / 
                      test_data$RecreationVisits)) * 100

cat("MAE: ", lm_mae, "\n")
cat("RMSE:", lm_rmse, "\n")
cat("MAPE:", lm_mape, "%\n")
```

**Interpretation**:
- **MAE**: Average error in number of visits
- **RMSE**: Like MAE but penalizes big errors more
- **MAPE**: Percentage error (easier to interpret)

---

## Step 6: Method 2A - ARIMA Model

### Create Time Series Object

```r
train_ts <- ts(train_data$RecreationVisits, 
               start = c(train_data$Year[1], train_data$Month[1]), 
               frequency = 12)
```

**What this does**: Tells R this is monthly data (frequency = 12)

### Fit ARIMA

```r
arima_model <- auto.arima(train_ts, seasonal = TRUE)
summary(arima_model)
```

**What `auto.arima` does**:
- Tries many different ARIMA specifications
- Picks the best one based on AIC (quality metric)
- Considers both trend and seasonality

### Forecast

```r
arima_forecast <- forecast(arima_model, h = 24)
arima_predictions <- as.numeric(arima_forecast$mean)

# Visualize
plot(arima_forecast)
```

### Evaluate

```r
arima_mae <- mean(abs(test_data$RecreationVisits - arima_predictions))
arima_rmse <- sqrt(mean((test_data$RecreationVisits - arima_predictions)^2))
arima_mape <- mean(abs((test_data$RecreationVisits - arima_predictions) / 
                         test_data$RecreationVisits)) * 100
```

---

## Step 7: Method 2B - ETS Model

### Fit ETS

```r
ets_model <- ets(train_ts)
summary(ets_model)
```

**What ETS does**:
- **E**rror: How errors behave
- **T**rend: How the trend changes
- **S**easonal: How seasons repeat

### Forecast

```r
ets_forecast <- forecast(ets_model, h = 24)
ets_predictions <- as.numeric(ets_forecast$mean)

plot(ets_forecast)
```

### Evaluate

```r
ets_mae <- mean(abs(test_data$RecreationVisits - ets_predictions))
ets_rmse <- sqrt(mean((test_data$RecreationVisits - ets_predictions)^2))
ets_mape <- mean(abs((test_data$RecreationVisits - ets_predictions) / 
                       test_data$RecreationVisits)) * 100
```

---

## Step 8: Method 3 - Random Forest

### Create Features

Random Forest doesn't understand "time" on its own, so we create helpful features:

```r
create_features <- function(data) {
  data %>%
    mutate(
      TimeIndex = row_number(),
      MonthFactor = factor(Month),
      Quarter = quarter(Date),
      Lag12 = lag(RecreationVisits, 12),  # Same month last year
      MA3 = rollmean(RecreationVisits, k = 3, fill = NA, align = "right"),
      MA12 = rollmean(RecreationVisits, k = 12, fill = NA, align = "right")
    )
}

train_rf <- create_features(train_data) %>%
  filter(!is.na(Lag12) & !is.na(MA3) & !is.na(MA12))
```

**Features explained**:
- **TimeIndex**: Time progression
- **MonthFactor**: Which month (1-12)
- **Quarter**: Which quarter (1-4)
- **Lag12**: Visits from same month last year
- **MA3**: Average of last 3 months
- **MA12**: Average of last 12 months

### Train Random Forest

```r
set.seed(42)  # For reproducibility
rf_model <- randomForest(
  RecreationVisits ~ TimeIndex + MonthFactor + Quarter + Lag12 + MA3 + MA12,
  data = train_rf,
  ntree = 500,    # Number of trees
  importance = TRUE
)

print(rf_model)
```

### Variable Importance

```r
varImpPlot(rf_model)
```

**What this shows**: Which features are most useful for prediction

### Predict and Evaluate

```r
# Prepare test data
full_data <- bind_rows(
  train_data %>% mutate(Set = "train"),
  test_data %>% mutate(Set = "test")
) %>%
  create_features()

test_rf <- full_data %>%
  filter(Set == "test", !is.na(Lag12), !is.na(MA3), !is.na(MA12))

rf_predictions <- predict(rf_model, newdata = test_rf)

rf_mae <- mean(abs(test_rf$RecreationVisits - rf_predictions))
rf_rmse <- sqrt(mean((test_rf$RecreationVisits - rf_predictions)^2))
rf_mape <- mean(abs((test_rf$RecreationVisits - rf_predictions) / 
                      test_rf$RecreationVisits)) * 100
```

---

## Step 9: Compare All Models

```r
comparison <- data.frame(
  Model = c("Linear Regression", "ARIMA", "ETS", "Random Forest"),
  MAE = c(lm_mae, arima_mae, ets_mae, rf_mae),
  RMSE = c(lm_rmse, arima_rmse, ets_rmse, rf_rmse),
  MAPE = c(lm_mape, arima_mape, ets_mape, rf_mape)
) %>%
  arrange(MAPE)  # Sort by accuracy

print(comparison)
```

**What to look for**:
- Which model has the lowest MAPE?
- Are the differences large or small?
- Do all models perform reasonably well?

---

## Step 10: Visualize Forecast Comparison

```r
forecast_df <- test_data %>%
  mutate(
    Actual = RecreationVisits,
    LinearReg = lm_predictions,
    ARIMA = arima_predictions,
    ETS = ets_predictions
  ) %>%
  pivot_longer(cols = c(Actual, LinearReg, ARIMA, ETS),
               names_to = "Model",
               values_to = "Visits")

ggplot(forecast_df, aes(x = Date, y = Visits, color = Model)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = comma) +
  labs(title = "Forecast Comparison: Test Period",
       x = "Date",
       y = "Visits") +
  theme_minimal()
```

**What to look for**:
- How close are forecasts to actual values?
- Do some models track actual better than others?
- Are there periods where all models struggle?

---

## Step 11: Check Model Assumptions (ARIMA)

```r
checkresiduals(arima_model)
```

**What to look for**:
- **Residual plot**: Should look random (no pattern)
- **ACF plot**: Should stay within blue lines
- **Histogram**: Should look roughly normal
- **Ljung-Box test**: p-value > 0.05 is good (residuals are random)

---

## Step 12: Make Future Forecasts

Once you've selected the best model, refit on ALL data and forecast into the future:

```r
# Refit on full dataset
full_ts <- ts(arches_clean$RecreationVisits,
              start = c(arches_clean$Year[1], arches_clean$Month[1]),
              frequency = 12)

final_model <- auto.arima(full_ts, seasonal = TRUE)

# Forecast 24 months ahead
future_forecast <- forecast(final_model, h = 24)

# Plot
plot(future_forecast, main = "24-Month Forecast for Arches NP")
```

**The shaded areas**:
- **Dark shade**: 80% confidence interval
- **Light shade**: 95% confidence interval
- The forecast is the blue line in the middle

---

## Key Takeaways

### When to Use Each Method

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| Linear Regression | Quick baseline | Simple, fast, interpretable | Assumes linear trend, fixed seasonality |
| ARIMA | Standard forecasting | Handles autocorrelation, flexible | Can be complex, needs stationarity |
| ETS | Seasonal data | Intuitive, automatic | Less flexible than ARIMA |
| Random Forest | Complex patterns | Handles nonlinearity, external variables | Needs feature engineering, less interpretable |

### Checklist for Your Analysis

- [ ] Visualize the data first
- [ ] Check for seasonality and trend
- [ ] Split data into train/test
- [ ] Try multiple methods
- [ ] Compare using consistent metrics
- [ ] Check model assumptions (especially for ARIMA)
- [ ] Consider forecast uncertainty
- [ ] Refit on full data for final forecasts

### Common Mistakes to Avoid

1. ❌ Training and testing on the same data
2. ❌ Ignoring obvious seasonal patterns
3. ❌ Only using one method
4. ❌ Not checking residuals
5. ❌ Forecasting too far into the future
6. ❌ Treating forecasts as certainties

---

## Practice Exercises

### Exercise 1: Sensitivity Analysis
- Change the train/test split ratio
- How does this affect model accuracy?
- Which model is most sensitive?

### Exercise 2: Different Horizons
- Try forecasting 6, 12, and 36 months
- How does accuracy change with horizon?
- Why might longer forecasts be less accurate?

### Exercise 3: Feature Engineering
- Add new features to the Random Forest (e.g., Lag24, different moving averages)
- Does this improve accuracy?
- Which new features are most important?

### Exercise 4: Model Ensemble
- Create a combined forecast: average of ARIMA and ETS
- Does it outperform individual models?
- Try weighted averages based on past performance

### Exercise 5: Interpretation
- Write a one-page memo to park managers
- Explain your forecast in non-technical terms
- Include recommendations based on your findings

---

## Need Help?

### Debugging Tips

**Error: "object not found"**
- Make sure you ran all previous code chunks
- Check variable names for typos

**Error: "could not find function"**
- Did you load the required library?
- Run `library(packagename)` again

**Plots not showing**
- Click on "Plots" tab in RStudio
- Try `print(plot_object)`

**ARIMA taking forever**
- Add `stepwise = TRUE` to `auto.arima()`
- This makes it faster but potentially less optimal

### Resources

- R Documentation: `?auto.arima`, `?ets`, `?randomForest`
- Stack Overflow: Search "R time series forecasting"
- Course materials: See FORECASTING_METHODS_GUIDE.md

---

## Next Steps

Once you're comfortable with this analysis:

1. Apply it to other national parks
2. Add external variables (weather, economics)
3. Try Prophet or other methods
4. Build an interactive dashboard with Shiny
5. Write up results as a professional report

Good luck with your forecasting! 🎯

# ============================================================================
# Forecasting Arches National Park Visitation
# Teaching Example: Multiple Forecasting Methods
# ============================================================================
setwd("~/Library/CloudStorage/OneDrive-Colostate/teaching/arec_346/other_material/forecast")

# Load required libraries
library(tidyverse)    # Data manipulation and visualization
library(lubridate)    # Date handling
library(forecast)     # Time series forecasting
library(randomForest) # Machine learning
library(zoo)          # Time series utilities
library(scales)       # Pretty formatting

# ============================================================================
# 1. DATA PREPARATION
# ============================================================================

# Load the data
arches_data <- read_csv("data/arches.csv")

# Clean and prepare the data
arches_clean <- arches_data %>%
  # Remove commas from numeric columns and convert to numeric
  mutate(RecreationVisits = as.numeric(gsub(",", "", RecreationVisits)),
         Year = as.numeric(Year),
         Month = as.numeric(Month)) %>%
  # Create a proper date column
  mutate(Date = make_date(Year, Month, 1)) %>%
  # Select only the columns we need
  select(Date, Year, Month, RecreationVisits) %>%
  # Arrange by date
  arrange(Date) %>%
  # Add time index
  mutate(TimeIndex = row_number())

# Display summary statistics
cat("\n=== DATA SUMMARY ===\n")
print(summary(arches_clean))
cat("\nDate Range:", as.character(min(arches_clean$Date)), "to", 
    as.character(max(arches_clean$Date)), "\n")
cat("Total Observations:", nrow(arches_clean), "\n")

# Visualize the raw data
p1 <- ggplot(arches_clean, aes(x = Date, y = RecreationVisits)) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_smooth(method = "loess", se = FALSE, color = "red", linetype = "dashed") +
  scale_y_continuous(labels = comma) +
  labs(title = "Arches National Park: Monthly Recreation Visits",
       subtitle = "Raw time series with smoothed trend",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

print(p1)

# ============================================================================
# 2. EXPLORATORY DATA ANALYSIS
# ============================================================================

cat("\n=== EXPLORATORY DATA ANALYSIS ===\n")

# Decompose seasonality visually
arches_clean <- arches_clean %>%
  mutate(MonthName = month(Date, label = TRUE, abbr = FALSE))

# Seasonality plot
p2 <- ggplot(arches_clean, aes(x = MonthName, y = RecreationVisits)) +
  geom_boxplot(fill = "lightblue", alpha = 0.7) +
  scale_y_continuous(labels = comma) +
  labs(title = "Seasonal Patterns in Arches NP Visitation",
       subtitle = "Boxplots show distribution by month across all years",
       x = "Month",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p2)

# Yearly growth trend
yearly_summary <- arches_clean %>%
  group_by(Year) %>%
  summarize(AnnualVisits = sum(RecreationVisits, na.rm = TRUE),
            .groups = "drop")

p3 <- ggplot(yearly_summary, aes(x = Year, y = AnnualVisits)) +
  geom_line(color = "darkgreen", linewidth = 1) +
  geom_point(color = "darkgreen", size = 2) +
  scale_y_continuous(labels = comma) +
  labs(title = "Annual Visitation Trend",
       x = "Year",
       y = "Total Annual Visits") +
  theme_minimal()

print(p3)

# ============================================================================
# 3. TRAIN-TEST SPLIT
# ============================================================================

# Reserve last 24 months for testing
train_size <- nrow(arches_clean) - 24
train_data <- arches_clean[1:train_size, ]
test_data <- arches_clean[(train_size + 1):nrow(arches_clean), ]

cat("\nTraining data:", nrow(train_data), "observations\n")
cat("Test data:", nrow(test_data), "observations\n")
cat("Test period:", as.character(min(test_data$Date)), "to", 
    as.character(max(test_data$Date)), "\n")

# ============================================================================
# 4. METHOD 1: BASIC TREND EXTRAPOLATION (LINEAR REGRESSION)
# ============================================================================

cat("\n=== METHOD 1: LINEAR TREND EXTRAPOLATION ===\n")

# Fit linear model with time index and seasonal dummies
train_data <- train_data %>%
  mutate(MonthFactor = factor(Month))

lm_model <- lm(RecreationVisits ~ TimeIndex + MonthFactor, data = train_data)

# Display model summary
cat("\nLinear Model Summary:\n")
print(summary(lm_model))

# Make predictions on test set
test_data <- test_data %>%
  mutate(MonthFactor = factor(Month))

lm_predictions <- predict(lm_model, newdata = test_data)

#Plot predictions against actuals
p_lm <- ggplot() +
  geom_line(data = test_data, aes(x = Date, y = RecreationVisits), color = "black", linewidth = 1) +
  geom_line(data = test_data, aes(x = Date, y = lm_predictions), color = "blue", linetype = "dashed", linewidth = 1) +
  scale_y_continuous(labels = comma) +
  labs(title = "Linear Model: Actual vs Predicted Visits",
       x = NULL,
       y = "Recreation Visits") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

print(p_lm)

# Calculate accuracy metrics
lm_mae <- mean(abs(test_data$RecreationVisits - lm_predictions))
lm_rmse <- sqrt(mean((test_data$RecreationVisits - lm_predictions)^2))
lm_mape <- mean(abs((test_data$RecreationVisits - lm_predictions) / 
                      test_data$RecreationVisits)) * 100

cat("\nLinear Model Performance:\n")
cat("MAE: ", format(lm_mae, big.mark = ","), "\n")
cat("RMSE:", format(lm_rmse, big.mark = ","), "\n")
cat("MAPE:", round(lm_mape, 2), "%\n")

# ============================================================================
# 5. METHOD 2: TIME SERIES METHODS (ARIMA and ETS)
# ============================================================================

cat("\n=== METHOD 2: TIME SERIES FORECASTING ===\n")

# Create time series object
train_ts <- ts(train_data$RecreationVisits, 
               start = c(train_data$Year[1], train_data$Month[1]), 
               frequency = 12)

# 5.1 ARIMA Model
cat("\n--- ARIMA Model ---\n")
arima_model <- auto.arima(train_ts, seasonal = TRUE, stepwise = FALSE, 
                          approximation = FALSE)
cat("\nAuto-selected ARIMA model:\n")
print(summary(arima_model))

# Forecast with ARIMA
arima_forecast <- forecast(arima_model, h = 24)
autoplot(arima_forecast) +
  labs(title = "ARIMA Model Forecast",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))


arima_predictions <- as.numeric(arima_forecast$mean)

# Calculate ARIMA accuracy
arima_mae <- mean(abs(test_data$RecreationVisits - arima_predictions))
arima_rmse <- sqrt(mean((test_data$RecreationVisits - arima_predictions)^2))
arima_mape <- mean(abs((test_data$RecreationVisits - arima_predictions) / 
                         test_data$RecreationVisits)) * 100

cat("\nARIMA Performance:\n")
cat("MAE: ", format(arima_mae, big.mark = ","), "\n")
cat("RMSE:", format(arima_rmse, big.mark = ","), "\n")
cat("MAPE:", round(arima_mape, 2), "%\n")

# 5.2 ETS (Exponential Smoothing) Model
cat("\n--- ETS Model ---\n")
ets_model <- ets(train_ts)
cat("\nETS model:\n")
print(summary(ets_model))

#Decompose ETS components and plot using ggplot
ets_decomp <- decompose(train_ts)
autoplot(ets_decomp) +
  labs(title = "ETS Model Decomposition",
       x = "Date") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))


# Forecast with ETS
ets_forecast <- forecast(ets_model, h = 24)
autoplot(ets_forecast) +
  labs(title = "ETS Model Forecast",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

ets_predictions <- as.numeric(ets_forecast$mean)

# Calculate ETS accuracy
ets_mae <- mean(abs(test_data$RecreationVisits - ets_predictions))
ets_rmse <- sqrt(mean((test_data$RecreationVisits - ets_predictions)^2))
ets_mape <- mean(abs((test_data$RecreationVisits - ets_predictions) / 
                       test_data$RecreationVisits)) * 100

cat("\nETS Performance:\n")
cat("MAE: ", format(ets_mae, big.mark = ","), "\n")
cat("RMSE:", format(ets_rmse, big.mark = ","), "\n")
cat("MAPE:", round(ets_mape, 2), "%\n")

# ============================================================================
# 6. METHOD 3: MACHINE LEARNING (RANDOM FOREST)
# ============================================================================

cat("\n=== METHOD 3: RANDOM FOREST (MACHINE LEARNING) ===\n")

# Create feature-engineered dataset
create_features <- function(data) {
  data %>%
    mutate(
      # Time features
      TimeIndex = row_number(),
      
      # Calendar features
      MonthFactor = factor(Month),
      Quarter = quarter(Date),
      
      # Lag features (previous year same month)
      Lag12 = lag(RecreationVisits, 12),
      
      # Rolling averages (3-month and 12-month)
      MA3 = rollmean(RecreationVisits, k = 3, fill = NA, align = "right"),
      MA12 = rollmean(RecreationVisits, k = 12, fill = NA, align = "right"),
      
      # Trend
      Trend = row_number()
    )
}

# Apply feature engineering
train_rf <- create_features(train_data) %>%
  filter(!is.na(Lag12) & !is.na(MA3) & !is.na(MA12))

# Prepare test data with features
# Need to combine train and test to calculate lags properly
full_data_for_features <- bind_rows(
  train_data %>% mutate(Set = "train"),
  test_data %>% mutate(Set = "test")
) %>%
  create_features()

test_rf <- full_data_for_features %>%
  filter(Set == "test") %>%
  filter(!is.na(Lag12) & !is.na(MA3) & !is.na(MA12))

# Train Random Forest
set.seed(42)
rf_model <- randomForest(
  RecreationVisits ~ TimeIndex + MonthFactor + Quarter + Lag12 + MA3 + MA12 + Trend,
  data = train_rf,
  ntree = 500,
  mtry = 3,
  importance = TRUE
)

cat("\nRandom Forest Model:\n")
print(rf_model)

# Variable importance
cat("\nVariable Importance:\n")
importance_df <- as.data.frame(importance(rf_model)) %>%
  rownames_to_column("Variable") %>%
  arrange(desc(`%IncMSE`))
print(importance_df)

# Plot variable importance
varImpPlot(rf_model, main = "Random Forest: Variable Importance")

# Make predictions
rf_predictions <- predict(rf_model, newdata = test_rf)

# Match test data
test_rf_aligned <- test_rf %>%
  mutate(RF_Prediction = rf_predictions)

# Calculate accuracy
rf_mae <- mean(abs(test_rf_aligned$RecreationVisits - rf_predictions))
rf_rmse <- sqrt(mean((test_rf_aligned$RecreationVisits - rf_predictions)^2))
rf_mape <- mean(abs((test_rf_aligned$RecreationVisits - rf_predictions) / 
                      test_rf_aligned$RecreationVisits)) * 100

cat("\nRandom Forest Performance:\n")
cat("MAE: ", format(rf_mae, big.mark = ","), "\n")
cat("RMSE:", format(rf_rmse, big.mark = ","), "\n")
cat("MAPE:", round(rf_mape, 2), "%\n")

# ============================================================================
# 7. MODEL COMPARISON
# ============================================================================

cat("\n=== MODEL COMPARISON ===\n")

# Create comparison table
comparison <- data.frame(
  Model = c("Linear Regression", "ARIMA", "ETS", "Random Forest"),
  MAE = c(lm_mae, arima_mae, ets_mae, rf_mae),
  RMSE = c(lm_rmse, arima_rmse, ets_rmse, rf_rmse),
  MAPE = c(lm_mape, arima_mape, ets_mape, rf_mape)
) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

print(comparison)

# Identify best model
best_model_idx <- which.min(comparison$MAPE)
cat("\nBest performing model (by MAPE):", comparison$Model[best_model_idx], "\n")

# ============================================================================
# 8. VISUALIZATION OF FORECASTS
# ============================================================================

cat("\n=== GENERATING FORECAST VISUALIZATIONS ===\n")

# Prepare data for plotting
forecast_comparison <- test_data %>%
  mutate(
    Actual = RecreationVisits,
    `Linear Regression` = lm_predictions,
    ARIMA = arima_predictions,
    ETS = ets_predictions
  ) %>%
  select(Date, Actual, `Linear Regression`, ARIMA, ETS)

# Add RF predictions (may have fewer rows due to lag requirements)
forecast_comparison <- forecast_comparison %>%
  left_join(
    test_rf_aligned %>% select(Date, RF_Prediction),
    by = "Date"
  ) %>%
  rename(`Random Forest` = RF_Prediction)

# Reshape for plotting
forecast_long <- forecast_comparison %>%
  pivot_longer(cols = -Date, names_to = "Model", values_to = "Visits")

# Create the comparison plot
p4 <- ggplot(forecast_long, aes(x = Date, y = Visits, color = Model, 
                                 linetype = Model)) +
  geom_line(linewidth = 1) +
  scale_linetype_manual(values = c("Actual" = "solid", 
                                   "Linear Regression" = "dashed",
                                   "ARIMA" = "dotted",
                                   "ETS" = "dotdash",
                                   "Random Forest" = "longdash")) +
  scale_color_manual(values = c("Actual" = "black",
                                "Linear Regression" = "blue",
                                "ARIMA" = "red",
                                "ETS" = "green",
                                "Random Forest" = "purple")) +
  scale_y_continuous(labels = comma) +
  labs(title = "Forecast Comparison: Test Period",
       subtitle = "Comparing multiple forecasting methods",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))

print(p4)

# Plot with training data context
last_12_train <- train_data %>%
  tail(36) %>%
  mutate(Model = "Training Data", Visits = RecreationVisits) %>%
  select(Date, Model, Visits)

combined_plot_data <- bind_rows(
  last_12_train,
  forecast_long
)

p5 <- ggplot(combined_plot_data, aes(x = Date, y = Visits, color = Model)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = min(test_data$Date), linetype = "dashed", 
             color = "gray50", alpha = 0.7) +
  annotate("text", x = min(test_data$Date), y = max(combined_plot_data$Visits, na.rm = TRUE), 
           label = "Forecast Start", vjust = -0.5, hjust = -0.1, size = 3) +
  scale_y_continuous(labels = comma) +
  labs(title = "Forecasts in Context",
       subtitle = "Last 36 months of training data + 24-month forecast horizon",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))

print(p5)

# Residual analysis for best model
cat("\n=== RESIDUAL ANALYSIS FOR ARIMA MODEL ===\n")
checkresiduals(arima_model)

# ============================================================================
# 9. FUTURE FORECASTING
# ============================================================================

cat("\n=== GENERATING FUTURE FORECASTS ===\n")

# Refit best model on full dataset
full_ts <- ts(arches_clean$RecreationVisits,
              start = c(arches_clean$Year[1], arches_clean$Month[1]),
              frequency = 12)

# Fit ARIMA on full data
final_arima <- auto.arima(full_ts, seasonal = TRUE, stepwise = FALSE, 
                          approximation = FALSE)

# Forecast 24 months ahead
future_forecast <- forecast(final_arima, h = 24)

# Create future dates
last_date <- max(arches_clean$Date)
future_dates <- seq(last_date + months(1), by = "month", length.out = 24)

# Prepare forecast data
future_data <- data.frame(
  Date = future_dates,
  Forecast = as.numeric(future_forecast$mean),
  Lower80 = as.numeric(future_forecast$lower[, 1]),
  Upper80 = as.numeric(future_forecast$upper[, 1]),
  Lower95 = as.numeric(future_forecast$lower[, 2]),
  Upper95 = as.numeric(future_forecast$upper[, 2])
)

cat("\nFuture Forecast (next 24 months):\n")
print(future_data)

# Plot future forecast
historical_tail <- arches_clean %>%
  tail(36) %>%
  mutate(Type = "Historical")

p6 <- ggplot() +
  # Historical data
  geom_line(data = historical_tail, aes(x = Date, y = RecreationVisits),
            color = "black", linewidth = 1) +
  # Forecast
  geom_line(data = future_data, aes(x = Date, y = Forecast),
            color = "blue", linewidth = 1) +
  # Confidence intervals
  geom_ribbon(data = future_data, aes(x = Date, ymin = Lower80, ymax = Upper80),
              fill = "lightblue", alpha = 0.4) +
  geom_ribbon(data = future_data, aes(x = Date, ymin = Lower95, ymax = Upper95),
              fill = "lightblue", alpha = 0.2) +
  geom_vline(xintercept = last_date, linetype = "dashed", color = "gray50") +
  scale_y_continuous(labels = comma) +
  labs(title = "Arches NP Visitation Forecast",
       subtitle = "24-month forecast with 80% and 95% confidence intervals",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

print(p6)

# ============================================================================
# 10. KEY INSIGHTS AND RECOMMENDATIONS
# ============================================================================

cat("\n=== KEY INSIGHTS ===\n\n")

cat("1. SEASONALITY:\n")
cat("   - Strong seasonal pattern with peak visitation in summer months\n")
cat("   - Lowest visitation typically in winter (Dec-Feb)\n\n")

cat("2. TREND:\n")
yearly_growth <- (yearly_summary$AnnualVisits[nrow(yearly_summary)] - 
                  yearly_summary$AnnualVisits[1]) / 
                 yearly_summary$AnnualVisits[1] * 100
cat("   - Overall growth of", round(yearly_growth, 1), "% from", 
    min(yearly_summary$Year), "to", max(yearly_summary$Year), "\n\n")

cat("3. MODEL PERFORMANCE:\n")
cat("   - All models capture the general trend and seasonality\n")
cat("   - Time series models (ARIMA/ETS) perform best for this data\n")
cat("   - Machine learning (RF) competitive but requires more feature engineering\n\n")

cat("4. RECOMMENDATIONS FOR FORECASTING:\n")
cat("   - Use ARIMA or ETS for operational planning (simpler, interpretable)\n")
cat("   - Consider ensemble methods combining multiple forecasts\n")
cat("   - Monitor forecast accuracy and retrain models regularly\n")
cat("   - Account for external factors (economic conditions, marketing, etc.)\n\n")

cat("\n=== ANALYSIS COMPLETE ===\n")

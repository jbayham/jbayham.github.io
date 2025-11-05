# ============================================================================
# Forecasting Arches National Park Visitation with Weather Variables
# Extended Analysis Including External Predictors
# ============================================================================
setwd("~/Library/CloudStorage/OneDrive-Colostate/teaching/arec_346/other_material/forecast")

# Load required libraries
library(tidyverse)
library(lubridate)
library(forecast)
library(randomForest)
library(zoo)
library(scales)

# ============================================================================
# 1. LOAD DATA
# ============================================================================

cat("\n=== LOADING DATA ===\n")

# Check if weather data exists
if (!file.exists("data/arches_with_weather.csv")) {
  cat("Weather data not found. Please run 'fetch_weather_data.R' first.\n")
  cat("Falling back to regular forecasting without weather variables.\n")
  stop("Run fetch_weather_data.R to get weather data")
}

# Load combined data (visitation + weather)
full_data <- read_csv("data/arches_with_weather.csv", show_col_types = FALSE)

cat("Loaded data:", nrow(full_data), "observations\n")
cat("Date range:", as.character(min(full_data$Date)), "to", 
    as.character(max(full_data$Date)), "\n")




# Display structure
cat("\nAvailable variables:\n")
print(names(full_data))

# ============================================================================
# 2. FEATURE ENGINEERING
# ============================================================================

cat("\n=== FEATURE ENGINEERING ===\n")

# Add time-based features
full_data <- full_data %>%
  arrange(Date) %>%
  mutate(
    # Time index
    TimeIndex = row_number(),
    
    # Calendar features
    MonthFactor = factor(Month),
    Quarter = quarter(Date),
    MonthName = month(Date, label = TRUE),
    
    # Lag features (previous year same month)
    Visits_Lag12 = lag(RecreationVisits, 12),
    
    # Weather lags (sometimes previous month's weather affects decisions)
    Temp_Lag1 = lag(TempMean, 1),
    Precip_Lag1 = lag(TotalPrecipitation, 1),
    
    # Rolling statistics
    Visits_MA3 = rollmean(RecreationVisits, k = 3, fill = NA, align = "right"),
    Visits_MA12 = rollmean(RecreationVisits, k = 12, fill = NA, align = "right"),
    
    # Weather anomalies (deviation from monthly average)
    TempAnomaly = TempMean - mean(TempMean, na.rm = TRUE),
    PrecipAnomaly = TotalPrecipitation - mean(TotalPrecipitation, na.rm = TRUE),
    
    # Interaction terms
    TempSunshine = TempMean * AvgSunshine,
    
    # Seasonal weather indicators
    IsSummer = ifelse(Month %in% 6:8, 1, 0),
    IsWinter = ifelse(Month %in% c(12, 1, 2), 1, 0),
    IsPleasantWeather = ifelse(TempMean > 50 & TempMean < 85 & 
                                TotalPrecipitation < 1, 1, 0)
  )

cat("Features created\n")

# ============================================================================
# 3. EXPLORATORY ANALYSIS
# ============================================================================

cat("\n=== WEATHER-VISITATION RELATIONSHIPS ===\n")

# Temperature vs visitation by season
p1 <- ggplot(full_data, aes(x = TempMean, y = RecreationVisits, color = MonthName)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "loess", se = FALSE, color = "black", linewidth = 1) +
  scale_y_continuous(labels = comma) +
  scale_color_viridis_d() +
  labs(title = "Temperature vs. Visitation",
       subtitle = "Colored by month",
       x = "Average Temperature (°F)",
       y = "Recreation Visits",
       color = "Month") +
  theme_minimal()

print(p1)

# Precipitation vs visitation
p2 <- ggplot(full_data, aes(x = TotalPrecipitation, y = RecreationVisits)) +
  geom_point(alpha = 0.3, color = "steelblue") +
  geom_smooth(method = "loess", color = "red", se = TRUE) +
  scale_y_continuous(labels = comma) +
  labs(title = "Precipitation vs. Visitation",
       x = "Total Precipitation (inches)",
       y = "Recreation Visits") +
  theme_minimal()

print(p2)

# Correlation matrix
weather_vars <- c("RecreationVisits", "TempMean", "TotalPrecipitation", 
                  "AvgSunshine", "AvgWindSpeed", "PrecipDays")
cor_matrix <- cor(full_data %>% select(all_of(weather_vars)), 
                  use = "complete.obs")

cat("\nCorrelation Matrix:\n")
print(round(cor_matrix, 3))

# ============================================================================
# 4. TRAIN-TEST SPLIT
# ============================================================================

cat("\n=== TRAIN-TEST SPLIT ===\n")

# Reserve last 24 months for testing
train_size <- nrow(full_data) - 24
train_data <- full_data[1:train_size, ]
test_data <- full_data[(train_size + 1):nrow(full_data), ]

cat("Training data:", nrow(train_data), "observations\n")
cat("Test data:", nrow(test_data), "observations\n")

# ============================================================================
# 5. METHOD 1: LINEAR REGRESSION WITH WEATHER
# ============================================================================

cat("\n=== LINEAR REGRESSION WITH WEATHER VARIABLES ===\n")

# Model 1a: Baseline (no weather)
lm_baseline <- lm(RecreationVisits ~ TimeIndex + MonthFactor, 
                  data = train_data)

# Model 1b: With weather
lm_weather <- lm(RecreationVisits ~ TimeIndex + MonthFactor + 
                   TempMean + TotalPrecipitation + AvgSunshine + AvgWindSpeed,
                 data = train_data)

# Model 1c: With weather + interactions
lm_weather_full <- lm(RecreationVisits ~ TimeIndex + MonthFactor + 
                        TempMean + TotalPrecipitation + AvgSunshine + 
                        AvgWindSpeed + TempSunshine + IsPleasantWeather,
                      data = train_data)

# Compare models
cat("\n--- Model Comparison (Training) ---\n")
cat("Baseline R²:", summary(lm_baseline)$r.squared, "\n")
cat("With Weather R²:", summary(lm_weather)$r.squared, "\n")
cat("With Weather + Interactions R²:", summary(lm_weather_full)$r.squared, "\n")

# Display best model summary
cat("\n--- Best Linear Model Summary ---\n")
print(summary(lm_weather_full))

# Predictions
lm_pred_baseline <- predict(lm_baseline, newdata = test_data)
lm_pred_weather <- predict(lm_weather, newdata = test_data)
lm_pred_weather_full <- predict(lm_weather_full, newdata = test_data)

# Accuracy
calc_metrics <- function(actual, predicted, model_name) {
  mae <- mean(abs(actual - predicted), na.rm = TRUE)
  rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  mape <- mean(abs((actual - predicted) / actual), na.rm = TRUE) * 100
  
  cat("\n", model_name, ":\n", sep = "")
  cat("  MAE: ", format(mae, big.mark = ",", digits = 2), "\n", sep = "")
  cat("  RMSE:", format(rmse, big.mark = ",", digits = 2), "\n", sep = "")
  cat("  MAPE:", round(mape, 2), "%\n", sep = "")
  
  return(c(MAE = mae, RMSE = rmse, MAPE = mape))
}

cat("\n--- Test Set Performance ---\n")
metrics_lm_baseline <- calc_metrics(test_data$RecreationVisits, lm_pred_baseline, 
                                    "LM Baseline (no weather)")
metrics_lm_weather <- calc_metrics(test_data$RecreationVisits, lm_pred_weather, 
                                   "LM with Weather")
metrics_lm_full <- calc_metrics(test_data$RecreationVisits, lm_pred_weather_full, 
                                "LM with Weather + Interactions")

# ============================================================================
# 6. METHOD 2: ARIMA WITH EXTERNAL REGRESSORS
# ============================================================================

cat("\n=== ARIMA WITH EXTERNAL REGRESSORS ===\n")

# Prepare external regressors
train_xreg <- train_data %>%
  select(TempMean, TotalPrecipitation, AvgSunshine) %>%
  as.matrix()

test_xreg <- test_data %>%
  select(TempMean, TotalPrecipitation, AvgSunshine) %>%
  as.matrix()

# Create time series
train_ts <- ts(train_data$RecreationVisits,
               start = c(train_data$Year[1], train_data$Month[1]),
               frequency = 12)

# Fit ARIMA without regressors (baseline)
arima_baseline <- auto.arima(train_ts, seasonal = TRUE)
arima_baseline_fc <- forecast(arima_baseline, h = 24)

# Fit ARIMA with weather regressors
cat("\nFitting ARIMA with external regressors...\n")
arima_weather <- auto.arima(train_ts, xreg = train_xreg, seasonal = TRUE)

cat("\n--- ARIMA with Weather Summary ---\n")
print(summary(arima_weather))

# Forecast
arima_weather_fc <- forecast(arima_weather, xreg = test_xreg, h = 24)

# Accuracy
metrics_arima_baseline <- calc_metrics(test_data$RecreationVisits, 
                                       as.numeric(arima_baseline_fc$mean),
                                       "ARIMA Baseline")
metrics_arima_weather <- calc_metrics(test_data$RecreationVisits,
                                      as.numeric(arima_weather_fc$mean),
                                      "ARIMA with Weather")

# ============================================================================
# 7. METHOD 3: RANDOM FOREST WITH WEATHER
# ============================================================================

cat("\n=== RANDOM FOREST WITH WEATHER VARIABLES ===\n")

# Prepare data (remove NAs from lags)
train_rf <- train_data %>%
  filter(!is.na(Visits_Lag12) & !is.na(Visits_MA3) & !is.na(Visits_MA12)) %>%
  select(RecreationVisits, TimeIndex, MonthFactor, Quarter, 
         Visits_Lag12, Visits_MA3, Visits_MA12,
         TempMean, TotalPrecipitation, AvgSunshine, AvgWindSpeed,
         PrecipDays, TempSunshine, IsPleasantWeather)

test_rf <- test_data %>%
  filter(!is.na(Visits_Lag12) & !is.na(Visits_MA3) & !is.na(Visits_MA12)) %>%
  select(RecreationVisits, TimeIndex, MonthFactor, Quarter,
         Visits_Lag12, Visits_MA3, Visits_MA12,
         TempMean, TotalPrecipitation, AvgSunshine, AvgWindSpeed,
         PrecipDays, TempSunshine, IsPleasantWeather)

# Train Random Forest
set.seed(42)
rf_weather <- randomForest(
  RecreationVisits ~ .,
  data = train_rf,
  ntree = 500,
  mtry = 4,
  importance = TRUE
)

cat("\n--- Random Forest Model ---\n")
print(rf_weather)

# Variable importance
cat("\n--- Variable Importance ---\n")
importance_df <- as.data.frame(importance(rf_weather)) %>%
  rownames_to_column("Variable") %>%
  arrange(desc(`%IncMSE`))
print(importance_df)

# Plot importance
varImpPlot(rf_weather, main = "Random Forest: Variable Importance\n(Including Weather)")

# Predictions
rf_pred_weather <- predict(rf_weather, newdata = test_rf)

# Accuracy
metrics_rf_weather <- calc_metrics(test_rf$RecreationVisits, rf_pred_weather,
                                   "Random Forest with Weather")

# ============================================================================
# 8. MODEL COMPARISON
# ============================================================================

cat("\n=== COMPREHENSIVE MODEL COMPARISON ===\n")

comparison <- data.frame(
  Model = c("LM Baseline", "LM + Weather", "LM + Weather + Interactions",
            "ARIMA Baseline", "ARIMA + Weather", "RF + Weather"),
  MAE = c(metrics_lm_baseline["MAE"], metrics_lm_weather["MAE"], 
          metrics_lm_full["MAE"], metrics_arima_baseline["MAE"],
          metrics_arima_weather["MAE"], metrics_rf_weather["MAE"]),
  RMSE = c(metrics_lm_baseline["RMSE"], metrics_lm_weather["RMSE"],
           metrics_lm_full["RMSE"], metrics_arima_baseline["RMSE"],
           metrics_arima_weather["RMSE"], metrics_rf_weather["RMSE"]),
  MAPE = c(metrics_lm_baseline["MAPE"], metrics_lm_weather["MAPE"],
           metrics_lm_full["MAPE"], metrics_arima_baseline["MAPE"],
           metrics_arima_weather["MAPE"], metrics_rf_weather["MAPE"])
) %>%
  mutate(across(where(is.numeric), ~round(., 2))) %>%
  arrange(MAPE)

print(comparison)

# Calculate improvement from adding weather
cat("\n--- Impact of Weather Variables ---\n")
lm_improvement <- (metrics_lm_baseline["MAPE"] - metrics_lm_full["MAPE"]) / 
                  metrics_lm_baseline["MAPE"] * 100
arima_improvement <- (metrics_arima_baseline["MAPE"] - metrics_arima_weather["MAPE"]) /
                     metrics_arima_baseline["MAPE"] * 100

cat("LM MAPE improvement with weather:", round(lm_improvement, 2), "%\n")
cat("ARIMA MAPE improvement with weather:", round(arima_improvement, 2), "%\n")

# ============================================================================
# 9. VISUALIZATION OF FORECASTS
# ============================================================================

cat("\n=== GENERATING FORECAST VISUALIZATIONS ===\n")

# Prepare comparison data
forecast_comparison <- test_data %>%
  mutate(
    Actual = RecreationVisits,
    `LM Baseline` = lm_pred_baseline,
    `LM + Weather` = lm_pred_weather_full,
    `ARIMA Baseline` = as.numeric(arima_baseline_fc$mean),
    `ARIMA + Weather` = as.numeric(arima_weather_fc$mean)
  ) %>%
  select(Date, Actual, `LM Baseline`, `LM + Weather`, 
         `ARIMA Baseline`, `ARIMA + Weather`)

# Add RF (may have fewer observations)
rf_results <- test_rf %>%
  mutate(Date = test_data$Date[match(row_number(), 
                                      which(!is.na(test_data$Visits_Lag12)))],
         `RF + Weather` = rf_pred_weather) %>%
  select(Date, `RF + Weather`)

forecast_comparison <- forecast_comparison %>%
  left_join(rf_results, by = "Date")

# Reshape for plotting
forecast_long <- forecast_comparison %>%
  pivot_longer(cols = -Date, names_to = "Model", values_to = "Visits")

# Plot comparison
p3 <- ggplot(forecast_long, aes(x = Date, y = Visits, color = Model, 
                                 linetype = Model)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("Actual" = "black",
                                "LM Baseline" = "gray50",
                                "LM + Weather" = "blue",
                                "ARIMA Baseline" = "pink",
                                "ARIMA + Weather" = "red",
                                "RF + Weather" = "darkgreen")) +
  scale_linetype_manual(values = c("Actual" = "solid",
                                   "LM Baseline" = "dotted",
                                   "LM + Weather" = "dashed",
                                   "ARIMA Baseline" = "dotted",
                                   "ARIMA + Weather" = "dashed",
                                   "RF + Weather" = "longdash")) +
  scale_y_continuous(labels = comma) +
  labs(title = "Forecast Comparison: With vs. Without Weather Data",
       subtitle = "Test period (24 months)",
       x = "Date",
       y = "Recreation Visits") +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p3)

# Plot improvement
improvement_data <- data.frame(
  Model = c("Linear Regression", "ARIMA"),
  Baseline = c(metrics_lm_baseline["MAPE"], metrics_arima_baseline["MAPE"]),
  WithWeather = c(metrics_lm_full["MAPE"], metrics_arima_weather["MAPE"])
) %>%
  pivot_longer(cols = c(Baseline, WithWeather), 
               names_to = "Version", values_to = "MAPE")

p4 <- ggplot(improvement_data, aes(x = Model, y = MAPE, fill = Version)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = round(MAPE, 2)), 
            position = position_dodge(width = 0.9), vjust = -0.5) +
  scale_fill_manual(values = c("Baseline" = "gray70", 
                               "WithWeather" = "steelblue")) +
  labs(title = "Impact of Weather Variables on Forecast Accuracy",
       subtitle = "Lower MAPE is better",
       x = "Model Type",
       y = "MAPE (%)",
       fill = "Model Version") +
  theme_minimal()

print(p4)

# ============================================================================
# 10. WEATHER IMPACT ANALYSIS
# ============================================================================

cat("\n=== WEATHER IMPACT ANALYSIS ===\n")

# Extract coefficients from linear model
weather_coefs <- coef(lm_weather_full)[c("TempMean", "TotalPrecipitation", 
                                          "AvgSunshine", "AvgWindSpeed")]

cat("\nWeather Variable Effects (Linear Model):\n")
cat("  Temperature (+1°F):", round(weather_coefs["TempMean"], 0), "visits\n")
cat("  Precipitation (+1 inch):", round(weather_coefs["TotalPrecipitation"], 0), "visits\n")
cat("  Sunshine (+1 hour/day):", round(weather_coefs["AvgSunshine"], 0), "visits\n")
cat("  Wind speed (+1 mph):", round(weather_coefs["AvgWindSpeed"], 0), "visits\n")

# Scenario analysis
cat("\n=== SCENARIO ANALYSIS ===\n")
cat("Impact on monthly visitation:\n\n")

baseline_scenario <- data.frame(
  TimeIndex = max(train_data$TimeIndex) + 1,
  MonthFactor = factor(7, levels = 1:12),  # July
  TempMean = 85,
  TotalPrecipitation = 0.5,
  AvgSunshine = 10,
  AvgWindSpeed = 8,
  TempSunshine = 85 * 10,
  IsPleasantWeather = 1
)

baseline_pred <- predict(lm_weather_full, newdata = baseline_scenario)

# Scenario 1: Warmer month
warm_scenario <- baseline_scenario
warm_scenario$TempMean <- 90
warm_scenario$TempSunshine <- 90 * 10
warm_pred <- predict(lm_weather_full, newdata = warm_scenario)

cat("Baseline (July, 85°F):", format(round(baseline_pred), big.mark = ","), "visits\n")
cat("Warmer scenario (+5°F):", format(round(warm_pred), big.mark = ","), "visits\n")
cat("Change:", format(round(warm_pred - baseline_pred), big.mark = ","), 
    "(", round((warm_pred - baseline_pred) / baseline_pred * 100, 1), "%)\n\n")

# Scenario 2: Rainy month
rainy_scenario <- baseline_scenario
rainy_scenario$TotalPrecipitation <- 2.0
rainy_scenario$IsPleasantWeather <- 0
rainy_pred <- predict(lm_weather_full, newdata = rainy_scenario)

cat("Rainy scenario (+1.5 inches precip):", format(round(rainy_pred), big.mark = ","), "visits\n")
cat("Change from baseline:", format(round(rainy_pred - baseline_pred), big.mark = ","),
    "(", round((rainy_pred - baseline_pred) / baseline_pred * 100, 1), "%)\n\n")

# ============================================================================
# 11. KEY INSIGHTS
# ============================================================================

cat("\n=== KEY INSIGHTS ===\n\n")

cat("1. WEATHER IMPACT ON FORECAST ACCURACY:\n")
cat("   - Adding weather variables improved MAPE by", round(lm_improvement, 1), "% (Linear Model)\n")
cat("   - ARIMA with weather improved by", round(arima_improvement, 1), "%\n\n")

cat("2. MOST IMPORTANT WEATHER VARIABLES:\n")
top_weather <- importance_df %>%
  filter(Variable %in% c("TempMean", "TotalPrecipitation", "AvgSunshine", 
                         "AvgWindSpeed", "PrecipDays")) %>%
  head(3)
for (i in 1:nrow(top_weather)) {
  cat("   ", i, ". ", top_weather$Variable[i], "\n", sep = "")
}
cat("\n")

cat("3. WEATHER EFFECTS ON VISITATION:\n")
if (weather_coefs["TempMean"] > 0) {
  cat("   - Warmer temperatures generally increase visitation\n")
} else {
  cat("   - Higher temperatures may decrease visitation (heat)\n")
}
if (weather_coefs["TotalPrecipitation"] < 0) {
  cat("   - Precipitation negatively impacts visitation\n")
}
if (weather_coefs["AvgSunshine"] > 0) {
  cat("   - More sunshine hours increase visitation\n")
}

cat("\n4. BEST MODEL:\n")
best_model <- comparison$Model[which.min(comparison$MAPE)]
cat("   -", best_model, "with MAPE of", 
    min(comparison$MAPE), "%\n\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Weather-enhanced forecasting models successfully trained and evaluated.\n")

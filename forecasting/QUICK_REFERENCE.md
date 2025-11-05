# Forecasting Quick Reference Sheet

A cheat sheet for common forecasting tasks in R.

## 📦 Essential Libraries

```r
library(tidyverse)    # Data wrangling & viz
library(lubridate)    # Dates
library(forecast)     # Time series
library(zoo)          # Rolling stats
```

---

## 🔧 Data Preparation

### Load Time Series Data
```r
data <- read_csv("file.csv")
```

### Create Date Column
```r
data <- data %>%
  mutate(Date = make_date(Year, Month, Day))
```

### Create Time Series Object
```r
# Monthly data
ts_data <- ts(data$value, start = c(2000, 1), frequency = 12)

# Quarterly data
ts_data <- ts(data$value, start = c(2000, 1), frequency = 4)

# Annual data
ts_data <- ts(data$value, start = 2000, frequency = 1)
```

---

## 📊 Exploratory Analysis

### Basic Plot
```r
plot(ts_data)
autoplot(ts_data)  # ggplot2 style
```

### Decomposition
```r
decompose(ts_data) %>% plot()
stl(ts_data, s.window = "periodic") %>% plot()
```

### Check Stationarity
```r
library(tseries)
adf.test(ts_data)  # p < 0.05 means stationary
```

### ACF and PACF
```r
acf(ts_data)
pacf(ts_data)
```

---

## 🎯 Train/Test Split

### By Index
```r
n <- length(ts_data)
train_size <- floor(0.8 * n)
train <- window(ts_data, end = time(ts_data)[train_size])
test <- window(ts_data, start = time(ts_data)[train_size + 1])
```

### By Date
```r
train <- window(ts_data, end = c(2020, 12))
test <- window(ts_data, start = c(2021, 1))
```

---

## 🔮 Forecasting Methods

### Linear Regression
```r
model <- lm(value ~ time + factor(month), data = df)
predictions <- predict(model, newdata = test_df)
```

### ARIMA
```r
# Automatic
model <- auto.arima(train)

# Manual specification: ARIMA(p,d,q)(P,D,Q)[m]
model <- Arima(train, order = c(1,1,1), seasonal = c(1,1,1))

# Forecast
fc <- forecast(model, h = 12)
```

### ETS
```r
model <- ets(train)
fc <- forecast(model, h = 12)
```

### Seasonal Naive
```r
model <- snaive(train, h = 12)
```

### Prophet
```r
library(prophet)
df <- data.frame(ds = dates, y = values)
model <- prophet(df)
future <- make_future_dataframe(model, periods = 12, freq = 'month')
fc <- predict(model, future)
```

### Random Forest
```r
library(randomForest)
model <- randomForest(y ~ ., data = train_df, ntree = 500)
predictions <- predict(model, newdata = test_df)
```

---

## 📏 Accuracy Metrics

### Calculate Metrics
```r
actual <- test_df$value
predicted <- predictions

# MAE
mae <- mean(abs(actual - predicted))

# RMSE
rmse <- sqrt(mean((actual - predicted)^2))

# MAPE
mape <- mean(abs((actual - predicted) / actual)) * 100

# Using forecast package
accuracy(fc, test)
```

---

## 🔍 Model Diagnostics

### ARIMA Residuals
```r
checkresiduals(model)
```

### Ljung-Box Test
```r
Box.test(residuals(model), type = "Ljung-Box")
# p-value > 0.05 is good (white noise)
```

### Shapiro-Wilk Normality Test
```r
shapiro.test(residuals(model))
```

---

## 📈 Visualization

### Basic Forecast Plot
```r
plot(fc)
autoplot(fc)
```

### ggplot2 Custom Plot
```r
fc_df <- data.frame(
  Date = seq(start_date, by = "month", length.out = h),
  Forecast = fc$mean,
  Lower = fc$lower[,2],
  Upper = fc$upper[,2]
)

ggplot() +
  geom_line(data = historical, aes(x = Date, y = Value), color = "black") +
  geom_line(data = fc_df, aes(x = Date, y = Forecast), color = "blue") +
  geom_ribbon(data = fc_df, aes(x = Date, ymin = Lower, ymax = Upper),
              alpha = 0.3, fill = "blue")
```

### Compare Multiple Forecasts
```r
df <- data.frame(
  Date = test_dates,
  Actual = test_values,
  ARIMA = arima_fc,
  ETS = ets_fc
) %>%
  pivot_longer(cols = -Date, names_to = "Model", values_to = "Value")

ggplot(df, aes(x = Date, y = Value, color = Model)) +
  geom_line()
```

---

## 🛠️ Feature Engineering

### Lag Features
```r
df <- df %>%
  mutate(
    lag1 = lag(value, 1),
    lag12 = lag(value, 12)
  )
```

### Rolling Statistics
```r
library(zoo)
df <- df %>%
  mutate(
    ma3 = rollmean(value, k = 3, fill = NA, align = "right"),
    ma12 = rollmean(value, k = 12, fill = NA, align = "right"),
    sd12 = rollapply(value, width = 12, FUN = sd, fill = NA, align = "right")
  )
```

### Date Features
```r
df <- df %>%
  mutate(
    year = year(Date),
    month = month(Date),
    quarter = quarter(Date),
    day_of_week = wday(Date),
    day_of_year = yday(Date),
    week_of_year = week(Date)
  )
```

---

## 🎲 Cross-Validation

### Time Series CV
```r
library(forecast)

# Define CV scheme
cv <- tsCV(ts_data, forecastfunction = function(y, h) {
  forecast(auto.arima(y), h = h)
}, h = 12)

# Calculate RMSE
rmse <- sqrt(mean(cv^2, na.rm = TRUE))
```

---

## 🔄 Model Comparison

### Compare Multiple Models
```r
models <- list(
  arima = auto.arima(train),
  ets = ets(train),
  snaive = snaive(train, h = length(test))
)

# Get forecasts
forecasts <- lapply(models, function(m) {
  if (class(m)[1] == "forecast") m else forecast(m, h = length(test))
})

# Calculate accuracy
acc <- lapply(forecasts, accuracy, test)
do.call(rbind, acc)
```

---

## 💾 Save and Load Models

### Save
```r
saveRDS(model, "model.rds")
```

### Load
```r
model <- readRDS("model.rds")
```

---

## 🎨 Pretty Output

### Format Numbers
```r
library(scales)

# Comma separator
comma(1234567)  # "1,234,567"

# Percentage
percent(0.1234)  # "12.3%"

# Dollar
dollar(1234.56)  # "$1,234.56"
```

### Round Data Frame
```r
df %>%
  mutate(across(where(is.numeric), ~round(., 2)))
```

---

## ⚙️ Common Parameters

### auto.arima()
```r
auto.arima(
  y,
  seasonal = TRUE,      # Include seasonal component?
  stepwise = FALSE,     # Exhaustive search (slower, better)
  approximation = FALSE,# Exact likelihood (slower, better)
  trace = TRUE,         # Show models tested
  ic = "aic"           # Information criterion: "aic", "bic", "aicc"
)
```

### ets()
```r
ets(
  y,
  model = "ZZZ",  # Auto-select: E/T/S can be Z/N/A/M
  damped = NULL,  # Auto-select damping
  ic = "aic"
)
```

### randomForest()
```r
randomForest(
  formula,
  data,
  ntree = 500,        # Number of trees
  mtry = sqrt(p),     # Variables per split
  importance = TRUE,  # Calculate variable importance
  na.action = na.omit
)
```

---

## 🚨 Troubleshooting

### ARIMA won't converge
```r
# Try simpler model
auto.arima(y, stepwise = TRUE, approximation = TRUE)

# Or specify manually
Arima(y, order = c(1,1,1))
```

### Missing values
```r
# Interpolate
library(zoo)
y_clean <- na.approx(y)

# Or remove
y_clean <- na.omit(y)
```

### Non-stationary series
```r
# Difference once
y_diff <- diff(y)

# Seasonal difference
y_sdiff <- diff(y, lag = 12)
```

### Forecasts are negative
```r
# Use Box-Cox transformation
lambda <- BoxCox.lambda(y)
model <- auto.arima(y, lambda = lambda)
fc <- forecast(model, h = 12)
# Forecasts will be back-transformed automatically
```

---

## 📚 Helpful Functions

### Summary
```r
summary(model)      # Model summary
coef(model)         # Coefficients
residuals(model)    # Residuals
fitted(model)       # Fitted values
```

### Information
```r
AIC(model)          # Akaike Information Criterion
BIC(model)          # Bayesian Information Criterion
```

### Tests
```r
# Unit root test
library(tseries)
adf.test(y)

# Seasonality test
library(seastests)
isSeasonal(y)
```

---

## 🎯 Quick Workflow Template

```r
# 1. Load and prepare
data <- read_csv("data.csv") %>%
  mutate(Date = make_date(Year, Month))

# 2. Create time series
ts_data <- ts(data$value, start = c(2000, 1), frequency = 12)

# 3. Explore
plot(ts_data)
decompose(ts_data) %>% plot()

# 4. Split
train <- window(ts_data, end = c(2020, 12))
test <- window(ts_data, start = c(2021, 1))

# 5. Fit models
m1 <- auto.arima(train)
m2 <- ets(train)

# 6. Forecast
fc1 <- forecast(m1, h = 12)
fc2 <- forecast(m2, h = 12)

# 7. Evaluate
accuracy(fc1, test)
accuracy(fc2, test)

# 8. Check best model
checkresiduals(m1)

# 9. Refit on full data
final_model <- auto.arima(ts_data)

# 10. Forecast future
future_fc <- forecast(final_model, h = 24)
plot(future_fc)
```

---

## 🔗 Useful Links

- [Forecasting: Principles and Practice](https://otexts.com/fpp3/)
- [forecast package documentation](https://pkg.robjhyndman.com/forecast/)
- [Time Series Analysis in R](https://a-little-book-of-r-for-time-series.readthedocs.io/)

---

**Last Updated**: November 2025

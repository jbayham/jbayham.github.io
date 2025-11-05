# Installation Guide

Quick setup guide to get R and required packages installed for the Arches NP forecasting project.

## Step 1: Install R

### Windows
1. Go to https://cran.r-project.org/bin/windows/base/
2. Click "Download R x.x.x for Windows"
3. Run the installer
4. Accept default options

### Mac
1. Go to https://cran.r-project.org/bin/macosx/
2. Download the appropriate .pkg file for your macOS version
3. Run the installer
4. Accept default options

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install r-base r-base-dev
```

## Step 2: Install RStudio (Recommended)

RStudio provides a much better interface for R.

1. Go to https://posit.co/download/rstudio-desktop/
2. Download RStudio Desktop (Free)
3. Install the downloaded file
4. Open RStudio (not R directly)

## Step 3: Install Required Packages

Open RStudio and run the following in the Console:

```r
# Install all packages at once
install.packages(c(
  "tidyverse",
  "lubridate",
  "forecast",
  "randomForest",
  "zoo",
  "scales"
))
```

This may take 5-10 minutes. You'll see lots of text scrolling by - this is normal!

### If You Encounter Errors

**Error: "package 'xxx' is not available"**
- Check your internet connection
- Try installing packages one at a time
- Update R to the latest version

**Windows: "compilation required"**
- Install Rtools: https://cran.r-project.org/bin/windows/Rtools/
- Or answer "No" when asked to install from source

**Mac: "clang error"**
- Install Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

**Linux: "package dependency errors"**
```bash
# Install system dependencies
sudo apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev
```

## Step 4: Verify Installation

Run this in RStudio to check everything works:

```r
# Load libraries
library(tidyverse)
library(lubridate)
library(forecast)
library(randomForest)
library(zoo)
library(scales)

# Should see no errors - just some startup messages
cat("All packages loaded successfully!\n")
```

## Step 5: Set Working Directory

In RStudio:
1. Go to Session → Set Working Directory → Choose Directory
2. Navigate to your forecast folder
3. Click "Open"

Or use code:
```r
setwd("/path/to/your/forecast/folder")
```

## Step 6: Test with Sample Data

```r
# Quick test
data <- data.frame(
  date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
  value = rnorm(24, mean = 100, sd = 10)
)

# Create time series
ts_data <- ts(data$value, frequency = 12)

# Fit simple model
model <- auto.arima(ts_data)

# Forecast
fc <- forecast(model, h = 6)

# Plot
plot(fc)
```

If you see a plot, everything is working! 🎉

## Alternative: Google Colab (No Installation)

If you can't install R locally, use Google Colab:

1. Go to https://colab.research.google.com/
2. Create a new notebook
3. Change runtime to R:
   - Runtime → Change runtime type → R
4. Install packages in the first cell:
   ```r
   install.packages("tidyverse")
   install.packages("forecast")
   # etc.
   ```

## Package Versions (for reference)

This project was developed with:
- R version 4.3+
- tidyverse 2.0.0
- forecast 8.21
- randomForest 4.7-1.1
- zoo 1.8-12

To check your versions:
```r
sessionInfo()
```

## Troubleshooting

### RStudio won't open
- Make sure you installed R first, then RStudio
- Try restarting your computer

### Packages won't install
```r
# Try setting a different mirror
options(repos = "https://cloud.r-project.org/")
install.packages("package_name")
```

### "Permission denied" errors
- On Windows: Run RStudio as Administrator
- On Mac/Linux: Don't use sudo with R

### Plot window is blank
- In RStudio, check the "Plots" tab (bottom-right)
- Try: `dev.new()` before plotting

## Getting Help

- RStudio Help: Help → RStudio Docs
- Package help: `?auto.arima` (or any function)
- Stack Overflow: https://stackoverflow.com/questions/tagged/r
- Course instructor: [Your contact info]

## Next Steps

Once everything is installed:
1. Read `README.md` for project overview
2. Follow `TUTORIAL.md` for step-by-step walkthrough
3. Run `arches_forecasting.R` for full analysis

Good luck! 🚀

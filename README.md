# United States Temperature and Electricity Generation Shiny App

## Overview

This Shiny dashboard visualizes and forecasts the relationship between U.S. average monthly temperature and electricity generation. It offers three main tabs:

1. **Time Plots** : Line plots of Electricity, Temperature, Electricity vs. Temperature, and Temperature Stress by type (HDD/CDD).
2. **Decomposition Plots**: Classical time-series decompositions of Electricity, Temperature, HDD, and CDD.  
3. **Models & Predictions**  
   - **VAR (HDD/CDD)**: Vector AutoRegression forecast using Heating Degree Days and Cooling Degree Days.  
   - **VAR (Temperature)**: VAR forecast using raw Temperature.  
   - **TSLM**: Time Series Linear Model forecast of Electricity on Temperature + seasonality.  

## Files

- **app.R**  
  The single-file Shiny app
- **electempdatatsa.csv**  
  Monthly data with columns `Date`, `Temp`, and `Electricity`  
- **README.md**  
  This file

## Prerequisites

- **R** ≥ 4.1  
- **Packages**  
  ```r
  install.packages(c(
    "shiny", "shinydashboard", "shinyjs",
    "tidyverse", "tsibble", "fpp3",
    "ggplot2", "feasts", "fable", "fabletools"
  ))

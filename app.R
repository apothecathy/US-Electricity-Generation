# load libraries  
library(ggplot2)      
library(fable)        
library(fabletools)   
library(feasts)       
library(shiny)
library(shinydashboard)
library(fpp3)
library(tidyverse)
library(tsibble)
library(shinyjs)

# Load and process data
electempdata <- readr::read_csv("electempdatatsa.csv", show_col_types = FALSE)

electemp <<- electempdata %>%
  mutate(date = yearmonth(Date)) %>%
  select(-Date) %>%
  as_tsibble(index = date) %>%
  slice_head(n = nrow(.) - 3) %>%
  mutate(
    HDD = pmax(0, 65 - Temp),
    CDD = pmax(0, Temp - 65),
    temp_stress = pmax(HDD, CDD),
    stress_type = case_when(
      HDD > CDD ~ "HDD",
      CDD > HDD ~ "CDD",
      TRUE ~ "Neutral")
  )

# split into test and training data sets
train_size <- 29
electemp_train <<- electemp %>% slice_head(n = train_size)
electemp_test  <<- electemp %>% slice_tail(n = nrow(electemp) - train_size)

# Fit models
fit <<- electemp_train %>% model(VAR_model = VAR(vars(HDD, CDD, Electricity), ic = "bic"))
fit2 <<- electemp_train %>% model(VAR_model = VAR(vars(Temp, Electricity), ic = "bic"))
model_tslm <<- electemp %>% model(TSLM(Electricity ~ Temp + season()))

header <- dashboardHeader(title = "United States Temperature and Electricity Generation", titleWidth = 600)

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Plots", icon = icon("chart-line"),
             menuSubItem("Time", tabName = "time"),
             menuSubItem("Decomposition", tabName = "decomp"),
             menuSubItem("Models & Predictions", tabName = "models")
    )
  )
)

body <- dashboardBody(
  tabItems(
    
    # Plots over time
    tabItem(tabName = "time",
            h3("Time Visualizations"),
            selectInput("time_plot", "Select Time Plot:",
                        choices = c("Electricity Over Time", "Temperature Over Time", "Electricity vs Temperature", "Temperature Stress by Type")),
            plotOutput("time_plot_output")
    ),
    
    # Decompositions
    tabItem(tabName = "decomp",
            h3("Decomposition Plots"),
            selectInput("decomp_plot", "Select Variable:",
                        choices = c("Electricity", "Temperature", "HDD", "CDD")),
            plotOutput("decomp_plot_output")
    ),
    
    # Models and forecasts
    tabItem(tabName = "models",
            h3("Forecast Models"),
            selectInput("model_plot", "Select Model Forecast:",
                        choices = c("VAR (HDD/CDD)", "VAR (Temperature)", "TSLM")),
            plotOutput("model_plot_output")
    )
  )
)


ui <- dashboardPage(header, sidebar, body)

server <- function(input, output, session) {
  
  output$time_plot_output <- renderPlot({
    req(input$time_plot)
    switch(input$time_plot,
           "Electricity Over Time" = ggplot(electemp, aes(x = date, y = Electricity)) + geom_line(),
           "Temperature Over Time" = ggplot(electemp, aes(x = date, y = Temp)) + geom_line(),
           "Electricity vs Temperature" = ggplot(electemp, aes(x = Temp, y = Electricity)) +
             geom_point() + geom_smooth(method = "lm"),
           "Temperature Stress by Type" = ggplot(electemp, aes(x = temp_stress, y = Electricity, color = stress_type)) +
             geom_point() + geom_smooth(method = "lm", se = FALSE))
  })
  
  output$decomp_plot_output <- renderPlot({
    req(input$decomp_plot)
    ts_data <- switch(input$decomp_plot,
                      "Electricity" = ts(electemp$Electricity, start = c(2022, 1), frequency = 12),
                      "Temperature" = ts(electemp$Temp, start = c(2022, 1), frequency = 12),
                      "HDD" = ts(electemp$HDD, start = c(2010, 1), frequency = 12),
                      "CDD" = ts(electemp$CDD, start = c(2010, 1), frequency = 12))
    plot(decompose(ts_data))
  })
  
  output$model_plot_output <- renderPlot({
    req(input$model_plot)
    if (input$model_plot == "VAR (HDD/CDD)") {
      autoplot(forecast(fit, h = nrow(electemp_test)), level = c(80, 90)) +
        autolayer(electemp_test, Electricity, color = "red") +
        labs(title = "VAR Forecast: HDD/CDD")
    } else if (input$model_plot == "VAR (Temperature)") {
      autoplot(forecast(fit2, h = nrow(electemp_test)), level = c(80, 90)) +
        autolayer(electemp_test, Electricity, color = "red") +
        labs(title = "VAR Forecast: Temperature")
    } else {
      autoplot(forecast(model_tslm, new_data = electemp_test), level = c(80, 90)) +
        autolayer(electemp_test, Electricity, color = "red") +
        labs(title = "TSLM Forecast")
    }
  })
}


shinyApp(ui = ui, server = server)

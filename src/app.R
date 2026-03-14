library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(leaflet)

data_path <- file.path("data", "raw", "gbif-beetle.csv")
beetles <- read.delim(data_path, sep = "\t", stringsAsFactors = FALSE)

beetles$year <- suppressWarnings(as.integer(beetles$year))
beetles$month <- suppressWarnings(as.integer(beetles$month))
beetles$decimalLatitude <- suppressWarnings(as.numeric(beetles$decimalLatitude))
beetles$decimalLongitude <- suppressWarnings(as.numeric(beetles$decimalLongitude))

year_limits <- range(beetles$year, na.rm = TRUE)
country_choices <- c("All", sort(unique(stats::na.omit(beetles$countryCode))))
basis_choices <- c("All", sort(unique(stats::na.omit(beetles$basisOfRecord))))
month_levels <- c(
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
)

ui <- page_sidebar(
  title = "Japanese Beetle Tracker",
  theme = bs_theme(
    version = 5,
    bootswatch = "minty",
    primary = "#1f5f3b",
    secondary = "#d7ead8"
  ),
  sidebar = sidebar(
    sliderInput(
      "year_range",
      "Year range",
      min = year_limits[1],
      max = year_limits[2],
      value = year_limits,
      sep = ""
    ),
    selectInput(
      "country",
      "Country",
      choices = country_choices,
      selected = "All"
    ),
    radioButtons(
      "basis_record",
      "Basis of record",
      choices = basis_choices,
      selected = "All"
    ),
    actionButton("reset_filters", "Reset filters", class = "btn-warning")
  ),
  layout_columns(
    uiOutput("total_obs_box"),
    uiOutput("countries_box"),
    uiOutput("latest_year_box"),
    col_widths = c(4, 4, 4)
  ),
  layout_columns(
    card(
      full_screen = TRUE,
      card_header("Observations over time"),
      plotOutput("year_plot", height = 320)
    ),
    card(
      full_screen = TRUE,
      card_header("Seasonal observations"),
      plotOutput("month_plot", height = 320)
    ),
    col_widths = c(6, 6)
  ),
  layout_columns(
    card(
      full_screen = TRUE,
      card_header("Top regions"),
      tableOutput("top_regions")
    ),
    card(
      full_screen = TRUE,
      card_header("Observation map"),
      leafletOutput("obs_map", height = 420)
    ),
    col_widths = c(5, 7)
  )
)

server <- function(input, output, session) {
  filtered_data <- reactive({
    data <- beetles |>
      filter(!is.na(year)) |>
      filter(year >= input$year_range[1], year <= input$year_range[2])

    if (!identical(input$country, "All")) {
      data <- data |>
        filter(countryCode == input$country)
    }

    if (!identical(input$basis_record, "All")) {
      data <- data |>
        filter(basisOfRecord == input$basis_record)
    }

    data
  })

  observeEvent(input$reset_filters, {
    updateSliderInput(session, "year_range", value = year_limits)
    updateSelectInput(session, "country", selected = "All")
    updateRadioButtons(session, "basis_record", selected = "All")
  })

  output$total_obs_box <- renderUI({
    value_box(
      title = "Total observations",
      value = format(nrow(filtered_data()), big.mark = ",")
    )
  })

  output$countries_box <- renderUI({
    country_total <- filtered_data() |>
      summarise(n = n_distinct(countryCode, na.rm = TRUE)) |>
      pull(n)

    value_box(
      title = "Countries represented",
      value = country_total
    )
  })

  output$latest_year_box <- renderUI({
    latest_year <- filtered_data() |>
      summarise(n = max(year, na.rm = TRUE)) |>
      pull(n)

    if (!is.finite(latest_year)) {
      latest_year <- "N/A"
    }

    value_box(
      title = "Latest year in filter",
      value = latest_year
    )
  })

  output$year_plot <- renderPlot({
    yearly_counts <- filtered_data() |>
      count(year, name = "observations")

    validate(need(nrow(yearly_counts) > 0, "No observations match the current filters."))

    ggplot(yearly_counts, aes(x = year, y = observations)) +
      geom_line(color = "#1f5f3b", linewidth = 1) +
      geom_point(color = "#1f5f3b", size = 2) +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      labs(
        x = "Year",
        y = "Observations"
      ) +
      theme_minimal(base_size = 12)
  })

  output$month_plot <- renderPlot({
    monthly_counts <- filtered_data() |>
      filter(!is.na(month), month >= 1, month <= 12) |>
      count(month, name = "observations") |>
      mutate(month_label = factor(month_levels[month], levels = month_levels))

    validate(need(nrow(monthly_counts) > 0, "No monthly observation data is available."))

    ggplot(monthly_counts, aes(x = month_label, y = observations)) +
      geom_col(fill = "#7fb069") +
      labs(
        x = "Month",
        y = "Observations"
      ) +
      theme_minimal(base_size = 12)
  })

  output$top_regions <- renderTable({
    filtered_data() |>
      filter(!is.na(stateProvince), nzchar(stateProvince)) |>
      count(stateProvince, sort = TRUE, name = "observations") |>
      head(10)
  })

  output$obs_map <- renderLeaflet({
    map_data <- filtered_data() |>
      filter(
        !is.na(decimalLatitude),
        !is.na(decimalLongitude),
        decimalLatitude >= -90,
        decimalLatitude <= 90,
        decimalLongitude >= -180,
        decimalLongitude <= 180
      )

    validate(need(nrow(map_data) > 0, "No mappable observations match the current filters."))

    if (nrow(map_data) > 5000) {
      map_data <- slice_sample(map_data, n = 5000)
    }

    leaflet(map_data) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      addCircleMarkers(
        lng = ~decimalLongitude,
        lat = ~decimalLatitude,
        radius = 4,
        stroke = FALSE,
        fillOpacity = 0.55,
        color = "#1f5f3b",
        popup = ~paste0(
          "<strong>Country:</strong> ", ifelse(is.na(countryCode), "Unknown", countryCode),
          "<br><strong>Region:</strong> ", ifelse(is.na(stateProvince), "Unknown", stateProvince),
          "<br><strong>Year:</strong> ", ifelse(is.na(year), "Unknown", year),
          "<br><strong>Basis of record:</strong> ", ifelse(is.na(basisOfRecord), "Unknown", basisOfRecord)
        ),
        clusterOptions = markerClusterOptions()
      )
  })
}

shinyApp(ui = ui, server = server)

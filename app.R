library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(leaflet)
library(plotly)

data_path <- file.path("data", "raw", "gbif-beetle.csv")

if (!file.exists(data_path)) {
  stop("Could not find data/raw/gbif-beetle.csv.")
}

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
map_tiles <- c(
  "Carto Light" = "CartoDB.Positron",
  "Esri Gray" = "Esri.WorldGrayCanvas",
  "OpenStreetMap" = "OpenStreetMap.Mapnik"
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
    selectInput(
      "map_underlay",
      "Map underlay",
      choices = map_tiles,
      selected = "Esri.WorldGrayCanvas"
    ),
    actionButton("reset_filters", "Reset filters", class = "btn-warning")
  ),
  layout_columns(
    uiOutput("total_obs_box"),
    uiOutput("first_recorded_box"),
    uiOutput("status_box"),
    col_widths = c(4, 4, 4)
  ),
  card(
    full_screen = TRUE,
    card_header("Geographic distribution map"),
    leafletOutput("obs_map", height = 420)
  ),
  layout_columns(
    card(
      full_screen = TRUE,
      card_header("Occurrences over time"),
      plotlyOutput("year_plot", height = 320)
    ),
    card(
      full_screen = TRUE,
      card_header("Basis of record"),
      plotlyOutput("basis_plot", height = 320)
    ),
    col_widths = c(6, 6)
  ),
  layout_columns(
    card(
      full_screen = TRUE,
      card_header("Top rights holders"),
      plotlyOutput("rights_plot", height = 320)
    ),
    card(
      full_screen = TRUE,
      card_header("Seasonal observations"),
      plotlyOutput("month_plot", height = 320)
    ),
    col_widths = c(6, 6)
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
    updateSelectInput(session, "map_underlay", selected = "Esri.WorldGrayCanvas")
  })

  output$total_obs_box <- renderUI({
    value_box(
      title = "Total observations",
      value = format(nrow(filtered_data()), big.mark = ",")
    )
  })

  output$first_recorded_box <- renderUI({
    first_year <- filtered_data() |>
      summarise(n = min(year, na.rm = TRUE)) |>
      pull(n)

    if (!is.finite(first_year)) {
      first_year <- "N/A"
    }

    value_box(
      title = "First recorded",
      value = first_year
    )
  })

  output$status_box <- renderUI({
    latest_year <- filtered_data() |>
      filter(!is.na(year)) |>
      summarise(n = max(year, na.rm = TRUE)) |>
      pull(n)

    status_value <- filtered_data() |>
      filter(year == latest_year, !is.na(occurrenceStatus), nzchar(occurrenceStatus)) |>
      count(occurrenceStatus, sort = TRUE, name = "n") |>
      slice_head(n = 1) |>
      pull(occurrenceStatus)

    if (!length(status_value)) {
      status_value <- "N/A"
    }

    value_box(
      title = paste0("Status in region as of ", input$year_range[2]),
      value = tools::toTitleCase(tolower(status_value))
    )
  })

  output$year_plot <- renderPlotly({
    yearly_counts <- filtered_data() |>
      count(year, name = "observations")

    validate(need(nrow(yearly_counts) > 0, "No observations match the current filters."))

    p <- ggplot(
      yearly_counts,
      aes(
        x = year,
        y = observations,
        group = 1,
        text = paste0(
          "Year: ", year,
          "<br>Observations: ", format(observations, big.mark = ",")
        )
      )
    ) +
      geom_line(color = "#1f5f3b", linewidth = 1) +
      geom_point(color = "#1f5f3b", size = 2) +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      labs(
        x = "Year",
        y = "Observations"
      ) +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = "text") |>
      layout(hoverlabel = list(align = "left"), showlegend = FALSE)
  })

  output$basis_plot <- renderPlotly({
    basis_counts <- filtered_data() |>
      filter(!is.na(basisOfRecord), nzchar(basisOfRecord)) |>
      count(basisOfRecord, sort = TRUE, name = "observations")

    validate(need(nrow(basis_counts) > 0, "No basis of record data is available."))

    plot_ly(
      basis_counts,
      labels = ~basisOfRecord,
      values = ~observations,
      type = "pie",
      hole = 0.45,
      textinfo = "label+percent",
      hovertemplate = paste(
        "%{label}",
        "<br>Observations: %{value:,}",
        "<br>Share: %{percent}",
        "<extra></extra>"
      )
    ) |>
      layout(showlegend = TRUE)
  })

  output$rights_plot <- renderPlotly({
    rights_counts <- filtered_data() |>
      filter(!is.na(rightsHolder), nzchar(rightsHolder)) |>
      count(rightsHolder, sort = TRUE, name = "observations") |>
      slice_head(n = 10)

    validate(need(nrow(rights_counts) > 0, "No rights holder data is available."))

    plot_ly(
      rights_counts,
      x = ~observations,
      y = ~reorder(rightsHolder, observations),
      type = "bar",
      orientation = "h",
      marker = list(color = "#4f79a8"),
      hovertemplate = paste(
        "Rights holder: %{y}",
        "<br>Observations: %{x:,}",
        "<extra></extra>"
      )
    ) |>
      layout(
        xaxis = list(title = "Observations"),
        yaxis = list(title = ""),
        margin = list(l = 180)
      )
  })

  output$month_plot <- renderPlotly({
    monthly_counts <- filtered_data() |>
      filter(!is.na(month), month >= 1, month <= 12) |>
      count(month, name = "observations") |>
      mutate(month_label = factor(month_levels[month], levels = month_levels))

    validate(need(nrow(monthly_counts) > 0, "No monthly observation data is available."))

    p <- ggplot(
      monthly_counts,
      aes(
        x = month_label,
        y = observations,
        text = paste0(
          "Month: ", month_label,
          "<br>Observations: ", format(observations, big.mark = ",")
        )
      )
    ) +
      geom_col(fill = "#7fb069") +
      labs(
        x = "Month",
        y = "Observations"
      ) +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = "text") |>
      layout(hoverlabel = list(align = "left"), showlegend = FALSE)
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
      addProviderTiles(providers[[input$map_underlay]]) |>
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

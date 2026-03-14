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
  tags$head(
    tags$style(HTML("
      body {
        background: #edf7eb;
      }
      .bslib-sidebar-layout > .main {
        background: #edf7eb;
      }
      .card {
        border: 1px solid #d5e2d1;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
      }
      .chart-card {
        background: #f1f7e8;
      }
      .chart-card > .card-header {
        background: #9fcd9f;
        color: #215c2d;
        font-weight: 600;
      }
      .section-card > .card-header {
        background: #edf7eb;
        font-size: 1.15rem;
        font-weight: 600;
      }
      .leaflet-hint {
        background: rgba(255, 255, 255, 0.92);
        padding: 10px 14px;
        border-radius: 10px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.18);
        font-size: 0.95rem;
      }
      .chart-frame {
        min-height: 380px;
      }
      .chart-frame .html-widget,
      .chart-frame .plotly,
      .chart-frame .plot-container {
        height: 100% !important;
        min-height: 340px;
      }
    "))
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
    class = "section-card",
    full_screen = TRUE,
    card_header("Geographic distribution map"),
    leafletOutput("obs_map", height = 420)
  ),
  card(
    class = "section-card",
    full_screen = TRUE,
    card_header("Observation charts"),
    layout_columns(
      card(
        class = "chart-card",
        full_screen = TRUE,
        card_header("Occurrences over time"),
        card_body(
          class = "chart-frame",
          fill = TRUE,
          plotlyOutput("year_plot", height = "100%")
        )
      ),
      card(
        class = "chart-card",
        full_screen = TRUE,
        card_header("Basis of record"),
        card_body(
          class = "chart-frame",
          fill = TRUE,
          plotlyOutput("basis_plot", height = "100%")
        )
      ),
      col_widths = c(6, 6)
    )
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
      geom_line(color = "#4f79a8", linewidth = 1.1) +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      scale_y_continuous(labels = scales::comma) +
      labs(
        x = "Year",
        y = "Observations"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "#f8faf6", color = NA),
        plot.background = element_rect(fill = "#f8faf6", color = NA)
      )

    ggplotly(p, tooltip = "text") |>
      layout(
        hoverlabel = list(align = "left"),
        showlegend = FALSE,
        paper_bgcolor = "#f1f7e8",
        plot_bgcolor = "#f8faf6"
      ) |>
      config(displayModeBar = FALSE)
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
      sort = FALSE,
      marker = list(colors = c("#4f79a8", "#f28e2b", "#d45b52", "#6db3af")),
      textinfo = "none",
      hovertemplate = paste(
        "%{label}",
        "<br>Observations: %{value:,}",
        "<br>Share: %{percent}",
        "<extra></extra>"
      )
    ) |>
      layout(
        showlegend = TRUE,
        paper_bgcolor = "#f1f7e8",
        plot_bgcolor = "#f8faf6"
      ) |>
      config(displayModeBar = FALSE)
  })

  output$obs_map <- renderLeaflet({
    if (!requireNamespace("leaflet.extras2", quietly = TRUE)) {
      stop("Package 'leaflet.extras2' is required for the hexbin map. Install it with install.packages('leaflet.extras2', repos = 'https://cloud.r-project.org').")
    }

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
      addControl(
        html = "<div class='leaflet-hint'>Hover over a cell</div>",
        position = "topright"
      ) |>
      leaflet.extras2::addHexbin(
        lng = ~decimalLongitude,
        lat = ~decimalLatitude,
        radius = 12,
        opacity = 0.6,
        options = leaflet.extras2::hexbinOptions(
          colorRange = c("#2b0a8f", "#7a1fa2", "#c03a7a", "#f18f3b", "#f0f921"),
          tooltip = "Observations: "
        )
      )
  })
}

shinyApp(ui = ui, server = server)

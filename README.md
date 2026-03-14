# Japanese Beetle Tracker

An R Shiny dashboard for tracking Japanese beetle observations across the world.

## App Purpose

The dashboard helps users explore Japanese beetle observations across time and location. It allows filtering the dataset to answer questions such as:

- how observation volume changes by year
- how observations are distributed geographically
- how citizen-science versus other record types appear in the dataset

## Install Packages

Option 1: use `renv` to restore the project environment.

```r
install.packages("renv")
renv::restore()
```

Option 2: install the required packages directly.

```r
install.packages(c("shiny", "bslib", "dplyr", "ggplot2", "leaflet", "leaflet.extras2", "plotly", "scales"))
```

## Run Locally

From the repository root in R:

```r
shiny::runApp()
```

Or from the terminal:

```bash
R -e "shiny::runApp()"
```

## Deployment

This app is deployed on Posit Connect Cloud.

- `app.R` as the app entry point
- `manifest.json` for Posit Connect Cloud deployment
- `DESCRIPTION` for dependency detection
- `renv.lock` for local package restoration

## Deployed App

[Open the deployed app](https://019ceb45-947d-b345-2aaf-b2d623ebec62.share.connect.posit.cloud/)

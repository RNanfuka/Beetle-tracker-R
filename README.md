# Japanese Beetle Tracker

This repository contains my individual assignment app for DSCI 532. It re-implements the group project's beetle dashboard in Shiny for R, using GBIF occurrence data for `Popillia japonica`.

The app supports the assignment requirements with:

- input controls for `year range`, `country`, and `basis of record`
- a reactive filtered dataset that updates from the selected inputs
- multiple reactive outputs: value boxes, plots and an interactive map

## App Purpose

The dashboard helps users explore Japanese beetle observations across time and location. It allows filtering the dataset to answer questions such as:

- how observation volume changes by year
- which months have the most records
- which countries and regions contribute observations
- how citizen-science versus other record types appear in the dataset

## Project Structure

```text
Beetle-tracker-R/
├── app.R
├── data/raw/gbif-beetle.csv
├── notebooks/eda_analysis.Rmd
├── DESCRIPTION
├── renv.lock
└── README.md
```

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

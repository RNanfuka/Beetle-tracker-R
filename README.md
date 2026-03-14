# Japanese Beetle Tracker

This repository contains my individual assignment app for DSCI 532. It re-implements the group project's beetle dashboard in Shiny for R, using GBIF occurrence data for `Popillia japonica`.

The app supports the assignment requirements with:

- input controls for `year range`, `country`, and `basis of record`
- a reactive filtered dataset that updates from the selected inputs
- multiple reactive outputs: value boxes, plots, a table, and an interactive map

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
├── src/app.R
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
install.packages(c("shiny", "bslib", "dplyr", "ggplot2", "leaflet", "scales"))
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

Deploy this repository to your own Posit Connect Cloud account. The repository includes:

- `app.R` as the root app entry point
- `DESCRIPTION` for dependency detection
- `renv.lock` for package restoration

After deployment:

1. Copy the deployed app URL.
2. Add the URL to the GitHub repository About section.
3. Keep the repository public for grading.

## Deployed App

Add your Posit Connect Cloud link here after deployment:

`<paste deployed app URL here>`

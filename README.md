# Beetle-tracker-R

## Japanese Beetle Tracker

This repository contains my individual Shiny for R version of the Japanese Beetle dashboard. The app uses GBIF occurrence data to let users explore where beetle observations happened, how observation counts changed over time, and which locations contribute the most records.

The dashboard includes:

- input controls for year range, country, and basis of record
- a reactive filtered dataset shared across outputs
- multiple reactive outputs: value boxes, plots, a table, and an interactive map

## Project Structure

The repository is organized as follows:

```
Beetle-tracker-R/
├── src/
│   ├── app.R
│   ├── www/  # Static assets (CSS, JS, etc.)
├── data/
│   ├── raw/  # Raw data files
│       ├── gbif-beetle.csv
├── img/      # Images for the project
├── notebooks/ # EDA and analysis notebooks
├── reports/  # Reports and documentation
├── DESCRIPTION
├── LICENSE
├── README.md
```

### Instructions

1. **Set up the R environment**:
   ```R
   install.packages("renv")
   renv::init()
   renv::restore()
   ```

2. **Run the Shiny App**:
   ```R
   shiny::runApp("src/app.R")
   ```

3. **Contributing**:
   - Follow the project structure.
   - Commit changes with meaningful messages.
   - Push changes to the repository.

4. **Data**:
   - Place raw data files in the `data/raw/` folder.
   - Processed data can be stored in `data/processed/` (if needed).

5. **Reports**:
   - Add reports and documentation in the `reports/` folder.

6. **Notebooks**:
   - Add EDA and analysis notebooks in the `notebooks/` folder.

## Running the App Locally

### Install packages

Open R and install the required packages:

```r
install.packages(c("shiny", "bslib", "dplyr", "ggplot2", "leaflet", "scales"))
```

The repository also includes a `DESCRIPTION` file so Posit Connect Cloud can detect dependencies during deployment.

### Run the app

From the repository root, start the app with:

```r
shiny::runApp()
```

Or from the terminal:

```bash
R -e "shiny::runApp()"
```

## Repository Structure

- `app.R`: main Shiny for R application
- `DESCRIPTION`: dependency manifest for Posit Connect Cloud
- `data/raw/gbif-beetle.csv`: occurrence data used by the app

## Deployment

Deploy this repository to your own Posit Connect Cloud account. After deployment:

1. Copy the stable deployed URL.
2. Add that URL to the GitHub repository About section.
3. Make sure the repository stays public for grading.

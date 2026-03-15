# Film-Industry-EDA

### Exploratory Data Analysis of 60,000+ Films Using R, SQLite, and ggplot2

---

## Overview
This project performs an exploratory data analysis of over 60,000 films sourced from The Movie Database (TMDB). The goal is to uncover patterns in genre popularity, audience ratings, and release trends across four decades of cinema (1980–2023).

Raw data is loaded into a local SQLite database and queried with SQL before being pulled into R for wrangling and visualization using the tidyverse ecosystem.

---

## Key Questions
- Which genres are most represented in the film industry?
- How have genre trends shifted across decades?
- Which genres receive the highest audience ratings?
- How have average ratings changed over time?
- Which movies have the highest popularity scores?
- Is there a relationship between a movie's popularity and its rating?
- Do Action and Drama movies receive significantly different ratings?

---

## Workflow
```
CSV → SQLite Database → SQL Query → R (tidyverse) → ggplot2 Visualizations
```

---

## Visualizations

| Plot | Description |
|------|-------------|
| `01_releases_per_year.png` | Number of movie releases per year (1980–2023) |
| `02_top_genres.png` | Top 10 genres by total movie count |
| `03_rating_by_genre.png` | Top 10 genres by average audience rating |
| `04_genre_trends_decade.png` | How the top 6 genres have grown or declined by decade |
| `05_rating_by_decade.png` | Average audience rating per decade |
| `06_most_popular.png` | Top 10 most popular movies by TMDB popularity score |

---

## Statistical Analysis

**Pearson Correlation — Popularity vs. Rating**
Tests whether a movie's popularity score is related to its audience rating.

**Welch Two-Sample T-Test — Action vs. Drama Ratings**
Tests whether Action and Drama movies receive statistically different audience ratings.
- H₀: No significant difference in ratings between Action and Drama movies
- H₁: A significant difference exists

---
## Key Findings

**Popularity vs. Rating (Pearson Correlation, r = 0.087)**
There is a statistically significant but practically negligible relationship between a movie's popularity score and its audience rating (r = 0.087, p < 0.001). This suggests that popularity and quality are largely independent — a movie can be widely watched without being highly rated, and vice versa.

**Action vs. Drama Ratings (Welch T-Test, p < 0.001)**
Action and Drama movies receive statistically different audience ratings. The difference is significant at the p < 0.05 level, indicating that genre is a meaningful factor in how audiences rate films on TMDB.

---

## Data & Filtering Decisions

**Source:** [TMDB Movies Dataset on Kaggle](https://www.kaggle.com/datasets/asaniczka/tmdb-movies-dataset-2023-930k-movies) — 1.38M rows, 24 columns

**Filters applied:**
- `status = 'Released'` — excludes movies still in production, planned, or cancelled
- `release_year >= 1980 AND release_year <= 2023` — focuses on four decades of modern cinema
- `vote_count >= 10` — removes entries with insufficient community ratings, reducing noise from obscure or low-quality entries. TMDB is a community-contributed database, so a minimum vote threshold ensures only movies with measurable audience engagement are included.

**Note on date filtering:** SQLite stores R date objects as integers (days since 1970-01-01) rather than human-readable strings. Date range filtering was therefore handled in R using `lubridate` after querying from SQLite, rather than directly in SQL.

**Note on financial data:** Budget and revenue fields were excluded from this analysis. Only ~17,000 of 1.38M entries had both budget and revenue recorded — insufficient for meaningful analysis.

---

## Tech Stack
- **Language:** R
- **Packages:** tidyverse, ggplot2, lubridate, scales, ggrepel, DBI, RSQLite, readr
- **Database:** SQLite (via DBI + RSQLite)
- **Analysis:** Pearson Correlation, Welch Two-Sample T-Test

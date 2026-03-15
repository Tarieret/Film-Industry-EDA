# install necessary packages
install.packages(c("tidyverse", "lubridate", "scales", "ggrepel","RSQLite", "DBI"))
               
library(tidyverse)
library(lubridate)
library(scales)
library(ggrepel)
library(RSQLite)
library(DBI)

# load data (!large data set, give it a minute or two)
library(readr)
movies_raw <- read_csv("Documents/Programming/R/tmdb-movie-analysis/data/TMDB_1M_movie_dataset.csv")
View(movies_raw)

dim(movies_raw)
shape(movies_raw)
names(movies_raw)
data.class(movies_raw)

#----------------------------------------------------------------------------------

# Create database file and open connection to load into SQLITE
con <- dbConnect(SQLite(), "Documents/Programming/R/tmdb-movie-analysis/data/tmdb.db")

# Write dataframe to SQLite as a table (one-time, takes a few minutes)
dbWriteTable(con, "movies", movies_raw, overwrite = TRUE)

# Confirm if table loaded
dbListTables(con)


# Pull clean, filtered dataset for analysis by querying the SQLite database. 
#We filter for released movies with valid release dates between 1980 and 2023. 
# This sholud give us around 100k movies to work with.
movies <- dbGetQuery(con, "
  SELECT
    id,
    title,
    release_date,
    vote_average,
    vote_count,
    popularity,
    runtime,
    genres,
    original_language,
    status
  FROM movies
  WHERE status = 'Released'
    AND release_date IS NOT NULL
    AND release_date != ''
") |>
  mutate(
    release_date = as.Date(release_date, origin = "1970-01-01"),
    release_year = year(release_date)
  ) |>
filter(
  !is.na(release_date),
  release_year >= 1980,
  release_year <= 2023,
  vote_count >= 10
)

cat("Rows after filtering:", nrow(movies), "\n")


#---------------------------------------------------------------------------------


# Get summary Stats
cat("\n--- Basic Summary ---\n")
movies |>
  summarise(
    total_movies  = n(),
    avg_rating    = round(mean(vote_average, na.rm = TRUE), 2),
    median_rating = round(median(vote_average, na.rm = TRUE), 2),
    avg_runtime   = round(mean(runtime, na.rm = TRUE), 1),
    avg_popularity = round(mean(popularity, na.rm = TRUE), 2)
  ) |>
  print()


#  Genres: Genres are stored as comma-separated strings — split into individual rows
genres_df <- movies |>
  select(id, title, release_year, vote_average, vote_count, popularity, genres) |>
  mutate(genres = str_remove_all(genres, "\\[|\\]|'")) |>
  separate_rows(genres, sep = ",\\s*") |>
  filter(genres != "", !is.na(genres))

cat("Genre rows:", nrow(genres_df), "\n")

# Color palette
my_palette <- c("#4E79A7","#F28E2B","#E15759","#76B7B2",
                "#59A14F","#EDC948","#B07AA1","#FF9DA7","#9C755F","#BAB0AC")


# Plot 1: Movie releases per year
movies |>
  count(release_year) |>
  ggplot(aes(x = release_year, y = n)) +
  geom_line(color = "#4E79A7", linewidth = 1) +
  geom_area(fill = "#4E79A7", alpha = 0.2) +
  scale_y_continuous(labels = comma) +
  labs(
    title   = "Movie Releases Per Year (1980–2023)",
    x       = "Year",
    y       = "Number of Movies",
    caption = "Source: TMDB"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Documents/Programming/R/tmdb-movie-analysis/plots/01_releases_per_year.png",
       width = 10, height = 6, dpi = 150)

# Plot 2: Top 10 genres by movie count
genres_df |>
  count(genres, sort = TRUE) |>
  slice_head(n = 10) |>
  ggplot(aes(x = n, y = reorder(genres, n), fill = genres)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = comma(n)), hjust = -0.1, size = 3) +
  scale_fill_manual(values = my_palette) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title   = "Top 10 Genres by Movie Count",
    x       = "Number of Movies",
    y       = NULL,
    caption = "Source: TMDB"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )

ggsave("Documents/Programming/R/tmdb-movie-analysis/plots/02_top_genres.png",
       width = 9, height = 6, dpi = 150)

# Plot 3: Average rating by genres
genres_df |>
  group_by(genres) |>
  summarise(avg_rating = mean(vote_average, na.rm = TRUE), n = n()) |>
  filter(n >= 500) |>
  slice_max(avg_rating, n = 10) |>
  ggplot(aes(x = avg_rating, y = reorder(genres, avg_rating), fill = genres)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = round(avg_rating, 2)), hjust = -0.1, size = 3) +
  scale_fill_manual(values = my_palette) +
  scale_x_continuous(limits = c(0, 10), expand = expansion(mult = c(0, 0.1))) +
  labs(
    title   = "Top 10 Genres by Average Rating",
    x       = "Average Rating (out of 10)",
    y       = NULL,
    caption = "Source: TMDB | Genres with 500+ movies only"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )

ggsave("Documents/Programming/R/tmdb-movie-analysis/plots/03_rating_by_genre.png",
       width = 10, height = 6, dpi = 150)

# Plot 4: Genre popularity over decades
top6_genres <- genres_df |>
  count(genres, sort = TRUE) |>
  slice_head(n = 6) |>
  pull(genres)

genres_df |>
  filter(genres %in% top6_genres) |>
  mutate(decade = floor(release_year / 10) * 10) |>
  count(decade, genres) |>
  ggplot(aes(x = decade, y = n, color = genres)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = my_palette) +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(breaks = seq(1980, 2020, 10)) +
  labs(
    title   = "Top 6 Genre Trends by Decade",
    x       = "Decade",
    y       = "Number of Movies",
    color   = "Genre",
    caption = "Source: TMDB"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Documents/Programming/R/tmdb-movie-analysis/plots/04_genre_trends_decade.png",
       width = 10, height = 6, dpi = 150)

# Plot 5: Average rating by decade
movies |>
  mutate(decade = floor(release_year / 10) * 10) |>
  group_by(decade) |>
  summarise(avg_rating = mean(vote_average, na.rm = TRUE), n = n()) |>
  ggplot(aes(x = decade, y = avg_rating)) +
  geom_line(color = "#4E79A7", linewidth = 1.2) +
  geom_point(color = "#4E79A7", size = 3) +
  scale_x_continuous(breaks = seq(1980, 2020, 10)) +
  scale_y_continuous(limits = c(0, 10)) +
  labs(
    title   = "Average Movie Rating by Decade",
    x       = "Decade",
    y       = "Average Rating (out of 10)",
    caption = "Source: TMDB"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Documents/Programming/R/tmdb-movie-analysis/plots/05_rating_by_decade.png",
       width = 9, height = 6, dpi = 150)

# Plot 6: Top 10 most popular movies (by popularity score) 
# Filtered to movies with 100+ votes to ensure mainstream relevance
movies |>
  filter(vote_count >= 100) |>
  slice_max(popularity, n = 10) |>
  ggplot(aes(x = popularity, y = reorder(title, popularity))) +
  geom_col(fill = "#4E79A7", width = 0.7) +
  geom_text(aes(label = round(popularity, 1)), hjust = -0.1, size = 3) +
  scale_x_continuous(
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.2))
  ) +
  labs(
    title    = "Top 10 Most Popular Movies",
    subtitle = "Among movies with 1,000+ votes",
    x        = "Popularity Score",
    y        = NULL,
    caption  = "Source: TMDB"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )

ggsave("Documents/Programming/R/tmdb-movie-analysis/plots/06_most_popular.png",
       width = 10, height = 6, dpi = 150)



#-----------------------------------------------------------------------------------

# Statistical Analysis: Correlation and T-Test

# Correlation: Popularity vs Rating
# To see if there's a relationship between how popular a movie is (popularity score) 
#and how well it's rated (vote_average).
cat("\n Correlation: Popularity vs Rating \n")
cor_test <- cor.test(movies$popularity, movies$vote_average, method = "pearson")
print(cor_test)
cat("Correlation coefficient:", round(cor_test$estimate, 3), "\n")

# correlation coefficient (r) ranges from -1 to 1:
# r > 0 indicates a positive correlation (as popularity increases, ratings tend to increase)
# r < 0 indicates a negative correlation (as popularity increases, ratings tend to decrease)
# r = 0 indicates no correlation (popularity and ratings are not related)


# T-Test: Do Action movies rate higher than Drama? 
# comparing the average ratings of Action and Drama movies using a t-test to see if there's a statistically significant difference between the two genres.
cat("\n T-Test: Action vs Drama Ratings \n")
action_ratings <- genres_df |> filter(genres == "Action") |> pull(vote_average)
drama_ratings  <- genres_df |> filter(genres == "Drama")  |> pull(vote_average)

t_result <- t.test(action_ratings, drama_ratings)
print(t_result)

cat("\nConclusion:\n")
if (t_result$p.value < 0.05) {
  cat("p =", round(t_result$p.value, 4),
      "< 0.05 — Significant difference in ratings between Action and Drama movies.\n")
} else {
  cat("p =", round(t_result$p.value, 4),
      ">= 0.05 — No significant difference detected.\n")
}

# Additionally, we can look at the average ratings for each genre to see which one has a higher mean rating.
genres_df |>
  filter(genres %in% c("Action", "Drama")) |>
  group_by(genres) |>
  summarise(
    avg_rating = round(mean(vote_average, na.rm = TRUE), 3),
    n = n()
  )
#------------------------------------------------------------------------------------------

# Close DB connection
dbDisconnect(con)
cat("\nDatabase connection closed. Analysis complete!\n")
cat("Plots saved to /plots folder.\n")

# Loading necessary libraries

library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RSQLite)

# Variables that will be used in the script going forward

start_date = "2026-06-09" # picking one date to ensure that pull is successful
end_date = "2026-06-09"
season = format(as.Date(end_date), "%Y")

base_url = "https://statsapi.mlb.com/api/v1"
savant_url = "https://baseballsavant.mlb.com/statcast_search/csv"
params = list(sportId = 1, startDate = start_date, endDate = end_date)

# Setup the database 

db_file = "baseball.sqlitedb"
conn <- dbConnect(RSQLite::SQLite(), db_file)
dbExecute(conn, "PRAGMA foreign_keys = ON")

# Set up function to write data into db once data has been pulled

insert_rows <- function(table, df) {
  sql <- sprintf("INSERT OR REPLACE INTO %s (%s) VALUES (%s)",
                 table,
                 paste(names(df), collapse = ", "),
                 paste(rep("?", ncol(df)), collapse = ", "))
  dbExecute(conn, sql, params = unname(as.list(df)))
}


# Set up to pull data from the API

get_with_retry <- function(api_url, query = list(), max_tries = 3, timeout_sec = 30) {
  stop_codes <- c(400, 401, 403, 404)
  
  for (i in 1:max_tries) {
    response <- tryCatch(
      GET(api_url, query = query, timeout(timeout_sec)),
      error = function(e) NULL
    )
    
    if (is.null(response)) {
      message("Attempt ", i, " of ", max_tries, ": no response")
      next
    }
    
    code <- status_code(response)
    
    if (code == 200) return(content(response, as = "text", encoding = "UTF-8"))
    
    if (code %in% stop_codes) {
      message("HTTP ", code, " (not retrying): ", api_url)
      return(NULL)
    }
    
    message("Attempt ", i, " of ", max_tries, ": HTTP ", code)
  }
  
  NULL
}

#MLB endpoint

get_mlb <- function(endpoint, query = list()) {
  txt <- get_with_retry(paste0(base_url, "/", endpoint), query = query)
  if (is.null(txt)) return(NULL)
  fromJSON(txt, simplifyVector = FALSE)
}

# Cleaning function to run on each table
#trims white-space, turns empty strings into NA,
# drops rows with a missing key, and keeps the first row of any duplicated key

clean_df <- function(df, key) {
  n_start <- nrow(df)
  
  df <- df |>
    mutate(across(where(is.character), ~ na_if(trimws(.x), ""))) |>
    filter(if_all(all_of(key), ~ !is.na(.x))) |>
    distinct(across(all_of(key)), .keep_all = TRUE)
  
  message("clean_df: ", n_start - nrow(df), " rows dropped (missing or duplicate key)")
  df
}

# Fetches any player ids not yet in the players data frame from the people endpoint
# and returns the players data frame with them added (nothing is written to the db here)

add_missing_players <- function(players, ids) {
  ids <- setdiff(unique(ids[!is.na(ids)]), players$player_id)

  if (length(ids) == 0) {
    message("add_missing_players: none missing")
    return(players)
  }

  new_list <- lapply(split(ids, ceiling(seq_along(ids) / 100)), function(chunk) {
    res <- get_mlb("people", list(personIds = paste(chunk, collapse = ",")))
    if (is.null(res)) return(NULL)
    tibble(player = res$people)
  })

  new_df <- bind_rows(new_list) |>
    hoist(
      player,
      player_id     = "id",
      player_name   = "fullName",
      position_code = c("primaryPosition", "code"),
      position_name = c("primaryPosition", "name"),
      current_age   = "currentAge",
      bats          = c("batSide", "code"),
      throws        = c("pitchHand", "code")
    ) |>
    select(-player) |>
    mutate(across(c(player_id, current_age), as.integer)) |>
    clean_df("player_id")

  print(new_df)
  message("add_missing_players: ", nrow(new_df), " players added")
  bind_rows(players, new_df)
}

# Pull "Team" data first

team_data <- get_mlb("teams", list(sportId = 1, season = season))
if (is.null(team_data)) stop("Teams pull failed")

teams_df <- tibble(team = team_data$teams) |>
  hoist(
    team,
    team_id           = "id",
    team_name         = "name",
    team_nickname     = "teamName",
    team_location     = "locationName",
    team_abbreviation = "abbreviation",
    team_first_year   = "firstYearOfPlay",
    team_active       = "active",
    team_league_id    = c("league", "id"),
    team_division_id  = c("division", "id")
  ) |>
  select(-team) |>
  mutate(
    across(c(team_id, team_first_year, team_league_id, team_division_id), as.integer),
    team_active = as.integer(team_active)
  )

teams_df <- clean_df(teams_df, "team_id")

print(head(teams_df))

# Checking for missing values and duplicates

# Missing values by column
colSums(is.na(teams_df))

# Rows with at least one missing value
teams_df |> filter(if_any(everything(), is.na))

# Searching for empty strings 
teams_df |> summarise(across(where(is.character), ~ sum(.x == "", na.rm = TRUE)))

# Unique, non-missing team_id and unique team_name check
sum(duplicated(teams_df$team_id))
sum(duplicated(teams_df$team_name))
sum(is.na(teams_df$team_id))

# Check types and row count too (expect 30 rows)
str(teams_df)
nrow(teams_df)

# Retrieve the player roster, getting one per team

roster_list <- lapply(teams_df$team_id, function(tid) {
  roster <- get_mlb(paste0("teams/", tid, "/roster"),
                    list(rosterType = "active", hydrate = "person", date = end_date))
  if (is.null(roster)) {
    message("Roster pull failed for team ", tid)
    return(NULL)
  }
  Sys.sleep(0.2)
  tibble(player = roster$roster, roster_team_id = tid)
})

players_df <- bind_rows(roster_list) |>
  hoist(
    player,
    player_id     = c("person", "id"),
    player_name   = c("person", "fullName"),
    position_code = c("person", "primaryPosition", "code"),
    position_name = c("person", "primaryPosition", "name"),
    current_age   = c("person", "currentAge"),
    bats          = c("person", "batSide", "code"),
    throws        = c("person", "pitchHand", "code")
  ) |>
  select(-player) |>
  mutate(across(c(player_id, roster_team_id, current_age), as.integer))

# Clean data before loading

players_df <- players_df |>
  clean_df("player_id") |>
  mutate(roster_team_id = if_else(roster_team_id %in% teams_df$team_id,
                                  roster_team_id, NA_integer_))

print(head(players_df))

# Checking for missing values and duplicates

# Missing values by column
colSums(is.na(players_df))

# Rows with at least one missing value

players_df |> filter(if_any(everything(), is.na))

#Searching for empty strings

players_df |> summarise(across(where(is.character), ~ sum(.x == "", na.rm = TRUE)))

# player_id must be unique and non-missing 
sum(duplicated(players_df$player_id))
sum(is.na(players_df$player_id))

# Every roster_team_id must exist in team 
setdiff(players_df$roster_team_id, teams_df$team_id)

# Check types and row count 
str(players_df)
nrow(players_df)

# No team should be missing or oddly small
players_df |> 
          count(roster_team_id) |> 
              arrange(n)

# Pull " Schedule" data


schedule_data <- get_mlb("schedule", params)
if (is.null(schedule_data)) stop("Schedule pull failed")
if (length(schedule_data$dates) == 0) stop("No games in that date range")

# Games are nested inside each date, so stack them into one list
games <- unlist(lapply(schedule_data$dates, function(d) d$games), recursive = FALSE)

schedule_df <- tibble(game = games) |>
  hoist(
    game,
    game_id      = "gamePk",
    game_date    = "officialDate",
    start_utc    = "gameDate",
    game_type    = "gameType",
    game_status  = c("status", "detailedState"),
    away_team_id = c("teams", "away", "team", "id"),
    home_team_id = c("teams", "home", "team", "id"),
    away_score   = c("teams", "away", "score"),
    home_score   = c("teams", "home", "score")
  ) |>
  select(-game) |>
  mutate(across(c(game_id, away_team_id, home_team_id, away_score, home_score), as.integer))

# Clean data before loading

schedule_df <- schedule_df |>
  clean_df("game_id") |>
  mutate(
    away_team_id = if_else(away_team_id %in% teams_df$team_id, away_team_id, NA_integer_),
    home_team_id = if_else(home_team_id %in% teams_df$team_id, home_team_id, NA_integer_)
  )

print(head(schedule_df))

# Checking for any missing values and duplicates

# Missing values by column
colSums(is.na(schedule_df))

# Rows with at least one missing value

schedule_df |> filter(if_any(everything(), is.na))

# Searching for empty strings
schedule_df |> summarise(across(where(is.character), ~ sum(.x == "", na.rm = TRUE)))

# game_id must be unique and non-missing
sum(duplicated(schedule_df$game_id))
sum(is.na(schedule_df$game_id))

# Every team id must exist in team
setdiff(c(schedule_df$away_team_id, schedule_df$home_team_id), teams_df$team_id)

# Types, row count, and what kinds of games came back
str(schedule_df)
nrow(schedule_df)
schedule_df |> count(game_type, game_status)

# Pull Box_score data

# Pull "Box Score" data: one call per finished game

final_games <- schedule_df$game_id[schedule_df$game_status == "Final"]

get_box_players <- function(gid) {
  box <- get_mlb(paste0("game/", gid, "/boxscore"))
  if (is.null(box)) {
    message("Box score pull failed for game ", gid)
    return(NULL)
  }
  Sys.sleep(0.2)
  bind_rows(lapply(c("away", "home"), function(side) {
    team <- box$teams[[side]]
    tibble(player = unname(team$players), game_id = gid, team_id = team$team$id)
  }))
}

box_list <- lapply(final_games, get_box_players)

box_df <- bind_rows(box_list) |>
  hoist(
    player,
    player_id           = c("person", "id"),
    plate_appearances   = c("stats", "batting", "plateAppearances"),
    at_bats             = c("stats", "batting", "atBats"),
    hits                = c("stats", "batting", "hits"),
    home_runs           = c("stats", "batting", "homeRuns"),
    rbi                 = c("stats", "batting", "rbi"),
    putouts             = c("stats", "fielding", "putOuts"),
    assists             = c("stats", "fielding", "assists"),
    innings_pitched     = c("stats", "pitching", "inningsPitched"),
    earned_runs         = c("stats", "pitching", "earnedRuns"),
    pitching_strikeouts = c("stats", "pitching", "strikeOuts"),
    mlb_pitches         = c("stats", "pitching", "numberOfPitches")
  ) |>
  select(-player) |>
  mutate(
    # innings are written like "6.1" (6 innings, 1 out), so convert to total outs
    ip = as.numeric(innings_pitched),
    pitching_outs = as.integer(floor(ip) * 3 + round((ip %% 1) * 10)),
    across(c(game_id, player_id, team_id, plate_appearances, at_bats, hits, home_runs,
             rbi, putouts, assists, earned_runs, pitching_strikeouts, mlb_pitches),
           as.integer)
  ) |>
  select(game_id, player_id, team_id, plate_appearances, at_bats, hits, home_runs, rbi,
         putouts, assists, pitching_outs, earned_runs, pitching_strikeouts, mlb_pitches)

# Drop players on the roster sheet who never played
n_before <- nrow(box_df)
box_df <- box_df |>
  filter(if_any(c(plate_appearances, at_bats, hits, home_runs, rbi, putouts, assists,
                  pitching_outs, earned_runs, pitching_strikeouts, mlb_pitches),
                ~ !is.na(.x)))
message(n_before - nrow(box_df), " rows dropped (no stats recorded)")

# Clean the data keeping unknown teams with NA
box_df <- box_df |>
  clean_df(c("game_id", "player_id")) |>
  mutate(team_id = if_else(team_id %in% teams_df$team_id, team_id, NA_integer_))

print(head(box_df))

# Checking for missing values and duplicates

# Missing values by column (NAs in pitching columns are normal for hitters, and vice versa)
colSums(is.na(box_df))

# The NAs should all be of that kind (each of these should be 0)
box_df |> filter(is.na(at_bats), is.na(pitching_outs)) |> nrow()
box_df |> filter(!is.na(at_bats), if_any(c(plate_appearances, hits, home_runs, rbi), is.na)) |> nrow()
box_df |> filter(!is.na(pitching_outs), if_any(c(earned_runs, pitching_strikeouts, mlb_pitches), is.na)) |> nrow()

# Searching for empty strings
box_df |> summarise(across(where(is.character), ~ sum(.x == "", na.rm = TRUE)))

# game_id + player_id must be unique and non-missing
sum(duplicated(box_df[c("game_id", "player_id")]))
sum(is.na(box_df$game_id)); sum(is.na(box_df$player_id))

# Every game_id must exist in schedule
setdiff(box_df$game_id, schedule_df$game_id)

# Types, row count, and rows per game
str(box_df)
nrow(box_df)
box_df |> count(game_id) |> arrange(n)

# Players in the box scores who are not in players_df yet
length(setdiff(box_df$player_id, players_df$player_id))

# Fetch the missing players from the people endpoint and add them to players_df
players_df <- add_missing_players(players_df, box_df$player_id)

# Every player_id in box_df should now be in players_df (expect 0 rows)
setdiff(box_df$player_id, players_df$player_id)

# Pull "Transactions" data

trans_data <- get_mlb("transactions", 
                  list(startDate = start_date, endDate = end_date, sportId = 1))
if (is.null(trans_data)) stop("Transactions pull failed")

transactions_df <- tibble(trans = trans_data$transactions) |>
  hoist(
    trans,
    transaction_id   = "id",
    transaction_date = "date",
    effective_date   = "effectiveDate",
    player_id        = c("person", "id"),
    from_team_id     = c("fromTeam", "id"),
    to_team_id       = c("toTeam", "id"),
    type_code        = "typeCode",
    type_description = "typeDesc",
    description      = "description"
  ) |>
  select(-trans) |>
  mutate(across(c(transaction_id, player_id, from_team_id, to_team_id),
                as.integer))

# Clean the data (a team that is not in team, such as a minor league club, is set to NA)
transactions_df <- transactions_df |>
  clean_df("transaction_id") |>
  mutate(
    from_team_id = if_else(from_team_id %in% teams_df$team_id, from_team_id, NA_integer_),
    to_team_id   = if_else(to_team_id %in% teams_df$team_id, to_team_id, NA_integer_)
  )

print(head(transactions_df))

# Checking for missing values and duplicates

colSums(is.na(transactions_df))
transactions_df |> 
          summarise(across(where(is.character), ~ sum(.x == "", na.rm = TRUE)))

sum(duplicated(transactions_df$transaction_id))
sum(is.na(transactions_df$transaction_id))

# What kinds of transactions came back
transactions_df |> count(type_code, type_description) |> arrange(desc(n))

str(transactions_df)
nrow(transactions_df)

# Players in transactions who are not in players_df yet, then add them
length(setdiff(transactions_df$player_id[!is.na(transactions_df$player_id)],
               players_df$player_id))
players_df <- add_missing_players(players_df, transactions_df$player_id)

# Pull "Pitch" data from Statcast: one CSV per finished game

get_pitches <- function(gid) {
  txt <- get_with_retry(savant_url, 
                        list(all = "true", 
                        type = "details", 
                        game_pk = gid),
                        timeout_sec = 60)
  if (is.null(txt) || nchar(txt) < 100) {
    message("No Statcast data for game ", gid)
    return(NULL)
  }
  Sys.sleep(0.5)
  
  read_csv(I(txt), show_col_types = FALSE, progress = FALSE) |>
    transmute(
      game_id           = as.integer(game_pk),
      at_bat_number     = as.integer(at_bat_number),
      pitch_number      = as.integer(pitch_number),
      pitcher_id        = as.integer(pitcher),
      batter_id         = as.integer(batter),
      inning            = as.integer(inning),
      inning_half       = as.character(inning_topbot),
      pitch_type        = as.character(pitch_type),
      description       = as.character(description),
      release_speed     = as.numeric(release_speed),
      release_spin_rate = as.numeric(release_spin_rate)
    )
}

pitch_df <- bind_rows(lapply(final_games, get_pitches))

# Clean the data
pitch_df <- pitch_df |>
  clean_df(c("game_id", "at_bat_number", "pitch_number"))

print(head(pitch_df))

# Checking for missing values and duplicates

colSums(is.na(pitch_df))
pitch_df |> summarise(across(where(is.character), ~ sum(.x == "", na.rm = TRUE)))

sum(duplicated(pitch_df[c("game_id", "at_bat_number", "pitch_number")]))

# Every game_id must exist in schedule
setdiff(pitch_df$game_id, schedule_df$game_id)

str(pitch_df)
nrow(pitch_df)
pitch_df |> count(pitch_type) |> arrange(desc(n))

# Statcast pitches per game should closely match the MLB pitch counts in the box score
pitch_df |>
  count(game_id, name = "statcast") |>
  left_join(box_df |> group_by(game_id) |> summarise(mlb = sum(mlb_pitches, na.rm = TRUE)),
            by = "game_id") |>
  mutate(diff = statcast - mlb)

# Pitchers and batters not in players_df yet, then add them
players_df <- add_missing_players(players_df, c(pitch_df$pitcher_id, pitch_df$batter_id))

# INSERT ALL DATA INTO DATABASE TABLES
# Parent tables go first so the foreign keys are satisfied. Everything runs in one
# transaction, so if any insert fails, nothing is written.

dbWithTransaction(conn, {
  insert_rows("team",         teams_df)
  insert_rows("players",      players_df)
  insert_rows("schedule",     schedule_df)
  insert_rows("box_score",    box_df)
  insert_rows("transactions", transactions_df)
  insert_rows("pitch",        pitch_df)
})

# Row counts for each table
sapply(c("team", "players", "schedule", "box_score", "transactions", "pitch"), 
       function(tbl) {
         dbGetQuery(conn, sprintf("SELECT COUNT(*) AS n FROM %s", tbl))$n
})



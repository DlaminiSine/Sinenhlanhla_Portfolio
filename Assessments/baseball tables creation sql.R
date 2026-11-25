library(DBI)
library(RSQLite)

#database file
db_file <- "baseball.sqlitedb"

#Clear the file if it  already exists

if (file.exists(db_file)) {
  unlink(db_file)
}

#Connect the file using SQLite
conn <- dbConnect(RSQLite::SQLite(), db_file)

execute <- function(sql){
  dbExecute(conn, sql)
}

#Enable foreign keys
execute("PRAGMA foreign_keys = ON")

#Create the Team table
execute("
       CREATE TABLE IF NOT EXISTS team (
        team_id INTEGER PRIMARY KEY,
        team_name TEXT UNIQUE,
        team_nickname TEXT,
        team_location TEXT,
        team_abbreviation TEXT,
        team_first_year INTEGER,
        team_active INTEGER,
        team_league_id INTEGER,
        team_division_id INTEGER
       )
       ")

# Create the players table

execute("
        CREATE TABLE IF NOT EXISTS players (
          player_id INTEGER PRIMARY KEY,
          player_name TEXT,
          position_code TEXT,
          position_name TEXT,
          roster_team_id ITEGER,
          current_age INTEGER,
          bats TEXT,
          throws TEXT,
          FOREIGN KEY (roster_team_id) REFERENCES team(team_id)
        )
        ")

# Create the schedule table

execute("
        CREATE TABLE IF NOT EXISTS schedule (
          game_id INTEGER PRIMARY KEY,
          game_date TEXT,
          start_utc TEXT,
          game_type TEXT,
          game_status TEXT,
          away_team_id INTEGER,
          home_team_id INTEGER,
          away_score INTEGER,
          home_score INTEGER,
          FOREIGN KEY (away_team_id) REFERENCES team(team_id),
          FOREIGN KEY (home_team_id) REFERENCES team(team_id)
        )
        ")

#Create box_score table

execute("
        CREATE TABLE IF NOT EXISTS box_score (
          game_id INTEGER,
          player_id INTEGER,
          team_id INTEGER,
          plate_appearances INTEGER,
          at_bats INTEGER,
          hits INTEGER,
          home_runs INTEGER,
          rbi INTEGER,
          putouts INTEGER,
          assists INTEGER,
          pitching_outs INTEGER,
          earned_runs INTEGER,
          pitching_strikeouts INTEGER,
          mlb_pitches INTEGER,
          statcast_pitches INTEGER,
          avg_release_speed REAL,
          max_release_speed REAL,
          PRIMARY KEY (game_id, player_id)
          FOREIGN KEY(game_id) REFERENCES schedule(game_id),
          FOREIGN KEY(player_id) REFERENCES players(player_id),
          FOREIGN KEY(team_id) REFERENCES team(team_id)
        )
        ")

# Create pitch table

execute("
        CREATE TABLE IF NOT EXISTS pitch(
          game_id INTEGER,
          at_bat_number INTEGER,
          pitch_number INTEGER,
          pitcher_id INTEGER,
          batter_id INTEGER,
          inning INTEGER,
          inning_half TEXT,
          pitch_type TEXT,
          description TEXT,
          release_speed REAL,
          release_spin_rate REAL,
          PRIMARY KEY(game_id, at_bat_number, pitch_number)
          FOREIGN KEY(game_id) REFERENCES schedule(game_id),
          FOREIGN KEY (pitcher_id) REFERENCES players(player_id),
          FOREIGN KEY (batter_id) REFERENCES players(player_id)
        )
        ")

# Create transactions table

execute("
        CREATE TABLE IF NOT EXISTS transactions(
          transaction_id INTEGER PRIMARY KEY,
          transaction_date TEXT,
          effective_date TEXT,
          player_id INTEGER,
          from_team_id INTEGER,
          to_team_id INTEGER,
          type_code TEXT,
          type_description TEXT,
          description TEXT,
          FOREIGN KEY (player_id) REFERENCES players(player_id),
          FOREIGN KEY (from_team_id) REFERENCES team(team_id),
          FOREIGN KEY (to_team_id) REFERENCES team(team_id)
        )
        ")

print(dbListTables(conn))

# Disconnect from the db file
dbDisconnect(conn)





















<a id="readme-top"></a>

# Baseball Data Pipeline

I use R to create the pipeline which pulls teams, players, schedule, box scores, pitch-level Statcast data, and transactions from public MLB sources, cleans them, and loads them into a SQLite database.

## Table of Contents

1. [About The Project](#about-the-project)
   - [Tools used to build project](#Tools-used-to-build-project)
   - [Table Design](#table-design)
   - [How the Pipeline Works](#how-the-pipeline-works)
2. [Getting Started](#getting-started)
   - [Prerequisites](#prerequisites)
   - [Installation](#installation)
3. [Usage](#usage)
   - [Example Queries](#example-queries)
4. [Assumptions](#assumptions)
5. [Lessons Learned](lessons-learned)
6. [Future Enhancements](#future-enhancements)
7. [Contact](#contact)
8. [Acknowledgments](#acknowledgments)

## About The Project

The objective of the project was to build a small baseball database from two public sources: the MLB Stats API and Baseball Savant / Statcast (pitch-level data). 
Instead of hard-coding the dates, I create a program that accepts a start date and end date, pulls the data for that range, cleans it, and stores it in `baseball.sqlitedb`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Tools used to build project

- [R](https://www.r-project.org/)
- [httr](https://httr.r-lib.org/) and [jsonlite](https://jeroen.r-universe.dev/jsonlite) for API calls and JSON
- [dplyr](https://dplyr.tidyverse.org/), [tidyr](https://tidyr.tidyverse.org/), [tibble](https://tibble.tidyverse.org/), and [readr](https://readr.tidyverse.org/) for cleaning and reshaping
- [DBI](https://dbi.r-dbi.org/) and [RSQLite](https://rsqlite.r-dbi.org/) with [SQLite](https://www.sqlite.org/) for storage
- Data: [MLB Stats API](https://statsapi.mlb.com/api/v1/) and [Baseball Savant / Statcast](https://baseballsavant.mlb.com/statcast_search)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Table Design

Tables load in this order because of foreign keys: `team` → `players` → `schedule` → `box_score` → `transactions` → `pitch`.

| Table | One row per | Key | Foreign keys | Main columns |
|---|---|---|---|---|
| `team` | MLB team | `team_id` | none | name, nickname, location, abbreviation, first year, active flag, league and division ids |
| `players` | player | `player_id` | `roster_team_id` → `team` | name, position code and name, current age, bats, throws |
| `schedule` | game | `game_id` | away and home team → `team` | date, UTC start time, game type, status, away and home score |
| `box_score` | player per game | `game_id`, `player_id` | game → `schedule`, player → `players`, team → `team` | batting (PA, AB, H, HR, RBI), fielding (putouts, assists), pitching (outs, earned runs, strikeouts, MLB pitch count), plus three Statcast fields |
| `pitch` | pitch | `game_id`, `at_bat_number`, `pitch_number` | game → `schedule`, pitcher and batter → `players` | inning, half, pitch type, result description, release speed, spin rate |
| `transactions` | transaction | `transaction_id` | player → `players`, from/to team → `team` | transaction and effective dates, type code and description, full text |

**Design choices**

- **Small column sets.** Only fields a few useful fields are kept, not every field the APIs return.
- **Statcast fields on `box_score`.** For pitchers, the box score carries three fields calculated from `pitch`: `statcast_pitches` (total pitches), `avg_release_speed`, and `max_release_speed`. `mlb_pitches` comes from the MLB box score.
- **Innings are stored as outs.** The API reports innings as text like `"6.1"`, so `pitching_outs` stores 19. This makes sums and averages valid.
- **Foreign keys are enforced** (`PRAGMA foreign_keys = ON`), so the database rejects orphaned rows.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### How the Pipeline Works

For every table the script pulls the data, cleans it, prints checks, and then loads it. Four functions are used throughout:

- `get_with_retry()` makes each API call with a timeout (30 seconds, 60 for Statcast) and with a maximum of 3 tries. It stops on HTTP 400, 401, 403, or 404, since retrying cannot fix those, and returns `NULL` if the pull never worked.
- `get_mlb()` builds an MLB Stats API request on top of it and parses the JSON.
- `clean_df()` trims text, turns empty strings into NA, drops rows with a missing key, and keeps the first row of any duplicated key. It prints how many rows it dropped.
- `add_missing_players()` fetches any player who appears in a later table but not in `players`, and adds them.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

To get a local copy up and running, follow these steps. No API key is needed, since all sources are public.

### Prerequisites

- R 4.1 or newer (the script uses the `|>` pipe)
- These R packages:

  ```r
  install.packages(c("httr", "jsonlite", "dplyr", "tidyr", "tibble", "readr", "DBI", "RSQLite"))
  ```

### Installation

1. Download or clone the project files into one folder.
2. Install the R packages above.
3. Create the database tables by running `baseball_tables_creation_sql.R`. This builds `baseball.sqlitedb` with all six tables and their keys. It rebuilds the file, so only run it when you want a fresh database.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

Run the pipeline with a start and end date (format `YYYY-MM-DD`):

```
Rscript BRS_Data_walkthrough_v2.R 2026-06-01 2026-06-07
```

The script stops with a clear message if a date is not in that format or the start date is after the end date. If no dates are given (for example when the script is run from RStudio), it uses a single default day, `2026-06-09`, which can be changed.

The console prints the checks and how many rows each cleaning step dropped, and the script ends with a row count for every table and four example queries. The script was developed and tested with a single-day range (`2026-06-09`).

### Example Queries

**1. Did every table load?** 

```sql
SELECT 'team' AS tbl, COUNT(*) AS n FROM team
UNION ALL SELECT 'players', COUNT(*) FROM players
UNION ALL SELECT 'schedule', COUNT(*) FROM schedule
UNION ALL SELECT 'box_score', COUNT(*) FROM box_score
UNION ALL SELECT 'pitch', COUNT(*) FROM pitch
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;
```

**2. What happened in each game?** 

```sql
SELECT s.game_date, a.team_name AS away_team, s.away_score,
       h.team_name AS home_team, s.home_score, s.game_status
FROM schedule s
LEFT JOIN team a ON s.away_team_id = a.team_id
LEFT JOIN team h ON s.home_team_id = h.team_id
ORDER BY s.game_date, s.game_id;
```

**3. Who threw the hardest?**

```sql
SELECT p.player_name, b.mlb_pitches, b.statcast_pitches,
       b.avg_release_speed, b.max_release_speed
FROM box_score b
JOIN players p ON b.player_id = p.player_id
WHERE b.statcast_pitches IS NOT NULL
ORDER BY b.max_release_speed DESC
LIMIT 10;
```

**4. Do all six tables line up?**

```sql
SELECT s.game_date,
       p.player_name,
       t.team_name,
       b.mlb_pitches,
       b.statcast_pitches,
       (SELECT COUNT(*) FROM pitch x
        WHERE x.game_id = b.game_id AND x.pitcher_id = b.player_id) AS pitch_rows,
       (SELECT COUNT(*) FROM transactions tr
        WHERE tr.player_id = b.player_id) AS transactions
FROM box_score b
JOIN schedule s ON b.game_id = s.game_id
JOIN players  p ON b.player_id = p.player_id
JOIN team     t ON b.team_id = t.team_id
WHERE b.mlb_pitches IS NOT NULL
ORDER BY b.mlb_pitches DESC
LIMIT 20;
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Assumptions

**Scope**

- Only MLB is covered (`sportId = 1`). 
- Box scores and pitches are pulled only for games with status "Final".

**Players**

- `players` starts from active rosters as of `end_date`, so `roster_team_id` shows the team on that last day, not necessarily the team during each game.
- A player who appears in a box score, transaction, or pitch (as pitcher or batter) but is not in `players` is fetched from the `people` endpoint and added, with `roster_team_id` left NULL. This keeps the foreign keys valid without dropping data.

**Cleaning**

- Text is trimmed and empty strings become NULL.
- A row with a missing key is dropped. If a key appears twice, with the first row being kept.
- A team id that is not one of the 30 MLB clubs (for example a minor league team in a transaction) is set to NULL and the row is kept. For transactions, the `description` text still names the team.
- Players listed in a box score who never played (no stats) are dropped from `box_score`.

**NULL versus zero**

- A pitcher who did not bat has NULL batting columns, and a position player who did not pitch has NULL pitching columns. A zero appears only where the source reports a real zero, such as putouts and assists.
- NULLs are left in place because replacing them with zero would change averages.

**Statcast**

- The Statcast columns of `box_score` are calculated from `pitch`, grouped by `game_id` and `pitcher_id`, with an `UPDATE` that runs after the pitch load. They stay NULL for hitters and for games where Statcast returned nothing.
- `INSERT OR REPLACE` on `box_score` overwrites the whole row, including the Statcast columns.
- (`game_id`, `at_bat_number`, `pitch_number`) is used to identify a pitch uniquely. If any are repeated by Statcast, the first row is kept.
- The MLB pitch count (`mlb_pitches`) and the Statcast count (`statcast_pitches`) should be similar.

**Transactions**

- Each transaction is assumed to have a unique `id`, which is used as the key.

**API calls**

- A failed pull returns `NULL`. The teams, schedule, and transactions pulls stop the script, and a single failed game's box score or Statcast pull is skipped with a message.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Lessons Learned

- **The teams pull failed several times.** The request function was built from a variable name that didn't exist in the session (`mlb_url` vs `base_url`). The retry helper catches errors, and so the real cause was hidden and the console only showed "no response" three times. Next time, a retry wrapper will be created to show the underlying error message and not just retry silently.
- **A table-name typo in the foreign keys.** The tables referenced `player(player_id)` but the table is named `players`. SQLite only checks this when a row is inserted, so the tables were created with no error and the first `box_score` insert failed. I edited the three affected tables (`box_score`, `pitch`, `transactions`, all empty at that point) with the correct reference in the creation script.
- **Many NAs in the box score.** Hitters showed NA in the pitching columns and pitchers in the batting columns. I checked that every row had either batting or pitching stats and that no row was missing part of a group, which came back clean. The NAs are structural, not bad data, so I left them as NULL.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Future Enhancements

Things I would do with more time:

- [ ] Create a single function (for example `run_pipeline(start_date, end_date)`) that pulls, cleans, checks, and loads every table in the right order in one call. I built the pipeline table by table so I could check each step, but one function would be easier to run and re-run.
- [ ] Run the checks both before and after cleaning, so the console shows what the raw data looked like and confirms the cleaning worked. Right now they run after cleaning, and `clean_df()` reports the rows it dropped.
- [ ] Turn the key checks (duplicate keys, orphaned foreign keys) into `stopifnot()` calls, so the script stops instead of only printing a result.
- [ ] Make the retry helper print the underlying error, and collect failed games into a summary at the end of the run, so a failed pull is hard to miss.
- [ ] Pull the roster for each game date instead of a single date, so a player's team is correct per game.
- [ ] Add pitch-type counts per pitcher to `box_score`.
- [ ] Load all tables inside one database transaction, so a failure part-way through rolls everything back.
- [ ] Add the optional MLB Trade Rumors and Retrosheet extensions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Dlamini Sinenhlanhla - dlamini.s@northeastern.edu (mailto:dlamini.s@northeastern.edu)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

- [MLB Stats API](https://statsapi.mlb.com/api/v1/) for teams, players, schedules, box scores, and transactionst
- [Baseball Savant / Statcast](https://baseballsavant.mlb.com/statcast_search) for pitch-level data
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) for the README structure

<p align="right">(<a href="#readme-top">back to top</a>)</p>

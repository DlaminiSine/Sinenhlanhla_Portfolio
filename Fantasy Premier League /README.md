# Fantasy Premier League — Player Performance Analysis

A structured data analysis and visualization project exploring Fantasy Premier League (FPL) player and gameweek data using **SQL** and **Tableau**.

The project evaluates player performance across positions, identifies top-performing players and teams, and presents insights that could support Fantasy Premier League team-selection decisions.

## Interactive Dashboard

Explore the complete analysis through the interactive Tableau dashboard:

### [View the Fantasy Premier League 2022/23 Dashboard on Tableau Public](https://public.tableau.com/app/profile/sinenhlanhla.dlamini/viz/FantasypremierLeague2223Dashboard/FantasyPremierLeague2223SeasonDashboard)

The dashboard allows users to:

* Compare player performance across all four positions
* Identify leading players based on points, goals, assists, and advanced FPL metrics
* Explore performance by Premier League team
* Compare players based on their playing time
* Filter and interact with the data to support FPL team-selection decisions

---

## Project Objectives

The main objectives of this project were to:

* Validate and clean raw Fantasy Premier League data before analysis
* Explore player performance across goalkeepers, defenders, midfielders, and forwards
* Identify top performers by goals, assists, total points, creativity, influence, and threat
* Analyze player performance by Premier League team
* Compare players based on full and partial minutes played
* Transform SQL analysis into an interactive Tableau dashboard
* Generate insights that could inform FPL team-selection decisions

---

## Tools and Technologies

| Tool           | Purpose                                                  |
| -------------- | -------------------------------------------------------- |
| SQLite         | Database creation and management                         |
| DBeaver        | SQL query writing and execution                          |
| SQL            | Data validation, cleaning, transformation, and analysis  |
| Tableau Public | Interactive dashboard development and data visualization |
| GitHub         | Project documentation and version control                |

---

## Data Source

The data was obtained from the [vaastav Fantasy Premier League GitHub repository](https://github.com/vaastav/Fantasy-Premier-League), which provides historical and current-season Fantasy Premier League statistics.

The analysis used two primary tables:

### `cleaned_players`

Contains season-level player statistics, including:

* Player names
* Total points
* Goals scored
* Assists
* Minutes played
* Clean sheets
* Goals conceded
* Creativity
* Influence
* Threat

### `merged_gw`

Contains gameweek-level player data, including:

* Player name
* Position
* Premier League team
* Gameweek information
* Kickoff time
* Match-level performance statistics

---

## Project Structure

```text
fpl-sql-analysis/
│
├── fpl_analysis.sql       # Data validation, cleaning, and analytical SQL queries
└── README.md              # Project documentation and Tableau dashboard link
```

---

## Data Validation and Cleaning

Before conducting the analysis, the data was inspected to identify structural and quality issues.

The cleaning and validation process included:

* Previewing the raw tables and reviewing their structures
* Checking the number of records in each table
* Identifying duplicate player entries
* Resolving duplicated player records
* Creating a unified `name` column by concatenating first-name and second-name fields
* Checking for null values in important variables
* Confirming the date range of the gameweek dataset
* Verifying that player names could be used to connect the two tables

These steps helped ensure that the analysis was based on complete and consistent player records.

---

## Exploratory Data Analysis

The initial exploratory analysis focused on understanding the overall distribution and structure of player performance.

The analysis included:

* Top 20 players by goals scored
* Top 20 players by assists
* Distribution of total FPL points across all players
* Maximum and minimum player-performance values
* Number of players represented in the dataset
* Dataset date range using minimum and maximum kickoff times
* Comparison of players based on minutes played

---

## Position-Based Analysis

Players were analyzed across the four official Fantasy Premier League positions:

* Goalkeepers
* Defenders
* Midfielders
* Forwards

The position-level analysis included:

* Top five players by total points for each position
* Leading goal scorers by position
* Leading assist providers by position
* Most creative players by position
* Most influential players by position
* Most threatening players by position
* Comparison of full-minute and partial-minute players
* Goalkeeper and defender clean-sheet performance
* Goalkeepers and defenders ranked by goals conceded

This analysis made it possible to compare players against others performing similar roles rather than comparing all players using the same expectations.

---

## Team-Level Analysis

The project also examined player performance across Premier League teams.

A SQL window function was used to rank players within each team and identify the top three point scorers.

This analysis demonstrates how ranking functions can be used to compare observations within specific groups.

### Sample Query

```sql
-- Top three players from each team based on total points

SELECT
    team,
    name,
    total_points
FROM
(
    SELECT
        mg.team AS team,
        cp.name AS name,
        cp.total_points AS total_points,
        ROW_NUMBER() OVER (
            PARTITION BY mg.team
            ORDER BY cp.total_points DESC
        ) AS player_rank
    FROM cleaned_players cp
    JOIN merged_gw mg
        ON mg.name = cp.name
    GROUP BY
        mg.team,
        cp.name,
        cp.total_points
) AS ranked_players
WHERE player_rank <= 3;
```

The `ROW_NUMBER()` function assigns a ranking to each player within their respective team based on total points.

The outer query then filters the results to retain only the three highest-ranked players from each team.

---

## Advanced FPL Metrics

In addition to traditional statistics such as goals, assists, and total points, the analysis examined three advanced Fantasy Premier League performance metrics.

### Creativity

Creativity measures a player's ability to create scoring opportunities for teammates.

It helps identify players who contribute through:

* Key passes
* Chance creation
* Assisting opportunities
* Attacking involvement

### Influence

Influence measures the extent to which a player affects match outcomes.

It considers performance contributions such as:

* Goals
* Assists
* Defensive actions
* Overall involvement in the match

### Threat

Threat measures how likely a player is to score.

It reflects factors such as:

* Shooting opportunities
* Positioning near the goal
* Attacking involvement
* Goal-scoring potential

Analyzing these metrics provided a broader understanding of performance beyond total points alone.

---

## Tableau Dashboard

The results of the SQL analysis were developed into an interactive Tableau dashboard covering the **2022/23 Fantasy Premier League season**.

The dashboard presents player-performance information in an accessible format and allows users to explore the data interactively.

Key dashboard features include:

* Player-performance comparisons
* Position-based analysis
* Team-level comparisons
* Total-points rankings
* Goal and assist analysis
* Creativity, influence, and threat metrics
* Playing-time comparisons
* Interactive filters and visualizations

### Dashboard Link

[Open the Fantasy Premier League 2022/23 Season Dashboard](https://public.tableau.com/app/profile/sinenhlanhla.dlamini/viz/FantasypremierLeague2223Dashboard/FantasyPremierLeague2223SeasonDashboard)

---

## Key Insights

The analysis demonstrates that total FPL points should not be considered in isolation when evaluating players.

A more complete player assessment can include:

* Total points earned
* Number of minutes played
* Position
* Goals and assists
* Clean sheets
* Goals conceded
* Creativity
* Influence
* Threat
* Performance relative to teammates

Players with high creativity or threat scores may represent strong future selections even when they are not currently among the highest total-point scorers.

Similarly, comparing players within their positions and teams provides more useful context than ranking every player together.

---

## Skills Demonstrated

This project demonstrates proficiency in:

* Relational database querying
* Multi-table analysis using `JOIN`
* Data validation and cleaning
* Duplicate identification and resolution
* String concatenation and data transformation
* Aggregate functions such as `COUNT`, `MIN`, `MAX`, and `SUM`
* Grouped analysis using `GROUP BY`
* Conditional filtering
* SQL subqueries
* Window functions
* `ROW_NUMBER() OVER (PARTITION BY ...)`
* Position-based performance analysis
* Team-level player ranking
* Exploratory data analysis
* Interactive Tableau dashboard development
* Data visualization
* Data storytelling
* Translating analytical findings into decision-oriented insights

---

## Potential Future Improvements

Future versions of the project could include:

* Player-price and value-for-money analysis
* Points-per-million calculations
* Gameweek-level performance trends
* Home-versus-away performance comparisons
* Fixture-difficulty analysis
* Player consistency and volatility measures
* Expected goals and expected assists
* Captaincy recommendations
* Automated data updates for future FPL seasons
* Predictive modeling for future player points

---

## Author

**Sinenhlanhla Dlamini**
MS Economics, Northeastern University

* [Tableau Public Profile](https://public.tableau.com/app/profile/sinenhlanhla.dlamini/vizzes)
* Email: [dlamini.s@northeastern.edu](mailto:dlamini.s@northeastern.edu)

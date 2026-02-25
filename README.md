# Fantasy Premier League — Player Performance Analysis

A structured data analysis project exploring Fantasy Premier League (FPL) player and gameweek data using SQL. The goal was to assess player performance across positions, identify top performers, and extract insights that could inform FPL team selection decisions.

---

## Objectives

- Validate and clean raw FPL data before analysis
- Explore player performance metrics across all four positions (GK, DEF, MID, FWD)
- Identify top performers by goals, assists, total points, creativity, influence, and threat
- Analyze performance by team and playing time (full vs. partial minutes played)

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| SQLite | Database management |
| DBeaver | Query writing and execution |
| SQL | Data cleaning, transformation, and analysis |

---

## Data Source

Data sourced from the [vaastav Fantasy Premier League GitHub repository](https://github.com/vaastav/Fantasy-Premier-League), which provides historical and current season FPL statistics. Two tables were used:

- `cleaned_players` — season-level player statistics
- `merged_gw` — gameweek-level player data including position and team

---

## Project Structure

```
fpl-sql-analysis/
│
├── fpl_analysis.sql       # All queries: data validation, cleaning, and exploration
└── README.md              # Project documentation
```

---

## Key Analysis Performed

**Data Validation & Cleaning**
- Previewed raw data and checked for structural issues
- Identified and resolved duplicate player entries
- Created a unified `name` column by concatenating first and last name fields
- Confirmed absence of null values in the dataset

**Exploratory Analysis**
- Top 20 players by goals scored and assists
- Distribution of total points across all players
- Date range of the dataset confirmed via `MIN` and `MAX` kickoff times

**Position-Based Analysis**
- Top 5 performers by total points for each position (GK, DEF, MID, FWD)
- Top performers filtered by full minutes played (1530) vs. partial minutes
- Goals and assists leaders broken down by position

**Team-Level Analysis**
- Top 3 point scorers per team using a `ROW_NUMBER()` window function partitioned by team

**Advanced Metrics**
- Most creative, influential, and threatening players using FPL's proprietary rating metrics
- Goalkeepers and defenders ranked by goals conceded and clean sheets

---

## Sample Query

```sql
-- Top 3 players of each team with the most points
SELECT team, name, total_points FROM 
(
    SELECT mg.team team,
    cp.name name,
    cp.total_points total_points,
    ROW_NUMBER() OVER (PARTITION BY mg.team ORDER BY cp.total_points DESC) AS rank 
    FROM cleaned_players cp 
    JOIN merged_gw mg ON mg.name = cp.name 
    GROUP BY mg.team, cp.name, cp.total_points 
) RNK 
WHERE rank <= 3
```

---

## Skills Demonstrated

- Multi-table relational database querying using `JOIN`
- Data cleaning and deduplication
- Aggregate functions (`COUNT`, `MIN`, `MAX`, `GROUP BY`)
- Window functions (`ROW_NUMBER() OVER PARTITION BY`)
- Conditional filtering and subqueries
- Exploratory data analysis using SQL

---

## Author

**Sinenhlanhla Dlamini**  
MS Economics, Northeastern University  
[LinkedIn](https://www.linkedin.com) | dlamini.s@northeastern.edu

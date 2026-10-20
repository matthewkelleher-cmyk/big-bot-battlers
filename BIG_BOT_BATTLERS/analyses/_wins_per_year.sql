with matches as (
    SELECT *
    FROM {{ref('_stg_matches')}}
),

events as (
    SELECT *
    FROM {{ref('_stg_events')}}
),

fighters as (
    SELECT *
    FROM {{ref('_stg_fighters')}}
),

match_dates as (
    SELECT m.match_id, e.event_date, m.winner_fighter_id
    FROM matches m
    LEFT JOIN events e
    ON m.event_id = e.event_id
),

fighter_wins as (
    SELECT COALESCE(COUNT(DISTINCT md.match_id), 0) as wins, f.fighter_id, YEAR(md.event_date) as year
    FROM fighters f
    LEFT JOIN match_dates md
    GROUP BY fighter_id, year
    
)

SELECT * FROM fighter_wins
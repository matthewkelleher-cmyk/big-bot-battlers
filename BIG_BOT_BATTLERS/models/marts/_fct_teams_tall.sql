with foundational_stats as (
    select team_name
        ,founded_on
        ,city
        ,state
        ,region
        ,count(distinct match_id) as total_matches_fought
        ,sum(winner_flag) as total_wins
        ,total_wins/total_matches_fought as total_win_rate
        ,avg(bout_number) as avg_bout_number
        ,count(distinct fighter_id) as lifetime_fighter_count
        ,count(distinct event_date) as events_competed_in
        ,avg(duration_seconds)/60 as avg_fight_length_minutes
        ,avg(armour_rating) as avg_fight_armour_rating
        ,avg(mobility_rating) as avg_fight_mobility_rating
        ,avg(damage_pct) as avg_damage_pct
    from {{ref('_int_teams')}}
    group by all
),

points_overall as (
    select team_name
        ,year(event_date) as season
        ,SUM(points_scored) over (partition by team_name, season) as season_points
    from {{ref('_int_teams')}}
),

points_grouped as (
    select *
    from points_overall
    group by all
),

wins_overall as (
    select team_name
        ,year(event_date) as season
        ,SUM(winner_flag) over (partition by team_name, season) as season_wins
    from {{ref('_int_teams')}}
),

wins_grouped as (
    select *
    from wins_overall
    group by all
),

joins as (
    select fs.team_name
        ,founded_on
        ,city
        ,state
        ,region
        ,total_matches_fought
        ,total_wins
        ,total_win_rate
        ,avg_bout_number
        ,lifetime_fighter_count
        ,events_competed_in
        ,avg_fight_length_minutes
        ,avg_fight_armour_rating
        ,avg_fight_mobility_rating
        ,avg_damage_pct
        ,pg.season
        ,pg.season_points
        ,wg.season_wins
    from foundational_stats as fs
    left join points_grouped as pg
    on fs.team_name = pg.team_name
    left join wins_grouped as wg
    on fs.team_name = wg.team_name and pg.season = wg.season
)

select *
from joins
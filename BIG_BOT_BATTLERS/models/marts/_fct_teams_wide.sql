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
        ,SUM(points_scored) over (partition by team_name, season) as points
    from {{ref('_int_teams')}}
),

points_pivoted as (
    SELECT *
    FROM points_overall
    PIVOT (
        SUM(points)
        FOR season IN (
            2012 as points_2012,
            2013 as points_2013,
            2014 as points_2014,
            2015 as points_2015,
            2016 as points_2016,
            2017 as points_2017,
            2018 as points_2018,
            2019 as points_2019,
            2020 as points_2020,
            2021 as points_2021,
            2022 as points_2022,
            2023 as points_2023,
            2024 as points_2024,
            2025 as points_2025,
            2026 as points_2026)
    )
    ORDER BY team_name
),

wins_overall as (
    select team_name
        ,year(event_date) as season
        ,SUM(winner_flag) over (partition by team_name, season) as wins
    from {{ref('_int_teams')}}
),

wins_pivoted as (
    SELECT *
    FROM wins_overall
    PIVOT (
        SUM(wins)
        FOR season IN (
            2012 as wins_2012,
            2013 as wins_2013,
            2014 as wins_2014,
            2015 as wins_2015,
            2016 as wins_2016,
            2017 as wins_2017,
            2018 as wins_2018,
            2019 as wins_2019,
            2020 as wins_2020,
            2021 as wins_2021,
            2022 as wins_2022,
            2023 as wins_2023,
            2024 as wins_2024,
            2025 as wins_2025,
            2026 as wins_2026)
    )
    ORDER BY team_name
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
        ,points_2012
        ,points_2013
        ,points_2014
        ,points_2015
        ,points_2016
        ,points_2017
        ,points_2018
        ,points_2019
        ,points_2020
        ,points_2021
        ,points_2022
        ,points_2023
        ,points_2024
        ,points_2025
        ,points_2026
        ,wins_2012
        ,wins_2013
        ,wins_2014
        ,wins_2015
        ,wins_2016
        ,wins_2017
        ,wins_2018
        ,wins_2019
        ,wins_2020
        ,wins_2021
        ,wins_2022
        ,wins_2023
        ,wins_2024
        ,wins_2025
        ,wins_2026
    from foundational_stats as fs
    left join points_pivoted as pp
    on fs.team_name = pp.team_name
    left join wins_pivoted as wp
    on fs.team_name = wp.team_name
)

select *
from joins
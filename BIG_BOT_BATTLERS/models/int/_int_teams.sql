with team as (
    select team_id
        ,team_name
        ,licensed_on as founded_on
        ,c.city_name as city
        ,c.state_code as state
        ,c.region
    from {{ref('_stg_teams')}} as t
    left join {{ref('_stg_cities')}} as c 
    on t.home_city_id = c.city_id
),

fighter as (
select fighter_id
    ,team_id
    ,status
from {{ref('_stg_fighters')}}
),

long_weapon_success as (
    select match_id
        ,fighter_id
        ,fighter_name
        ,points_scored
        ,damage_pct
        ,bout_number
        ,winner_flag
        ,decision
        ,duration_seconds
        ,armour_rating 
        ,mobility_rating
    from {{ref('_int_weapon_success_long')}}
    group by all
),

event_date as (
    select match_id
        ,event_date
    from {{ref('_stg_events')}} as e
    left join {{ref('_stg_matches')}} as m
    on e.event_id = m.event_id
),

joins as (
    select t.team_id
        ,team_name
        ,founded_on
        ,city
        ,state
        ,region
        ,f.fighter_id
        ,fighter_name
        ,status
        ,lws.match_id
        ,event_date
        ,points_scored
        ,damage_pct
        ,bout_number
        ,winner_flag
        ,decision
        ,duration_seconds
        ,armour_rating 
        ,mobility_rating
    from long_weapon_success as lws
    left join fighter as f
    on lws.fighter_id = f.fighter_id
    left join team as t
    on f.team_id = t.team_id
    left join event_date as ed
    on lws.match_id = ed.match_id
)

select *
from joins
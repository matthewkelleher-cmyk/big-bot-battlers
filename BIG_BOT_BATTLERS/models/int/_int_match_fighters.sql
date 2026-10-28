with match_entries as (
    SELECT loadout_id, match_id
    FROM {{ref('_stg_match_entries')}}
),

loadouts as (
    SELECT loadout_id, fighter_id
    FROM {{ref('_stg_fighter_loadouts')}}
),

matches as (
    SELECT match_id, event_id
    FROM {{ref('_stg_matches')}}
),

events as (
    SELECT event_id, event_name, season, event_date
    FROM {{ref('_stg_events')}}
),

me_fighters as (
    SELECT me.match_id, l.fighter_id
    FROM match_entries me
    LEFT JOIN loadouts l
    ON me.loadout_id = l.loadout_id
),

event_matches as (
    SELECT m.event_id, m.match_id, e.event_name, e.season, e.event_date
    FROM matches m
    LEFT JOIN events e
    ON m.event_id = e.event_id
),

final as (
    SELECT e.event_id, e.match_id, e.event_name, e.season, e.event_date, m.fighter_id
    FROM event_matches e
    LEFT JOIN me_fighters m
    ON e.match_id = m.match_id
)

SELECT * FROM final




with matchengis as (
    SELECT *
    FROM {{ref('_int_engineer_by_match')}}
),

fighters as (
    SELECT *
    FROM {{ref('_int_match_fighters')}}
),

final as (
    SELECT e.match_id, 
    e.winner_fighter_id, 
    e.decision, 
    e.employee_id, 
    f.event_id, 
    f.event_name, 
    f.season, 
    f.event_date, 
    f.fighter_id
    FROM matchengis e
    LEFT JOIN fighters f
    ON e.match_id = f.match_id
)

SELECT * FROM final
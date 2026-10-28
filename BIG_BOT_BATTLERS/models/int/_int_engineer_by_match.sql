with match_assignments as (
    SELECT match_id, employee_id
    FROM {{ref('_stg_employee_match_assignments')}}
    WHERE equipment_access = 'TRUE'
),

matches as (
    SELECT match_id, event_id, winner_fighter_id, decision
    FROM {{ref('_stg_matches')}}
),

final as (
    SELECT m.match_id, m.event_id, m.winner_fighter_id, m.decision, e.employee_id
    FROM matches m
    LEFT JOIN match_assignments e
    ON m.match_id = e.match_id
)

SELECT * FROM final
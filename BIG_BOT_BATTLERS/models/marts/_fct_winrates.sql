with won_matches_by_eng as (
    SELECT employee_id, fighter_id, COUNT(*) as won
    FROM {{ref('_int_aggmatch')}}
    WHERE fighter_id = winner_fighter_id
    GROUP BY fighter_id, employee_id
),

won_matches as (
    SELECT fighter_id, COUNT(*) as won
    FROM {{ref('_int_aggmatch')}}
    WHERE fighter_id = winner_fighter_id
    GROUP BY fighter_id
),

total_matches_by_eng as (
    SELECT employee_id, fighter_id, COUNT(*) as total
    FROM {{ref('_int_aggmatch')}}
    GROUP BY fighter_id, employee_id
),

total_matches as (
    SELECT fighter_id, COUNT(*) as total
    FROM {{ref('_int_aggmatch')}}
    GROUP BY fighter_id
),

joined_eng as (
    SELECT w.employee_id, w.fighter_id, w.won, tm.total
    FROM won_matches_by_eng w
    LEFT JOIN total_matches_by_eng tm
    ON w.employee_id = tm.employee_id AND w.fighter_id = tm.fighter_id
),

joined_overall as (
    SELECT w.fighter_id, w.won, tm.total
    FROM won_matches w
    LEFT JOIN total_matches tm
    ON  w.fighter_id = tm.fighter_id
),

win_rates_by_eng as (
    SELECT *, (won/total)*100 as win_rate
    FROM joined_eng
    ORDER BY fighter_id asc, employee_id asc
),

win_rates_overall as (
    SELECT *, (won/total)*100 as win_rate
    FROM joined_overall
),

final as (
    SELECT e.*, o.total as total_matches_won, o.win_rate as total_winrate
    FROM win_rates_by_eng e
    LEFT JOIN win_rates_overall o
    ON e.fighter_id = o.fighter_id
)

SELECT * FROM final
with fail_rates as (
    SELECT *
    FROM {{ref('_int_part_failure_rates')}}
),

discrepency as (
    SELECT
    *,
    overall_fail_rate - fail_rate as fr_diff
    FROM fail_rates
),

final as (
    SELECT 
    employee_id, 
    SUM(total_appearances) as total_weapon_appearances,
    SUM(fr_diff * total_appearances)/NULLIF(SUM(total_appearances), 0) as average_difference
    FROM discrepency
    WHERE employee_id IS NOT NULL
        AND overall_fail_rate IS NOT NULL
        AND fail_rate IS NOT NULL
    GROUP BY employee_id
    ORDER BY average_difference asc
)

SELECT * FROM final
ORDER BY average_difference asc
with failures as (
    SELECT *
    FROM {{ref('_stg_weapon_failures')}}
),

engineers as (
    SELECT *
    FROM {{ref('_int_engineer_by_match')}}
),

loadouts as (
    SELECT *
    FROM {{ref('_stg_fighter_loadouts')}}
),

match_entries as (
    SELECT *
    FROM {{ref('_stg_match_entries')}}
),

failures_by_eng as (
    SELECT
    f.*,
    e.employee_id,
    FROM failures f
    LEFT JOIN engineers e
    ON f.match_id = e.match_id
),

match_loadouts as (
    SELECT m.*, 
    l.primary_weapon_id as primary, 
    l.secondary_weapon_id as secondary, 
    l.special_weapon_id as special
    FROM match_entries m
    LEFT JOIN loadouts l
    ON m.loadout_id = l.loadout_id
),

match_loadouts_by_eng as (
    SELECT
    m.*,
    e.employee_id
    FROM match_loadouts m
    LEFT JOIN engineers e
    ON m.match_id = e.match_id
),

primary_counts as (
    SELECT primary as weapon_id, 
    COUNT(*) as pri_count
    FROM match_loadouts
    GROUP BY weapon_id
),

primary_counts_by_eng as (
    SELECT 
    primary as weapon_id,
    employee_id,
    COUNT(*) as pri_count
    FROM match_loadouts_by_eng
    GROUP BY weapon_id, employee_id
),

secondary_counts as (
    SELECT secondary as weapon_id, 
    COUNT(*) as sec_count
    FROM match_loadouts
    GROUP BY weapon_id
),

secondary_counts_by_eng as (
    SELECT 
    secondary as weapon_id,
    employee_id,
    COUNT(*) as sec_count
    FROM match_loadouts_by_eng
    GROUP BY weapon_id, employee_id
),

special_counts as (
    SELECT special as weapon_id, 
    COUNT(*) as sp_count
    FROM match_loadouts
    GROUP BY weapon_id
),

special_counts_by_eng as (
    SELECT 
    special as weapon_id,
    employee_id,
    COUNT(*) as sp_count
    FROM match_loadouts_by_eng
    GROUP BY weapon_id, employee_id
),

weapon_appearances as (
    SELECT pri.weapon_id,
    COALESCE(pri.pri_count, 0) as primary_count,
    COALESCE(sec.sec_count, 0) as secondary_count,
    COALESCE(sp.sp_count,0) as special_count,
    (primary_count + secondary_count + special_count) as total_appearances
    FROM primary_counts pri
    LEFT JOIN secondary_counts sec
    ON pri.weapon_id = sec.weapon_id 
    LEFT JOIN special_counts sp
    ON pri.weapon_id = sp.weapon_id 
),

weapon_appearances_by_eng as (
    SELECT pri.weapon_id,
    pri.employee_id,
    COALESCE(pri.pri_count, 0) as primary_count,
    COALESCE(sec.sec_count, 0) as secondary_count,
    COALESCE(sp.sp_count,0) as special_count,
    (primary_count + secondary_count + special_count) as total_appearances
    FROM primary_counts_by_eng pri
    LEFT JOIN secondary_counts_by_eng sec
    ON pri.weapon_id = sec.weapon_id AND pri.employee_id = sec.employee_id
    LEFT JOIN special_counts_by_eng sp
    ON pri.weapon_id = sp.weapon_id AND pri.employee_id = sp.employee_id
),

weapon_fail_count as (
    SELECT 
    weapon_model_id as weapon_id,
    COUNT(*) as failure_count
    FROM failures
    GROUP BY weapon_id
),

weapon_fail_count_by_eng as (
    SELECT 
    weapon_model_id as weapon_id,
    employee_id,
    COUNT(*) as failure_count
    FROM failures_by_eng
    GROUP BY weapon_id, employee_id
),

weapon_fail_rate as (
    SELECT 
    a.weapon_id,
    a.total_appearances,
    f.failure_count,
    (f.failure_count/a.total_appearances)*100 as fail_rate
    FROM weapon_appearances a
    LEFT JOIN weapon_fail_count f
    ON a.weapon_id = f.weapon_id  
),

weapon_fail_rate_by_eng as (
    SELECT 
    a.weapon_id,
    a.total_appearances,
    a.employee_id,
    f.failure_count,
    (f.failure_count/a.total_appearances)*100 as fail_rate
    FROM weapon_appearances_by_eng a
    LEFT JOIN weapon_fail_count_by_eng f
    ON a.weapon_id = f.weapon_id AND a.employee_id = f.employee_id
),

final as (
    SELECT 
    efr.*,
    fr.fail_rate as overall_fail_rate
    FROM weapon_fail_rate_by_eng efr
    LEFT JOIN weapon_fail_rate fr
    ON efr.weapon_id = fr.weapon_id
)

SELECT * FROM final
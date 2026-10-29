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

match_loadouts as (
    SELECT m.*, 
    l.primary_weapon_id as primary, 
    l.secondary_weapon_id as secondary, 
    l.special_weapon_id as special
    FROM match_entries m
    LEFT JOIN loadouts l
    ON m.loadout_id = l.loadout_id
),

primary_counts as (
    SELECT primary, 
    COUNT(*) as pri_count
    FROM match_loadouts
    GROUP BY primary
),

secondary_counts as (
    SELECT secondary, 
    COUNT(*) as sec_count
    FROM match_loadouts
    GROUP BY secondary
),

special_counts as (
    SELECT special, 
    COUNT(*) as sp_count
    FROM match_loadouts
    GROUP BY special
),

weapon_appearances as (
    SELECT pri.*,
    sec.sec_count,
    sp.sp_count,
    (pri.pri_count + sec.sec_count + sp.sp_count) as total_appearances
    FROM primary_counts pri
    LEFT JOIN secondary_counts sec
    ON pri.primary = sec.secondary
    LEFT JOIN special_counts sp
    ON pri.primary = sp.special
),

weapons_fail_count as (
    SELECT 
    weapon_model_id as weapon_id,
    COUNT(*) as failure_count
    FROM failures
    GROUP BY weapon
),

weapon_fail_rate as (
    SELECT 
    a.weapon_id,
    a.total_appearances,
    f.failure_count,
    (f.failure_count/a.total_appearances)*100 as fail_rate
    FROM weapon_appearances a
    LEFT JOIN weapons_fail_count f
    ON a.weapon_id = f.weapon_id
    
)

SELECT * FROM weapon_fail_rate
with matches as (
    select match_id
        ,bout_number
        ,winner_fighter_id
        ,decision
        ,duration_seconds
    from {{ref('_stg_matches')}}
),

entrants as (
    select match_id
        ,upper(replace(fighter_name_entered, '.', ' ')) as fighter_name
        ,loadout_id
        ,points_scored
        ,damage_pct
    from {{ref('_stg_match_entries')}}
),

names as (
    select f.fighter_id
        ,upper(f.registered_name) as fighter_name
        ,t.team_id
    from {{ref('_stg_fighters')}} as f
    left join {{ref('_stg_teams')}} as t 
    on f.team_id = t.team_id
),

loadout_primer as (
    select loadout_id
        ,fighter_id
        ,pilot_id
        ,armour_rating
        ,mobility_rating
    from {{ref('_stg_fighter_loadouts')}}
),

loadout_union as (
    select loadout_id
        ,fighter_id
        ,'primary' as weapon_slot
        ,weapon_model_id
        ,model_name as weapon_name
        ,nominal_power_mw as weapon_power
    from {{ref('_stg_fighter_loadouts')}} as fl
    left join {{ref('_stg_weapon_models')}} as wm 
    on fl.primary_weapon_id = wm.weapon_model_id

    UNION ALL
    
    select loadout_id
        ,fighter_id
        ,'secondary' as weapon_slot
        ,weapon_model_id
        ,model_name as weapon_name
        ,nominal_power_mw as weapon_power
    from {{ref('_stg_fighter_loadouts')}} as fl
    left join {{ref('_stg_weapon_models')}} as wm 
    on fl.secondary_weapon_id = wm.weapon_model_id

    UNION ALL
    
    select loadout_id
        ,fighter_id
        ,weapon_model_id
        ,'special' as weapon_slot
        ,model_name as weapon_name
        ,nominal_power_mw as weapon_power
    from {{ref('_stg_fighter_loadouts')}} as fl
    left join {{ref('_stg_weapon_models')}} as wm 
    on fl.special_weapon_id = wm.weapon_model_id
),

pilot as (
    select pilot_id
        ,pilot_name
    from {{ref('_stg_pilots')}}
),

weapon_failures as (
    select match_id
        ,fighter_id
        ,weapon_model_id
        ,upper(replace(failure_mode, '.', ' ')) as failure_mode
        ,severity
    from {{ref('_stg_weapon_failures')}}
),

joins as (
    select m.match_id
        ,n.fighter_name
        ,pilot_name
        ,points_scored
        ,damage_pct
        ,bout_number
        ,(case when winner_fighter_id = n.fighter_id then 1 else 0 end) as winner_flag
        ,decision
        ,duration_seconds
        ,armour_rating
        ,mobility_rating
        ,weapon_slot
        ,weapon_name
        ,weapon_power
        ,failure_mode
        ,severity
        ,n.fighter_id
        ,lp.loadout_id
    from entrants as e
    left join matches as m 
    on e.match_id = m.match_id
    left join names as n
    on e.fighter_name = n.fighter_name
    left join loadout_primer as lp
    on n.fighter_id = lp.fighter_id and e.loadout_id = lp.loadout_id
    left join loadout_union as lu
    on n.fighter_id = lu.fighter_id and e.loadout_id = lu.loadout_id
    left join pilot as p
    on lp.pilot_id = p.pilot_id
    left join weapon_failures as wf
    on m.match_id = wf.match_id and n.fighter_id = wf.fighter_id and lu.weapon_model_id = wf.weapon_model_id
)

select *
from joins
where weapon_name IS NOT NULL
order by match_id, fighter_id
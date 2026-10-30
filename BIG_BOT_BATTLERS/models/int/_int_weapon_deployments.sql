with checks as (
    select
        match_id,
        fighter_id,
        weapon_slot,
        max_by(weapon_model_id, check_id) as weapon_model_id,
        max_by(employee_id, check_id) as inspected_by_employee_id,
        max_by(check_result, check_id) as check_result,
        max_by(output_test_pct, check_id) as output_test_pct,
        count(*) as checks_performed
    from {{ ref('_stg_equipment_checks') }}
    group by 1, 2, 3
),

access as (
    select match_id, employee_id, boolor_agg(equipment_access) as had_access
    from {{ ref('_stg_employee_match_assignments') }}
    group by 1, 2
)

select
    c.match_id,
    c.fighter_id,
    c.weapon_slot,
    c.weapon_model_id,
    c.inspected_by_employee_id,
    c.check_result,
    upper(trim(c.check_result)) = 'PASS' as passed_check,
    c.output_test_pct,
    c.checks_performed,
    coalesce(a.had_access, false) as inspector_had_equipment_access,
    e.event_date,
    date_trunc('month', e.event_date) as event_month
from checks c
left join access a
    on a.match_id = c.match_id and a.employee_id = c.inspected_by_employee_id
left join {{ ref('_stg_matches') }} m on m.match_id = c.match_id
left join {{ ref('_stg_events') }}  e on e.event_id = m.event_id
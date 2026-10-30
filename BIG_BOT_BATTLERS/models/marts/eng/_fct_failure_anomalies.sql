{{ config(materialized='table') }}
with f as (
    select * from {{ ref('_fct_weapon_failures') }}
),

combo as (
    select
        weapon_model_id, failed_component_id, failure_mode,
        ratio_to_report(count(*)) over (partition by weapon_model_id) as share_of_model_failures
    from f
    group by 1, 2, 3
),

bom as (
    select distinct weapon_model_id, component_id
    from {{ ref('_stg_weapon_materials_bill') }}
),

timing as (
    select
        failure_id,
        percent_rank() over (partition by weapon_model_id order by minute_in_bout) as minute_pct_rank
    from f
),

spikes as (
    select event_month, failed_component_id, failure_mode, is_spike
    from {{ ref('_fct_failure_rate_monthly') }}
),

-- Did each PASSED inspection end in a failure of that same weapon, same fight?
failed_weapons as (
    select distinct match_id, fighter_id, weapon_slot from f
),

passed_checks as (
    select
        d.inspected_by_employee_id,
        fw.match_id is not null as failed_in_match
    from {{ ref('_int_weapon_deployments') }} d
    left join failed_weapons fw
        on  fw.match_id = d.match_id
        and fw.fighter_id = d.fighter_id
        and fw.weapon_slot = d.weapon_slot
    where d.passed_check
),

overall as (
    select avg(iff(failed_in_match, 1, 0)) as p from passed_checks
),

inspectors as (
    select
        pc.inspected_by_employee_id,
        count(*) as passed_checks,
        count_if(pc.failed_in_match) as passed_then_failed,
        div0(count_if(pc.failed_in_match) - count(*) * o.p,
             sqrt(count(*) * o.p * (1 - o.p))) as z_score
    from passed_checks pc
    cross join overall o
    group by pc.inspected_by_employee_id, o.p
),

flagged as (
    select
        f.*,
        c.share_of_model_failures,
        i.z_score as inspector_z_score,

        coalesce(f.passed_pre_match_check, false) as flag_passed_then_failed,
        c.share_of_model_failures < 0.02 as flag_rare_pattern,
        b.component_id is null as flag_part_not_in_model,
        t.minute_pct_rank < 0.05 as flag_early_failure,
        coalesce(s.is_spike, false) as flag_monthly_spike,
        coalesce(i.passed_checks >= 30 and i.z_score > 3, false) as flag_inspector_outlier,
        f.inspected_by_employee_id is not null
            and not f.inspector_had_equipment_access as flag_check_without_access
    from f
    left join combo c
        on  c.weapon_model_id = f.weapon_model_id
        and c.failed_component_id = f.failed_component_id
        and c.failure_mode = f.failure_mode
    left join bom b
        on  b.weapon_model_id = f.weapon_model_id
        and b.component_id = f.failed_component_id
    left join timing t on t.failure_id = f.failure_id
    left join spikes s
        on  s.event_month = f.event_month
        and s.failed_component_id = f.failed_component_id
        and s.failure_mode = f.failure_mode
    left join inspectors i on i.inspected_by_employee_id = f.inspected_by_employee_id
)

select
    *,
    iff(flag_passed_then_failed, 1, 0)
  + iff(flag_rare_pattern, 1, 0)
  + iff(flag_part_not_in_model, 1, 0)
  + iff(flag_early_failure, 1, 0)
  + iff(flag_monthly_spike, 1, 0)
  + iff(flag_inspector_outlier, 1, 0)
  + iff(flag_check_without_access, 1, 0) as anomaly_score
from flagged

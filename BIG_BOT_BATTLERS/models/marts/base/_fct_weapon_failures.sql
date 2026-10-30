{{ config(materialized='table') }}

-- Base fact table. Grain: one row per weapon failure.
--
-- Everything you need about a failure in one place:
--   when/where it happened, what broke, the pre-match inspection, and the repair cost.
-- Descriptive columns (model name, component name, event date) are folded in
-- directly instead of living in separate dim tables.
--
-- Failures with no repair (4 at last check) are kept, with zero cost and
-- was_repaired = false.

with failures as (
    select
        failure_id,
        match_id,
        fighter_id,
        weapon_slot,
        weapon_model_id,
        component_id,
        -- 'HYDRAULIC.LEAK' / 'Hydraulic Leak' / 'hydraulic_leak' -> 'Hydraulic Leak'
        initcap(trim(regexp_replace(failure_mode, '[._ ]+', ' '))) as failure_mode,
        severity,
        minute_in_bout
    from {{ ref('_stg_weapon_failures') }}
),

-- rolled up per failure so the grain stays safe even if a failure ever
-- gets more than one repair order
repairs as (
    select
        failure_id,
        count(*)                    as repair_orders,
        max(completed_on)           as last_repair_completed_on,
        sum(labour_hours)           as labour_hours,
        sum(labour_cost_usd)        as labour_cost_usd,
        sum(parts_cost_usd)         as parts_cost_usd,
        sum(total_repair_cost_usd)  as total_repair_cost_usd,
        sum(ledger_cost_usd)        as ledger_cost_usd
    from {{ ref('_int_repair_costs') }}
    group by 1
)

select
    f.failure_id,

    -- when / where
    f.match_id,
    m.event_id,
    e.event_name,
    e.event_date,
    date_trunc('month', e.event_date)  as event_month,
    e.season,

    -- what broke
    f.fighter_id,
    f.weapon_slot,
    f.weapon_model_id,
    w.model_name,
    w.weapon_family,
    f.component_id                     as failed_component_id,
    c.component_name                   as failed_component_name,
    c.component_class                  as failed_component_class,
    f.failure_mode,
    f.severity,
    f.minute_in_bout,

    -- pre-match inspection of the weapon that failed
    d.inspected_by_employee_id,
    d.passed_check                     as passed_pre_match_check,
    d.output_test_pct                  as pre_match_output_test_pct,
    d.inspector_had_equipment_access,

    -- repair
    coalesce(r.repair_orders, 0)       as repair_orders,
    coalesce(r.repair_orders, 0) > 0   as was_repaired,
    r.last_repair_completed_on,
    datediff('day', e.event_date, r.last_repair_completed_on) as days_to_repair,

    -- cost
    coalesce(r.labour_hours, 0)          as labour_hours,
    coalesce(r.labour_cost_usd, 0)       as labour_cost_usd,
    coalesce(r.parts_cost_usd, 0)        as parts_cost_usd,
    coalesce(r.total_repair_cost_usd, 0) as total_repair_cost_usd,
    r.ledger_cost_usd                    -- null before 2026 (no ledger yet)

from failures f
left join {{ ref('_stg_matches') }}       m on m.match_id = f.match_id
left join {{ ref('_stg_events') }}        e on e.event_id = m.event_id
left join {{ ref('_stg_weapon_models') }} w on w.weapon_model_id = f.weapon_model_id
left join {{ ref('_stg_components') }}    c on c.component_id = f.component_id
left join repairs r on r.failure_id = f.failure_id
left join {{ ref('_int_weapon_deployments') }} d
    on  d.match_id    = f.match_id
    and d.fighter_id  = f.fighter_id
    and d.weapon_slot = f.weapon_slot

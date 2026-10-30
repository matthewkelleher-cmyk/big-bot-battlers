{{ config(materialized='table') }}
select
    f.event_month,
    f.season,

    f.weapon_model_id,
    f.model_name,
    f.weapon_family,

    f.failed_component_id,
    f.failed_component_name,
    f.failed_component_class,

    count(*) as failures,
    count_if(f.was_repaired) as repaired_failures,
    sum(f.labour_hours) as labour_hours,
    sum(f.labour_cost_usd) as labour_cost_usd,
    sum(f.parts_cost_usd) as parts_cost_usd,
    sum(f.total_repair_cost_usd) as total_repair_cost_usd,
    sum(f.ledger_cost_usd) as ledger_cost_usd,
    div0(sum(f.total_repair_cost_usd), count_if(f.was_repaired)) as avg_cost_per_repaired_failure,
    avg(f.days_to_repair) as avg_days_to_repair

from {{ ref('_fct_weapon_failures') }} f
group by all

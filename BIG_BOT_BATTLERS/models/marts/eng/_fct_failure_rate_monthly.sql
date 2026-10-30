{{ config(materialized='table') }}

with months as (
    select event_month, count(*) as deployments
    from {{ ref('_int_weapon_deployments') }}
    where event_month is not null
    group by 1
),

combos as (
    select failed_component_id, failure_mode, any_value(failed_component_name) as failed_component_name
    from {{ ref('_fct_weapon_failures') }}
    group by 1, 2
),

failures as (
    select
        event_month, failed_component_id, failure_mode,
        count(*) as failures,
        sum(total_repair_cost_usd) as repair_cost_usd
    from {{ ref('_fct_weapon_failures') }}
    group by 1, 2, 3
),

grid as (
    select
        m.event_month,
        m.deployments,
        c.failed_component_id,
        c.failed_component_name,
        c.failure_mode,
        coalesce(f.failures, 0) as failures,
        coalesce(f.repair_cost_usd, 0) as repair_cost_usd,
        1000 * coalesce(f.failures, 0) / nullif(m.deployments, 0) as rate_per_1k
    from months m
    cross join combos c
    left join failures f
        on  f.event_month = m.event_month
        and f.failed_component_id = c.failed_component_id
        and f.failure_mode = c.failure_mode
),

baselined as (
    select
        *,
        avg(rate_per_1k) over (
            partition by failed_component_id, failure_mode
            order by event_month rows between 12 preceding and 1 preceding) as baseline_rate_per_1k,
        stddev(rate_per_1k) over (
            partition by failed_component_id, failure_mode
            order by event_month rows between 12 preceding and 1 preceding) as baseline_stddev,
        count(*) over (
            partition by failed_component_id, failure_mode
            order by event_month rows between 12 preceding and 1 preceding) as baseline_months
    from grid
),

scored as (
    select
        *,
        div0(rate_per_1k - baseline_rate_per_1k, baseline_stddev) as z_score
    from baselined
)

select
    *,
    (baseline_months >= 6 and failures >= 3 and z_score > 3)
        or (baseline_months >= 6 and baseline_rate_per_1k = 0 and failures >= 3)
        as is_spike
from scored

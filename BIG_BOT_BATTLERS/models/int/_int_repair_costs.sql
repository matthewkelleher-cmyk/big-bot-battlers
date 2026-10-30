with repair_orders as (
    select *
    from {{ ref('_stg_repair_orders') }}
    qualify row_number() over (partition by repair_order_id order by repair_order_id) = 1 --deduping
),

parts as (
    select
        repair_order_id,
        count(*) as part_lines,
        sum(quantity_used * unit_cost_usd) as parts_cost_usd
    from {{ ref('_stg_repair_parts') }}
    group by 1
),

ledger as (
    select
        repair_order_id,
        sum(expense_usd) as ledger_cost_usd
    from {{ ref('_stg_finance_ledger') }}
    where repair_order_id is not null
    group by 1
)

select
    r.repair_order_id,
    r.failure_id,
    r.opened_on,
    r.completed_on,
    r.status,
    r.labour_hours,
    r.labour_hours * r.hourly_rate_usd as labour_cost_usd,
    coalesce(p.part_lines, 0) as part_lines,
    coalesce(p.parts_cost_usd, 0) as parts_cost_usd,
    r.labour_hours * r.hourly_rate_usd
        + coalesce(p.parts_cost_usd, 0) as total_repair_cost_usd,
    l.ledger_cost_usd,
    l.ledger_cost_usd is not null as is_in_ledger
from repair_orders r
left join parts  p using (repair_order_id)
left join ledger l using (repair_order_id)

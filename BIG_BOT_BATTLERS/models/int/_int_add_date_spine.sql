with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2012-01-01' as date)",
        end_date="cast('2026-10-01' as date)"
    ) }}
)

select
    s.date_day,
    t.* replace (
        coalesce(sales_date, s.date_day) as sales_date,
        coalesce(tickets_sold, 0) as tickets_sold,
        coalesce(tickets_refunded, 0) as tickets_refunded,
        coalesce(refunds_usd, 0) as refunds_usd
    )
from spine s
left join {{ ref('_int_ticket_sales_union') }} t
    on s.date_day = t.sales_date
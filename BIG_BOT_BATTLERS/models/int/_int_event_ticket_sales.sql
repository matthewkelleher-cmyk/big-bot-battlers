with sales as (

    select * from {{ ref('_int_ticket_sales_merged') }}

),

events as (

    select 
        event_id, 
        advertised_on 
    from {{ ref('_stg_events') }}

),

event_totals as (

    select
        event_id,
        sum(tickets_sold) as gross_tickets_sold,
        sum(tickets_refunded) as tickets_refunded,
        sum(net_tickets) as net_paid_tickets,
        sum(iff(ticket_class = 'PREMIUM', net_tickets, 0)) as net_premium_tickets,
        sum(iff(sales_channel = 'WEB', net_tickets, 0)) as net_web_tickets,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(refunds_usd) as refunds_usd,
        sum(net_revenue_usd) as net_ticket_revenue_usd
    from sales
    group by event_id

),

daily_running as (

    select
        event_id,
        sales_date,
        sum(net_tickets) over (
            partition by event_id
            order by sales_date
            rows between unbounded preceding and current row
        ) as running_net_tickets
    from (
        select event_id, sales_date, sum(net_tickets) as net_tickets
        from sales
        group by event_id, sales_date
    )

),


final as (
select
    event_totals.*,
    div0(event_totals.net_premium_tickets, event_totals.net_paid_tickets) as premium_ticket_share,
    div0(event_totals.net_ticket_revenue_usd, event_totals.net_paid_tickets) as avg_ticket_price_usd,
    div0(event_totals.tickets_refunded, event_totals.gross_tickets_sold) as refund_rate
from event_totals
left join events
    on event_totals.event_id = events.event_id
)

select * from final
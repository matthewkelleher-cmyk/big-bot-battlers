with legacy_deduped as (
 
   select *
   from {{ ref('_stg_ticket_sales_legacy') }}
   qualify row_number() over (
       partition by transaction_id
       order by extract_row_id
   ) = 1
 
),
 
legacy_cleaned as (
 
   select
       'ticket_sales_legacy' as source_name,
       event_id,
       transaction_date as sales_date,
       case
           when upper(trim(ticket_class)) in ('First Class', 'FIRST CLASS') then 'PREMIUM'
           else 'STANDARD'
       end as ticket_class,
       case
           when upper(trim(sales_channel)) in ('CASH', 'BOX OFFICE') then 'BOX_OFFICE'
           else 'WEB'
       end as sales_channel,
       quantity_signed,
       try_to_decimal(replace(replace(trim(amount_usd), '$', ''), ',', ''), 12, 2) as amount_usd
   from legacy_deduped
 
),
 
legacy_aggregated as (
 
   select
       source_name,
       event_id,
       sales_date,
       ticket_class,
       sales_channel,
       sum(iff(quantity_signed > 0, quantity_signed, 0)) as tickets_sold,
       sum(iff(quantity_signed < 0, -quantity_signed, 0)) as tickets_refunded,
       sum(iff(amount_usd > 0, amount_usd, 0)) as gross_sales_usd,
       sum(iff(amount_usd < 0, -amount_usd, 0)) as refunds_usd
   from legacy_cleaned
   group by
       source_name,
       event_id,
       sales_date,
       ticket_class,
       sales_channel
 
),
 
daily_latest_revision as (
 
   select
       'ticket_sales_daily' as source_name,
       event_id,
       sales_date,
       upper(trim(ticket_class)) as ticket_class,
       upper(trim(sales_channel)) as sales_channel,
       tickets_sold,
       tickets_refunded,
       gross_sales_usd,
       refunds_usd
   from {{ ref('_stg_ticket_sales_daily') }}
   qualify row_number() over (
       partition by sales_batch_id
       order by revision desc
   ) = 1
 
),
 
unioned as (
 
   select * 
   from legacy_aggregated
   union all
   select * 
   from daily_latest_revision
 
),
 
events as (
 
    select
        event_id, 
        event_date 
    from {{ ref('_stg_events') }}
 
),
 
coverage as (
 
   select
       source_name,
       event_date_from,
       event_date_to_exclusive
   from {{ ref('_stg_ticket_source_coverage') }}
 
),

Final as (
select
   unioned.source_name,
   unioned.event_id,
   unioned.sales_date,
   unioned.ticket_class,
   unioned.sales_channel,
   unioned.tickets_sold,
   unioned.tickets_refunded,
   unioned.tickets_sold - unioned.tickets_refunded as net_tickets,
   unioned.gross_sales_usd,
   unioned.refunds_usd,
   unioned.gross_sales_usd - unioned.refunds_usd as net_revenue_usd
from unioned
inner join events
   on unioned.event_id = events.event_id
inner join coverage
   on unioned.source_name = coverage.source_name
   and events.event_date >= coverage.event_date_from
   and events.event_date < coverage.event_date_to_exclusive
)


Select * from final
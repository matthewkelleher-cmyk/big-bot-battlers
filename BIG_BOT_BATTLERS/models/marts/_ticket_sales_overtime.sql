with ticket_sales as (
    select *
    from {{ref('_int_ticket_sales_union')}}
), 
add_time_col as 
(
select
    *
    , date_trunc('month', SALES_DATE)   as sale_month
    , date_trunc('quarter', SALES_DATE) as sale_quarter
    , date_part('month', SALES_DATE) as sale_month_num
    , date_part('year', SALES_DATE) as sale_year
    , case
        when date_part('month', SALES_DATE) in (12, 1, 2) then 'Winter'
        when date_part('month', SALES_DATE) in (3, 4, 5)  then 'Spring'
        when date_part('month', SALES_DATE) in (6, 7, 8)  then 'Summer'
        else 'Fall'
      end as sale_season
    , case 
        when date_part('month', SALES_DATE) = 12
            then date_part('year', SALES_DATE) + 1 
        else date_part('year', SALES_DATE)
      end as sale_season_year
from ticket_sales
), 
add_tickets_sold_agg as (
    select 
    * 
    , sum(TICKETS_SOLD) over(partition by sale_month) as tickets_sold_month
    , sum(TICKETS_SOLD) over(partition by sale_quarter) as tickets_sold_quarter 
    , sum(TICKETS_SOLD) over(partition by sale_season_year) as tickets_sold_season
    from add_time_col 
), 
final as (
    select 
    SALES_BATCH_ID
    , EVENT_ID
    , SALES_DATE
    , TICKET_CLASS
    , SALES_CHANNEL
    , TICKETS_SOLD
    , tickets_sold_month
    , tickets_sold_quarter
    , tickets_sold_season
    -- , GROSS_SALES_USD need to clean column to drop '$' and cast as int
    , BUYER_STATE
    from add_tickets_sold_agg
    )
select * 
from final 
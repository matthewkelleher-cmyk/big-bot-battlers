with legacy_sales as 
(
    select 
    --   max(TRANSACTION_DATE) as min_date
    -- , min(TRANSACTION_DATE) as max_date
    count(TRANSACTION_TYPE) as num_non_null_rows
    from {{ref('_stg_ticket_sales_legacy')}}
)
, 
daily_sales as 
(
    select 
    max(SALES_DATE) as max_date 
    , min(SALES_DATE) as min_date
    from {{ref('_stg_ticket_sales_daily')}}
)
select * 
from legacy_sales
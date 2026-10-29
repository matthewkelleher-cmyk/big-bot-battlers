with legacy_sales as 
(
    select 
    trasnaction_id 
    , max(transaction_date) as min_date
    , min(tranaction_date) as max_date
    from {{ref('_stg_ticket_sales_legacy')}}
    group by trasnaction_id
)
select * 
from legacy_sales
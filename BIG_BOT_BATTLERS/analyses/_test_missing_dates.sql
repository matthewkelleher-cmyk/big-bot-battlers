select
    min(sales_date) as min_date
    , max(sales_date) as max_date
    , count(*) as row_count
    , count(distinct sales_date) as distinct_days
from {{ ref('_int_ticket_sales_union') }}
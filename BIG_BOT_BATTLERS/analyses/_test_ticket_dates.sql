with unioned as (
    select * 
    from {{ ref('_int_ticket_sales_union') }}
), 
 bounds as (
    select
        min(sales_date) as min_date,
        max(sales_date) as max_date
    from unioned
),

numbers as (
    select row_number() over (order by seq4()) - 1 as n
    from table(generator(rowcount => 20000))   -- ~54 years of days; raise if needed
),

spine as (
    select dateadd(day, n.n, b.min_date) as date_day
    from bounds b
    cross join numbers n
    where dateadd(day, n.n, b.min_date) <= b.max_date
),

actual as (
    select distinct sales_date
    from unioned
)

select s.date_day as missing_date
from spine s
left join actual a
    on a.sales_date = s.date_day
where a.sales_date is null
order by s.date_day
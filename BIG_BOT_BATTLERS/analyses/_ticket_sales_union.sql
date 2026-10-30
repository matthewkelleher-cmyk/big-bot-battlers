with unioned as 
(
    select * 
    from {{ref('_int_ticket_sales_union')}}
)

select * 
from unioned 
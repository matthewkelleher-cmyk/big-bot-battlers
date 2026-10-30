with legacy_tickets as 
(
    select * 
    from {{ref('_stg_ticket_sales_legacy')}}
),

 daily_tickets as 
(
    select * 
    from {{ref('_stg_ticket_sales_daily')}}
),
 rename_legacy as(
    select 
    TRANSACTION_ID as SALES_BATCH_ID
    , EVENT_ID
    , TRANSACTION_DATE as SALES_DATE
    , TICKET_CLASS
    , SALES_CHANNEL
    , TRANSACTION_TYPE
    , ORIGINAL_TRANSACTION_ID
    , QUANTITY_SIGNED as TICKETS_SOLD
    , AMOUNT_USD as GROSS_SALES_USD 
    , BUYER_STATE 
    , EXTRACT_ROW_ID
    , EXTRACTED_AT
    from legacy_tickets
),

 unioned as (

select * from rename_legacy 
union all by name 
select * from daily_tickets
 )

 select * from unioned 
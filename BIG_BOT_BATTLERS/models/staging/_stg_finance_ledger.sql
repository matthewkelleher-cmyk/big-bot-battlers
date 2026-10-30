select
    journal_line_id,
    posted_on,
    division,
    cost_category,
    repair_order_id,
    expense_usd,
    memo
from {{ source('input_data', 'raw_finance_ledger') }}
with loadouts as (
    SELECT *
    FROM {{ref('_stg_fighter_loadouts')}}
),

pilots as (
    SELECT *
    FROM {{ref('_stg_pilots')}}
),

final as (
    SELECT l.*, p.* EXCLUDE(pilot_id, extract_row_id, extracted_at)
    FROM loadouts l
    LEFT JOIN pilots p
    ON l.pilot_id = p.pilot_id
)

SELECT * FROM final
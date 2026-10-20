with source as (
        select * from {{ source('input_data', 'raw_fighter_loadouts') }}
  ),
  renamed as (
      select
          {{ adapter.quote("LOADOUT_ID") }},
        {{ adapter.quote("FIGHTER_ID") }},
        {{ adapter.quote("PILOT_ID") }},
        {{ adapter.quote("VALID_FROM") }},
        {{ adapter.quote("VALID_TO") }},
        {{ adapter.quote("PRIMARY_WEAPON_ID") }},
        {{ adapter.quote("SECONDARY_WEAPON_ID") }},
        {{ adapter.quote("SPECIAL_WEAPON_ID") }},
        {{ adapter.quote("ARMOUR_RATING") }},
        {{ adapter.quote("MOBILITY_RATING") }},
        {{ adapter.quote("EXTRACT_ROW_ID") }},
        {{ adapter.quote("EXTRACTED_AT") }}

      from source
  )
  select * from renamed
    
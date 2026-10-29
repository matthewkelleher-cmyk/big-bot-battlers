with events as (
    select *
    from {{ ref('_stg_events') }}
),

venues as (
    select *
    from {{ ref('_stg_venues') }}
),

cities as (
    select * 
    from {{ ref('_stg_cities') }}
),

capacity_history as (
    select *
    from {{ ref('_stg_venue_capacity_history') }}
),

joined as (
    select
        events.event_id,
        events.event_name,
        events.event_date,
        events.season,
        events.advertised_on,
        datediff('day', events.advertised_on, events.event_date) as days_since_advertisement,
        dayname(events.event_date) as event_day,
        monthname(events.event_date) as event_month,
        events.venue_id,
        venues.venue_name,
        venues.property_model,
        venues.opened_on as venue_opened_on,
        venues.closed_on as venue_closed_on,
        venues.city_id,
        cities.city_name,
        cities.state_code,
        cities.region,
        capacity_history.certified_capacity,
        events.blocked_seats,
        events.public_health_limit_pct,
        events.sellable_capacity,
        floor(
            (capacity_history.certified_capacity - events.blocked_seats) * events.public_health_limit_pct / 100
        ) as sellable_capacity_recal,
    from events
        left join venues
            on events.venue_id = venues.venue_id
        left join cities
            on venues.city_id = cities.city_id
        left join capacity_history
            on events.venue_id = capacity_history.venue_id
            and events.event_date >= capacity_history.valid_from
            and (capacity_history.valid_to is null or events.event_date < capacity_history.valid_to)
),

final as (
    select 
        *,
        public_health_limit_pct < 100 as is_health_restricted,
        sellable_capacity <> sellable_capacity_recal as mismatch_sellable_capacity,
        event_date >= venue_opened_on and event_date <= coalesce(venue_closed_on, '9999-12-31'::date) as is_within_venue_dates
    from joined 
)

select * from final
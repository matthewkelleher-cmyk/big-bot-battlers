SELECT match_id, COUNT(DISTINCT event_id) as count
FROM {{ref('_stg_matches')}}
GROUP BY match_id
ORDER BY count desc
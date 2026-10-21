with match_assignments as (
    SELECT match_id, employee_id
    FROM {{ref('_stg_employee_match_assignments')}}
    WHERE equipment_access = 'TRUE'
)

SELECT * from match_assignments
{% macro append_created_at() %}
with base as (
    {{ caller() }}
)
select
    *,
    current_timestamp as created_at
from base
{% endmacro %}

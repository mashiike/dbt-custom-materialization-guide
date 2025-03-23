{{ config(materialized='view') }}

{% call append_created_at() %}
select 1 as id
{% endcall %}

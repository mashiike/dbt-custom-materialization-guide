{{ config(
    materialized='noop',
    pre_hook = '{{ this }} is a noop model.'
) }}

-- This is a noop model. It does nothing.

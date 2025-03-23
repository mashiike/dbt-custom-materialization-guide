{{-
    config(
        materialized='table',
    )
}}

select
    'player ' || mod(draw_order, 4)+1 as player,
    card_rank,
    suit
from {{ ref('draw_cards') }}(20)
order by 1

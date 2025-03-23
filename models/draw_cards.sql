{{-
    config(
        materialized='table_function',
        args=[
            {
                "name": "p_n",
                "type": "int",
                "default": 1,
            }
        ],
    )
}}

WITH card_ranks AS (
    SELECT unnest(ARRAY['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']) AS card_rank
),
suits AS (
    SELECT unnest(ARRAY['Spades', 'Hearts', 'Diamonds', 'Clubs']) AS suit
),
deck AS (
    SELECT CAST(c.card_rank AS TEXT) as card_rank, CAST(s.suit as TEXT) as suit
    FROM card_ranks as c CROSS JOIN suits as s
),
shuffled_deck AS (
    SELECT d.card_rank, d.suit,
            row_number() OVER (ORDER BY random()) AS rnd_order
    FROM deck as d
)
SELECT d.card_rank, d.suit, CAST(d.rnd_order as INT) as draw_order
FROM shuffled_deck as d
WHERE d.rnd_order <= p_n
ORDER BY d.rnd_order

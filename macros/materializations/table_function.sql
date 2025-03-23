{%- materialization table_function, default %}
  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}
  {%- set args = config.get('args',[]) %}
  {%- set table_schema = config.get('table_schema') %}
  {%- if table_schema is none%}

    -- argを置き換えて実際にクエリできるように変換
    {%- set pre_select_sql = [sql] %}
    {%- if args | length > 0 %}
      {%- for arg in args %}
        {%- if arg.default is defined %}
          {%- do pre_select_sql.append(pre_select_sql | last | replace(arg.name, arg.default)) %}
        {%- else %}
          {%- do pre_select_sql.append(pre_select_sql | last | replace(arg.name, 'CAST(NULL as '~arg.type~')')) %}
        {%- endif %}
      {%- endfor %}
    {%- endif %}

    -- 一時テーブルを作成する
    {%- set intermediate_relation =  make_intermediate_relation(this) -%}
    {%- set preexisting_intermediate_relation = load_cached_relation(intermediate_relation) -%}
    {{ drop_relation_if_exists(preexisting_intermediate_relation) }}
    {%- set query %}
        CREATE TABLE {{ intermediate_relation }} AS
        {{ pre_select_sql | last }}
    {%- endset %}
    {%- do run_query(query) %}

    -- 一時テーブルのカラムからスキーマを構成
    {%- set columns = adapter.get_columns_in_relation(intermediate_relation) -%}
    {%- set table_schema = [] -%}
    {%- for column in columns %}
        {%- do table_schema.append({'name': column.name, 'type': column.dtype}) %}
    {%- endfor %}
  {%- endif %}

  {%- set query %}
    SELECT
        'DROP FUNCTION ' || n.nspname || '.' || p.proname || '(' ||
        pg_get_function_identity_arguments(p.oid) || ');' AS query
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = '{{this.schema}}' and p.proname = '{{this.identifier}}';
  {%- endset %}
  {%- set results = run_query(query).rows %}
  {%- if results | length > 0 %}
    {%- do run_query(results[0].query) %}
  {%- endif %}

  {% call statement('main') %}
    CREATE OR REPLACE FUNCTION {{ this }}(
        {%- for arg in args -%}
        {{ arg.name }} {{ arg.type }} {% if arg.default is defined %}DEFAULT {{ arg.default }}
        {%- endif %}{% if not loop.last %}, {% endif %}
        {%- endfor -%}
    )
    RETURNS TABLE(
        {%- for column in table_schema -%}
        {{ column.name }} {{ column.type }}{% if not loop.last %}, {% endif %}
        {%- endfor -%}
    ) AS $$
    BEGIN
        RETURN QUERY
        {{ sql }}
        ;
    END;
    $$ LANGUAGE plpgsql;
  {% endcall %}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  -- `COMMIT` happens here
  {{ adapter.commit() }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [this]}) }}
{%- endmaterialization %}

{%- materialization noop, default %}
  {%- for pre_hook in pre_hooks %}
    {%- set before_rendered = pre_hook.get('sql') | trim %}
    {%- do log('Before renderd pre-hook: ' ~ before_rendered,info=True) %}
    {%- set rendered = render(pre_hook.get('sql')) | trim %}
    {%- do log('Rendered pre-hook: ' ~ rendered, info=True) %}
  {%- endfor %}
  {% call noop_statement('main', 'Nothing TODO', 'OK', 0) %}
-- this materialization does nothing. following is a compiled model code
    {{ sql }}
  {% endcall %}
  {{ return({'relations': []}) }}
{%- endmaterialization %}

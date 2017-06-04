{% if page.comments %}
  {% include './comments/disqus.swig' %}
  {% include './comments/hypercomments.swig' %}
  {% include './comments/gitment.swig' %}
{% endif %}

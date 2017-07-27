{% if page.comments %}
  {% include './comments/disqus.swig' %}
  {% include './comments/hypercomments.swig' %}
  {% include './comments/livere.swig' %}
  {% include './comments/gitment.swig' %}
{% endif %}

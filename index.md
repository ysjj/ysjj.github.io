{% for cat in site.categories %}
<h2>{{ cat[0] }}</h2>
<ul class="highlight">
  {% for post in cat[1] %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <small class="c">({{ post.date | date: "%Y-%m-%d" }})</small>
    </li>
  {% endfor %}
</ul>
{% endfor %}

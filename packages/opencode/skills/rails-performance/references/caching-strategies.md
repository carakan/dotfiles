# Caching Strategies

## Fragment Caching

Cache expensive view partials to avoid re-rendering:

```erb
<%# Basic fragment cache — key derived from record's cache_key_with_version %>
<% cache @article do %>
  <%= render @article %>
<% end %>

<%# Explicit versioned key %>
<% cache ['v1', @article] do %>
  <%= render @article %>
<% end %>

<%# Collection caching — caches each item individually %>
<%= render partial: 'article', collection: @articles, cached: true %>
```

## Russian Doll Caching

Nest fragment caches so inner changes only invalidate the inner cache:

```erb
<% cache @article do %>
  <article>
    <h1><%= @article.title %></h1>

    <% cache @article.author do %>
      <div class="author">
        <%= render @article.author %>
      </div>
    <% end %>

    <% @article.comments.each do |comment| %>
      <% cache comment do %>
        <%= render comment %>
      <% end %>
    <% end %>
  </article>
<% end %>
```

Use `touch: true` on `belongs_to` to propagate cache invalidation to parent records:

```ruby
class Comment < ApplicationRecord
  belongs_to :article, touch: true
end
```

When a comment updates, `article.updated_at` changes, busting the outer cache.

## Low-Level Caching

Cache arbitrary data (query results, API responses, computed values):

```ruby
# Read-through cache with automatic expiration
Rails.cache.fetch('all_posts', expires_in: 1.hour) do
  Post.published.to_a
end

# Prevent thundering herd with race_condition_ttl
Rails.cache.fetch('popular_posts', expires_in: 1.hour, race_condition_ttl: 10.seconds) do
  Post.popular.limit(10).to_a
end

# Manual cache operations
Rails.cache.write('key', value, expires_in: 1.hour)
Rails.cache.read('key')
Rails.cache.delete('key')
Rails.cache.exist?('key')
```

### Cache Key Design

Build deterministic, versioned cache keys:

```ruby
# Model-based (automatic versioning via updated_at)
Rails.cache.fetch(@user) { expensive_computation }

# Custom composite keys
Rails.cache.fetch([@user, 'dashboard', Date.current]) do
  build_dashboard_data(@user)
end

# Collection digest
Rails.cache.fetch([User.maximum(:updated_at), User.count]) do
  User.active.to_a
end
```

## HTTP Caching

### Conditional GET (ETag / Last-Modified)

Avoid re-rendering responses when content has not changed:

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])

    # Returns 304 Not Modified if ETag matches
    if stale?(@article)
      respond_to do |format|
        format.html
        format.json { render json: @article }
      end
    end
  end

  def index
    @articles = Article.published

    # Cache in browser and CDN for 1 hour
    expires_in 1.hour, public: true
  end
end
```

### stale? Options

```ruby
# ETag based on record
stale?(@article)

# ETag based on multiple records
stale?([@article, current_user])

# Explicit last_modified
stale?(@article, last_modified: @article.published_at)

# Public caching (CDN-friendly)
stale?(@article, public: true)
```

## Cache Store Configuration

### Redis (Recommended for Production)

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.day,
  namespace: 'myapp_cache',
  error_handler: ->(method:, returning:, exception:) {
    Rails.logger.error("Redis error: #{exception}")
    Sentry.capture_exception(exception)
  }
}
```

### Memcached

```ruby
config.cache_store = :mem_cache_store, ENV['MEMCACHED_URL']
```

### Solid Cache (Rails 8+)

Database-backed cache using the same database or a separate one:

```ruby
config.cache_store = :solid_cache_store
```

Solid Cache is a good default for applications that do not need a separate Redis/Memcached instance, with automatic expiration managed by a background job.

### Memory Store (Development/Testing)

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

## Cache Invalidation Patterns

### Time-Based Expiration

```ruby
Rails.cache.fetch('stats', expires_in: 15.minutes) { compute_stats }
```

### Key-Based Expiration (Preferred)

Rely on `cache_key_with_version` so stale entries expire naturally:

```ruby
# cache_key_with_version includes updated_at
# e.g., "users/123-20240101120000"
cache @user do
  # Automatically invalidated when user.updated_at changes
end
```

### Manual Invalidation

```ruby
# Delete specific key
Rails.cache.delete('custom_key')

# Delete by pattern (Redis only)
Rails.cache.delete_matched('views/articles/*')

# Clear entire cache (use sparingly)
Rails.cache.clear
```

---
name: rails-performance
description: Use when encountering slow page loads, high database query counts, memory bloat, or when optimizing a Rails application. Also applies when choosing a caching strategy, adding database indexes, or deciding what to move to background jobs. Covers N+1 prevention, eager loading, indexing, caching, pagination, and profiling tools.
---

# Rails Performance Optimization

Guidance for optimizing Rails application performance including database queries, caching, background processing, and profiling.

## N+1 Query Prevention

Detect N+1 queries by checking for association access inside loops. Resolve with eager loading:

```ruby
# BAD: N+1 — each iteration queries the database
users.each { |u| u.posts.count }

# GOOD: Eager load with includes
users = User.includes(:posts)
users.each { |u| u.posts.size }  # No additional queries
```

| Method       | Query Style      | Use When                              |
| ------------ | ---------------- | ------------------------------------- |
| `includes`   | Auto (smart)     | Default choice for eager loading      |
| `preload`    | Separate queries | Multiple has_many, avoiding cartesian |
| `eager_load` | Single LEFT JOIN | Filtering/ordering by association     |
| `joins`      | INNER JOIN       | Filtering only, not accessing data    |

Enable strict loading in development to surface N+1 issues as errors:

```ruby
# config/environments/development.rb
config.active_record.strict_loading_by_default = true
```

For detailed eager loading patterns, Bullet gem setup, and strict loading configuration, read `references/eager-loading.md`.

## Database Optimization

### Indexing

Add indexes for foreign keys, WHERE clause columns, ORDER BY columns, and composite queries:

```ruby
add_index :posts, :user_id
add_index :users, :email, unique: true
add_index :orders, [:status, :created_at]
```

### Query Patterns

```ruby
# Select only needed columns
User.select(:id, :name, :email)

# Use pluck for arrays of values (skips model instantiation)
User.where(active: true).pluck(:email)

# Check existence efficiently
User.where(email: email).exists?  # Not .count > 0

# Batch process large datasets
User.find_each(batch_size: 1000) { |u| u.process! }

# Bulk operations
User.where(active: false).update_all(deleted_at: Time.current)
```

### Counter Caches

Avoid repeated counting queries by maintaining a cached count column:

```ruby
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end
# user.posts_count reads the column — no query
```

### Pagination

Paginate all large collections to avoid loading entire tables:

```ruby
# Pagy (recommended — faster, lower memory)
@pagy, @users = pagy(User.all, items: 25)

# Kaminari
@users = User.page(params[:page]).per(25)
```

For indexing strategies, EXPLAIN analysis, bulk operations, and advanced query patterns, read `references/database-optimization.md`.

## Caching Strategies

### Fragment Caching

Cache expensive view partials:

```erb
<% cache @article do %>
  <%= render @article %>
<% end %>

<%# Collection caching %>
<%= render partial: 'article', collection: @articles, cached: true %>
```

### Low-Level Caching

Cache arbitrary data with automatic expiration:

```ruby
Rails.cache.fetch('popular_posts', expires_in: 1.hour, race_condition_ttl: 10.seconds) do
  Post.popular.limit(10).to_a
end
```

### HTTP Caching

Return 304 Not Modified when content has not changed:

```ruby
def show
  @article = Article.find(params[:id])
  if stale?(@article)
    respond_to { |format| format.html }
  end
end
```

### Cache Store Configuration

```ruby
# Redis (recommended for production)
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.day,
  namespace: 'myapp_cache'
}

# Solid Cache (Rails 8+ — database-backed)
config.cache_store = :solid_cache_store
```

For Russian Doll caching, cache key design, invalidation patterns, and detailed store options, read `references/caching-strategies.md`.

## Background Jobs

Move slow operations out of the request cycle:

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)
    ProcessOrderJob.perform_later(@order.id)
    SendConfirmationEmailJob.perform_later(@order.id)
    redirect_to @order, notice: 'Order placed!'
  end
end
```

Offload to background jobs: email sending, external API calls, report generation, file processing, and any operation exceeding ~100ms.

## Streaming Large Responses

For large exports (CSV, JSON), stream the response to avoid buffering in memory:

```ruby
def export
  headers['Content-Type'] = 'text/csv'
  headers['Content-Disposition'] = 'attachment; filename="users.csv"'

  self.response_body = Enumerator.new do |yielder|
    yielder << "name,email\n"
    User.find_each(batch_size: 1000) do |user|
      yielder << "#{user.name},#{user.email}\n"
    end
  end
end
```

Combine `find_each` (batch loading) with an `Enumerator` (streaming output) to export large datasets without memory bloat or request timeouts.

## Profiling

### rack-mini-profiler

Add a timing badge to every page showing SQL queries, rendering time, and memory:

```ruby
gem 'rack-mini-profiler'
# Press Alt+P to show/hide. Append ?pp=flamegraph for flamegraphs.
```

### Benchmark Comparisons

```ruby
Benchmark.bm do |x|
  x.report('includes') { User.includes(:posts).to_a }
  x.report('preload')  { User.preload(:posts).to_a }
end
```

For MemoryProfiler, derailed_benchmarks, ActiveSupport::Notifications, and production monitoring setup, read `references/profiling-tools.md`.

## Performance Checklist

### Database

- [ ] Indexes on foreign keys and frequently queried columns
- [ ] No N+1 queries (use includes/preload)
- [ ] Select only needed columns
- [ ] `find_each` for large dataset processing
- [ ] Pagination on all listings

### Caching

- [ ] Fragment caching for expensive view partials
- [ ] Collection caching with `cached: true`
- [ ] HTTP caching headers (stale?/expires_in)
- [ ] Redis or Solid Cache in production

### Background Processing

- [ ] Heavy operations in background jobs
- [ ] Email sending async
- [ ] External API calls async
- [ ] Large exports use streaming responses

## Quick Reference

| Problem         | Solution                   |
| --------------- | -------------------------- |
| N+1 queries     | `includes(:association)`   |
| Slow counting   | Counter cache              |
| Large datasets  | `find_each` + pagination   |
| Slow views      | Fragment caching           |
| Slow operations | Background jobs            |
| Missing indexes | `add_index` migration      |
| Heavy queries   | Select only needed columns |
| Large exports   | `find_each` + streaming    |

## Additional Resources

### Reference Files

For detailed patterns and techniques, consult:
- **`references/eager-loading.md`** — N+1 detection, includes vs preload vs eager_load, Bullet gem, strict loading
- **`references/database-optimization.md`** — Indexing strategies, EXPLAIN analysis, batch processing, bulk operations, counter caches
- **`references/caching-strategies.md`** — Russian Doll caching, low-level cache keys, HTTP caching, cache store configuration, invalidation patterns
- **`references/profiling-tools.md`** — rack-mini-profiler, Benchmark, MemoryProfiler, derailed_benchmarks, ActiveSupport::Notifications

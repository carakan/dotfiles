# Eager Loading & N+1 Query Prevention

## Identifying N+1 Queries

N+1 queries occur when association access happens inside a loop:

```ruby
# BAD: N+1 queries
users = User.all
users.each do |user|
  puts user.posts.count  # Each iteration queries the database!
end
# Result: 1 query for users + N queries for posts
```

## Eager Loading Methods

### `includes` — Separate Query per Association (Most Common)

```ruby
users = User.includes(:posts)
users.each { |u| u.posts.size }  # No additional queries

# Nested associations
users = User.includes(posts: :comments)

# Multiple associations
users = User.includes(:posts, :comments, :profile)
```

Rails automatically chooses between separate queries and a LEFT JOIN depending on usage.

### `preload` — Always Separate Queries

```ruby
users = User.preload(:posts, :comments)
# Always generates: SELECT * FROM posts WHERE user_id IN (1, 2, 3...)
```

Use `preload` when separate queries are preferred (e.g., to avoid cartesian product issues with multiple has_many associations).

### `eager_load` — Single LEFT JOIN

```ruby
# Required when filtering on the association
users = User.eager_load(:posts).where(posts: { published: true })
# Generates: SELECT * FROM users LEFT OUTER JOIN posts ON ...
```

Use `eager_load` when filtering or ordering by association columns in WHERE or ORDER BY clauses.

### `joins` — For Filtering Only (Does Not Load Association)

```ruby
users = User.joins(:posts).where(posts: { published: true }).distinct
# Only loads users, NOT their posts
```

Use `joins` when filtering by association data but not accessing the association objects.

## Decision Guide

| Method       | Loads Association? | Query Style      | Use When                              |
| ------------ | ------------------ | ---------------- | ------------------------------------- |
| `includes`   | Yes                | Auto (smart)     | Default choice for eager loading      |
| `preload`    | Yes                | Separate queries | Multiple has_many, avoiding cartesian |
| `eager_load` | Yes                | Single LEFT JOIN | Filtering/ordering by association     |
| `joins`      | No                 | INNER JOIN       | Filtering only, not accessing data    |

## Bullet Gem for Automated Detection

Configure Bullet to detect N+1 queries and unused eager loads in development:

```ruby
# Gemfile
gem 'bullet', group: :development

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
end
```

Bullet reports:
- **N+1 queries** — associations accessed in loops without eager loading
- **Unused eager loading** — `includes` calls where the association is never accessed
- **Counter cache suggestions** — counting queries that could use counter caches

## Advanced Patterns

### Conditional Eager Loading

```ruby
# Load different associations based on context
scope = User.all
scope = scope.includes(:posts) if params[:include_posts]
scope = scope.includes(:comments) if params[:include_comments]
```

### Strict Loading (Rails 6.1+)

Raise errors instead of silently performing N+1 queries:

```ruby
# Per-query
users = User.strict_loading.all
users.first.posts  # Raises ActiveRecord::StrictLoadingViolationError

# Per-model
class User < ApplicationRecord
  self.strict_loading_by_default = true
end

# Per-association
class User < ApplicationRecord
  has_many :posts, strict_loading: true
end
```

Enable globally in development to catch all N+1 issues:

```ruby
# config/environments/development.rb
config.active_record.strict_loading_by_default = true
```

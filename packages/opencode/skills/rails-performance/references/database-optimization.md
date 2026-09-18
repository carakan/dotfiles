# Database Optimization

## Indexing Strategy

Add indexes for columns used in queries. Missing indexes are the most common cause of slow queries.

### When to Add Indexes

```ruby
# 1. Foreign keys (always)
add_index :posts, :user_id

# 2. Columns in WHERE clauses
add_index :users, :email, unique: true
add_index :posts, :published

# 3. Columns in ORDER BY
add_index :posts, :created_at

# 4. Composite indexes for multi-column queries
add_index :posts, [:user_id, :published]
add_index :orders, [:status, :created_at]

# 5. Polymorphic associations (always composite)
add_index :comments, [:commentable_type, :commentable_id]
```

### Composite Index Column Order

Place the most selective (highest cardinality) column first, or the column used in equality conditions:

```ruby
# Good: status (equality) before created_at (range)
add_index :orders, [:status, :created_at]
# Supports: WHERE status = 'pending' AND created_at > 1.day.ago
# Supports: WHERE status = 'pending'
# Does NOT support: WHERE created_at > 1.day.ago (alone)
```

### Partial Indexes (PostgreSQL)

Index only rows that matter to reduce index size:

```ruby
add_index :orders, :created_at, where: "status = 'pending'", name: 'index_pending_orders'
```

## Query Optimization

### Select Only Needed Columns

```ruby
# Avoid SELECT * when only specific fields are needed
User.select(:id, :name, :email)

# Use pluck to get an array of values (skips model instantiation)
User.where(active: true).pluck(:email)
# => ["alice@example.com", "bob@example.com"]

# Use pick for a single value
User.where(email: "alice@example.com").pick(:id)
# => 42
```

### Efficient Existence and Counting

```ruby
# Check existence — stops at first match
User.where(email: email).exists?  # Better than .count > 0

# Count in database — avoids loading records
User.where(active: true).count    # Better than .all.size
```

### Batch Processing

Process large datasets without loading everything into memory:

```ruby
# find_each: loads in batches (default 1000)
User.find_each(batch_size: 1000) do |user|
  user.process!
end

# find_in_batches: yields arrays of records
User.find_in_batches(batch_size: 500) do |users|
  ElasticSearch.bulk_index(users)
end

# in_batches: yields ActiveRecord::Relation (supports update_all, delete_all)
User.where(active: false).in_batches(of: 1000) do |relation|
  relation.update_all(archived: true)
end
```

### Bulk Operations

Avoid N individual INSERT/UPDATE statements:

```ruby
# Bulk insert (skips validations and callbacks)
User.insert_all([{ name: 'A', email: 'a@example.com' }, { name: 'B', email: 'b@example.com' }])

# Bulk upsert
User.upsert_all(records, unique_by: :email)

# Bulk update
User.where(active: false).update_all(deleted_at: Time.current)

# Bulk delete
User.where('last_login_at < ?', 2.years.ago).delete_all
```

## Counter Caches

Avoid counting queries by maintaining a cached count column:

```ruby
# Migration
add_column :users, :posts_count, :integer, default: 0, null: false
User.find_each { |u| User.reset_counters(u.id, :posts) }

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Usage — reads column, no query
user.posts_count
```

### Custom Counter Cache Column

```ruby
belongs_to :user, counter_cache: :published_posts_count
```

## Pagination

Paginate all collections displayed in the UI to avoid loading entire tables:

```ruby
# Kaminari
@users = User.page(params[:page]).per(25)

# Pagy (faster, lower memory)
@pagy, @users = pagy(User.all, items: 25)
```

For API endpoints with large datasets, prefer cursor-based pagination over offset-based:

```ruby
# Cursor-based (stable under concurrent writes)
@users = User.where('id > ?', params[:after]).order(:id).limit(25)
```

## EXPLAIN and Query Analysis

Use EXPLAIN to understand query execution plans:

```ruby
# Rails EXPLAIN
User.where(active: true).explain
# => EXPLAIN for SELECT * FROM users WHERE active = true

# PostgreSQL EXPLAIN ANALYZE (shows actual execution time)
ActiveRecord::Base.connection.execute(
  "EXPLAIN ANALYZE SELECT * FROM users WHERE active = true"
)
```

### What to Look For

- **Seq Scan** on large tables — indicates a missing index
- **Nested Loop** with high row counts — consider a different join strategy
- **Sort** operations — add an index matching the ORDER BY
- **High cost estimates** — compare before and after adding indexes

## Database-Level Optimizations

### Connection Pooling

```ruby
# config/database.yml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  checkout_timeout: 5
```

For high-concurrency applications, use PgBouncer or a similar connection pooler in front of PostgreSQL.

### Advisory Locks

Prevent duplicate background job execution:

```ruby
ActiveRecord::Base.connection.execute("SELECT pg_advisory_lock(#{lock_id})")
# ... do work ...
ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
```

### Database Views for Complex Queries

Encapsulate complex reporting queries in database views:

```ruby
# Migration
execute <<~SQL
  CREATE VIEW active_user_stats AS
  SELECT users.id, users.name, COUNT(posts.id) as post_count
  FROM users
  JOIN posts ON posts.user_id = users.id
  WHERE users.active = true
  GROUP BY users.id, users.name
SQL

# Model
class ActiveUserStat < ApplicationRecord
  self.primary_key = :id
  def readonly? = true
end
```

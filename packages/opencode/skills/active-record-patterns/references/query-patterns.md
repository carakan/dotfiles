# Query Patterns

Detailed examples of ActiveRecord query optimization, scopes, and bulk operations for Rails 7+.

## Scopes

### Basic Scopes

```ruby
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(views_count: :desc) }
end
```

### Parameterized Scopes

```ruby
class Post < ApplicationRecord
  scope :by_author, ->(user) { where(user: user) }
  scope :created_after, ->(date) { where('created_at > ?', date) }
  scope :with_tag, ->(tag) { joins(:tags).where(tags: { name: tag }) }
end
```

### Chaining Scopes

```ruby
Post.published.recent.by_author(current_user).limit(10)
```

Scopes always return an `ActiveRecord::Relation`, making them chainable. Prefer scopes over class methods for simple query conditions.

## Preventing N+1 Queries

### The Problem

```ruby
# Triggers N+1 queries — one SELECT per user
users = User.all
users.each { |u| puts u.posts.count }
```

### Solutions

```ruby
# includes: Loads associations in separate query (or JOIN if filtering)
users = User.includes(:posts)
users.each { |u| puts u.posts.size }  # No additional queries

# preload: Always uses separate queries (best for large associations)
users = User.preload(:posts, :comments)

# eager_load: Always uses LEFT JOIN (needed for filtering on association)
users = User.eager_load(:posts).where(posts: { published: true })

# joins: For filtering only (does NOT load association data)
users = User.joins(:posts).where(posts: { published: true }).distinct
```

### Choosing a Loading Strategy

| Strategy     | SQL                | Loads data? | Filter on assoc? | Best for                    |
| ------------ | ------------------ | ----------- | ----------------- | --------------------------- |
| `includes`   | Separate or JOIN   | Yes         | Yes (auto-picks)  | General-purpose eager load  |
| `preload`    | Separate queries   | Yes         | No                | Large or multiple assocs    |
| `eager_load` | LEFT OUTER JOIN    | Yes         | Yes               | Filtering on association    |
| `joins`      | INNER JOIN         | No          | Yes               | Filtering without loading   |

## Selecting Specific Columns

```ruby
# Load only needed columns
users = User.select(:id, :name, :email)

# pluck: Returns array of values (no AR objects)
emails = User.where(active: true).pluck(:email)

# pick: Returns single value
latest_id = User.order(created_at: :desc).pick(:id)
```

## Batch Processing

For large datasets, avoid loading everything into memory:

```ruby
# find_each: Yields one record at a time
User.find_each(batch_size: 1000) do |user|
  user.send_newsletter
end

# in_batches: Yields a relation per batch
User.in_batches(of: 1000) do |users|
  users.update_all(newsletter_sent: true)
end

# find_in_batches: Yields an array per batch
User.find_in_batches(batch_size: 500) do |users_array|
  SomeExternalService.bulk_sync(users_array)
end
```

**Note:** Batch methods order by primary key and do not support custom ordering.

## Bulk Operations

```ruby
# insert_all: Skip validations and callbacks
User.insert_all([
  { email: 'a@example.com', name: 'A' },
  { email: 'b@example.com', name: 'B' }
])

# upsert_all: Insert or update on conflict
User.upsert_all(
  [{ email: 'a@example.com', name: 'Updated A' }],
  unique_by: :email
)

# update_all: Mass update (no callbacks)
User.where(active: false).where('last_login < ?', 1.year.ago).update_all(archived: true)

# delete_all: Mass delete (no callbacks)
User.where(archived: true).delete_all
```

## Counter Caches

For frequently counted associations, avoid `COUNT(*)` queries:

```ruby
# Migration
add_column :users, :posts_count, :integer, default: 0
User.find_each { |u| User.reset_counters(u.id, :posts) }

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Usage — no query needed
user.posts_count
```

## Advanced Query Patterns

### Subqueries

```ruby
# Find users with at least one published post
User.where(id: Post.where(published: true).select(:user_id))
```

### Merge

Combine scopes from different models:

```ruby
User.joins(:posts).merge(Post.published).distinct
```

### OR Queries

```ruby
User.where(role: 'admin').or(User.where(role: 'moderator'))
```

### Exists Checks

```ruby
# Efficient existence check — stops at first match
User.where(email: 'admin@example.com').exists?
```

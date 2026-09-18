# Query & Association Anti-Patterns

## Law of Demeter Violations

Reaching deep into object graphs creates tight coupling and makes code fragile when models change.

**Bad:**

```ruby
# Controller
@user.company.address.city
@order.customer.billing_address.zip_code
@post.author.profile.avatar_url

# View
<%= @order.line_items.first.product.category.name %>
```

**Good** — use delegation:

```ruby
class Order < ApplicationRecord
  belongs_to :customer
  delegate :billing_city, to: :customer
end

class Customer < ApplicationRecord
  has_one :billing_address, class_name: 'Address'
  delegate :city, to: :billing_address, prefix: :billing
end

# Usage
@order.billing_city
```

## Processing in Ruby Where SQL Suffices

Loading records into Ruby to filter, sort, or aggregate when the database can do it more efficiently.

**Bad:**

```ruby
# Loads ALL users into memory, then filters in Ruby
active_users = User.all.select { |u| u.last_login_at > 30.days.ago }

# Loads ALL orders, then sums in Ruby
total = Order.where(user: current_user).map(&:total).sum

# Sorts in Ruby instead of SQL
posts = Post.all.sort_by { |p| p.comments.count }.reverse
```

**Good** — let the database do the work:

```ruby
active_users = User.where('last_login_at > ?', 30.days.ago)

total = Order.where(user: current_user).sum(:total)

posts = Post.left_joins(:comments)
            .group(:id)
            .order('COUNT(comments.id) DESC')
```

## Missing Eager Loading (N+1 Queries)

Querying the database once per record in a collection. See `rails-performance` and `active-record-patterns` skills for comprehensive eager loading strategies.

**Bad:**

```ruby
# View iterates users and accesses association — N+1!
@users = User.all
# In view: user.posts.count triggers a query per user
```

**Good:**

```ruby
@users = User.includes(:posts)
# Or for counting specifically:
@users = User.left_joins(:posts)
             .select('users.*, COUNT(posts.id) AS posts_count')
             .group('users.id')
```

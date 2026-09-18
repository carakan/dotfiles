# Query Objects

Encapsulate complex, reusable database queries in dedicated objects. Query objects accept a base relation and return a refined relation, making them composable.

## Pattern

```ruby
# app/queries/active_users_query.rb
class ActiveUsersQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def call(since: 30.days.ago)
    @relation
      .where("last_sign_in_at > ?", since)
      .where(active: true)
      .order(last_sign_in_at: :desc)
  end
end
```

## Usage

```ruby
# Standalone
ActiveUsersQuery.new.call(since: 7.days.ago)

# Scoped to an organization
ActiveUsersQuery.new(Organization.find(1).users).call

# Composed with other queries
relation = ActiveUsersQuery.new.call(since: 7.days.ago)
PremiumUsersQuery.new(relation).call
```

## Key Principles

- **Accept a relation, return a relation** — This makes query objects composable with scopes and other query objects.
- **Default to `.all`** — Allow standalone usage without requiring a base relation.
- **Keep them read-only** — Query objects select and filter; they never create, update, or destroy records.
- **Place in `app/queries/`** — Separate from models and services for clear organization.

## When to Use

- The same multi-condition query appears in more than one place.
- A scope would be too complex or would clutter the model.
- Reporting or analytics queries that don't fit naturally on a model.
- Queries that need to be tested in isolation.

## Alternative: Scopes

For simple, single-model queries, prefer ActiveRecord scopes:

```ruby
class User < ApplicationRecord
  scope :active_since, ->(date) {
    where("last_sign_in_at > ?", date).where(active: true)
  }
end
```

Use query objects when the logic is complex, spans joins, or needs to be shared across unrelated parts of the application.

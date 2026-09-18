---
name: active-record-patterns
description: Use when designing model associations, adding validations, writing complex queries, or organizing model code. Also applies when choosing between has_many :through and HABTM, optimizing queries with eager loading, or setting up callbacks and scopes. Covers associations, validations, query optimization, and model organization.
---

# Active Record Patterns

Guidance for designing and implementing ActiveRecord models with proper associations, validations, queries, and performance optimizations in Rails 7+.

## Associations

ActiveRecord supports several association types. Always specify `:dependent` on `has_many` and `has_one`.

| Association                  | Use case                                          |
| ---------------------------- | ------------------------------------------------- |
| `belongs_to`                 | Child side of one-to-many or one-to-one           |
| `has_many`                   | Parent side of one-to-many                        |
| `has_one`                    | One-to-one relationship                           |
| `has_many :through`          | Many-to-many with join model (preferred)          |
| `has_and_belongs_to_many`    | Simple many-to-many without join model attributes |
| Polymorphic (`as:`)          | Single association pointing to multiple models    |
| Delegated type               | Rails 6.1+ alternative to STI                     |

For full code examples of each type, dependent options, and self-referential/delegated type patterns, consult **`references/associations.md`**.

## Validations

Apply validations to enforce data integrity at the model layer:

- **Presence/uniqueness** — `validates :email, presence: true, uniqueness: true`
- **Format** — `format: { with: /pattern/ }`
- **Numericality** — `numericality: { greater_than: 0 }`
- **Length** — `length: { minimum: 5, maximum: 200 }`
- **Conditional** — `if:` / `unless:` with method or lambda
- **Custom** — `validate :method_name` for complex rules
- **Contexts** — `on: :create` or custom contexts like `on: :registration`

For detailed examples of each validation type, custom validator classes, and a complete options reference, consult **`references/validations.md`**.

## Scopes

Define reusable query fragments as scopes. Scopes always return an `ActiveRecord::Relation`, making them chainable:

```ruby
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(user) { where(user: user) }
end

# Chain scopes together
Post.published.recent.by_author(current_user).limit(10)
```

Prefer scopes over class methods for simple query conditions.

## Query Optimization

### Preventing N+1 Queries

| Strategy     | Loads data? | Filter on assoc? | Best for                   |
| ------------ | ----------- | ----------------- | -------------------------- |
| `includes`   | Yes         | Yes (auto-picks)  | General-purpose eager load |
| `preload`    | Yes         | No                | Large or multiple assocs   |
| `eager_load` | Yes         | Yes               | Filtering on association   |
| `joins`      | No          | Yes               | Filtering without loading  |

### Key Techniques

- **Select specific columns** — `User.select(:id, :name)` or `pluck(:email)`
- **Batch processing** — `find_each` / `in_batches` for large datasets
- **Bulk operations** — `insert_all` / `upsert_all` for mass writes (skip callbacks)
- **Counter caches** — `belongs_to :user, counter_cache: true` to avoid COUNT queries
- **Subqueries** — `User.where(id: Post.published.select(:user_id))`
- **Existence checks** — `User.where(email: value).exists?` (stops at first match)

For full code examples of all query patterns, consult **`references/query-patterns.md`**.

## Callbacks

Use callbacks sparingly — only for model-centric operations:

```ruby
class User < ApplicationRecord
  before_validation :normalize_email
  before_save :encrypt_password, if: :password_changed?
  after_create :send_welcome_email
  after_destroy :cleanup_associated_files
end
```

**Callback order:** `before_validation` → `after_validation` → `before_save` → `before_create`/`before_update` → `after_create`/`after_update` → `after_save` → `after_commit`/`after_rollback`

**Avoid callbacks for:**
- External API calls (use background jobs)
- Complex business logic (use service objects)
- Sending emails (use background jobs)
- Audit logging (consider `after_commit` or a dedicated gem)

## Model Organization

Organize model code in a consistent order:

```ruby
class User < ApplicationRecord
  # 1. Includes and extends
  include Searchable

  # 2. Constants
  ROLES = %w[admin member guest].freeze

  # 3. Associations
  has_many :posts, dependent: :destroy
  has_one :profile, dependent: :destroy

  # 4. Validations
  validates :email, presence: true, uniqueness: true

  # 5. Scopes
  scope :active, -> { where(active: true) }

  # 6. Callbacks
  before_save :normalize_email

  # 7. Class methods
  def self.find_by_credentials(email, password)
    find_by(email: email)&.authenticate(password)
  end

  # 8. Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  # 9. Private methods
  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

## Quick Reference

| Need                  | Solution                         |
| --------------------- | -------------------------------- |
| Load association data | `includes(:association)`         |
| Filter by association | `joins(:association).where(...)` |
| Count without query   | Counter cache                    |
| Process large dataset | `find_each` or `in_batches`      |
| Bulk insert           | `insert_all`                     |
| Custom validation     | `validate :method_name`          |
| Reusable query        | `scope :name, -> { ... }`        |

## Additional Resources

### Reference Files

For detailed patterns and code examples, consult:
- **`references/associations.md`** — Association types, dependent options, polymorphic, delegated types
- **`references/validations.md`** — Validation patterns, custom validators, contexts, options reference
- **`references/query-patterns.md`** — N+1 prevention, scopes, batching, bulk operations, counter caches

# Model and Controller Convention Examples

## Association Naming

```ruby
class User < ApplicationRecord
  has_many :posts                    # Standard plural
  has_many :comments, through: :posts
  has_one :profile                   # Singular
  belongs_to :organization           # Singular
end

class Post < ApplicationRecord
  belongs_to :user                   # Singular
  belongs_to :author, class_name: 'User'  # Custom name
  has_many :comments, dependent: :destroy
end
```

### Polymorphic Associations

```ruby
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

class Post < ApplicationRecord
  has_many :comments, as: :commentable
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable
end
```

### Self-Referential Associations

```ruby
class Employee < ApplicationRecord
  belongs_to :manager, class_name: 'Employee', optional: true
  has_many :reports, class_name: 'Employee', foreign_key: :manager_id
end
```

### Single Table Inheritance (STI)

All subclasses share the base class table. Rails stores the class name in a `type` column.

```ruby
# Table: vehicles (with a `type` string column)
# app/models/vehicle.rb
class Vehicle < ApplicationRecord
  # shared behavior
end

# app/models/car.rb
class Car < Vehicle
  # Car-specific behavior
end

# app/models/truck.rb
class Truck < Vehicle
  # Truck-specific behavior
end
```

- **Table**: `vehicles` (plural of the base class — shared by all subclasses)
- **Type column**: `type` (string) — Rails sets this automatically
- **Files**: Each subclass gets its own file in `app/models/` (`car.rb`, `truck.rb`)
- **Migration**: `add_column :vehicles, :type, :string` (add index for query performance)

Prefer STI when subclasses share the same columns. Use polymorphic associations or delegated types when schemas diverge significantly.

## Validation Patterns

```ruby
class User < ApplicationRecord
  # Presence and uniqueness
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 }

  # Numericality
  validates :age, numericality: { greater_than: 0 }, allow_nil: true

  # Format
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: 'only lowercase letters, numbers, and hyphens' }

  # Conditional
  validates :company_name, presence: true, if: :business_account?

  # Custom
  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, 'must be after start date') if end_date <= start_date
  end
end
```

## Scope Naming

Name scopes after the condition they represent:

```ruby
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(user) { where(user: user) }
  scope :created_after, ->(date) { where('created_at > ?', date) }
end
```

### Scope Chaining

```ruby
# Scopes should be composable
Post.published.recent.by_author(current_user)

# Avoid scopes that return non-relation objects
# Bad: scope :latest, -> { order(created_at: :desc).first }
# Good: scope :latest, -> { order(created_at: :desc).limit(1) }
```

## Callback Conventions

```ruby
class User < ApplicationRecord
  # Use for simple, model-internal side effects
  before_validation :normalize_email
  after_create_commit :send_welcome_email

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

Avoid callbacks for complex business logic — use service objects instead (see `service-patterns` skill).

## Concern Patterns

### Model Concerns

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(query) { where('name ILIKE ?', "%#{query}%") }
  end

  class_methods do
    def searchable_columns
      raise NotImplementedError
    end
  end
end
```

### Controller Concerns

```ruby
# app/controllers/concerns/paginatable.rb
module Paginatable
  extend ActiveSupport::Concern

  private

  def page
    params.fetch(:page, 1).to_i
  end

  def per_page
    params.fetch(:per_page, 25).to_i.clamp(1, 100)
  end
end
```

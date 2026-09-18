# Validation Patterns

Detailed examples of ActiveRecord validation patterns for Rails 7+.

## Presence and Uniqueness

```ruby
class User < ApplicationRecord
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
end
```

## Numericality

```ruby
class Product < ApplicationRecord
  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
```

## Inclusion and Exclusion

```ruby
class User < ApplicationRecord
  validates :role, inclusion: { in: %w[admin member guest],
                                message: "%{value} is not a valid role" }
  validates :subdomain, exclusion: { in: %w[www admin api],
                                     message: "%{value} is reserved" }
end
```

## Format

```ruby
class User < ApplicationRecord
  validates :username, format: { with: /\A[a-zA-Z0-9_]+\z/,
                                 message: "only allows letters, numbers, and underscores" }
  validates :phone, format: { with: /\A\+?[\d\s\-()]+\z/ }, allow_blank: true
end
```

## Length

```ruby
class Post < ApplicationRecord
  validates :title, length: { minimum: 5, maximum: 200 }
  validates :body, length: { minimum: 50, message: "is too short (minimum 50 characters)" }
  validates :summary, length: { maximum: 500 }
end
```

## Conditional Validations

```ruby
class Order < ApplicationRecord
  validates :shipping_address, presence: true, if: :requires_shipping?
  validates :credit_card, presence: true, unless: -> { payment_method == 'invoice' }

  # Multiple conditions
  validates :tax_id, presence: true, if: [:business_account?, :eu_based?]
end
```

## Custom Validations

### Method-based

```ruby
class User < ApplicationRecord
  validate :password_complexity

  private

  def password_complexity
    return if password.blank?
    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add(:password, 'must include lowercase, uppercase, and digit')
    end
  end
end
```

### Custom Validator Class

```ruby
class EmailDomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    domain = value.split('@').last
    unless options[:allowed_domains].include?(domain)
      record.errors.add(attribute, "must be from an allowed domain")
    end
  end
end

class User < ApplicationRecord
  validates :email, email_domain: { allowed_domains: %w[company.com subsidiary.com] }
end
```

## Validation Contexts

```ruby
class User < ApplicationRecord
  validates :terms_accepted, acceptance: true, on: :registration
  validates :password, presence: true, on: :create
  validates :deletion_reason, presence: true, on: :deactivation
end

# Usage
user.save(context: :registration)
user.valid?(:deactivation)
```

## Common Validation Options

| Option           | Purpose                                         |
| ---------------- | ----------------------------------------------- |
| `allow_nil`      | Skip validation when value is nil               |
| `allow_blank`    | Skip validation when value is blank             |
| `on:`            | Run only in specified context (:create, :update) |
| `if:` / `unless:` | Conditional validation                         |
| `message:`       | Custom error message                            |
| `strict: true`   | Raise exception instead of adding error         |

# Model Anti-Patterns

## God Object

A model that accumulates unrelated responsibilities and grows to hundreds of lines.

**Bad:**

```ruby
class User < ApplicationRecord
  # Authentication
  has_secure_password
  def generate_token; end
  def reset_password; end

  # Billing
  def charge_subscription; end
  def update_payment_method; end
  def calculate_invoice; end

  # Notifications
  def send_welcome_email; end
  def send_weekly_digest; end
  def notify_followers; end

  # Reporting
  def activity_report; end
  def usage_statistics; end

  # ... 500+ more lines
end
```

**Good** — extract focused modules and service objects:

```ruby
class User < ApplicationRecord
  include Authenticatable   # Only auth-related model behavior
  has_many :subscriptions
  has_many :notifications
end

# Billing logic in service objects
# Notification delivery in background jobs
# Reporting in query objects
```

## Callback Hell

Chaining side effects through callbacks creates hidden, hard-to-debug execution flows.

**Bad:**

```ruby
class Order < ApplicationRecord
  after_create :send_confirmation_email
  after_create :notify_warehouse
  after_create :update_inventory
  after_create :charge_payment
  after_create :create_audit_log
  after_update :recalculate_totals
  after_update :sync_with_erp
  after_save :bust_cache
  before_destroy :refund_payment
  before_destroy :restore_inventory
end
```

Callbacks are appropriate for **data integrity operations intrinsic to the model** (e.g., normalizing an email before save). They are not appropriate for side effects like sending emails, calling external services, or orchestrating multi-step workflows.

**Good** — use a service object for orchestration:

```ruby
class Order < ApplicationRecord
  before_validation :set_reference_number

  private

  def set_reference_number
    self.reference_number ||= SecureRandom.hex(8)
  end
end

# Side effects live in the service that creates the order
class PlaceOrder
  def call
    ActiveRecord::Base.transaction do
      order = Order.create!(order_attrs)
      Inventory.reserve!(order.line_items)
    end
    SendConfirmationEmailJob.perform_later(order.id)
    NotifyWarehouseJob.perform_later(order.id)
    Result.success(order: order)
  end
end
```

## `default_scope` Abuse

`default_scope` applies to every query on the model, leading to surprising behavior and hard-to-find bugs.

**Bad:**

```ruby
class Article < ApplicationRecord
  default_scope { where(published: true) }
  default_scope { order(created_at: :desc) }
end

# Surprises:
Article.count          # Only counts published articles!
Article.find(123)      # Raises NotFound if article 123 is unpublished
Article.new            # Sets published: true by default
user.articles.count    # Only published, even in admin panel
```

**Good** — use explicit named scopes:

```ruby
class Article < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
end

# Explicit and clear
Article.published.recent
Article.count  # All articles
```

## Concerns as Junk Drawers

Using concerns to split a god object into multiple files without addressing the underlying design problem.

**Bad:**

```ruby
class User < ApplicationRecord
  include BillingConcern       # 200 lines of billing methods
  include NotificationConcern  # 150 lines of notification methods
  include ReportingConcern     # 100 lines of reporting methods
end
```

The User model is still a god object — the complexity is just spread across files.

**Good** — concerns should represent a single, reusable, cohesive behavior:

```ruby
# A focused concern for a single behavior
module Archivable
  extend ActiveSupport::Concern

  included do
    scope :archived, -> { where.not(archived_at: nil) }
    scope :active, -> { where(archived_at: nil) }
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def archived?
    archived_at.present?
  end
end
```

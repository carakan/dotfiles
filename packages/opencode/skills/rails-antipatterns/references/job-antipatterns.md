# Background Job Anti-Patterns

## Non-Idempotent Jobs

Jobs that produce duplicate side effects when retried (and jobs *will* be retried).

**Bad:**

```ruby
class ChargeCustomerJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    PaymentGateway.charge(order.total, order.customer.payment_token)
    order.update!(status: 'paid')
  end
end
# If the job crashes after charging but before updating status,
# a retry charges the customer twice.
```

**Good** — make jobs idempotent with guard clauses or idempotency keys:

```ruby
class ChargeCustomerJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    return if order.paid?

    PaymentGateway.charge(
      order.total,
      order.customer.payment_token,
      idempotency_key: "order-#{order.id}"
    )
    order.update!(status: 'paid')
  end
end
```

## Enqueueing Inside Transactions

Jobs enqueued inside a transaction can execute before the transaction commits, reading stale data.

**Bad:**

```ruby
ActiveRecord::Base.transaction do
  @order = Order.create!(order_params)
  @order.line_items.create!(line_item_params)
  ProcessOrderJob.perform_later(@order.id)  # May run before commit!
end
```

**Good** — enqueue after the transaction commits:

```ruby
ActiveRecord::Base.transaction do
  @order = Order.create!(order_params)
  @order.line_items.create!(line_item_params)
end

ProcessOrderJob.perform_later(@order.id)

# Or use after_commit callback on the model:
class Order < ApplicationRecord
  after_commit :enqueue_processing, on: :create

  private

  def enqueue_processing
    ProcessOrderJob.perform_later(id)
  end
end
```

## Complex Objects as Job Arguments

Passing ActiveRecord objects or complex data structures to jobs leads to serialization errors and stale data.

**Bad:**

```ruby
SendReceiptJob.perform_later(@order)           # Serializes entire object
NotifyJob.perform_later(user: @user, data: { items: @cart.items })
```

**Good** — pass only primitive IDs and let the job load fresh data:

```ruby
SendReceiptJob.perform_later(@order.id)
NotifyJob.perform_later(@user.id, @cart.id)

class SendReceiptJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    # Work with fresh data
  end
end
```

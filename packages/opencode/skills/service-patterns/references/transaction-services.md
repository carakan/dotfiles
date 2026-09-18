# Transaction Services

For operations that must succeed or fail atomically, wrap the logic in an `ActiveRecord::Base.transaction` block.

## Pattern

```ruby
# app/services/transfer_funds.rb
class TransferFunds
  include Callable

  def initialize(from:, to:, amount:)
    @from = from
    @to = to
    @amount = amount
  end

  def call
    ActiveRecord::Base.transaction do
      @from.withdraw!(@amount)
      @to.deposit!(@amount)
      record = create_transfer_record
      Result.success(transfer: record)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(errors: e.record.errors.full_messages)
  rescue InsufficientFundsError => e
    Result.failure(errors: [e.message])
  end

  private

  def create_transfer_record
    Transfer.create!(
      from_account: @from,
      to_account: @to,
      amount: @amount,
      completed_at: Time.current
    )
  end
end
```

## Key Principles

- Use bang methods (`create!`, `save!`) inside transactions so failures trigger a rollback.
- Rescue specific exceptions — never blanket `rescue StandardError`.
- Keep side effects (email, jobs) outside the transaction block. Enqueue them after a successful commit using `after_commit` or by checking the Result before dispatching.

## Nested Transactions

Rails wraps nested `transaction` blocks in savepoints by default. Be aware that a `rollback` in an inner block only rolls back to the savepoint unless `requires_new: true` is explicitly set:

```ruby
ActiveRecord::Base.transaction do
  # outer work
  ActiveRecord::Base.transaction(requires_new: true) do
    # inner work — rolls back independently on failure
  end
end
```

Avoid deep nesting. If a service composes multiple transactional services, consider orchestrating at a higher level with a single wrapping transaction.

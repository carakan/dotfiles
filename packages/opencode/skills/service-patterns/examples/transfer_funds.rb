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

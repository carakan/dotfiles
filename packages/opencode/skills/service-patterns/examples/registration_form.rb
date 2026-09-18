# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :company_name, :string
  attribute :plan, :string

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :company_name, presence: true
  validates :plan, inclusion: { in: %w[basic pro enterprise] }

  def save
    return Result.failure(errors: errors.full_messages) unless valid?

    ActiveRecord::Base.transaction do
      company = Company.create!(name: company_name, plan: plan)
      user = User.create!(email: email, password: password, company: company)
      Result.success(user: user, company: company)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(errors: e.record.errors.full_messages)
  end
end

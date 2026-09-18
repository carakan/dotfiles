# Form Objects

Handle complex form submissions that span multiple models by encapsulating validation and persistence in a single object backed by `ActiveModel`.

## Pattern

```ruby
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
```

## Usage in Controllers

```ruby
class RegistrationsController < ApplicationController
  def new
    @form = RegistrationForm.new
  end

  def create
    @form = RegistrationForm.new(registration_params)
    result = @form.save

    if result.success?
      redirect_to dashboard_path, notice: "Welcome!"
    else
      flash.now[:alert] = result.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:email, :password, :company_name, :plan)
  end
end
```

## Key Principles

- **Include `ActiveModel::Model`** — Gain validations, naming, and form builder compatibility for free.
- **Use `ActiveModel::Attributes`** — Declare typed attributes with defaults instead of raw `attr_accessor`.
- **Validate at the form level** — Catch errors before hitting the database. Model-level validations remain as a safety net.
- **Return a Result** — Keep the interface consistent with other service objects.
- **Place in `app/forms/`** — Separate from models to avoid confusion.

## When to Use

- A single form creates or updates records across multiple models.
- The form has validations that don't belong on any single model (e.g., password confirmation, terms acceptance).
- The controller `create` action is getting complex with multi-model orchestration.

## Working with Rails Form Builders

Form objects that include `ActiveModel::Model` work with `form_with` out of the box:

```erb
<%= form_with model: @form, url: registrations_path do |f| %>
  <%= f.text_field :email %>
  <%= f.password_field :password %>
  <%= f.text_field :company_name %>
  <%= f.select :plan, %w[basic pro enterprise] %>
  <%= f.submit "Register" %>
<% end %>
```

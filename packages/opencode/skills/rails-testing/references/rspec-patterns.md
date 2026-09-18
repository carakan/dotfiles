# RSpec Patterns for Rails

Detailed patterns and examples for testing Rails applications with RSpec.

## Essential Gems

```ruby
# Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'  # or 'playwright-driver'
  gem 'shoulda-matchers'
  gem 'webmock'
  gem 'vcr'
end
```

## Model Specs

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  # Associations (with shoulda-matchers)
  describe 'associations' do
    it { should belong_to(:organization).optional }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_one(:profile) }
  end

  # Validations
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  # Scopes
  describe 'scopes' do
    describe '.active' do
      let!(:active_user) { create(:user, active: true) }
      let!(:inactive_user) { create(:user, active: false) }

      it 'returns only active users' do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end
  end

  # Instance methods
  describe '#full_name' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

    it 'returns combined first and last name' do
      expect(user.full_name).to eq('John Doe')
    end

    context 'when last_name is nil' do
      let(:user) { build(:user, first_name: 'John', last_name: nil) }

      it 'returns only first name' do
        expect(user.full_name).to eq('John')
      end
    end
  end
end
```

## Request Specs

```ruby
# spec/requests/articles_spec.rb
RSpec.describe 'Articles', type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  describe 'GET /articles' do
    before { create_list(:article, 3, published: true) }

    it 'returns a list of articles' do
      get articles_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('articles')
    end
  end

  describe 'POST /articles' do
    let(:valid_params) { { article: { title: 'Test', body: 'Content' } } }

    context 'when logged in' do
      before { sign_in user }

      it 'creates a new article' do
        expect {
          post articles_path, params: valid_params
        }.to change(Article, :count).by(1)

        expect(response).to redirect_to(Article.last)
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        post articles_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /articles/:id' do
    before { sign_in user }

    it 'deletes the article' do
      article # create it

      expect {
        delete article_path(article)
      }.to change(Article, :count).by(-1)
    end
  end
end
```

## System Specs

```ruby
# spec/system/user_registration_spec.rb
RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'allows a user to sign up' do
    visit new_user_registration_path

    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    click_button 'Sign up'

    expect(page).to have_content('Welcome')
    expect(page).to have_current_path(root_path)
  end

  it 'shows errors for invalid registration' do
    visit new_user_registration_path
    click_button 'Sign up'

    expect(page).to have_content("Email can't be blank")
  end
end
```

## FactoryBot

### Factory Definitions

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { 'password123' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end

    factory :admin_user, traits: [:admin]
  end
end

# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    user
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    published { false }

    trait :published do
      published { true }
      published_at { Time.current }
    end
  end
end
```

### Factory Usage

```ruby
# Build (in memory, not persisted)
user = build(:user)

# Create (persisted to database)
user = create(:user)

# Create with attribute overrides
user = create(:user, name: 'Custom Name')

# Create with trait
admin = create(:user, :admin)

# Create list
users = create_list(:user, 5)

# Build attributes hash (useful for request params)
attributes = attributes_for(:user)
```

## Shared Examples and Contexts

### Shared Examples

```ruby
# spec/support/shared_examples/authenticatable.rb
RSpec.shared_examples 'requires authentication' do
  it 'redirects to login when not authenticated' do
    expect(response).to redirect_to(new_user_session_path)
  end
end

# Usage
describe 'GET /admin/dashboard' do
  before { get admin_dashboard_path }
  it_behaves_like 'requires authentication'
end
```

### Shared Contexts

```ruby
# spec/support/shared_contexts/authenticated_user.rb
RSpec.shared_context 'authenticated user' do
  let(:current_user) { create(:user) }
  before { sign_in current_user }
end

# Usage
describe 'POST /articles' do
  include_context 'authenticated user'

  it 'creates an article' do
    post articles_path, params: { article: attributes_for(:article) }
    expect(response).to have_http_status(:created)
  end
end
```

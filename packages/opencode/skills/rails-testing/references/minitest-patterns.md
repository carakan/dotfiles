# Minitest Patterns for Rails

Detailed patterns and examples for testing Rails applications with Minitest.

## Model Tests

```ruby
# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'should not save user without email' do
    user = User.new(name: 'Test')
    assert_not user.save, 'Saved user without email'
  end

  test 'email should be unique' do
    user = User.new(email: users(:john).email, name: 'Another')
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'full_name returns combined name' do
    user = users(:john)
    user.first_name = 'John'
    user.last_name = 'Doe'
    assert_equal 'John Doe', user.full_name
  end
end
```

## Controller Tests

```ruby
# test/controllers/articles_controller_test.rb
require 'test_helper'

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:one)
    @user = users(:john)
  end

  test 'should get index' do
    get articles_url
    assert_response :success
  end

  test 'should create article when logged in' do
    sign_in @user

    assert_difference('Article.count') do
      post articles_url, params: {
        article: { title: 'New Article', body: 'Content' }
      }
    end

    assert_redirected_to article_url(Article.last)
  end

  test 'should not create article when not logged in' do
    assert_no_difference('Article.count') do
      post articles_url, params: {
        article: { title: 'New Article', body: 'Content' }
      }
    end

    assert_redirected_to new_user_session_url
  end
end
```

## System Tests

```ruby
# test/system/user_registration_test.rb
require 'application_system_test_case'

class UserRegistrationTest < ApplicationSystemTestCase
  test 'allows a user to sign up' do
    visit new_user_registration_url

    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    click_on 'Sign up'

    assert_text 'Welcome'
  end

  test 'shows errors for invalid registration' do
    visit new_user_registration_url
    click_on 'Sign up'

    assert_text "Email can't be blank"
  end
end
```

## Fixtures

```yaml
# test/fixtures/users.yml
john:
  email: john@example.com
  name: John Doe
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>

jane:
  email: jane@example.com
  name: Jane Doe
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>

# test/fixtures/articles.yml
one:
  user: john
  title: First Article
  body: This is the content
  published: true

two:
  user: jane
  title: Second Article
  body: More content
  published: false
```

### Fixture Usage

```ruby
# Access fixture by name
user = users(:john)
article = articles(:one)

# Fixtures are loaded into the test database before each test
# Access via the pluralized model name method
```

## Parallelize Tests

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
end
```

## Custom Assertions

```ruby
# test/support/custom_assertions.rb
module CustomAssertions
  def assert_valid(record, message = nil)
    assert record.valid?, message || "Expected #{record.class} to be valid: #{record.errors.full_messages.join(', ')}"
  end

  def assert_invalid(record, *attributes)
    assert_not record.valid?
    attributes.each do |attr|
      assert record.errors[attr].any?, "Expected errors on #{attr}"
    end
  end
end

# Include in test_helper.rb
class ActiveSupport::TestCase
  include CustomAssertions
end
```

---
name: rails-testing
description: Use when writing or debugging tests in a Rails application, setting up test infrastructure, or choosing between RSpec and Minitest patterns. Also applies when creating factories, fixtures, shared examples, or mocking external services. Covers test strategy, framework detection, directory structure, and common patterns for all test types.
---

# Rails Testing

Guidance for testing Rails applications using RSpec or Minitest, covering test strategy, framework conventions, and common patterns.

## Testing Workflow

Follow this process when writing or modifying tests:

1. **Detect the framework** — check for `spec/` (RSpec) or `test/` (Minitest)
2. **Identify the test type** — model, request/controller, system, job, or mailer
3. **Study existing tests** — match the project's style, helpers, and conventions
4. **Write the test** — follow Arrange-Act-Assert, one assertion per test
5. **Run and verify** — ensure the test passes and covers the intended behavior

## Framework Detection

Check project structure to determine the testing framework:

- `spec/` directory with `_spec.rb` files → **RSpec** (with FactoryBot for test data)
- `test/` directory with `_test.rb` files → **Minitest** (with YAML fixtures for test data)

## Directory Structures

### RSpec

```
spec/
├── models/           # Model specs
├── requests/         # Request/controller specs
├── system/           # System specs (browser testing)
├── jobs/             # Background job specs
├── mailers/          # Mailer specs
├── support/          # Shared helpers, custom matchers
├── factories/        # FactoryBot factories
├── rails_helper.rb   # Rails-specific config
└── spec_helper.rb    # RSpec config
```

### Minitest

```
test/
├── models/           # Model tests
├── controllers/      # Controller tests (integration)
├── system/           # System tests
├── jobs/             # Job tests
├── mailers/          # Mailer tests
├── fixtures/         # YAML fixtures
├── test_helper.rb    # Test configuration
└── application_system_test_case.rb
```

## Test Writing Principles

### Arrange-Act-Assert

```ruby
it 'updates the user' do
  # Arrange
  user = create(:user, name: 'Old Name')

  # Act
  user.update(name: 'New Name')

  # Assert
  expect(user.reload.name).to eq('New Name')
end
```

### One Assertion Per Test

```ruby
# Focused tests — each verifies one behavior
it 'returns created status' do
  post users_path, params: valid_params
  expect(response).to have_http_status(:created)
end

it 'creates a user' do
  expect { post users_path, params: valid_params }.to change(User, :count).by(1)
end
```

### Test Behavior, Not Implementation

```ruby
# Good: tests observable behavior
it 'sends welcome email after registration' do
  expect { user.register! }.to have_enqueued_mail(UserMailer, :welcome)
end

# Bad: tests internal method calls
it 'calls the mailer' do
  expect(UserMailer).to receive(:welcome).with(user)
  user.register!
end
```

### Use `build` Over `create` When Possible

Prefer `build(:user)` (in-memory) over `create(:user)` (persisted) when database state is not needed. This speeds up tests significantly.

### Keep Tests Independent

Each test should set up its own data and not depend on ordering or shared mutable state. Use `let` (RSpec) or `setup` (Minitest) for per-test setup.

## Quick Reference

| Test Type          | RSpec Location | Minitest Location |
| ------------------ | -------------- | ----------------- |
| Model              | spec/models/   | test/models/      |
| Controller/Request | spec/requests/ | test/controllers/ |
| System             | spec/system/   | test/system/      |
| Job                | spec/jobs/     | test/jobs/        |
| Mailer             | spec/mailers/  | test/mailers/     |

| Need             | RSpec                       | Minitest            |
| ---------------- | --------------------------- | ------------------- |
| Create test data | `create(:user)`             | `users(:john)`      |
| Assert equal     | `expect(x).to eq(y)`        | `assert_equal y, x` |
| Assert true      | `expect(x).to be true`      | `assert x`          |
| Assert raises    | `expect { }.to raise_error` | `assert_raises { }` |
| Assert changes   | `expect { }.to change { }`  | `assert_difference` |

## Running Tests

```bash
# RSpec
bundle exec rspec                    # all specs
bundle exec rspec spec/models/       # model specs only
bundle exec rspec spec/models/user_spec.rb:42  # single example

rails test                           # all tests
rails test test/models/              # model tests only
rails test test/models/user_test.rb:15  # single test
```

## Additional Resources

### Reference Files

For detailed code examples and patterns, consult:

- **`references/rspec-patterns.md`** — Model specs, request specs, system specs, FactoryBot definitions, shared examples and contexts
- **`references/minitest-patterns.md`** — Model tests, controller tests, system tests, fixtures, custom assertions, parallel testing
- **`references/mocking-services.md`** — WebMock stubbing, VCR cassette recording, choosing between the two

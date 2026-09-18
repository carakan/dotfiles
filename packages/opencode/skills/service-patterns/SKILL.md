---
name: service-patterns
description: Use when controller actions grow beyond simple CRUD, business logic spans multiple models, or operations involve external APIs or multi-step transactions. Also applies when deciding whether to extract a service object, form object, or query object. Covers the Callable concern, Result objects, and file organization patterns.
---

# Rails Service Patterns

Extract business logic that spans multiple models or involves external systems into service objects to promote single responsibility, testability, and reusability.

## When to Extract a Service

**Indicators for service extraction:**

- Business logic spans multiple models
- An operation involves external API calls
- Multi-step operations need transaction safety
- Logic violates single responsibility in a model
- Controller actions grow beyond simple CRUD
- The same logic is needed in multiple places (controller, job, rake task)

**Keep logic in the model when:**

- It naturally fits as a model concern (validations, scopes, associations)
- A single ActiveRecord operation is sufficient
- A model callback is more appropriate

## Pattern Overview

| Pattern              | Use When                       | Location                   |
| -------------------- | ------------------------------ | -------------------------- |
| Service Object       | Multi-model business logic     | `app/services/`            |
| Transaction Service  | Atomic multi-step operations   | `app/services/`            |
| External API Service | Third-party integrations       | `app/services/<provider>/` |
| Query Object         | Complex, reusable queries      | `app/queries/`             |
| Form Object          | Multi-model form submissions   | `app/forms/`               |
| Result Object        | Consistent service return type | `app/services/result.rb`   |

## Callable Concern

DRY up the repeated `.call` class method across services with a shared concern. See `examples/callable.rb` for the full implementation.

```ruby
module Callable
  extend ActiveSupport::Concern

  class_methods do
    def call(...)
      new(...).call
    end
  end
end
```

Include in every service to get `MyService.call(args)` delegation to `new(args).call`.

## Basic Service Object

A minimal service with the `Callable` concern and `Result` return type:

```ruby
class CreatePost
  include Callable

  def initialize(params, user)
    @params = params
    @user = user
  end

  def call
    post = @user.posts.build(@params)

    if post.save
      NotifyFollowersJob.perform_later(post.id)
      Result.success(post: post)
    else
      Result.failure(errors: post.errors.full_messages)
    end
  end
end
```

See `examples/create_post.rb` for the full example.

## File Organization

```
app/
├── services/
│   ├── concerns/
│   │   └── callable.rb
│   ├── result.rb
│   ├── create_post.rb
│   ├── transfer_funds.rb
│   └── github/
│       └── create_issue.rb
├── queries/
│   └── active_users_query.rb
└── forms/
    └── registration_form.rb
```

## Testing Services

Test services through their `.call` interface. Assert on Result success/failure and side effects. Both RSpec and Minitest examples are available in `examples/`:

- **`examples/create_post_spec.rb`** — RSpec example
- **`examples/create_post_test.rb`** — Minitest example

## Design Principles

1. **Single responsibility** — One service does one thing
2. **Clear interface** — `.call` class method with explicit parameters
3. **Consistent return type** — Always return a Result object
4. **Proper error handling** — Rescue specific exceptions, never swallow errors
5. **Testability** — Easy to test in isolation, injectable dependencies
6. **Immutability** — Never modify input arguments

## Additional Resources

### Reference Files

For detailed implementations, patterns, and alternatives:

- **`references/result-object.md`** — Full Result implementation, Struct-based alternative, and `dry-monads` approach
- **`references/transaction-services.md`** — Transaction wrapping, nested transactions, and side-effect management
- **`references/external-api-services.md`** — API wrapper pattern with error handling, timeouts, and retry guidance
- **`references/query-objects.md`** — Query object pattern, composability, and when to prefer scopes
- **`references/form-objects.md`** — Multi-model forms with `ActiveModel`, validations, and form builder integration

### Example Files

Working code in `examples/`:

- **`examples/callable.rb`** — Callable concern to DRY up `.call` boilerplate
- **`examples/create_post.rb`** — Basic service object
- **`examples/transfer_funds.rb`** — Transaction service
- **`examples/registration_form.rb`** — Form object
- **`examples/create_post_spec.rb`** — RSpec test example
- **`examples/create_post_test.rb`** — Minitest test example

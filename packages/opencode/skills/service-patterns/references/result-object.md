# Result Object Pattern

A consistent return type for services that communicates success or failure with structured data.

## Hand-Rolled Implementation

```ruby
# app/services/result.rb
class Result
  attr_reader :data, :errors

  def initialize(success:, data: {}, errors: [])
    @success = success
    @data = data
    @errors = Array(errors)
  end

  def success? = @success
  def failure? = !@success

  def self.success(**data)
    new(success: true, data: data)
  end

  def self.failure(errors:)
    new(success: false, errors: Array(errors))
  end

  # Access data attributes as methods
  def method_missing(method, ...)
    @data.key?(method) ? @data[method] : super
  end

  def respond_to_missing?(method, include_private = false)
    @data.key?(method) || super
  end
end
```

## Usage in Controllers

```ruby
class PostsController < ApplicationController
  def create
    result = CreatePost.call(post_params, current_user)

    if result.success?
      redirect_to result.post, notice: 'Post created.'
    else
      @errors = result.errors
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Alternative Approaches

### Struct-Based Result

A simpler approach using Ruby's built-in Struct:

```ruby
class Result < Struct.new(:success, :data, :errors, keyword_init: true)
  def success? = success
  def failure? = !success

  def self.success(**data)
    new(success: true, data: data, errors: [])
  end

  def self.failure(errors:)
    new(success: false, data: {}, errors: Array(errors))
  end
end
```

### dry-monads

The `dry-monads` gem provides a mature, composable Result type with `Success` and `Failure`:

```ruby
# Gemfile
gem 'dry-monads'

# app/services/create_post.rb
class CreatePost
  include Dry::Monads[:result]

  def call(params, user)
    post = user.posts.build(params)
    if post.save
      Success(post: post)
    else
      Failure(errors: post.errors.full_messages)
    end
  end
end
```

`dry-monads` also supports `do notation` for chaining operations and railway-oriented programming. Consider it for larger codebases with many service objects.

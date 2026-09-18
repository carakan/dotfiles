# Association Patterns

Detailed examples of ActiveRecord association types for Rails 7+.

## belongs_to

The child side of a one-to-many or one-to-one relationship:

```ruby
class Post < ApplicationRecord
  belongs_to :user                    # Required by default in Rails 5+
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :category, optional: true  # Allow nil
end
```

## has_many

The parent side of a one-to-many relationship:

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :active_posts, -> { where(published: true) }, class_name: 'Post'
end
```

## has_one

A one-to-one relationship:

```ruby
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :most_recent_post, -> { order(created_at: :desc) }, class_name: 'Post'
end
```

## has_many :through

Many-to-many with a join model — preferred over HABTM when the join needs attributes or callbacks:

```ruby
class User < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
end

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :team
  # Can have additional attributes: role, joined_at, etc.
end

class Team < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
end
```

## has_and_belongs_to_many

Simple many-to-many without join model attributes. Generally prefer `has_many :through` for flexibility:

```ruby
class Post < ApplicationRecord
  has_and_belongs_to_many :tags
end

class Tag < ApplicationRecord
  has_and_belongs_to_many :posts
end
# Requires posts_tags join table (alphabetical order, no id column)
```

## Polymorphic Associations

```ruby
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

class Post < ApplicationRecord
  has_many :comments, as: :commentable
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable
end
```

## Dependent Options

Always specify `:dependent` for `has_many` and `has_one`:

| Option                     | Behavior                                                     |
| -------------------------- | ------------------------------------------------------------ |
| `:destroy`                 | Calls destroy on each associated record (triggers callbacks) |
| `:delete_all`              | Deletes directly from database (no callbacks)                |
| `:nullify`                 | Sets foreign key to NULL                                     |
| `:restrict_with_error`     | Prevents deletion if associated records exist                |
| `:restrict_with_exception` | Raises exception if associated records exist                 |

### Choosing a Dependent Option

- Use `:destroy` when associated records have their own callbacks or dependents.
- Use `:delete_all` for large collections where callbacks are unnecessary (performance).
- Use `:nullify` when associated records should persist but lose their parent reference.
- Use `:restrict_with_error` to prevent accidental deletion in user-facing flows.
- Use `:restrict_with_exception` to prevent deletion at the application level (catches programming errors).

## Self-Referential Associations

```ruby
class Employee < ApplicationRecord
  belongs_to :manager, class_name: 'Employee', optional: true
  has_many :reports, class_name: 'Employee', foreign_key: 'manager_id',
                     dependent: :nullify
end
```

## Delegated Types

Rails 6.1+ alternative to STI for shared interfaces:

```ruby
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[Message Comment]
end

class Message < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
end

class Comment < ApplicationRecord
  has_one :entry, as: :entryable, touch: true
end
```

# Migration Anti-Patterns

## Mixing Schema and Data Migrations

Combining structural changes with data manipulation makes migrations fragile and hard to reverse.

**Bad:**

```ruby
class AddStatusToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :status, :string, default: 'pending'

    # Data migration mixed in — breaks if run on empty database
    Order.where(completed: true).update_all(status: 'completed')
    Order.where(completed: false).update_all(status: 'pending')

    remove_column :orders, :completed
  end
end
```

**Good** — separate schema and data migrations:

```ruby
# Migration 1: Add column
class AddStatusToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :status, :string, default: 'pending'
  end
end

# Migration 2: Backfill data (or use a rake task)
class BackfillOrderStatus < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE orders SET status = CASE WHEN completed THEN 'completed' ELSE 'pending' END
    SQL
  end

  def down
    # no-op, column still exists
  end
end

# Migration 3: Remove old column (after backfill is verified)
class RemoveCompletedFromOrders < ActiveRecord::Migration[7.1]
  def change
    remove_column :orders, :completed, :boolean
  end
end
```

## Referencing Models in Migrations

Using model classes in migrations breaks when the model changes or is deleted later.

**Bad:**

```ruby
class PopulateDefaultRoles < ActiveRecord::Migration[7.1]
  def up
    Role.create!(name: 'admin')       # Breaks if Role model changes
    Role.create!(name: 'member')      # Breaks if validations are added
    User.find_each do |user|          # Breaks if User model is renamed
      user.update!(role: 'member')
    end
  end
end
```

**Good** — use raw SQL or inline model stubs:

```ruby
class PopulateDefaultRoles < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      INSERT INTO roles (name, created_at, updated_at)
      VALUES ('admin', NOW(), NOW()), ('member', NOW(), NOW())
    SQL

    execute <<~SQL
      UPDATE users SET role = 'member' WHERE role IS NULL
    SQL
  end

  def down
    execute "DELETE FROM roles WHERE name IN ('admin', 'member')"
  end
end
```

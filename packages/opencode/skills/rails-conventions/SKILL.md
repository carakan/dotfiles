---
name: rails-conventions
description: Use when creating new Rails files, naming models/controllers/views, organizing directories, or when unsure about Rails naming conventions. Also applies when reviewing code for convention violations like incorrect pluralization, wrong file locations, or non-standard naming. Covers file structure, naming patterns for models, controllers, views, routes, jobs, mailers, and migrations.
---

# Rails Conventions and Best Practices

Guidance for following Rails conventions, file organization, naming patterns, and "The Rails Way" for Rails 7+ applications.

## Core Principles

### Convention over Configuration

Rails provides sensible defaults. Follow conventions to benefit from:

- Automatic file loading and discovery
- Reduced configuration overhead
- Consistency across Rails projects
- Easier onboarding for new developers

### The Rails Way

- **DRY (Don't Repeat Yourself)**: Extract shared logic into concerns, helpers, or services
- **Fat Models, Skinny Controllers**: Business logic belongs in models, not controllers
- **RESTful Resources**: Design around resources with standard CRUD actions
- **Prefer Convention**: Only customize when Rails conventions don't fit

## File Structure

### Standard Directory Layout

```
app/
├── assets/           # CSS, images, fonts (managed by asset pipeline)
├── channels/         # Action Cable channels
├── components/       # ViewComponents (if used)
├── controllers/      # Request handlers
│   ├── concerns/     # Shared controller logic
│   └── api/          # API controllers (namespaced)
├── helpers/          # View helpers
├── javascript/       # JavaScript/Stimulus controllers
├── jobs/             # Background jobs
├── mailers/          # Email senders
├── models/           # ActiveRecord models
│   └── concerns/     # Shared model logic
├── services/         # Service objects (optional)
├── views/            # Templates and partials
│   ├── layouts/      # Application layouts
│   └── shared/       # Shared partials
config/
├── routes.rb         # Routing configuration
├── database.yml      # Database configuration
├── environments/     # Environment-specific settings
└── initializers/     # Startup configuration
db/
├── migrate/          # Database migrations
├── schema.rb         # Current schema (auto-generated)
└── seeds.rb          # Seed data
lib/
├── tasks/            # Rake tasks
└── generators/       # Custom generators
spec/ or test/        # Test files (mirrors app/ structure)
```

## Naming Conventions

### Models

- **Class**: Singular, PascalCase (`User`, `OrderItem`, `BlogPost`)
- **File**: Singular, snake_case (`user.rb`, `order_item.rb`, `blog_post.rb`)
- **Table**: Plural, snake_case (`users`, `order_items`, `blog_posts`)
- **Foreign key**: Singular model name + `_id` (`user_id`, `order_item_id`)

### Controllers

- **Class**: Plural, PascalCase + Controller (`UsersController`, `OrderItemsController`)
- **File**: Plural, snake_case (`users_controller.rb`, `order_items_controller.rb`)
- **Actions**: Lowercase (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`)

### Views

- **Directory**: Plural, snake_case (`app/views/users/`)
- **Template**: Action name + format + handler (`index.html.erb`, `show.json.jbuilder`)
- **Partial**: Underscore prefix (`_form.html.erb`, `_user.html.erb`)

### Routes

- **Resource**: Plural (`resources :users`, `resources :order_items`)
- **Singular Resource**: Singular (`resource :profile`, `resource :dashboard`)

### Jobs, Mailers, and Migrations

- **Job class**: Descriptive + Job (`SendWelcomeEmailJob`, `ProcessPaymentJob`)
- **Mailer class**: Descriptive + Mailer (`UserMailer`, `OrderMailer`)
- **Mailer methods**: Descriptive action (`welcome_email`, `order_confirmation`)
- **Migration file**: Timestamp + descriptive name (`20240101120000_create_users.rb`)
- **Migration class**: Descriptive PascalCase (`CreateUsers`, `AddEmailToUsers`)

## Quick Reference

| What        | Convention          | Example            |
| ----------- | ------------------- | ------------------ |
| Model class | Singular PascalCase | `User`             |
| Model file  | Singular snake_case | `user.rb`          |
| Table       | Plural snake_case   | `users`            |
| Controller  | Plural + Controller | `UsersController`  |
| View folder | Plural snake_case   | `views/users/`     |
| Route       | Plural resource     | `resources :users` |
| Foreign key | model_id            | `user_id`          |
| Join table  | Alphabetical        | `posts_tags`       |

Follow these conventions consistently to create maintainable Rails applications that are easy to understand and extend.

## Additional Resources

### Reference Files

For detailed code examples and patterns, consult:

- **`references/restful-design.md`** — Standard REST actions table, custom actions, nested resources, namespace/scope patterns, and controller structure
- **`references/model-controller-examples.md`** — Association naming, polymorphic/self-referential associations, validation patterns, scope naming and chaining, callback conventions, and concern patterns

### Related Skills

- **`service-patterns`** — Service objects, form objects, query objects, and interactors
- **`active-record-patterns`** — ActiveRecord query and association patterns in depth
- **`action-controller-patterns`** — Controller design patterns and advanced techniques
- **`rails-antipatterns`** — Common anti-patterns, code smells, and refactoring guidance

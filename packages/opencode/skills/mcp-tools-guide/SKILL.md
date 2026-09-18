---
name: mcp-tools-guide
description: Use when needing to analyze a Rails codebase programmatically — inspecting models, schemas, routes, or controllers. Also applies when looking up library documentation or tracing method definitions across files. Covers Rails MCP Server tools, Context7 documentation queries, and Ruby LSP code intelligence.
---

# MCP Tools Guide for Rails Development

Three MCP servers are available for Rails development. Use them to analyze codebases faster and more accurately than reading files manually.

## Rails MCP Server

The primary tool for Rails codebase analysis.

### Tool Discovery

```text
mcp__rails__search_tools
```

Returns available analyzers organized by category:

- **models** — Model analysis, associations, validations
- **database** — Schema, migrations, indexes
- **routing** — Route analysis and listing
- **controllers** — Controller structure, actions, filters
- **files** — File listing and reading
- **project** — Project-wide analysis
- **guides** — Rails guides and documentation

### Execute Analyzers

```text
mcp__rails__execute_tool(tool_name: "tool_name", params: {...})
```

| Tool                 | Purpose                                 | Example Params                           |
| -------------------- | --------------------------------------- | ---------------------------------------- |
| `analyze_models`     | Model associations, validations, scopes | `{ model_name: "User" }` (optional)      |
| `get_schema`         | Database schema and indexes             | `{}`                                     |
| `get_routes`         | Application routing table               | `{}`                                     |
| `analyze_controller` | Controller actions and filters          | `{ controller_name: "UsersController" }` |
| `list_files`         | Find files by pattern                   | `{ pattern: "app/models/**/*.rb" }`      |
| `get_file`           | Read a specific file                    | `{ path: "app/models/user.rb" }`         |

### Ruby Execution

```text
mcp__rails__execute_ruby(code: "...")
```

Read-only Ruby execution for custom analysis. Common queries:

```ruby
# Model introspection
User.reflect_on_all_associations.map { |a| [a.macro, a.name] }
User.validators.map { |v| [v.class.name, v.attributes] }

# Database introspection
ActiveRecord::Base.connection.indexes(:users).map(&:columns)
ActiveRecord::Base.connection.columns(:users).map { |c| [c.name, c.type] }

# Migration status
ActiveRecord::Base.connection.execute(
  "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 10"
)

# Route inspection
Rails.application.routes.routes.map { |r|
  [r.verb, r.path.spec.to_s, r.defaults[:controller], r.defaults[:action]].join(' ')
}

# File discovery
Dir.glob('app/services/**/*.rb')
Dir.glob('app/javascript/controllers/**/*.js')
Dir.glob('app/views/**/*.turbo_stream.erb')
Dir.glob('app/channels/**/*.rb')
Dir.glob('app/components/**/*.rb')
Dir.glob('spec/**/*_spec.rb')
Dir.glob('spec/factories/**/*.rb')
Dir.glob('spec/support/**/*.rb')
```

## Context7 MCP Server

Retrieves up-to-date documentation and code examples for any library.

### Workflow

1. **Resolve library ID first:**

   ```text
   mcp__plugin_context7_context7__resolve-library-id(
     libraryName: "rails",
     query: "your question"
   )
   ```

2. **Query documentation:**
   ```text
   mcp__plugin_context7_context7__query-docs(
     libraryId: "/rails/rails",
     query: "your question"
   )
   ```

### When to Use

- Verifying current Rails API behavior or method signatures
- Looking up gem documentation (Devise, Pundit, Sidekiq, etc.)
- Checking for deprecations in newer Rails versions
- Finding code examples for specific patterns
- Confirming configuration options and defaults

### Common Library IDs

| Library     | ID                   |
| ----------- | -------------------- |
| Rails       | `/rails/rails`       |
| Ruby        | `/ruby/ruby`         |
| Devise      | `/heartcombo/devise` |
| Pundit      | `/varvet/pundit`     |
| RSpec       | `/rspec/rspec`       |
| RSpec Rails | `/rspec/rspec-rails` |

For other gems, always call `resolve-library-id` first.

## Ruby LSP

Language-aware intelligence for Ruby code. Tools use the `mcp__ruby-lsp__` prefix.

### Key Tools

```text
mcp__ruby-lsp__definition(uri: "file:///path/to/file.rb", line: 10, character: 5)
```

Jump to the definition of a method, class, or module at a given position.

```text
mcp__ruby-lsp__references(uri: "file:///path/to/file.rb", line: 10, character: 5)
```

Find all usages of a symbol across the codebase.

```text
mcp__ruby-lsp__symbol(query: "UserPolicy")
```

Search for classes, modules, and methods by name across the workspace.

### Other Capabilities

- **Type checking** — Infer and validate types at a given position
- **Intelligent completions** — Context-aware code suggestions
- **Diagnostics** — Identify issues in Ruby code

### When to Use

- When Rails MCP tools don't provide enough detail about specific method implementations
- When tracing method calls across the codebase
- When investigating inheritance hierarchies or module mixins
- When locating all callers of a method before refactoring

## Quick Reference

| Need                     | Tool                                          |
| ------------------------ | --------------------------------------------- |
| Understand models/schema | Rails MCP: `analyze_models`, `get_schema`     |
| Check routes             | Rails MCP: `get_routes`                       |
| Analyze controllers      | Rails MCP: `analyze_controller`               |
| Find files               | Rails MCP: `list_files`                       |
| Custom analysis          | Rails MCP: `execute_ruby`                     |
| Verify API docs          | Context7: `resolve-library-id` + `query-docs` |
| Navigate code            | Ruby LSP: `definition`, `references`          |
| Find symbols             | Ruby LSP: `symbol`                            |

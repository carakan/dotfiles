---
name: rails-antipatterns
description: Use when reviewing Rails code for quality issues, refactoring problematic code, or encountering symptoms like fat controllers, god models, callback chains with side effects, N+1 queries, logic-heavy views, or non-idempotent background jobs. Covers controller, model, query, view, job, and migration anti-patterns with bad/good examples and fixes.
---

# Rails Anti-Patterns

A guide to recognizing and fixing common anti-patterns in Rails applications. Each reference file shows what to avoid (Bad), explains why it's problematic, and demonstrates the correct approach (Good).

## Controller Anti-Patterns

Business logic in controllers, non-RESTful route proliferation, and synchronous external calls in the request cycle.

- **Fat Controller** — Extract business logic to service objects (see `service-patterns` skill).
- **Non-RESTful Custom Actions** — Model state changes as nested RESTful resources instead of adding custom member actions.
- **Blocking External Calls** — Move external API calls to background jobs to keep requests fast and resilient.

For detailed Bad/Good examples, see **`references/controller-antipatterns.md`**.

## Model Anti-Patterns

God objects, callback-driven side effects, invisible query scoping, and misused concerns.

- **God Object** — Extract focused modules, service objects, and query objects instead of accumulating unrelated responsibilities.
- **Callback Hell** — Reserve callbacks for data integrity operations intrinsic to the model. Orchestrate side effects in service objects.
- **`default_scope` Abuse** — Use explicit named scopes instead of `default_scope`, which applies silently to every query.
- **Concerns as Junk Drawers** — Keep concerns small, cohesive, and reusable. Splitting a god object across files does not fix the design.

For detailed Bad/Good examples, see **`references/model-antipatterns.md`**.

## Query & Association Anti-Patterns

Tight coupling through deep object graphs, inefficient Ruby-side processing, and N+1 queries.

- **Law of Demeter Violations** — Use `delegate` instead of reaching deep into object graphs.
- **Processing in Ruby Where SQL Suffices** — Let the database filter, sort, and aggregate. See `active-record-patterns` skill.
- **Missing Eager Loading (N+1)** — Use `includes`, `preload`, or `eager_load`. See `rails-performance` skill.

For detailed Bad/Good examples, see **`references/query-antipatterns.md`**.

## View & Hotwire Anti-Patterns

Logic-heavy templates, hidden partial dependencies, nil gymnastics, and misuse of Turbo/Stimulus. See `hotwire-patterns` skill for correct Hotwire patterns.

- **Logic-Heavy Views** — Extract conditional logic to helpers, presenters, or model methods.
- **Instance Variables in Partials** — Use strict locals (Rails 7.1+) to make dependencies explicit.
- **Nil Gymnastics** — Use the Null Object pattern or handle nil at the data layer.
- **Turbo Streams When Frames Suffice** — Use Turbo Frames for simple in-place updates.
- **Stimulus for Everything** — Let the server render HTML; use Turbo to deliver it.
- **Ignoring Turbo Drive Compatibility** — Use Stimulus controllers instead of `DOMContentLoaded` listeners.

For detailed Bad/Good examples, see **`references/view-antipatterns.md`**.

## Background Job Anti-Patterns

Non-idempotent jobs, race conditions from enqueueing inside transactions, and serialization issues.

- **Non-Idempotent Jobs** — Add guard clauses and idempotency keys. Jobs *will* be retried.
- **Enqueueing Inside Transactions** — Enqueue after the transaction commits, or use `after_commit`.
- **Complex Objects as Job Arguments** — Pass only primitive IDs and let the job load fresh data.

For detailed Bad/Good examples, see **`references/job-antipatterns.md`**.

## Migration Anti-Patterns

Fragile migrations that mix concerns or depend on application code.

- **Mixing Schema and Data Migrations** — Separate structural changes from data backfills into distinct migrations.
- **Referencing Models in Migrations** — Use raw SQL or inline model stubs instead of application model classes.

For detailed Bad/Good examples, see **`references/migration-antipatterns.md`**.

## Quick Reference

| Anti-Pattern | Fix |
|---|---|
| Fat controller | Extract to service object |
| Non-RESTful actions | Model as nested resources |
| Blocking external calls | Move to background jobs |
| God object | Extract concerns, services, and query objects |
| Callback hell | Use service objects for orchestration |
| `default_scope` | Use explicit named scopes |
| Concerns as junk drawers | Keep concerns small and cohesive |
| Law of Demeter violations | Use `delegate` |
| Ruby where SQL suffices | Use ActiveRecord query methods |
| N+1 queries | Use `includes`, `preload`, or `eager_load` |
| Logic-heavy views | Extract to helpers or presenters |
| Instance vars in partials | Use strict locals |
| Nil gymnastics | Null Object pattern |
| Streams when Frames suffice | Use Turbo Frames for in-place updates |
| Stimulus for everything | Let Turbo Drive and Frames handle navigation |
| `DOMContentLoaded` listeners | Use Stimulus controllers |
| Non-idempotent jobs | Add guard clauses and idempotency keys |
| Enqueueing inside transactions | Enqueue after commit |
| Complex objects as job args | Pass primitive IDs only |
| Mixed schema/data migrations | Separate into distinct migrations |
| Model classes in migrations | Use raw SQL or inline stubs |

## Additional Resources

### Reference Files

For detailed Bad/Good code examples organized by category:
- **`references/controller-antipatterns.md`** — Fat controllers, non-RESTful actions, blocking calls
- **`references/model-antipatterns.md`** — God objects, callbacks, default_scope, concerns
- **`references/query-antipatterns.md`** — Law of Demeter, Ruby vs SQL, N+1 queries
- **`references/view-antipatterns.md`** — Logic-heavy views, partials, nil handling, Hotwire misuse
- **`references/job-antipatterns.md`** — Idempotency, transaction timing, serialization
- **`references/migration-antipatterns.md`** — Schema/data mixing, model references

### Related Skills

- **`service-patterns`** — Service object, form object, and interactor patterns
- **`hotwire-patterns`** — Correct Turbo Frames, Turbo Streams, and Stimulus patterns
- **`active-record-patterns`** — Query and association patterns
- **`rails-performance`** — Eager loading and optimization strategies

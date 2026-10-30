---
name: api-standards
description: >-
  Applies server-side engineering standards when implementing, refactoring,
  debugging, or reviewing API handlers, controllers, application workflows,
  authorization, persistence, integrations, webhooks, or backend workers. Use
  with coding-standards for backend behavior in any language or framework. Not for
  a frontend-only HTTP client change. Focuses on thin boundaries, explicit
  business rules, transaction ownership, concurrency, and reliable effects.
metadata:
  version: "1.1.0"
---

# API standards

Load the `coding-standards` skill first if it is not in context; if it is missing, say so.
Core owns limits, naming, contracts, and change safety. This skill adds server concerns only.
Apply only the relevant sections; a pure calculation needs no handler or database.

## First identify the boundary

Inspect the actual framework, authentication flow, validation, persistence/session lifecycle, error mapping,
and affected callers. Keep the repository's established mechanism where it satisfies the responsibility.
Do not introduce a new architecture because this skill uses the words service, repository, or adapter.

For database writes, external effects, retries, or concurrent work, read
[Persistence and external effects](references/reliability.md) first. For framework lifecycle details,
use that framework's own documentation.

## Keep transport thin

An HTTP route/controller should receive and validate transport input, resolve authentication/context, invoke
a coherent application operation, and translate its result into the response contract.

Do not put workflow orchestration, refund calculations, transaction ownership, important state transitions,
or repeated business policies into the handler. For other server entry points, use the analogous boundary:
a webhook receives an event; a worker receives a job. Neither should become a second implementation of the use case.

```text
transport boundary
    -> application operation
        -> explicit business decisions
        -> persistence / external capabilities
```

This is a responsibility sketch, not a requirement for four layers, four classes, or four files. Repositories
and adapters perform infrastructure work; keep domain decisions independent of infrastructure where practical.
A simple operation can remain an ordinary feature-local function. Respect native framework composition rather
than adding pass-through services or duplicating framework machinery.

## Give rules and workflows owners

An application operation coordinates required state, authorization, business rules, integrations, state changes,
and persistence. It should read like a workflow. Split a growing service by capability or use case, not by an
arbitrary method count. Avoid `BaseService`, generic CRUD frameworks, and speculative inheritance.

Name meaningful rules such as `ensure_order_can_be_cancelled`. Keep them directly testable and deterministic
where possible. Do not bury a rule in a serializer, an ORM query, or several subtly different conditions.
Use database constraints as additional protection where applicable, not as the only discoverable expression
of important policy.

Do not manufacture a domain layer for basic CRUD. Keep the operation small until real rules or multiple
responsibilities justify separating it.

## Authorization and validation

Resolve identity at the entry boundary and enforce the operation's actual authorization on the server.
A logged-in user is not automatically authorized to operate on every object. Never trust a hidden button,
client-supplied permission, ownership claim, ID, size, or metadata as authoritative.

Use the established request schema for transport validation. Apply domain validation to the operation itself.
Do not silently change which values are allowed, which callers are authorized, or which error the caller receives
under the label of refactoring.

## Infrastructure and failure contracts

Make transaction ownership, connection/session lifetime, timeout, retry, and cleanup behavior visible.
A helper must not unexpectedly commit. Do not share a mutable ORM session globally across concurrent requests.
A transaction alone is not proof that concurrent read-modify-write operations are safe.

Distinguish expected business rejection from infrastructure failure and programming errors. Map errors at the
appropriate transport boundary and preserve the API's intentional response contract. Broad top-level reporting
is acceptable; returning success after a failure is not.

Configuration and external capabilities should be provided explicitly through the application's established
construction mechanism. Validate required configuration early. Do not scatter environment lookups inside rules.
Do not introduce a DI container merely to satisfy this convention.

## Tests and completion

Use unit tests for decisions, calculations, validation, and transitions. Use database/integration tests for
constraints, transactions, persistence, concurrency, and adapter contracts. Use API tests for request validation,
authentication, object/operation authorization, error mapping, and critical workflows.

A mocked repository does not test the database guarantee. Test critical rejection paths as well as success;
for effectful changes, include the relevant duplicate, partial-failure, and concurrency cases.

Before completing work, check the core review questions plus:

- Is business behavior outside the transport handler without unnecessary architecture?
- Is the real authorization enforced independently of the client?
- Are persistence and external-effect failure cases accounted for at their actual boundaries?
- Do tests exercise the infrastructure guarantee being claimed?
- Are any API, schema, permission, or error-contract changes intentional and reported?

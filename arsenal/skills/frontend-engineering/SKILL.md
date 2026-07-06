---
name: frontend-engineering
description: >-
  Applies frontend engineering standards when implementing, refactoring, debugging,
  or reviewing UI features, components, navigation, client state, forms, tables,
  data fetching, accessibility, or component-library migrations. Use with
  coding-core for frontend work in any framework. Keeps features cohesive, routes
  thin, state ownership explicit, and behavior preserved. React and the preferred
  Vite/shadcn stack are optional references, not requirements for every frontend.
metadata:
  version: "1.0.0"
---

# Frontend engineering

Apply this with `coding-core`. Explicitly load that installed skill when it is not already in context.
With this bundle's sibling filesystem layout, it is [coding-core](../coding-core/SKILL.md).
Do not assume that naming another skill automatically loads it. If unavailable, report the missing dependency
and do not claim that the complete bundle was applied.

The core owns shared code quality, change safety, and language references. This skill owns UI boundaries,
state, interactions, presentation contracts, and frontend verification. Use native equivalents where a frontend
has no browser or URL; do not introduce web infrastructure into a native UI just to fit this document.

## Select only relevant references

Inspect the touched feature, actual framework/version, router, design system, data/form ownership, and test scripts.

| Task context | Read |
| --- | --- |
| React components, hooks, JSX, or React routing | [React](references/react.md) |
| React web work using shadcn, Tailwind, TanStack Query/Table, React Hook Form/Zod, or the explicitly selected preferred stack | [React web stack](references/react-web-stack.md); apply only sections for tools actually adopted |
| An explicitly requested or already-assigned migration to shadcn | [shadcn migration](references/shadcn-migration.md) |

Do not load every reference because `package.json` mentions React. A TypeScript backend task is not frontend
work. A full-stack task may need both concern skills, each applied to the appropriate code.
Do not install React, Vite, shadcn, a form library, or a query library merely to follow this skill.

## Boundaries and feature ownership

Keep feature rules, API calls, state configuration, and feature-specific components near their feature.
Maintain distinct responsibilities for generic UI primitives, small shared product patterns, and domain-aware
feature components. A generic button should not know about an inquiry; an inquiry action component may.

Do not enforce a universal directory tree; new files follow coding-core domain naming. In an existing repository, improve local ownership without relocating
unrelated code. Do not create a service layer because the backend has one, and do not force small features into
many files. A cohesive metadata module plus a field component can be enough.

A route establishes what appears at a location: parameters, redirects, context, authentication/layout boundaries,
and relevant routing data preparation. Keep application rules, mutation workflows, and large feature implementations
out of it. Framework-supported loaders may prepare route data without becoming a second business layer.

Authentication at a protected route is different from feature policy. A UI permission decides whether to show
or enable an action; it is not the operation's authoritative authorization. The server or other trusted boundary
must independently enforce the actual permission.

## State ownership

Give each state category one intentional owner:

| State | Responsibility |
| --- | --- |
| Remote/server data | The established fetching/cache/synchronization mechanism |
| Shareable navigation, filters, sorting, pagination | URL/navigation state where appropriate |
| Form values, dirty state, validation, field errors | The feature's form owner |
| Dialogs, local selection, expansion | Local interaction state unless sharing is genuinely needed |
| Values derived from existing inputs | Calculate from the source rather than synchronize a second copy |
| Genuine application-wide client state | A deliberately scoped shared owner |

Do not copy remote cache data into a global client store merely for access, duplicate fetching mechanisms,
or invent an abstraction to conceal competing sources of truth. Existing offline/local-first requirements may
justify a different deliberate owner; preserve that contract instead of forcing a web cache pattern onto it.

## Interaction and presentation

Give important UI decisions names and keep them out of dense template/JSX expressions. Use explicit states
rather than nested ternaries or many interacting conditions. Simple presentation conditions remain fine.

Use composition with meaningful responsibility. Components may connect to state and events; the goal is not
that every component becomes a data-free wrapper. Extract nontrivial handlers and cohesive operations, not
trivial setters merely for ceremony. Do not build universal table or form generators before real repetition exists.

Preserve the existing design system, semantic structure, tokens, spacing conventions, and interaction patterns.
Use established accessible primitives where they fit; do not wrap every primitive or replace it with a visually
similar but inaccessible custom control. The source's neutral, restrained shadcn visual preference is optional
stack guidance, not a rule banning another product's established visual design.

For data-driven features, deliberately handle loading, error, empty, populated, mutation pending/failure,
and meaningful success feedback. Account for background refresh where relevant. Never turn a failed request
into an empty-state success or erase existing data merely to simplify branching without checking the UX contract.

Preserve labels, keyboard operation, visible focus, dialog focus behavior, semantic controls, accessible names,
form-error association, and necessary accessibility state.

## Security and verification

Never put server secrets in client-delivered code/configuration. Do not render untrusted HTML through an unsafe
escape hatch. Treat browser-provided permissions and metadata as untrusted at the real enforcement boundary.

Test pure feature decisions, validation, and payload transformations with unit tests. Test important component
interactions through user-visible behavior. Exercise critical navigation, authentication, destructive actions,
complex forms, and uploads with browser/integration tests appropriate to the platform. Do not E2E-test every button.

For UI-library migrations, preserve API payloads, validation, defaults, permissions, query behavior, and navigation
unless the task explicitly changes them. Keep visual replacement, structural cleanup, and behavior changes
separately reviewable where practical.

Run the actual lint, formatting, type, test, and production build checks relevant to the change. Use a browser
or the platform's runtime check when visual or interaction behavior needs verification. Report when it was not run.
Finish with the core completion check plus state ownership, accessibility, and any intentional UX/contract differences.

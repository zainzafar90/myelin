# Explicit shadcn migration workflow

Read only when moving an existing interface to shadcn is explicitly requested or already in the assigned scope.
The presence of shadcn or another component library in dependencies is not permission to start a migration.

## 1. Understand current behavior

Inventory only the relevant scope: routes, component libraries, major screens, forms, tables, modals, permissions,
loading/error behavior, and custom controls. Protect critical workflows with tests.

Record the contracts that must remain stable: API inputs/outputs, payload mapping, query behavior, form defaults,
validation, authorization presentation, and navigation. Do not silently change them to simplify the new UI.

## 2. Establish the minimum foundation

Adopt the agreed shadcn primitives, Tailwind theme tokens, shared shell/layout conventions, and approved tooling.
Do not rebuild the shell or change the linter when that is unnecessary for the migration's actual scope.
Keep large formatting-only changes separate from behavioral work.

## 3. Migrate one representative feature

Choose a scoped feature that exercises the relevant patterns: header, list/table, form, dialog, loading, empty,
and error states. Make it the reference implementation rather than inventing a different visual system per screen.
Preserve accessibility, focus, keyboard interaction, defaults, and existing data behavior.

## 4. Repeat in reviewable slices

Keep these concerns separately identifiable:

```text
UI replacement:        previous primitives -> shadcn
Structural cleanup:    clearer feature ownership
Behavioral changes:    only explicitly intended changes
```

Do not turn a presentation migration into a rewrite of the router, data cache, API client, permission model,
and forms simultaneously. A small migration need not manufacture three separate pull requests, but its
behavioral differences must remain reviewable.

## 5. Remove migrated legacy code

Check remaining callers, then remove obsolete components, CSS, dependencies, and duplicate wrappers within scope.
Retain a compatibility layer only for a real consumer and document the reason.

Completion means old usage in the declared scope is gone or explicitly documented. Installing shadcn does not
count as completing a migration. Do not claim the whole application is migrated after changing one feature.

## Acceptance

Verify important user workflows, permissions/presentation, payloads, validation, defaults, query behavior,
navigation, accessibility, and loading/error/empty states. Run the repository's actual formatting, lint,
TypeScript, relevant tests, production build, and critical browser checks. Report anything not run.

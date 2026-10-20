# Optional React web stack

The preferred stack for new React web projects. It is not a requirement for every React application and
never authorizes replacing an existing stack. Read relevant sections when the touched code uses
these tools; ignore sections for tools it does not use. A migration requires an explicit task or project decision.

The preferred stack is React, Vite, TypeScript, Tailwind CSS v4, shadcn/ui, TanStack Query, TanStack Table,
React Hook Form, Zod, Oxlint, Oxfmt, Vitest, React Testing Library, and Playwright for critical flows.
Use the installed versions and their real configuration; this list is not an instruction to upgrade dependencies.

## shadcn and component ownership

Standardize interactive primitives and recurring patterns, not every HTML element. Use suitable shadcn buttons,
inputs, selects, dialogs, menus, popovers, tabs, tables, skeletons, and related controls. Keep semantic HTML for
page structure, headings, sections, and lists. Use Tailwind for layout.

Keep generic primitives in the repository's UI area, recurring product patterns in a deliberately small shared
area, and domain-aware components in features. `components/ui` and `components/patterns` are suggested names,
not mandatory relocation targets. Avoid meaningless `AppButton`, `OurDialog`, and `BaseCard` wrappers.

The default look is restrained: neutral surfaces, one primary accent, consistent spacing/control
heights, clear typography, minimal nested cards, predictable actions, and obvious data states. Use it when
that design direction is selected; preserve another established visual system otherwise.

Prefer semantic tokens such as:

```tsx
className="bg-background text-foreground border-border"
```

Keep global theme decisions in the theme layer. Avoid scattered arbitrary colors, shadows, spacing, animations,
and page-specific button designs without a real requirement. Do not construct partial Tailwind utilities such
as `bg-${color}-500`; use complete class-name mappings or CSS variables.

## TanStack Query

Keep transport and query configuration understandable, typically in feature-local `.api.ts` and `.queries.ts`
modules when those responsibilities merit separation.

Include every input that changes the dataset in its query key: for example workspace, entity ID, pagination,
sorting, and filters. Avoid accidental cache collisions. Reuse one deliberate query convention across components
and route loaders rather than implementing parallel fetching in stores, hooks, and helpers.

Choose freshness/refetch behavior intentionally and target invalidation at affected data. Do not invalidate the
whole application after every mutation. Do not copy query results into another global store simply to access them.
Do not wrap every query in a custom hook without meaningful additional reusable behavior.

## TanStack Table

Query fetches data; TanStack Table owns table behavior; shadcn Table renders the interface. Do not let the table
become a second fetching layer. Keep columns feature-local.

For server pagination, filtering, or sorting, configure that behavior deliberately. Do not filter just the
currently loaded page when the product promises filtering across the dataset. Avoid a universal `DataTable`
with dozens of options before actual repetition justifies it.

## Forms

Use React Hook Form for values, dirty state, validation wiring, and errors when it is the adopted form owner.
Use Zod for appropriate runtime input/form validation. Keep schemas, defaults, transformations, and payload
mapping explicit inside the feature. shadcn provides the appropriate presentation controls.

Do not introduce a dynamic form-generation framework as part of a component-library migration. Preserve defaults,
validation messages/behavior, payload shape, and permission behavior unless changes are intentional.

## Tooling and client configuration

Oxlint is the preferred linter and Oxfmt the preferred formatter. When migrating lint tools, preserve important
React, hooks, accessibility, import, and correctness checks. Do not remove ESLint until necessary equivalent
coverage is accounted for. Do not blanket-disable rules to finish a migration.

Keep TypeScript checking separate from Vite transpilation. Use the actual package scripts and production build.
Never treat `VITE_*` values as secrets: do not put server credentials in client configuration.

Use Vitest for pure rule/transform tests, React Testing Library for important interactions, and Playwright for
critical browser flows. Scope browser tests to meaningful journeys rather than every primitive button.

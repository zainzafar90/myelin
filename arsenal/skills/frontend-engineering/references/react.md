# React reference

Read for React components, hooks, JSX, and routing. Does not select Vite, Next.js, a router, a component library,
or a state library. Use the repository's actual React/runtime conventions.

## Routes and feature pages

Keep route parameters, redirects, protected layouts, and routing data preparation in routing infrastructure.
Render or compose the relevant feature/page. Do not let a route absorb feature permission rules, payload mapping,
mutation workflows, and hundreds of unrelated JSX lines.

A protected route may read a session and render loading, redirect to sign-in, or allow entry. This is not
object-level authorization. A router loader may prepare a feature query; it must not become the owner of
business transitions or mutate domain state simply while preparing a page.

Do not create `.service.ts` files by analogy with the backend. An API module, query configuration, ordinary
rule functions, and feature components are usually clearer when those responsibilities actually exist.
Only add client orchestration when there is a genuine workflow that needs it.

## Components and conditions

Name important rules before JSX. Prefer explicit branches for distinct application states; reserve ternaries
for simple binary presentation choices. A few straightforward `condition && <Element />` cases are fine.
Avoid requiring readers to mentally evaluate many interacting conditions to know what appears.

Illustrative state rendering:

```tsx
const query = useInquiries();

if (query.isPending) {
  return <InquiriesSkeleton />;
}

if (query.isError) {
  return <InquiriesError error={query.error} />;
}

if (query.data.length === 0) {
  return <InquiriesEmptyState />;
}

return <InquiriesTable inquiries={query.data} />;
```

This illustrates initial state handling, not every cache/background-refresh policy. Preserve the application's
actual behavior for retained data and background errors.

**Added implementation guardrail:** call ordinary React hooks in their valid top-level positions before
conditional returns. Refactoring into guard clauses must not introduce conditional hook calls or place a hook
after a conditional return. Follow the documented rules for the particular API; do not invent exemptions.

## State and event ownership

Keep form state with the form owner, temporary UI state local, shareable navigation in the router where relevant,
and server data with the established server-state owner. Use a global client store only for genuinely shared
client state. Derive values rather than synchronize duplicate state through effects.

Keep business calculations and validation in ordinary feature-local functions. Use hooks for meaningful reusable
React behavior, not as mandatory wrappers around every query or helper.

Name nontrivial handlers. A handler may coordinate a mutation and UI feedback, but extract substantive rules
or payload transformations into their owning feature code. Do not extract trivial inline state setters solely
to increase the number of named functions.

## Structure without fragmentation

A larger feature may have `inquiries.api.ts`, `inquiries.queries.ts`, `inquiry-rules.ts`, and feature components.
A small DG feature may need only `dg-metadata.ts` and `dg-documents-field.tsx`: parsing, validation, constants,
and payload construction can be one cohesive metadata responsibility.

Keep table columns near their table feature. Avoid root-level collections of unrelated hooks, types, services,
or components, and avoid universal data tables with dozens of speculative options.

## Tests

Test meaningful forms, visibility/enabled states, errors, and user workflows rather than private component
structure. For the preferred stack, Vitest, React Testing Library, and Playwright are the source defaults;
use existing equivalents when the repository has not selected that stack.

Additional guardrail source: `https://react.dev/reference/rules/rules-of-hooks`

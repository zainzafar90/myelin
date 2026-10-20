# TypeScript reference

Read for TypeScript on either side of the client/server boundary. TypeScript does not imply React, a browser,
Node.js, or a package manager. Limits, file naming, comments, and the package-manager rule live in
[coding-core](../SKILL.md); React rules live in `react-craft`.

## Contracts and types

- Annotate important boundaries; infer obvious locals. Exported functions annotate their return type.
- `interface` for object shapes that may be extended; `type` for unions, intersections, and tuples.
- Model alternatives as discriminated unions with exhaustive handling, not boolean flag soup:
  `{ status: "loading" } | { status: "error"; error: Error } | { status: "ready"; data: Order[] }`.
- No `any`, `@ts-ignore`, or `as unknown as X` to hide a contract failure. Use `unknown` and narrow.
  An unavoidable escape gets a narrow scope, a `/* */` reason of 8 words or fewer, and a test.
- A type assertion never replaces runtime validation of untrusted data.
- Keep types next to the code that produces them. No package-wide `types.ts`; a shared type exists only for
  a genuinely shared contract.

## Modules

- One exported concept per file.
- Named exports everywhere. Use a default export only where the framework requires one.
- No circular imports. If A imports B, B never imports A.
- A barrel (`index.ts`) only re-exports a feature's public API. No logic in barrels and no broad root barrels.

## Readability

Braces and multiline bodies always. Prefer meaningful explicit checks such as `attachmentIds.length === 0`.
Do not expand every ordinary expression into a named variable.

```ts
const attachmentIds = getAttachmentIds(values);

if (attachmentIds.length === 0) {
  throw new Error("At least one supporting attachment is required.");
}

const hasUnreadyFiles = hasPendingUploads(values);

if (hasUnreadyFiles) {
  throw new Error("Finish uploading or remove failed files before review.");
}

return buildAttachmentPayload(attachmentIds);
```

Never nest ternaries. A simple presentation label such as `isEditing ? "Save" : "Create"` is fine.

Pure feature rules are ordinary functions. Lack of JSX does not make them shared utilities, and being shared
does not require a service class.

Naming: `camelCase` for values and functions, `PascalCase` for types, classes, and components,
`UPPER_SNAKE_CASE` for true constants.

## Tests

- Bug fix: first write a test that fails on the unpatched code, then make it pass.
- A new feature module ships with its tests in the same change, not a follow-up.
- Test behavior and contracts, not private state. Name tests as behavior: `returns empty list when no items match`.

## Tooling

Use the touched package's lockfile, type configuration, and scripts. Keep type checking a separate step from
transpiling unless the build demonstrably includes it. No blanket suppressions. Formatter and linter config is
checked in and runs in CI.

Oxlint and Oxfmt are the preferred tools for new frontend projects, not a requirement for every repository.
Never drop existing lint coverage to change tools.

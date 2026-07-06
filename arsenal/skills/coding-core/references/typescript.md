# TypeScript reference

Read for TypeScript on either side of the client/server boundary. Do not assume that TypeScript implies React,
a browser, Node.js, or a particular package manager.

## Contracts

Use explicit types for important boundaries and infer obvious local implementation details. Prefer
discriminated unions for meaningful alternatives and exhaustive handling where missing a case would be a bug.

Do not use `any`, `@ts-ignore`, or `as unknown as Something` to hide migration or contract failures.
An exceptional interoperability escape needs a narrow scope, a documented reason, and validation/tests appropriate
to the risk. A type assertion is not a substitute for checking untrusted runtime data.

Keep types with their feature or contract. Avoid a root `types.ts` dumping ground, and do not split every small
type into another file. Create a shared type only when it genuinely describes a shared contract.

## Readability

Use braces and multiline control-flow bodies. Prefer explicit meaningful checks such as
`attachmentIds.length === 0`. Do not mechanically expand every ordinary expression into named variables.

Illustrative payload-boundary structure:

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

Prefer explicit branches over ternaries for business decisions. Never nest ternary expressions. A simple
presentation label such as `isEditing ? "Save" : "Create"` is fine.

Pure feature rules are ordinary TypeScript functions. Their lack of JSX does not make them shared utilities,
and being shared does not require a service class.

## Tooling

Use the package manager, lockfile, type configuration, and scripts that the touched package actually uses.
Keep TypeScript checking a separate verification step from transpilation/building unless the repository's
build demonstrably includes it. Do not add blanket suppressions.

Oxlint/Oxfmt are preferences in the optional frontend stack profile, not universal requirements for every
TypeScript repository. Do not remove existing lint coverage merely to change tools.

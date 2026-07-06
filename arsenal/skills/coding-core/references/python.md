# Python reference

Read when writing, refactoring, debugging, or reviewing Python. Applies to scripts, libraries, workers,
and APIs. This is a language reference, not a FastAPI, Django, or Flask architecture mandate.

## Contracts and ordinary construction

Use appropriate structures already established in the project:

- Pydantic for external/runtime-validated data when adopted by the repository.
- Dataclasses for internal structured data; enums for meaningful finite states.
- `TypedDict` when a dictionary representation is actually appropriate.
- `Protocol` when genuinely interchangeable implementations justify a structural interface.

Type important boundaries. Do not pass arbitrary dictionaries throughout the application, but do not introduce
DTO, domain, persistence, and response copies of every entity automatically. Ordinary functions and constructor
injection are usually enough. Do not add a DI container just to make the code look formal.

Use domain-specific exception types for expected rejections. Translate them at the appropriate boundary;
do not import a web framework into reusable business rules merely to raise an HTTP exception there.

## Readable control flow

Illustrative structure, not a complete inventory implementation:

```python
stock = repository.get(product_id)

if stock is None:
    raise ProductNotFound(product_id)

can_reserve = can_reserve_stock(
    stock=stock,
    requested_quantity=requested_quantity,
)

if not can_reserve:
    raise InsufficientStock(product_id)

return build_reservation(
    stock=stock,
    quantity=requested_quantity,
)
```

The rule has a name, failure is explicit, and each block has one purpose. A real persistence workflow must
also protect concurrent writes; this example intentionally does not claim to do that.

## Python hazards

Use `None` plus initialization rather than a mutable default argument. For dataclasses, use
`field(default_factory=list)` or the corresponding factory for mutable values.

Use timezone-aware timestamps for actual instants. Use integer minor units or `Decimal` with an explicit
rounding policy where exact currency behavior matters. Do not silently change units or precision while refactoring.

Use context managers where cleanup matters. Do not hide circular architecture with local imports, add
metaclass/decorator magic unnecessarily, or introduce a deep inheritance hierarchy for simple operations.

Do not use `assert` for required validation or authorization. Reject untrusted pickle loading and `eval()` or
`exec()` on untrusted input. Do not swallow unexpected exceptions.

## Tooling and tests

The source prompt's preferred baseline is `uv`, Ruff, mypy, and pytest. It is a preference for an adopted or
explicitly selected setup—not permission to replace another working toolchain.

When those tools and paths already match the repository, its checks may look like:

```bash
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked mypy src
uv run --locked pytest
```

Use the actual configured paths and commands. `uv sync --locked` is a dependency setup step only when
installation is needed and allowed, not an obligatory side effect of every review. Include relevant migration
and startup checks for server changes. Improve typing incrementally; do not blanket-suppress the existing codebase.

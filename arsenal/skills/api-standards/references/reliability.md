# Persistence and external effects

Read only when the task involves database writes, concurrent work, transactions, external side effects,
webhook/job retries, or resource/session ownership. Start with the guarantees the existing system provides.
Do not add distributed-systems machinery to a local CRUD operation.

## Transactions and concurrency

Name the operation that owns commit and rollback. Repositories/persistence helpers execute operations within
that contract; they must not unexpectedly commit another caller's work.

Use migrations and database constraints for enforceable invariants. For read-modify-write behavior, choose
an appropriate actual concurrency mechanism: a conditional update, row lock, optimistic version check,
a suitable isolation level, or a constraint. Do not assume that placing reads and writes in a transaction
alone prevents overselling or duplicate transitions.

Use request/work-unit scoped ORM sessions. Make resource cleanup explicit, normally with the language or
framework's lifecycle facilities. Do not share one session globally across concurrent work.

Test against the relevant database behavior when correctness depends on its constraints, locking, isolation,
or rollback semantics. Do not claim that an in-memory mock proves these guarantees.

## External calls and retries

Set explicit timeouts. Make retry decisions deliberate and bounded. Give retry policy a clear owner rather
than allowing several layers to multiply attempts independently.

A timeout is an uncertain outcome, not proof that the remote operation did nothing. Do not automatically
retry an important write unless the operation's idempotency or deduplication contract makes it safe.
Verify the actual provider's behavior rather than assuming all idempotency keys have the same semantics.

## Remote success, local failure

A local database rollback never undoes a separate remote call. The database transaction and the provider's
retry contract are two different boundaries; there is no combined cross-system transaction.

For a real effectful workflow, answer the relevant questions explicitly:

- How is the logical operation identified across retries, and who enforces deduplication?
- What durable state can distinguish not started, pending/uncertain, succeeded, and failed where needed?
- What happens after remote success followed by local failure, or after an ambiguous timeout?
- How is the result reconciled without silently duplicating or discarding the effect?

Use the smallest mechanism justified by the actual risk and existing infrastructure. A durable operation
record, reconciliation step, or outbox may be appropriate in a particular system; this skill does not mandate
any of them. Do not label a workflow atomic or exactly-once unless its real guarantees support that claim.

## Example acceptance cases

For a stock reservation, test that one request cannot reserve unavailable stock and that concurrent requests
cannot both consume the same remaining stock. Assert the invariant in persisted state, not only HTTP responses.

For an important external write, test a successful call, a rejected call, a timeout with an uncertain outcome,
and the relevant repeated delivery/retry. For a local transaction, test failure between related writes and
verify the intended rollback behavior.

Report unsupported guarantees and untested failure windows rather than presenting an incomplete protocol
as production-safe.

## References

- Transaction boundary: `https://www.postgresql.org/docs/current/tutorial-transactions.html`
- A provider idempotency contract: `https://docs.stripe.com/api/idempotent_requests`

Examples of the distinction only; they do not pick PostgreSQL or Stripe.

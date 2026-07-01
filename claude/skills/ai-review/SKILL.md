---
name: ai-review
description: Review code written or touched by AI for characteristic blind spots — integration holes, retry/idempotency bugs, type contract mismatches, missing failure handling, and coverage gaps. Use when asked to "review AI code", "check what Claude wrote", "audit AI changes", "vibe check this", or before submitting AI-assisted code.
allowed-tools: Read, Bash, Glob, WebFetch
license: MIT
---

# AI Code Review

AI-generated code has a characteristic failure profile. It handles the happy path well. It matches names and structures correctly. It often produces clean, readable code. But it has predictable blind spots:

- It writes new code without fully reasoning about how it interacts with existing code
- It models the success path deeply and the failure path shallowly
- It matches field names but misses type mismatches
- It implements the interface but skips the infrastructure (DLQs, retries, context propagation)
- It tests what it built, not what could go wrong
- It generates plausible-looking logic that silently corrupts data under concurrency or retry

This review exists to catch those patterns before they cost you a job offer, a production incident, or a failed PR.

---

## Inputs

The user provides one or more of:
- A file path or list of files to review
- A git diff or PR reference (`gh pr diff N --repo owner/repo`)
- A description of what was changed and why
- The original spec or requirements (if available)

If no specific files are given, check `git diff HEAD` or `git diff main...HEAD` to find what changed.

---

## Step 1 — Understand the Change

Before reviewing, establish context:

1. What was the stated goal of the change?
2. What files were modified vs. what files exist in the surrounding system?
3. What data stores, queues, or external services does this code interact with?
4. Are there existing functions/queries that now interact with new data the AI created?

Read the **unchanged files** that the changed code calls or shares data with. The bug is often there.

---

## Step 2 — Run the Checklist

Work through every category. Skip none. For each finding, cite the exact file and line.

---

### 2a. Integration Holes (highest yield)

AI writes new code but often doesn't reason about what the existing code will do with new data it creates.

**Check:**
- Does any new record type, table row, cache key, or queue message get picked up by an existing query or scan that wasn't updated to exclude it?
- Does any new field added to a shared struct/schema break existing deserialization elsewhere?
- Does any renamed or removed field leave callers passing wrong keys silently?
- If using a shared table/store with multiple record types: are all existing scans/queries filtered correctly?
- Does any new code assume an invariant that existing code can violate?

**Pattern to look for:** `Scan`, `SELECT *`, `GetAll`, `List*` operations that now return more than they used to.

---

### 2b. Type Contract Mismatches

AI matches field names correctly but misses type mismatches — especially at serialization boundaries.

**Check:**
- Cross-reference struct field types against the actual wire format (API spec, event schema, database column type)
- String `"7.33"` vs number `7.33` in JSON — these are not the same; most languages' JSON parsers will silently fail or coerce
- Integer vs float vs decimal — financial amounts are especially risky (float arithmetic is not exact)
- Nullable vs non-nullable — does the code assume a field is always present?
- Date/time formats — `RFC3339` vs `ISO8601` vs epoch vs custom — mismatches cause silent parse failures

---

### 2c. Retry and Idempotency

AI writes code for first execution. It rarely writes code for the second execution of the same operation.

**Check:**
- If this operation is retried (by a queue, a cron, a user clicking twice), does it produce the same result or does it double-write?
- Are atomic operations used where needed (compare-and-swap, conditional writes, `IF NOT EXISTS`)?
- For message queue consumers: if the handler returns an error, does the entire batch get retried? If so, are already-processed messages in that batch re-processed?
- Does the retry path re-read state before acting, or assume the previous state is still valid?
- For financial operations: is the increment/decrement idempotent, or can it be applied multiple times?

---

### 2d. Partial Failure and Batch Processing

AI handles the case where everything works. It rarely handles the case where some things work.

**Check:**
- For batch/bulk operations: if item N fails, what happens to items 1..N-1 that already succeeded?
- For message queue consumers (SQS, Kafka, Pub/Sub): is partial batch failure reported correctly so only failed messages are retried?
- For multi-step transactions without a real transaction: what is the state if step 2 fails after step 1 succeeded?
- For loops over items: does a failure in one iteration abort the rest, or continue?

---

### 2e. Error Handling Depth

AI handles errors structurally (it wraps and returns them) but often shallowly (it doesn't distinguish between error types or provide useful context).

**Check:**
- Are transient errors (network timeout, rate limit) distinguished from permanent errors (invalid input, not found)?
- Is there enough context in error messages to debug without a debugger? (Which ID? Which operation? What was the input?)
- Are errors logged at the right level? (Temporary retryable errors shouldn't fire alerts.)
- Do error responses leak internal details (stack traces, file paths, SQL queries) to external callers?
- Is `errors.As`/`errors.Is` (or equivalent) used for typed error matching, rather than string comparison or bare type assertions?

---

### 2f. Context and Cancellation Propagation

AI often uses `context.Background()` or `context.TODO()` where a real context should be threaded through.

**Check:**
- Are long-running or blocking operations (DB calls, HTTP calls, queue operations) passed a context with a deadline?
- Is the caller's context (e.g., the HTTP request context, the Lambda function context) propagated to downstream operations?
- If the caller is cancelled or times out, do downstream operations also stop, or do they continue running in an orphaned goroutine/thread?
- Are goroutines/async tasks started without a way to cancel them?

---

### 2g. Infrastructure Gaps

AI implements the application logic but often skips the infrastructure that makes it production-safe.

**Check:**
- Dead-letter queues: for message-driven consumers, what happens to messages that fail after max retries — are they captured or silently dropped?
- Permissions: is the principle of least privilege applied? (Read-only where write isn't needed, scoped to specific resources)
- Timeouts: do external calls have explicit timeouts, or do they block indefinitely?
- Circuit breakers / retry limits: for calls to external services, is there a ceiling on retries?
- Observability: are new code paths instrumented with metrics/traces/logs at the same level as existing code?

---

### 2h. Test Coverage Gaps

AI writes tests for the code it wrote, not for the ways that code can fail.

**Check:**
- Are there tests for error paths (what happens when the DB call fails, the network is down, the input is malformed)?
- Are there tests at the handler/controller level, not just the domain/library level?
- If the task explicitly asked for improved testability: are the handlers themselves testable via dependency injection, or just the inner functions?
- Do tests mock at the right boundary? (Mocking an interface is fine; mocking internals is brittle.)
- Are concurrency/race conditions tested? (Run with `-race` flag, or equivalent.)

---

### 2i. Dead Code and Cleanup

AI sometimes generates scaffolding, stubs, or intermediate variables that were not cleaned up.

**Check:**
- Unused imports, variables, parameters, functions
- TODO/FIXME/placeholder comments left in production code
- Commented-out code that was never removed
- Generated files that are out of sync with their source (re-run the generator to verify)
- Temporary debug logging left in

---

### 2j. Concurrency and Shared State

AI often writes correct single-threaded logic that breaks under concurrent access.

**Check:**
- Shared mutable state accessed from multiple goroutines/threads without synchronization
- Read-modify-write patterns that need atomic operations or locks
- Caches or in-process state that assumes single-reader/single-writer
- `init()` or global variable initialization that is not thread-safe

---

## Step 3 — Severity Classification

For every finding:

**🔴 Critical** — Causes visible incorrect behavior or data corruption in normal operation. Would be caught running the code once.

**🟡 Significant** — Correct in the happy path, breaks under realistic conditions (concurrent access, retry, partial failure, missing record). A code reviewer would flag it before merge.

**🟢 Moderate** — Quality or completeness gap. Doesn't cause immediate breakage but increases fragility or operational risk.

**⚪ Minor** — Style, idiom, or nice-to-have. Not a blocker.

---

## Step 4 — Verdict

```
VERDICT: SAFE TO SHIP / NEEDS FIXES / BLOCKED

Critical: N  |  Significant: N  |  Moderate: N  |  Minor: N

Blockers (fix before merge/submit):
  1. {file:line} — {one sentence on impact}

Recommended fixes:
  1. {fix} — {why it matters}

What's solid:
  - {specific thing done well}
```

**SAFE TO SHIP**: No critical or significant issues.
**NEEDS FIXES**: No critical issues; significant issues present — worth fixing.
**BLOCKED**: One or more critical issues. Do not merge or submit until resolved.

---

## Rules

- **Read files the changed code interacts with, not just the changed files themselves.** The most common AI bug is not in the new code — it's in how the new code's output is consumed by old code that wasn't updated.
- **Never mark anything "looks fine" without checking all ten categories.** Skipping takes 30 seconds; missing a critical bug costs a production incident or a job offer.
- **Be specific.** "This might have a concurrency issue" is useless. "The `UpdateItem ADD` on line 47 is idempotent per-call, but the SQS handler at line 12 returns an error on any failure, causing the entire batch to be retried and all previously processed messages to be re-incremented" is actionable.
- **AI-generated code is not more correct because it looks clean.** Confidence in the output of any AI (including this one) must be earned by verification, not assumed from readability.

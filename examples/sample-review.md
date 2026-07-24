A real review, as it lands in Slack.

---

*Add promo code support to checkout* — 5/10

❌ `src/checkout/service.js:142` — The payment is captured before the order row is written, so a failure on the insert charges the customer with no order to show for it. Move the capture after the write commits, or wrap both in a transaction with a compensating refund.
❌ `src/promo/repo.js:31` — `redemption_count` is read, incremented and written back in three statements, so two shoppers redeeming the last use of a code both succeed. Use a conditional update and check the affected row count.
⚠️ `src/checkout/service.js:88` — `findPromo` runs once per line item inside the loop. Fetch the codes in one query before the loop.
⚠️ `src/promo/validate.js:24` — The expiry comparison builds a date from the string with no timezone, so a code expires up to a day early for users behind UTC. Compare instants, not local dates.
⚠️ `src/checkout/controller.js:19` — `req.body` is passed to `createOrder` unfiltered, so a client can set `totalAmount` directly. Pick the fields you need.
🔹 `src/promo/repo.js:12` — Retry count hardcoded to 3. Move to config.
✅ The rollback path in `applyDiscount` is properly tested, including the partial-failure case.

Verdict: fix the capture ordering and the redemption race before merge. The rest can follow.

---

Same rubric runs locally through the `reviewer` subagent, so this is what the author saw before opening the PR.

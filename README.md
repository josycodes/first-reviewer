# first-reviewer

Every pull request reviewed and scored in Slack before a human opens the diff.

![demo](docs/demo.gif)

Your team already pays for AI seats. This turns them into something that runs without anyone typing a prompt: a PR opens, a review lands in the channel with a score out of ten, and the reviewer who picks it up already knows whether it is worth their next twenty minutes.

Runs on a Claude Code OAuth token or an Anthropic API key. Nothing else to host.

## What a review looks like

```
*Add promo code support to checkout* — 5/10

❌ src/checkout/service.js:142 — The payment is captured before the order row is
   written, so a failure on the insert charges the customer with no order.
⚠️ src/checkout/service.js:88 — findPromo runs once per line item inside the loop.
🔹 src/promo/repo.js:12 — Retry count hardcoded to 3. Move to config.

Verdict: fix the capture ordering before merge.
```

Full example in [`examples/sample-review.md`](examples/sample-review.md).

## Install

Fifteen minutes, all in the GitHub web UI.

**1. Copy four paths into your repository**

```
.github/workflows/pr-review.yml
prompts/review.md
prompts/domains/generic.md
scripts/post-to-slack.sh
```

**2. Create a Slack incoming webhook**

Slack → your workspace settings → Apps → Incoming Webhooks. Create one, point it at the channel that should receive reviews, copy the URL.

**3. Add repository secrets**

Settings → Secrets and variables → Actions → New repository secret.

| Secret | Value |
|---|---|
| `SLACK_WEBHOOK_URL` | The webhook from step 2 |
| `CLAUDE_CODE_OAUTH_TOKEN` | Run `claude setup-token` locally and paste the result |

Use `ANTHROPIC_API_KEY` instead if you would rather bill usage to an API account. Set one or the other. If both are set the API key wins.

**4. Set your protected branches**

Edit the `branches:` list at the top of `pr-review.yml`. Only pull requests targeting those branches are reviewed.

**5. Open a pull request**

The review posts to Slack within a minute or two. It is also attached to the workflow run as an artifact.

## Configuration

Everything tunable sits in the `env:` block at the top of the workflow.

| Variable | Default | What it does |
|---|---|---|
| `DOMAIN` | `generic` | Which file in `prompts/domains/` supplies stack-specific checks |
| `MODEL` | `claude-sonnet-4-6` | Model used for the review |
| `MAX_DIFF_CHARS` | `120000` | Diff is truncated beyond this, and the review says so |

## Tuning the rubric

`prompts/review.md` is the whole review. Severity bands, the scoring scale, the ignore list and the output format are all in that one file, and editing it changes every review immediately.

Two things worth knowing before you change it:

The score is set by the worst single finding, never by an average. That is deliberate — without the anchor, every PR comes back a 7 and the number stops carrying information.

The rubric is tuned to drop findings it is not confident about. Teams abandon automated review because of false positives, not because of gaps. If you widen it, expect that trade.

## Limits

The OAuth token is tied to one person's subscription and draws on that subscription's rate limits. Fine for a handful of repositories. If you are putting this across a large organisation with heavy PR volume, use an API key so the load is not landing on one engineer's quota.

Only the generic rubric ships here. Stack-specific rubrics, the local pre-PR reviewer, the test and documentation subagents, Teams and Google Chat delivery, and the multi-repo rollout SOP are part of the paid kit — see [the offer page]({{OFFER_URL}}).

## Licence

MIT. Use it, fork it, sell what you build with it.

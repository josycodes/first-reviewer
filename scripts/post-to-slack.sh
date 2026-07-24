#!/usr/bin/env bash
#
# Posts a review to Slack via an incoming webhook.
#
# Reads the review body on stdin.
#
# Required environment:
#   SLACK_WEBHOOK_URL   Incoming webhook URL
#   PR_TITLE            Pull request title
#   PR_URL              Link to the pull request
#   PR_AUTHOR           GitHub login of the author
#   REPO                owner/name
#
# Usage:
#   ./scripts/post-to-slack.sh < review.txt

set -euo pipefail

for var in SLACK_WEBHOOK_URL PR_TITLE PR_URL PR_AUTHOR REPO; do
  if [ -z "${!var:-}" ]; then
    echo "post-to-slack: ${var} is not set" >&2
    exit 1
  fi
done

command -v jq >/dev/null || { echo "post-to-slack: jq is required" >&2; exit 1; }

REVIEW="$(cat)"

if [ -z "${REVIEW//[[:space:]]/}" ]; then
  echo "post-to-slack: review body is empty, nothing to post" >&2
  exit 1
fi

# Slack rejects a section block over 3000 characters. The rubric caps output
# well below this; truncate anyway so a runaway response fails visibly rather
# than silently dropping the whole message.
MAX_CHARS=2900
if [ "${#REVIEW}" -gt "${MAX_CHARS}" ]; then
  REVIEW="${REVIEW:0:${MAX_CHARS}}"$'\n\n_Truncated. Full review is attached to the workflow run._'
fi

# Colour the message by score so the channel is scannable without reading.
# Falls back to grey when no score is present.
SCORE="$(printf '%s' "${REVIEW}" | grep -oE '\b([0-9]|10)/10\b' | head -n1 | cut -d/ -f1 || true)"
case "${SCORE}" in
  8|9|10) COLOR="#2eb886" ;;
  6|7)    COLOR="#daa038" ;;
  0|1|2|3|4|5) COLOR="#d93025" ;;
  *)      COLOR="#9aa0a6" ;;
esac

# Build the payload with jq so quotes, backticks, newlines and anything else
# in the review body are escaped correctly.
PAYLOAD="$(jq -n \
  --arg review "${REVIEW}" \
  --arg pr_url "${PR_URL}" \
  --arg author "${PR_AUTHOR}" \
  --arg repo "${REPO}" \
  --arg color "${COLOR}" \
  '{
    attachments: [
      {
        color: $color,
        blocks: [
          {
            type: "section",
            text: { type: "mrkdwn", text: $review }
          },
          {
            type: "context",
            elements: [
              { type: "mrkdwn", text: ("*" + $repo + "*  ·  by " + $author) }
            ]
          },
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: { type: "plain_text", text: "Open pull request" },
                url: $pr_url
              }
            ]
          }
        ]
      }
    ]
  }')"

HTTP_STATUS="$(
  curl --silent --show-error --fail-with-body \
    --max-time 20 \
    --retry 2 --retry-delay 2 --retry-connrefused \
    --output /tmp/slack-response.txt \
    --write-out '%{http_code}' \
    --header 'Content-Type: application/json' \
    --data "${PAYLOAD}" \
    "${SLACK_WEBHOOK_URL}"
)" || {
  echo "post-to-slack: request failed" >&2
  cat /tmp/slack-response.txt >&2 || true
  exit 1
}

if [ "${HTTP_STATUS}" != "200" ]; then
  echo "post-to-slack: Slack returned ${HTTP_STATUS}" >&2
  cat /tmp/slack-response.txt >&2 || true
  exit 1
fi

echo "post-to-slack: delivered"

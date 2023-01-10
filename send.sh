#!/bin/bash

set -ex

case $1 in
  "success" )
    EMBED_COLOR=3066993
    STATUS_MESSAGE="Passed"
    ;;

  "failure" )
    EMBED_COLOR=15158332
    STATUS_MESSAGE="Failed"
    ;;

  * )
    EMBED_COLOR=0
    STATUS_MESSAGE="Status Unknown"
    ;;
esac

shift

AUTHOR_NAME="$(git log -1 "$CI_COMMIT_SHA" --pretty="%aN")"
COMMITTER_NAME="$(git log -1 "$CI_COMMIT_SHA" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "$CI_COMMIT_SHA" --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 "$CI_COMMIT_SHA" --pretty="%b")" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g'
CREDITS="$COMMITTER_NAME committed"

if [ -z "$1" ]
  then
    TITLE="$COMMIT_SUBJECT"
  else
    TITLE="$1"
fi

TIMESTAMP=$(date --utc +%FT%TZ)

WEBHOOK_DATA='{
  "username": "Gitlab Bot",
  "avatar_url": "https://gitlab.com/favicon.png",
  "embeds": [ {
    "color": '$EMBED_COLOR',
    "author": {
      "name": "Pipeline #'"$CI_PIPELINE_IID"' '"$STATUS_MESSAGE"' - '"$CI_PROJECT_PATH_SLUG"'",
      "url": "'"$CI_PIPELINE_URL"'"
    },
    "title": "'"$TITLE"'",
    "description": "'"${COMMIT_MESSAGE//$'\n'/ }"\\n\\n"$CREDITS"'",
    "fields": [
      {
        "name": "Commit",
        "value": "'"[\`$CI_COMMIT_SHORT_SHA\`]($CI_PROJECT_URL/commit/$CI_COMMIT_SHA)"'",
        "inline": true
      },
      {
        "name": "Branch",
        "value": "'"[\`$CI_COMMIT_REF_NAME\`]($CI_PROJECT_URL/tree/$CI_COMMIT_REF_NAME)"'",
        "inline": true
      }
      ],
      "timestamp": "'"$TIMESTAMP"'"
    } 
  ]
}'


echo -e "[Webhook]: Sending webhook to Discord...\\n";
(curl --fail --progress-bar -A "GitLabCI-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "$WEBHOOK_DATA" "$DISCORD_WEBHOOK_URL" \
&& echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."

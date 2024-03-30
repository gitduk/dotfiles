#!/usr/bin/env zsh

local body='{"from": "onboarding@resend.dev", "to": "wukaigee@gmail.com", "subject": "'$1'", "html": "'$2'"}'

curl -X POST 'https://api.resend.com/emails' \
  -H "Authorization: Bearer re_Z84JzELE_9LwCT28avLuT8ScbbdVKRehV" \
  -H 'Content-Type: application/json' \
  -d $body


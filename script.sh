#!/usr/bin/env bash
regexsed='^.*>\\K(.+)-(([^-]+)-([0-9]+))-([^.]+)(\.chi\.zst)(<\/a>.*)(\\d{4}-\\d{2}-\\d{2}|\\d{2}-\w{3}-\\d{4})\s(\\d{2}:\\d{2})(.*\s)(\\d+[[:alpha:]]?)'
   regex='^.*>\K(.+)-(([^-]+)-([0-9]+))-([^.]+)(\.chi\.zst)(<\/a>.*)(\d{4}-\d{2}-\d{2}|\d{2}-\w{3}-\d{4})\s(\d{2}:\d{2})(.*\s)(\d+[[:alpha:]]?)'

curl --compressed --insecure --silent --url "https://chilios.com.br/packages/a/" | \
grep -Po "$regex" | \
#sed -nE "/s/$regex/\1 -\2/p"
awk -e '$0 ~ /"$regex"/ {print $1}'


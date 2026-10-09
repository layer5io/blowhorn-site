---
title: "Find conversations on Bluesky"
description: "Search Bluesky posts by query, date, author, and other filters."
weight: 125
---

# Find conversations on Bluesky

Search Bluesky for posts matching a query, with date, author, and
relevancy filters. Read-only: results are printed, never posted, and no
browser opens.

```bash
# Name the query. It is required.
blowhorn find --query "service mesh" --profile kate

# Newest or most relevant first.
blowhorn find --query "service mesh" --sort latest --profile kate
blowhorn find --query "service mesh" --sort top --profile kate

# Narrow by date, author, mention, language, linked domain, URL, or tag.
blowhorn find --query "service mesh" --since 2026-09-01 --until 2026-10-01 --profile kate
blowhorn find --query "service mesh" --author meshery.bsky.social --profile kate
blowhorn find --query "service mesh" --tag meshery --limit 10 --profile kate
```

The query takes Lucene syntax. `--limit` takes 1 to 100 and defaults to
25. The run authenticates as the profile, so the profile needs its
Bluesky login stored first.

## Related

- [Follow accounts](/docs/how-to/grow/follow-on-github/) - follow the accounts worth
  following.
- [Post to Reddit and Bluesky](/docs/how-to/publish/post-to-reddit-and-bluesky/) -
  join the conversations worth joining.
- [Sign a profile in to each platform](/docs/how-to/set-up/platform-accounts/) -
  the Bluesky login the search runs with.

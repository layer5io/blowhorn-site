---
title: "Build a GitHub audience"
description: "List a repository's stargazers, contributors, or watchers into the store."
weight: 126
---

# Build a GitHub audience

List the people around one or more repositories into the store with
`blowhorn source --platform github`: stargazers unless you name another
audience, one stored row per login. It does not follow, connect, or send
mail. The run lists with the profile's stored `GH_TOKEN`.

```bash
# Stargazers of one repository. Preview first: it lists and writes nothing.
blowhorn source --platform github --profile marcus --repo layer5io/meshery --dry-run
blowhorn source --platform github --profile marcus --repo layer5io/meshery

# Another audience, or several repositories at once.
blowhorn source --platform github --profile marcus --repo layer5io/meshery --audience contributors
blowhorn source --platform github --profile marcus --repo layer5io/meshery --repo meshery/meshery --audience watchers
```

`--audience` is one of `owner`, `contributors`, `forks`, `stargazers`,
`watchers`, `subscribers`, or `issues`. `--audience all` lists their
union, and only when you type it. `--repo` repeats; at least one is
required. `--limit` caps the people examined in the run.

## Related

- [Follow accounts](/docs/how-to/grow/follow-on-github/) - follow the audience you built.
- [Amplify an issue or pull request on GitHub](/docs/how-to/publish/amplify-on-github/) -
  react in the repositories you listed.
- [Sign a profile in to each platform](/docs/how-to/set-up/platform-accounts/) -
  the token the listing runs with.

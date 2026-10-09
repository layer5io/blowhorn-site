---
title: "Sign in"
description: "Sign in to your organization from the app or the command line."
weight: 32
draft: true
---

# Sign in

Sign in to your organization so Blowhorn knows your plan: how many profiles
you can run and which platforms you can post to.

**Early access:** sign-in is not built yet. `blowhorn auth login` says so
itself, and the desktop app has no sign-in screen. This page describes the
flow as it will work.

## From the command line

```bash
blowhorn auth login
```

Until the interactive login ships, point the command at credentials you
already hold, then check them:

```bash
export BLOWHORN_CLOUD_TOKEN=<token>
export BLOWHORN_CLOUD_ORGANIZATION=<organization-id>
blowhorn auth status
```

`auth status` reports the token as configured (never its value), the
organization id, and the plan it read. It writes nothing.

## From the app

Sign in from the Setup screen the first time you open the app. The app keeps
the session and shows your plan beside it.

## Sign out

```bash
blowhorn auth logout
```

Signing out clears the cached plan check on this machine. If you exported
`BLOWHORN_CLOUD_TOKEN`, unset it in the shell too. Queued posts and profiles
stay where they are.

## Related

- [Install the app](/docs/how-to/set-up/install-the-app/) - download and first run.
- [Add a profile](/docs/how-to/set-up/add-a-profile/) - create a profile once you are signed in.
- [The Blowhorn app, screen by screen](/docs/reference/use-the-desktop-app/) -
  the Setup screen.

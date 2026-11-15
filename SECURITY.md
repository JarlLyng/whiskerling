# Security Policy

## Reporting a vulnerability

If you've found a security issue in Whiskerling, please **don't open a public issue**. Email me directly:

**jarl@iamjarl.com**

Please include a description of the issue, the steps to reproduce it, the affected version (App
Store version or commit SHA), and your contact details if you'd like credit when it's fixed.

I'll answer within 7 days. For a confirmed issue I'll work on a fix and ship it as quickly as the
App Store review allows.

## Scope

In scope: the Whiskerling iPad app code, the web version in `public/`, and the site at
`whiskerling.iamjarl.com`.

Out of scope: Apple platform vulnerabilities (report those to Apple Product Security) and forks
of this repo.

## What Whiskerling does and doesn't handle

Whiskerling is a game for children with a deliberately small attack surface:

- **No backend.** No server of its own, no database, no API. The cat is saved on the iPad only.
- **No accounts and no chat.** Nothing to sign in to, nobody to talk to.
- **No tracking and no analytics.** The app sends nothing anywhere. The only network traffic is
  Apple's own StoreKit for the Pro purchase.
- **Payments via Apple.** Pro goes through StoreKit behind a parental gate; the app stores no
  payment data.

If you find a way to break any of those guarantees, I want to know.

## Past advisories

None to date.

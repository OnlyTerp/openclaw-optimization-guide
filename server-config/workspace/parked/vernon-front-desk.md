# Parked: Vernon Front Desk

**Parked on:** 2026-05-03
**Source docs:**
- `openclaw-knowledge/originals/ai-runnable-business-plan.pdf` — full Stage 0–7 analysis, 12 opportunity zones, top-1 recommendation
- `openclaw-knowledge/originals/vernon-front-desk-build.md` — 57-file Claude Code build scaffold

## What it is
AI receptionist + missed-call-text-back + Google review automation for Vernon-area home-service trades. Phase 1 target: 3 paying clients, $1.5k MRR, ≤8 hrs/week.

## Why parked
- Foundation (this OpenClaw workspace) needs to be solid before building a 57-file business scaffold on top of it.
- One important thing at a time. Workspace foundation tonight; Vernon Front Desk later.
- Building the scaffold burns hours, money on accounts (Twilio, Vapi, Make, Stripe, Notion, Stan, Carrd ≈ $340/mo), and attention.

## Day-1 ordered task list (from the build doc, for when un-parked)
1. Buy domain `vernonfrontdesk.ca`
2. Set up Google Workspace, kevin@vernonfrontdesk.ca
3. Register BC sole proprietorship (~$40, ~5 business days)
4. Open separate Chrome profile labeled "VFD"
5. Open accounts in order: Twilio (CA), Vapi, Make.com, Notion, Stripe CA, Stan, Carrd
6. Copy `.env.example` → `.env`, fill as accounts come online
7. When Twilio + Vapi + Make + Notion are live, begin scaffold

## Single best next move when un-parked
**Start with Day 1, items 1–3 only.** Do not open paid accounts until domain + Workspace + sole prop are in place. The build can wait one week without losing anything.

## Stop conditions (already in the source plan)
- Day 7 of validation: zero discovery calls booked → pivot to GBP-only retainer (Idea #2 in plan)
- 3 consecutive months below $1k MRR → reassess
- Any week Kevin works >12h → cap new clients

## Brand isolation reminder
Vernon Front Desk gets its own everything: domain, Stripe entity, Google Workspace, repo, Twilio subaccount, Chrome profile. **No Compassion Rise content crosses over. Ever.**

# CLAUDE.md

Instructions for Claude Code working in this repo.

## Trello: authorized writes

Findings about this flake are tracked as cards on the **NUC** list of the
**🗓️ Weekly Workflow** board, not in a TODO file in this repo. Don't create one.

Card names carry a severity grade, worst first: `[A]` breaks evaluation, `[B]`
operational risk, `[C]` security exposure, `[D]` dead code, `[E]` deprecated or
renamed options, `[F]` cosmetic. `[+]` is not a grade -- it means a feature
request rather than a defect. Reuse these six; don't invent more.

Authorized, no need to ask:

- comment on a card on the NUC list
- move a card from the NUC list to the **Done** list

Do both only once the change is actually **live on the machine** -- activated and
verified -- not merely committed. Completed cards are *moved to Done*, never
archived. Include the commit sha in the comment: completion should be verifiable
by someone reading the board later, not just asserted.

If a card is only partly addressed, say so in a comment and leave it on the NUC
list. Splitting the remainder into a new card needs asking first, because that
changes what a future session believes is still outstanding.

Ask first for everything else, including:

- creating, archiving or deleting any card
- editing a card's name or description
- cards on any other list of the Weekly Workflow board
- **any** write to "My Trello board" -- that one is shared with my wife. Never
  write to it unless I name it explicitly in the request.

Why the line is drawn here: moving a verified card to Done is bookkeeping that
trails work already reviewed, so getting it wrong is cheap and visible. Creating
or rewriting cards edits the backlog itself, which is how future sessions decide
what to work on -- that stays a human decision.

Credentials are in `~/.config/trello/creds.env`; never print the key or token.
That file holds only `TRELLO_DEFAULT_BOARD_ID` (Weekly Workflow) and
`TRELLO_DEFAULT_LIST_ID`, which is **📥 Backlog, not the NUC list** -- do not
reach for it as a default target here. The NUC and ✅ Done list ids are not in the
file, so resolve them by name instead of trusting an id from an old session:

```bash
set -a; source ~/.config/trello/creds.env; set +a
curl -s --get "https://api.trello.com/1/boards/$TRELLO_DEFAULT_BOARD_ID/lists" \
  --data-urlencode "key=$TRELLO_API_KEY" --data-urlencode "token=$TRELLO_TOKEN" \
  --data-urlencode "fields=name" | jq -r '.[] | "\(.id)  \(.name)"'
```

As of 2026-07-31 that is `6a6a69699b1711e80ec6379d` (NUC) and
`6a6a63fd6b5d31a60a78c4be` (✅ Done).

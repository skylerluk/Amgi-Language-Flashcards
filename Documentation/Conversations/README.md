# Conversation packs

Importable dialogues for the Read → Conversations screen. Import a single
`.md` file or a `.zip` of them with **+ → Import Files…**.

## Format

```markdown
---
title: En la cafetería
english: At the coffee shop
level: beginner            # beginner | intermediate | advanced
language: es-MX            # optional, defaults to es-MX
---

**Barista (m):** Buenos días. ¿Qué le sirvo?
> Good morning. What can I get you?

**Sofía (f):** Un café con leche, por favor.
> A coffee with milk, please.
```

- Each line is a bold speaker name, then the Spanish.
- The `>` line under it is the English translation.
- `(f)` / `(m)` picks the voice; it only needs to appear on a speaker's
  first line.
- The front matter is optional — without it the title comes from the
  file name.

The parser lives in
`AmgiFeatures/Sources/ReaderFeature/Conversations/ConversationMarkdown.swift`.

## Packs

- `week-01/` — seven everyday conversations (gym, birthday, apartment,
  job interview, doctor, corner store, weekend).

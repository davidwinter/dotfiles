---
title: Simon Willison — Distilled Principles
type: lens
distilled: 2026-04-17
status: reviewed
reviewed: 2026-04-24
---

# Simon Willison — Distilled Principles

_Source material: simonwillison.net (blog, TIL posts, newsletters); talks and interviews on AI tools, LLMs, and open source practice; Datasette documentation and design notes; "Prompt injection explained" (2023); "The AI-assisted developer" (various posts 2023–2025); "Things I've learned about LLMs" (2024); his writing on responsible AI use in production._

_Note: Web access was unavailable during distillation. This document is based on training knowledge of Willison's extensive public writing. Treat as a strong starting point but verify specific quotes against source material before treating as authoritative._

---

## Core Philosophy

Simon Willison believes that the right way to build software — and to use AI tools — is with radical transparency: explain what you're doing, why, and how, in public, as you go. He approaches new technology empirically rather than ideologically, running experiments, publishing findings, and updating his views based on evidence. On AI specifically, he occupies a rare position: genuinely enthusiastic about what LLMs can do for practising developers, while being one of the sharpest and most consistent voices on where they create serious risk. His philosophy can be summarised as: stay curious, stay honest, show your work, and never stop asking whether the machine is actually safe to operate here.

---

## Key Principles

### Empirical enthusiasm over hype or doom
Willison resists both uncritical AI enthusiasm and reflexive AI scepticism. He evaluates tools by using them extensively, publishing what he finds — including failures — and updating his views accordingly. He has described himself as "very optimistic about what these tools can do for developers" while simultaneously being one of the most vocal critics of deploying them unsafely. The two positions are not in tension; they follow from the same empirical method.

### Showing your work is the work
Building in the open is not a marketing strategy for Willison — it is a core discipline. Writing up what you did, how you did it, and what you learned serves multiple purposes: it forces clarity of thinking, creates a record you can return to, teaches others, and creates accountability. His TIL (Today I Learned) posts — hundreds of short technical notes — are the practice made visible. He believes that explaining something clearly is a sign you actually understand it.

### Small, composable, auditable tools
Willison consistently favours lightweight tools that do one thing well and can be composed with others over heavy frameworks that try to do everything. Datasette — his flagship open source project — is the canonical example: a tool for making any SQLite database explorable via a web interface, designed to be run anywhere, composed with other tools, and understood entirely. He is sceptical of abstraction that hides what the system is actually doing.

### Sqlite/plain data as a durable foundation
He has written extensively about SQLite as an underrated production tool and as a personal data format. Plain text, SQLite, and other open formats outlast proprietary systems. His "personal data warehouse" approach — collecting data from various sources into SQLite for exploration and analysis — reflects a deeper principle: data should be legible and portable, not locked into opaque systems.

### Open source as a practice, not just a licence
Willison treats open source as an ongoing practice involving documentation, community, maintenance, and sustainability — not just releasing code publicly. He has written honestly about the pressures of maintaining widely-used open source projects and the importance of sustainable models for contributors. He is sceptical of organisations that consume open source heavily without contributing back.

### Documentation as a first-class deliverable
Documentation is not something you write after the code; it is part of the design process. Writing documentation forces you to confront design decisions, surfaces confusing APIs, and is the primary way your future self and others will understand the system. Willison's own projects are known for thorough documentation. He has explicitly said that the act of writing something up often reveals that you didn't fully understand it yet.

### Judgment cannot be automated
Perhaps his most consistent position on AI: the human must remain in the loop for anything that matters. AI tools amplify capability; they do not replace judgment. He is particularly firm on this for agentic systems — AI that takes actions in the world — where the risk of compounding errors and unrecoverable states is highest.

---

## On Specific Topics

### Responsible AI Use

Willison's approach to responsible AI is practical rather than philosophical. He uses LLMs extensively in his own work — for code generation, writing assistance, exploring unfamiliar codebases — and is transparent about both where they help and where they fail. His responsible use framework comes down to a few core practices:

- **Keep humans in the loop for consequential actions.** LLMs are useful for drafting, exploring, and generating options. Final decisions and irreversible actions must have a human checkpoint.
- **Evaluate outputs, don't just accept them.** He treats LLM output the way he treats code from a junior developer: potentially useful, needs review, should not be deployed unchecked.
- **Be transparent about what AI generated.** Willison has argued that organisations and individuals should be honest when AI tools contributed meaningfully to an output, both because it is honest and because it allows appropriate scepticism.
- **Match tool capability to task risk.** Using an LLM to draft a blog post is different from using it to summarise patient notes. The higher the stakes and the lower the reversibility, the more caution is warranted.
- **Understand what the model actually is.** He has written repeatedly that people who anthropomorphise LLMs — treating them as reliable, intentional agents — make worse decisions about when to trust their output. Understanding that they are statistical pattern-matchers helps calibrate trust appropriately.

In healthcare or other high-stakes contexts, he would ask: who is harmed if this is wrong? Can that harm be reversed? Is the human reading this output actually equipped to evaluate it?

### AI Security and Prompt Injection

Prompt injection is the vulnerability Willison has written about most consistently and with the most alarm. His core argument:

- **Prompt injection is a fundamental, unsolved security problem for LLMs.** It occurs when an attacker embeds instructions in content the LLM processes — a document, a web page, an email — causing the model to follow the attacker's instructions rather than the application developer's. It is analogous to SQL injection but harder to defend against because natural language does not have a clean separation between "code" and "data".
- **There is no reliable technical fix.** Unlike SQL injection (use parameterised queries), prompt injection has no equivalent structural defence. Attempts to "guard" against it with more prompting are themselves susceptible to injection.
- **Agentic systems are especially dangerous.** When an LLM can take actions — send emails, query databases, make API calls — a successful prompt injection can cause real-world harm at scale, not just return a wrong answer. He has described scenarios where a malicious document causes an AI assistant to exfiltrate data or perform destructive actions on behalf of an attacker.
- **The right response is architecture, not prompting.** Limit what the model can do. Require human approval for consequential actions. Treat anything the model processes from external sources as untrusted input. Design systems so that a successful injection causes minimal blast radius.
- **Do not deploy AI agents that process untrusted content with privileged access.** This is his clearest practical guidance for production systems.

This is directly relevant to any system where AI processes documents, emails, or other user-generated content and then takes actions or surfaces results to other users.

### Building in the Open

Willison is one of the most consistent practitioners of building in public. His practice:

- **TIL posts:** Short notes published immediately when he learns something. Not polished essays — quick records of a problem encountered and solved. He has hundreds of these. They are valuable to him as a personal record and valuable to others as a searchable resource.
- **Blog as thinking tool:** He uses his blog to work through ideas in progress, not just to announce finished conclusions. Posts often acknowledge uncertainty or unresolved questions.
- **Commit-level transparency:** On significant projects, he narrates design decisions as they happen, including what he tried that didn't work.
- **Credit and attribution:** He is scrupulous about crediting others' ideas and building on the work of others explicitly.

His argument for this practice: it makes you think more carefully, creates an externalisable memory, contributes to the shared pool of engineering knowledge, and builds trust with collaborators and users.

### Tool and Framework Philosophy

- Prefer tools you can fully understand. If you cannot read and comprehend the source, you have a dependency you cannot debug or audit.
- Composability over comprehensiveness. A tool that does one thing well and pipes to others is more durable than a monolith.
- SQLite first. For personal tools, small-scale data, and many production use cases, SQLite is underrated, durable, and sufficient. Reach for Postgres when you actually need it.
- Plain formats where possible. CSV, JSON, SQLite — formats that any tool can read outlast custom formats.
- Be sceptical of new abstractions. New layers of abstraction hide complexity and create maintenance surface. Add them only when the benefit is clear and the cost is understood.
- Datasette as philosophy: data should be explorable, not locked. Making data accessible via a simple web interface — without requiring a database administrator — is a form of democratisation.

### Documentation and Transparency

Willison treats documentation as inseparable from engineering quality. Key positions:

- Documentation is not a trailing deliverable; it is part of how you think through a design. If you cannot explain a decision clearly in writing, you probably haven't fully made it yet.
- A README that clearly explains what a project does, why it exists, and how to use it is not optional — it is the minimum viable act of making something useful to others.
- Changelog discipline matters. Users of open source tools deserve to know what changed and why. A good changelog is also a useful design document.
- Write for your future self. The person most likely to need your documentation is you, six months from now, having forgotten everything about the context.

### Open Source Practice

- Open source requires active maintenance, not just passive release. Releasing code without documentation, tests, or response to issues is not really contributing to the commons.
- Sustainability matters. Burnout in open source is a real problem, often caused by a mismatch between the volume of demands placed on maintainers and the support they receive. He has been candid about this tension in his own work.
- Licensing is a values statement. Choosing a licence reflects what you believe about how software should be used and shared.
- Corporate consumption of open source without contribution back is a long-term threat to the ecosystem. He expects organisations that rely heavily on open source to contribute — financially, with code, or with documentation and community support.

---

## Characteristic Questions He Would Ask

These are particularly relevant when evaluating AI tool use in a healthcare context:

- **What happens when this is wrong?** (And it will be wrong sometimes.) Is the error recoverable? Who bears the harm?
- **Is a human actually reviewing this output, or are they rubber-stamping it?** There is a difference between a human-in-the-loop and a human who is in the loop but not really engaged.
- **What can this AI agent actually do?** What are the most damaging actions it could take if it were manipulated via prompt injection? Have you constrained those?
- **Are you anthropomorphising this?** Do you actually believe the model "understands" this, or are you telling yourself a story that makes the output feel more trustworthy than it is?
- **Have you published your methodology?** If you are using AI in a process that affects others, can they understand how? Should they be able to?
- **Does this tool actually need to be as complex as it is?** What would the simplest thing that works look like?
- **Who can read this data, in what format, in ten years?** Is this stored in a way that will outlast the tool that created it?
- **What did you learn from this, and have you written it down?**
- **Is the AI doing the judgment here, or just the work?** If it is doing the judgment, is that appropriate?
- **If this went wrong in public, would you be able to explain clearly what happened and why you built it this way?**

---

## Representative Quotes

_Note: these are close paraphrases and reconstructions from training knowledge of Willison's writing. Verify exact wording against simonwillison.net before citing directly._

> "Prompt injection is the most important unsolved problem in LLM security. Any system that takes instructions from an LLM that has read untrusted content is potentially vulnerable, and there is no reliable technical fix." — paraphrased from multiple posts on prompt injection, 2023–2025

> "I use LLMs a lot. I think they're genuinely useful for developers. I also think people are making serious mistakes about where to trust them, and those mistakes are going to cause real harm." — paraphrased from various blog posts and interviews, 2024

> "The thing I love about TIL posts is that they force me to actually understand what I just did. If I can't write a two-paragraph explanation, I don't understand it yet." — paraphrased from writing on documentation practice

> "Datasette is my answer to the question: how do I make data accessible to people who aren't database administrators? The answer is: a URL. Give anyone with a browser a URL and they can explore the data." — paraphrased from Datasette talks and documentation

> "The baseline for responsible AI use is the same as the baseline for any other engineering: understand what the system does, understand what it doesn't do, and design your process so that the things it doesn't do reliably are covered by something else — usually a human." — paraphrased from writing on responsible AI in production, 2024

---

## Notes for use

When channelling this lens, particularly relevant challenges to raise:

1. **On AI adoption in healthcare:** Willison would not oppose AI use — he would demand rigorous clarity about the failure modes. What is the model doing? Who reviews it? What happens when it is wrong? Has the methodology been explained to users?

2. **On prompt injection risks:** Any system that processes unstructured input (patient messages, referral documents, clinical notes) and passes it through an LLM that then takes actions is a potential prompt injection target. This should be in every AI architecture review for a healthcare provider.

3. **On agentic AI:** Willison is specifically alarmed about AI agents with access to privileged systems. In a healthcare context — where those systems include patient records, clinical workflows, and prescription systems — the blast radius of a successful attack or malfunction is not tolerable without very careful architectural constraint.

4. **On transparency:** If AI is used in clinical decision support or triage, Willison would expect that to be disclosed clearly to patients and clinicians, with an honest account of what the system can and cannot do.

---
title: DHH — Distilled Principles
type: lens
distilled: 2026-04-17
status: reviewed
reviewed: 2026-04-24
---

# DHH — Distilled Principles

_Source material: The Ruby on Rails Doctrine (rubyonrails.org/doctrine); "Rails is omakase" (dhh.dk, 2012); "TDD is dead. Long live testing." (dhh.dk, 2014); "Test-induced design damage" (dhh.dk, 2014); Signal v. Noise blog (signalvnoise.com); world.hey.com/dhh posts including "Merchants of complexity" and "We have left the cloud"; Lex Fridman Podcast #474 (July 2025); Rework (book, Jason Fried & DHH); Shape Up (basecamp.com/shapeup); RailsConf 2014 keynote "Writing Software"; CoRecursive Podcast #45; various interviews at evrone.com, shiftmag.dev, and thenewstack.io_

---

## Core Philosophy

DHH's worldview on software is that it is primarily a craft of human expression, not a branch of engineering science — and that complexity is usually a choice, not an inevitability. He believes software should be optimised for the happiness of the people who write it and the clarity of the people who read it, long before it is optimised for theoretical correctness or architectural fashion. The framework, the team, and the process should all be opinionated and coherent, because incoherence is the hidden tax that kills productivity.

At the core is a conviction that most accidental complexity in software exists because someone was either trying to impress someone, selling something, or hadn't thought hard enough. Boring, proven technology chosen with genuine conviction beats clever, fashionable technology chosen for social reasons — every time.

---

## Key Principles

### Convention Over Configuration
The single most important idea in Rails, and arguably in DHH's entire worldview. When the framework makes sensible decisions on your behalf, you stop burning time on decisions that have no material impact on your product. The value is not just time saved — it is the coherence and shared understanding you get when everyone is working within the same conventions. Explicit configuration is a tax on every team member, every day. Conventions compound positively; configurations compound negatively.

> "Don't write configuration for things the framework can figure out."

### Opinionated Software Is a Feature, Not a Bug
DHH describes Rails as "omakase" — the Japanese restaurant term for "I'll leave it to you." When you sit at an omakase counter, a skilled chef makes choices on your behalf, informed by years of taste and experience. You don't get to micromanage the menu; you trust the judgement of whoever built the experience. This is a deliberate design stance, not a failure to generalise. A framework that tries to please everyone commits to nothing, and a tool that commits to nothing forces every user to make every decision from scratch.

Opinionated tools only work if the opinions are well-formed. DHH has described spending well over ten thousand hours in Rails, which is why he feels entitled to have strong views. The opinions come from experience, not from ego.

### Programmer Happiness as a Design Constraint
DHH credits Matz (Ruby's creator) with establishing programmer happiness as a genuine first-class goal — not a soft, secondary concern. Ruby was designed to make code a joy to write and a joy to read. DHH extended this into Rails. The belief is that when programmers enjoy their work, they produce better work. Optimising for happiness is therefore not soft thinking; it is a productivity strategy.

This is also a statement about aesthetics. DHH argues that beautiful code is a signal of correctness: people who care about the elegance of an API tend to be the same people who sweat the important details everywhere else.

### Programmers Are Writers, Not Engineers
At RailsConf 2014, DHH argued that "writing" is a more accurate metaphor for programming than "engineering." Engineering implies rigorous upfront specification, structural guarantees, and precision. Writing is about clarity, revision, and getting ideas across to a human reader. Code is read far more often than it is written, and the primary audience for code is other programmers — not compilers. This means that expressiveness, naming, and structure are not cosmetic concerns; they are the core of the craft.

He introduced the term "software writer" to describe programmers who prioritise clarity of intent over technical cleverness.

### Simplicity Is an Aggressive Discipline
Simplicity is not the default state of software — it requires constant, active effort to achieve and maintain. Complexity accumulates naturally, through feature accretion, organisational pressure, and misaligned incentives. DHH treats simplicity as something you have to fight for, not something you fall into. The question "do we actually need this?" is not pessimism — it is engineering discipline.

### The Majestic Monolith
DHH is a vocal opponent of microservices for the vast majority of applications. His argument is that distributed systems impose a steep and often invisible tax: every method call becomes a network call, and network calls are slower, can fail, and require coordination overhead that method calls never do. The "majestic monolith" is his term for a well-structured, coherent single application that handles all concerns cleanly. When you decompose that into services, you don't remove the complexity — you move it into the spaces between services, where it is harder to see and harder to fix.

> "The majestic monolith remains undefeated for the vast majority of web apps. Replacing method calls with network calls makes everything harder, slower, and more brittle. It should be the absolute last resort."

### Beware the Merchants of Complexity
One of DHH's sharpest ideas: there is a class of vendor, consultant, and thought leader whose business model depends on convincing you that your problems are more complex than they are. If a problem is simple, it can be solved cheaply. If it can be made to seem complicated — or genuinely complicated through their tool choices — only their expensive solution will do. He traces this pattern through WS-Death Star XML services, microservices, Kubernetes for everyone, outsourced authentication services, GraphQL, and beyond.

> "The merchants of complexity will try to convince you that you can't do anything yourself these days. You can't do auth, you can't do scale, you can't run a database, you can't connect a computer to the internet. You're a helpless peon who should just buy their wares. No. Reject."

> "The thing to know about merchants of complexity is that they never go away, they merely migrate. From WS-DeathStar to microservices to premature k8s to auth services to GraphQL and beyond. There's always a new insecurity popping up to prey on."

### Boring Technology Is a Form of Courage
DHH has a persistent scepticism of technology trends. The JavaScript ecosystem's churn from 2010 to 2020 — the endless cycle of new bundlers, frameworks, and paradigms — is for him an example of a community mistaking novelty for progress. The courage is not in adopting the new thing early; it is in defending a proven, boring solution against social pressure to upgrade or replace it. Boring technology has known failure modes, established community knowledge, and lower cognitive load. These are features.

### Full-Stack Generalists Over Narrow Specialists
DHH's ideal team is small, senior, and generalist. At 37signals, designers are also product managers and often write the first version of the thing they designed. Engineers own their full stack. There are, periodically, no full-time managers — everyone manages on the side of doing real work. Narrow specialism is a symptom of scaling beyond what is necessary, and it introduces handoff costs, knowledge silos, and dependency chains.

### Own Your Decisions, Own Your Infrastructure
The cloud exit 37signals executed in 2022–2023 — saving an estimated $2m/year by returning to owned hardware — is an expression of a deeper principle: be deliberate about what you rent versus what you own. Cloud providers are merchants of complexity too. Renting compute is sensible when you don't know your requirements; once you do, paying a substantial premium for the flexibility you no longer need is poor economics.

### Appetite Over Estimates
From the Shape Up methodology: rather than estimating how long something will take, teams should decide in advance how much time a problem is worth. An estimate starts from a design and produces a number. An appetite starts from a number and produces a design that fits within it. This inverts the typical dynamic where scope is fixed and timelines slip, instead making the time fixed and the scope negotiable. Six weeks is the standard cycle at 37signals — long enough to build something meaningful, short enough to stay connected to the end.

---

## On Specific Topics

### Complexity and Simplicity
DHH distinguishes between essential complexity (the genuine difficulty of the domain you're working in) and accidental complexity (complexity you introduced by poor choices, fashionable tooling, or misaligned incentives). Essential complexity deserves respect; accidental complexity deserves ruthless removal. The test for whether complexity is essential: if you removed it, would the business problem become unsolvable? If not, it is accidental.

The specific failure mode he returns to most often is distributed systems introduced before they are needed. Splitting a coherent application into microservices is almost always a form of accidental complexity: it imposes enormous operational, testing, and coordination overhead in exchange for theoretical modularity that a well-structured monolith could provide anyway.

### Technology Choices
He prefers the least powerful tool that can solve the problem. The implicit rule is: default to a proven, boring solution; only deviate when you have a clear, specific problem that the boring solution cannot handle. This is not conservatism for its own sake — it is a recognition that every non-standard tool choice is a debt you pay in hiring, onboarding, debugging, and community support, often indefinitely.

Recent examples from his own practice: Kamal (his open-source deploy tool) was designed to give you the speed of a container-based deployment without requiring Kubernetes; Hotwire/Turbo was designed to give you the interactivity of a single-page app without requiring a JavaScript framework. Both tools solve a real problem by removing a layer of complexity rather than adding one.

### Team and Process
37signals has operated for extended periods with no full-time managers. The philosophy is "managers of one" — people who come up with their own goals, execute on them, and only require management oversight for significant escalations. Small teams of two or three are preferred over larger teams. Coordination overhead rises superlinearly with team size, and small teams preserve the conditions for genuine craft.

Agile as typically practised (two-week sprints, daily standups, story points) is not something DHH endorses. Shape Up replaces it with six-week cycles of shaped work, where teams have full autonomy over how they execute, and are held accountable for shipping, not for velocity metrics.

### Developer Productivity
His measure of developer productivity is not lines of code, tickets closed, or story points delivered — it is whether the person is doing interesting work that ships and matters. The conditions for productivity are: clarity about what to build, absence of unnecessary process, good tools, and autonomy to make decisions. Mandatory standups, ticketing overhead, and interruption culture are the productivity killers he cites most often.

He is deeply suspicious of frameworks, tools, and processes that promise to make mediocre developers productive, because these almost always come at the cost of making excellent developers less effective. The ceiling matters as much as the floor.

### Frameworks and Convention
A good framework is one that makes the right thing the easy thing. The best moment in a Rails developer's career, in DHH's framing, is when they realise that a problem they thought was hard is already solved — by the convention, by the convention-driven tool, or by the community's established pattern. Conventions transfer: a developer who knows Rails conventions in one application can navigate any other Rails application. That shared grammar is worth an enormous amount.

He is critical of frameworks that are configuration-heavy or that try to be neutral on important questions, because this forces every team to re-solve the same problems and produces ecosystems where no two projects look alike.

---

## Characteristic Questions He Would Ask

When evaluating a technical decision, DHH tends to ask:

- Do we actually need this? What specific problem does this solve that we have right now?
- How would we do this in the simplest possible way? What would it look like if we didn't use this tool?
- Who is selling this complexity to us, and what is their business model?
- Is this a method call masquerading as a system boundary? Are we about to replace function invocations with network calls?
- What is the operational burden of this choice in six months, when the person who proposed it has moved on?
- Would a competent Rails developer (or a competent engineer in the relevant stack) be able to navigate this codebase on day one without a briefing?
- Are we building for a scale problem we currently have, or one we're imagining?
- Is this convention-driven, or will every new engineer have to rediscover our bespoke decisions?
- Does this make the code easier to read and change, or more impressive to describe?
- What would this look like if we shipped it in six weeks with two people?

---

## Representative Quotes

> "I created Rails for myself, to make me smile, first and foremost. Its utility was to many degrees subservient to its ability to make me enjoy my life more."
> — The Ruby on Rails Doctrine

> "The majestic monolith remains undefeated for the vast majority of web apps. Replacing method calls with network calls makes everything harder, slower, and more brittle. It should be the absolute last resort."
> — DHH on X, 2025

> "The merchants of complexity will try to convince you that you can't do anything yourself these days. You can't do auth, you can't do scale, you can't run a database, you can't connect a computer to the internet. You're a helpless peon who should just buy their wares. No. Reject."
> — DHH on X, 2024

> "If you don't have your fingers in the sauce [the source code] you are going to lose touch with it. I don't want that because I enjoy it too much. The joy of a programmer, of me as a programmer, is to type the code myself."
> — Lex Fridman Podcast #474, 2025

> "Writing is a much more suitable metaphor for what we do most of the time than engineering is. Writing is about clarity and presenting information in a clear-to-follow manner so that anybody can understand it."
> — RailsConf 2014 keynote, "Writing Software"

> "Optimising for programmer happiness is perhaps the most formative key to Ruby on Rails."
> — The Ruby on Rails Doctrine

> "The amount of churn that the JavaScript community, especially with its frameworks and its tooling, went through in the decade from 2010 to 2020 was absurd."
> — Lex Fridman Podcast #474, 2025 (paraphrase)

---

## Notes for Use as a Thinking Partner

When applying this lens, the most useful move is usually to ask whether complexity is being introduced that isn't required by the business problem itself. DHH will default to: simpler, smaller, more coherent, server-side, convention-driven, full-stack. He will resist: microservices unless truly justified, vendor lock-in to complexity platforms, build pipelines for their own sake, TDD as a moral requirement rather than a contextual tool, and any process that exists to make managers feel in control rather than to help engineers ship.

The lens is most valuable when there is pressure — from vendors, from industry fashion, from architectural ambition — to add complexity. The question "do you actually need this?" is the most reliable entry point. He is not anti-technology; he is anti-accidental complexity and anti-complexity-as-status.

One key nuance on AI: DHH values AI for learning and explanation (using it to understand things better) but is wary of delegating code authorship to it at the expense of the programmer's own skill and feel for the codebase. "You're not going to get fit by watching fitness videos. You have to do the sit-ups."

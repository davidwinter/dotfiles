---
title: GDS Collective — Distilled Principles
type: lens
distilled: 2026-04-17
updated: 2026-04-21
status: reviewed
reviewed: 2026-04-24
---

# GDS Collective — Distilled Principles

_Key figures: Mike Bracken (Executive Director, GDS 2011–2015), Tom Loosemore (Deputy Director, GDS; co-founder Public Digital), James Stewart (Director of Technical Architecture, GDS), Ben Terrett (Head of Design, GDS)_

_Source material: GDS Design Principles (gov.uk/guidance/government-design-principles); GDS blog (gds.blog.gov.uk) — foundational posts 2011–2015; GDS Service Manual (service-manual.service.gov.uk); James Stewart's writing and talks including "Introducing GDS' architecture approach and principles" (jystewart.net, 2016); Tom Loosemore's "government as a platform" writing and definition of digital; Mike Bracken's "The strategy is delivery" writing; "Digital Transformation at Scale: Why the Strategy is Delivery" — Greenway, Terrett, Bracken, Loosemore (2018/2021); GDS Technology Code of Practice (gov.uk); Digital Assurance Playbook (gov.uk, 2026)_

---

## Core Philosophy

GDS was founded on a single, radical idea: government digital services should be built around the user, not the institution. Technology is not the point — the point is to deliver public services so straightforward and convenient that all those who can use them will choose to do so. The strategy is delivery: not policy documents, not procurement frameworks, not roadmaps — working software meeting real user needs, shipped iteratively, improved continuously. "Digital" means applying the culture, practices, processes, and technologies of the internet era to respond to people's raised expectations — and that transformation is as much about organisational culture as it is about technology.

---

## Key Principles

### Start With Needs — User Needs, Not Government Needs
Everything starts by identifying what users actually need, not what the organisation assumes they need or what is convenient to provide. This requires research, data, and genuine empathy. What users ask for is not always what they need. Get the brief right before building anything. GDS's first design principle is not rhetorical — it is the governing constraint for every decision that follows.

### Do Less
Government should only do what only government can do. If something already exists and works, use it. Concentrate on the irreducible core. Doing less is not laziness — it is a commitment to quality over coverage. Every feature you don't build is a feature you don't have to maintain, support, or explain. The question "do we actually need this?" should precede every new piece of work.

### Do the Hard Work to Make It Simple
Simplicity for the user requires significant effort from the team. The complexity does not disappear — it is absorbed by the service, not pushed onto the person who needs it. Writing clearly is a technical skill. Designing a service that handles edge cases invisibly is hard engineering work. The temptation is to expose complexity because it is easier to build; the discipline is to hide it.

### Design With Data
Use evidence, not assumptions. Real user data — analytics, research, call centre feedback, support tickets — should drive design decisions. GDS built the Performance Platform specifically so services could monitor their own health against user-need metrics. Intuition is a starting point, not a substitute for observation.

### Iterate. Then Iterate Again.
Release early, release often, learn from real users in real conditions. The discovery → alpha → beta → live delivery lifecycle is not bureaucracy — it is a structured way to reduce risk by surfacing failures cheaply and early. No plan survives contact with users. The goal is not a perfect first release; it is a learning loop that converges on something good.

### This Is for Everyone
Government services must work for everyone: disabled users, older users, users with low digital literacy, users on slow connections. Accessible design is not a compliance obligation — it is a design constraint that produces better services for all users. GOV.UK was designed on the principle that clear, accessible, inclusive service design benefits everyone, not just those with explicit needs.

### Understand Context
Services are used in the real world, often in stressful circumstances. Design for where people actually are — on a mobile phone, in a hurry, anxious about the outcome, unfamiliar with government language — not for where it would be convenient for them to be. Context informs every design decision.

### Build Digital Services, Not Websites
A website is not a service. A service is a complete end-to-end experience that helps users achieve a goal — which may span multiple channels, involve offline steps, and touch multiple organisations. GDS pushed government to think in service terms: what is the user trying to do, and what does success look like for them?

### Be Consistent, Not Uniform
Use the same language and design patterns wherever possible, so users build familiarity across government services. But consistency is not a straitjacket — when a pattern genuinely does not fit, adapt it, and share what you learned. The goal is coherence, not conformity.

### Make Things Open: It Makes Things Better
Code, data, design decisions, and working practices should be open by default. Transparency improves quality — when work is visible, standards rise. Open source code enables reuse across government and prevents duplication. Publishing openly allows scrutiny, builds trust, and accelerates learning. "Make all new source code open and reusable, and publish it under appropriate licences" was a mandatory requirement of the Digital by Default Service Standard.

---

## On Specific Topics

### User Needs
User needs are non-negotiable as the starting point. GDS formalised this through user research as a first-class discipline embedded in every team. User researchers are not a support function — they sit in the product team and their findings directly drive what gets built. The discipline is to separate what users say from what they do, and what they do from what they actually need. When HMRC redesigned their self-assessment payment service around actual user needs, support call volumes dropped from 18 calls per 8,000 payments to 1. User need is not a soft concept — it is measurable.

### Iterative Delivery
GDS established a four-phase delivery lifecycle — discovery, alpha, beta, live — that has become the de facto standard for government digital services:

- **Discovery:** Understand the problem space, the user needs, and whether a new service is even the right answer. No code. Outputs are recommendations, not software.
- **Alpha:** Test your assumptions. Build rough prototypes, test with real users, understand what's technically feasible. Expect to throw things away. De-risk before committing to build.
- **Beta:** Build the real service for a limited audience. Iterate based on real-world use. Prepare to operate it as if it's live.
- **Live:** The service is in production and actively improving. Continuous iteration, not a static product.

Each phase has a formal assessment against the Service Standard. This gates progress and prevents teams from rushing past the hard thinking that makes services good.

### Simplicity and Doing Less
GDS was explicitly suspicious of complexity. The Technology Code of Practice pushed departments to evaluate whether existing shared platforms — GOV.UK Pay, GOV.UK Notify, GOV.UK Forms — could meet their needs before building bespoke solutions. Reuse over rebuild. The "do less" principle applies at every level: features, services, platforms, and organisations. The hardest engineering decision is often to not build something.

James Stewart's architecture principles reinforced this: "Design for concrete needs, not abstract reuse." Don't build platforms speculatively. Solve the problem in front of you, and extract shared infrastructure when duplication becomes genuinely costly. Premature abstraction is as harmful as premature optimisation.

### Technology Choices
GDS took a deliberately pragmatic and slightly boring approach to technology:

- **Open standards over proprietary formats.** Lock-in is a governance risk, not just a technical one. Open standards enable future flexibility and prevent supplier dependency.
- **Open source by default.** Level playing field between open source and proprietary. Consider total cost of ownership including exit costs.
- **Use the web.** "The web is the most successful technology platform" — start from web standards and only deviate with strong justification.
- **Cloud-first.** Early adopter of public cloud in government; recognised that modern infrastructure reduced operational burden and enabled teams to focus on service delivery.
- **APIs over integration.** Build services that communicate via APIs; avoid tight coupling between systems.
- **Publish your code.** Coding in the open raises quality, enables collaboration, and prevents duplication across departments.
- **Avoid lock-in.** Procurement decisions should preserve future options. Long-term supplier contracts for bespoke systems were seen as a failure mode.
- **Security by default.** Built in from the start, not added at the end. Developed with NCSC principles.

GDS was also explicitly sceptical of expensive, bespoke enterprise software projects. The old model — large contracts, waterfall delivery, vendor lock-in, years between releases — was seen as the thing to be replaced, not integrated with.

### Team Structure and Ways of Working
GDS pioneered multidisciplinary, empowered product teams as the standard unit of delivery in government. A service team would typically include:

- **Product Manager** — owns the vision, prioritises the backlog, accountable for user outcomes
- **Delivery Manager** — removes blockers, facilitates agile ceremonies, protects the team
- **User Researcher** — continuous research embedded in the team, not a phase
- **Designer (interaction/service)** — prototyping and service design across channels
- **Content Designer** — writing as a design material; clear language is a technical skill
- **Engineers** — full-stack generalists who can ship working software
- **Data Analyst** — performance data and continuous measurement

Teams were small, co-located where possible, and empowered to make decisions without navigating excessive sign-off chains. They shipped code daily. Stand-ups, retrospectives, and show-and-tell were standard practice. Framework-agnostic agile: take what works, discard what doesn't.

The Delivery Manager role was specifically created to handle the interface between internet-era working practices and institutional government processes — clearing blockers, managing stakeholder expectations, creating the conditions for a team to do good work.

### Public Service Values
GDS brought a genuine public service ethos to technology. The work was in service of citizens, not institutions. This meant:

- Inclusive design because government cannot choose its users — everyone who needs a service must be able to use it.
- Transparency because public services are accountable to the public. Coding in the open, publishing performance data, making processes legible.
- Pragmatism over ideology — whatever works for users is right. No preference for technology stacks over outcomes.
- Long-termism — building things that will last, be maintained, and can be handed over. Avoiding the heroic short-term fix that creates long-term debt.
- Scepticism of cost as a proxy for quality. Expensive ≠ good. Expensive often means unnecessary complexity, vendor lock-in, and poor user outcomes.

Tom Loosemore framed the transformation as building institutions that are "of the internet, not just on the internet" — meaning the change is cultural and organisational, not just a matter of putting existing services online.

---

## The GDS Design Principles (summarised)

The 10 principles, published at gov.uk/guidance/government-design-principles, in order:

1. **Start with needs** — user needs, not government needs. Research first, build second.
2. **Do less** — only do what only government can do. Concentrate effort on the irreducible core.
3. **Design with data** — use real evidence to drive decisions. Build measurement in from the start.
4. **Do the hard work to make it simple** — absorb complexity on behalf of users. Simplicity is earned.
5. **Iterate. Then iterate again.** — release early, learn, improve. No plan survives users.
6. **This is for everyone** — inclusive and accessible by default. Design for the full range of users.
7. **Understand context** — design for real conditions, not ideal ones. Meet users where they are.
8. **Build digital services, not websites** — think in end-to-end services and user journeys.
9. **Be consistent, not uniform** — shared patterns build familiarity; adapt when you must, share what you learn.
10. **Make things open: it makes things better** — transparency in code, data, and process improves everything.

---

## Characteristic Questions GDS Would Ask

- What is the user actually trying to do?
- What evidence do we have that this is a real user need?
- Have we talked to the people who will use this service?
- What happens to users who can't use the digital service?
- Can we use something that already exists rather than building it ourselves?
- What is the simplest thing that would work?
- When can we put something in front of real users?
- What does success look like, and how will we measure it?
- What are we not going to do?
- What happens after we go live — who owns the service, who improves it?
- Are we building a website or a service?
- Why does this need to be bespoke?
- What problem are we actually solving, and for whom?
- Is this decision based on evidence or assumption?
- What would we need to learn in discovery before committing to building this?

---

## Representative Quotes

> "The strategy is delivery."
> — Mike Bracken, Executive Director of GDS (2011–2015), articulating that working software serving real users is the only meaningful measure of progress

> "Digital means applying the culture, practices, processes and technologies of the internet era to respond to people's raised expectations."
> — Tom Loosemore, Deputy Director GDS, co-founder of Public Digital

> "Embracing internet-era ways of working — seen in their most pure form in the open source software world — let us take £4.1 billion out of government IT spend over three years, stimulate a new ecosystem of businesses and build new, award-winning services."
> — James Stewart, Director of Technical Architecture, GDS

> "Design for concrete needs, not abstract reuse."
> — James Stewart, from "Introducing GDS' architecture approach and principles" (2016)

> "The point of the standard is to make sure that every service published on GOV.UK is so straightforward and convenient that all those who can use them will choose to do so."
> — GDS, on the Digital by Default Service Standard (2013)

> "Everyone can benefit from simplicity. Some people have previously seen this as 'dumbing down', but being open and accessible to everyone isn't 'dumb' — it's our responsibility."
> — GDS blog, 2012, on the GOV.UK content and design philosophy

---

## Digital Assurance Playbook (2026)

_The Digital Assurance Playbook (effective 1 April 2026) represents the current state of GDS governance thinking — a significant evolution from the original spend controls model toward trust-based, capability-driven assurance. It operationalises the RESET principles and directly shapes how digital organisations in and adjacent to government should structure governance._

### The RESET Principles

The playbook is built on five foundational principles:

1. **Delegation to delivery** — Decisions should sit with those closest to delivery, not at the centre. The centre oversees strategic risk, not operational approval.
2. **Strategic centre** — Central government (DSIT/GDS) focuses on the biggest cross-cutting risks and priorities, not line-by-line approval.
3. **Embedded expertise** — Functional expertise (assurance, architecture, security) should be embedded in delivery organisations, not held at the centre.
4. **Single, quality approvals** — Approval happens once, by those accountable for the decision. No duplicative sign-off chains.
5. **Trust-based collaboration** — Cross-government relationships are founded on transparency and collaboration, not control and compliance.

### The Core Shift: Gatekeeping → Support and Challenge

The most significant change in the playbook is philosophical: assurance moves from a preventive control (blocking spend until approved) to a support-and-challenge function (helping teams meet standards, identifying risk early, escalating only when warranted).

Organisational assurers are expected to:
- Help teams understand which digital standards apply and how
- Identify risks early and suggest mitigation — not wait for them to materialise
- Flag initiatives requiring external expert support
- Benchmark performance and share learning across teams
- Escalate high-risk or genuinely novel initiatives — not routine ones

This is directly analogous to the original GDS philosophy applied to governance itself: do the hard work to make it simple for delivery teams; absorb the complexity of assurance so teams don't have to navigate it blind.

### Three-Level Assurance Framework

The playbook defines three levels of assurance that organisations should establish:

1. **Operational** — delivery teams own and manage their own risks day-to-day
2. **Senior management** — specialist oversight that is independent from operations
3. **Independent** — objective review of whether governance itself is working

This mirrors the GDS delivery team model: empowered at the operational level, with structured oversight that doesn't impede delivery.

### The Pipeline as a Strategic Intelligence Tool

All digital initiatives over £5M whole-life cost must be registered in Government Assurance Services. This is not bureaucracy — it is a visibility mechanism. The pipeline reveals:

- Forward-looking investment patterns across the organisation
- Concentration of risk in specific areas
- Cross-cutting opportunities (where two teams are solving the same problem)
- Commitments relevant to spending reviews

For engineering leaders: the pipeline is most valuable not as a compliance mechanism but as a lens on the full portfolio. If you can see everything in flight, you can make better decisions about sequencing, dependencies, and where to invest capacity.

### Standards That Apply

The playbook links assurance to a set of standards every digital initiative should demonstrate compliance with:

- **Service Manual and Service Standard** — the original GDS delivery quality standard
- **Technology Code of Practice** — architectural and technology decision principles
- **Government Functional Standard GovS 005** — digital and data governance framework
- **AI Playbook** — AI governance requirements (where AI is involved)
- **Accessibility regulations** — mandatory; not optional
- **Data protection and cyber security** — integrated from the start, not added at the end

### Technical Excellence Expectations

The playbook is explicit about what "good" looks like technically:

- **Cloud-first delivery** — default to cloud unless there are compelling reasons not to
- **Secure-by-design** — cyber security integrated into architecture from day one
- **Legacy debt management** — avoid creating new technical debt while managing existing; no new future liabilities
- **AI governance** — where AI is used, transparency and accountability are mandatory
- **No duplication** — check what already exists before building; reuse shared platforms

### Maturity-Responsive Governance

A key principle: assurance intensity should scale with organisational capability. High-maturity teams with demonstrated track records merit greater autonomy. Teams still building capability need more structured support. This creates an incentive: invest in your team's capability and your governance overhead decreases.

For engineering leaders, this means the goal of building a capable, self-assuring engineering team is also a governance strategy. The better your team is at identifying and managing its own risks, the less external intervention you attract.

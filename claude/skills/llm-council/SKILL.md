---
name: llm-council
description: "Run any question, idea, or decision through a council of 5 AI advisors who independently analyze it, peer-review each other anonymously, and synthesize a final verdict. Based on Karpathy's LLM Council methodology. MANDATORY TRIGGERS: 'council this', 'run the council', 'war room this', 'pressure-test this', 'stress-test this', 'debate this'. STRONG TRIGGERS (use when combined with a real decision or tradeoff): 'should I X or Y', 'which option', 'what would you do', 'is this the right move', 'validate this', 'get multiple perspectives', 'I can't decide', 'I'm torn between'. Do NOT trigger on simple yes/no questions, factual lookups, or casual 'should I' without a meaningful tradeoff (e.g. 'should I use markdown' is not a council question). DO trigger when the user presents a genuine decision with stakes, multiple options, and context that suggests they want it pressure-tested from multiple angles."
---
<!-- imported from: https://gist.github.com/RyanHouchin/f8221de64f56ba815e48248f4b8e96dc -->

# LLM Council

Run the user's question through 5 independent advisor sub-agents, have them anonymously peer-review each other, then have a chairman synthesize a final verdict (adapted from Andrej Karpathy's LLM Council, using thinking lenses instead of different models).

**Scope check:** The council is for genuine decisions where being wrong is expensive (e.g. "Should I launch a $97 workshop or a $497 course?", "Which of these 3 positioning angles is strongest?", "I'm thinking of pivoting from X to Y — am I crazy?", "Here's my landing page copy — what's weak?"). Do NOT council questions with one right answer, creation tasks ("write me a tweet"), or processing tasks ("summarize this") — just answer those directly. If the user already knows the answer and just wants validation, the council will likely tell them things they don't want to hear — that's the point.

## The Five Advisors

Thinking styles, not personas. Use these descriptions verbatim in the advisor prompts:

1. **The Contrarian** — Actively looks for what's wrong, what's missing, what will fail. Assumes the idea has a fatal flaw and tries to find it. If everything looks solid, digs deeper. Not a pessimist — the friend who saves you from a bad deal by asking the questions you're avoiding.
2. **The First Principles Thinker** — Ignores the surface question and asks "what are we actually trying to solve here?" Strips away assumptions, rebuilds the problem from the ground up. May conclude "you're asking the wrong question entirely."
3. **The Expansionist** — Looks for upside everyone else is missing. What could be bigger? What adjacent opportunity is hiding? What's undervalued? Ignores risk (the Contrarian's job); cares about what happens if this works better than expected.
4. **The Outsider** — Has zero context about the user, their field, or their history. Responds purely to what's in front of them. Catches the curse of knowledge: things obvious to the user but confusing to everyone else.
5. **The Executor** — Only cares whether this can actually be done and the fastest path to doing it. Ignores theory and strategy. Asks "OK but what do you do Monday morning?" If an idea has no clear first step, says so.

These create deliberate tension: Contrarian vs Expansionist (downside vs upside), First Principles vs Executor (rethink vs just do it), Outsider keeping everyone honest.

## Procedure

### Step 1: Frame the question (with context enrichment)

**A. Scan the workspace for context.** Use Glob and quick Read calls to find and read the 2-3 files that would let advisors give specific, grounded advice instead of generic takes. Spend no more than 30 seconds. Check:
- `CLAUDE.md` / `claude.md` in the project root or workspace (business context, preferences, constraints)
- Any `memory/` folder (audience profiles, voice docs, business details, past decisions)
- Files the user explicitly referenced or attached
- Recent `council-transcript-*.md` files in the current working directory (avoid re-counciling the same ground)
- Other files relevant to the specific question (e.g. pricing question → revenue data, past launch results, audience research)

**B. Frame the question** as a clear, neutral prompt all five advisors will receive. Include:
1. The core decision or question
2. Key context from the user's message
3. Key context from workspace files (business stage, audience, constraints, past results, relevant numbers)
4. What's at stake (why this decision matters)

Do not add your own opinion or steer the framing. If the question is too vague ("council this: my business"), ask exactly one clarifying question, then proceed. Save the framed question for the transcript.

### Step 2: Convene the council (5 sub-agents in parallel)

Spawn all 5 advisors via the Task tool, with all 5 Task calls in a single message — that is what runs them in parallel. Never spawn sequentially (wastes time and lets earlier responses bleed into later ones). Each response must be 150-300 words. Prompt template:

```
You are [Advisor Name] on an LLM Council.

Your thinking style: [advisor description from above]

A user has brought this question to the council:

---
[framed question]
---

Respond from your perspective. Be direct and specific. Don't hedge or try to be balanced. Lean fully into your assigned angle. The other advisors will cover the angles you're not covering.

Keep your response between 150-300 words. No preamble. Go straight into your analysis.
```

### Step 3: Peer review (5 sub-agents in parallel)

Anonymize the 5 advisor responses as Response A through E. Randomize which advisor maps to which letter (avoids positional bias). Never reveal which advisor wrote which response — reviewers would defer to certain thinking styles instead of evaluating on merit.

Spawn 5 new sub-agents via the Task tool, one per advisor, again all 5 calls in a single message. Reviewer prompt template:

```
You are reviewing the outputs of an LLM Council. Five advisors independently answered this question:

---
[framed question]
---

Here are their anonymized responses:

**Response A:**
[response]

**Response B:**
[response]

**Response C:**
[response]

**Response D:**
[response]

**Response E:**
[response]

Answer these three questions. Be specific. Reference responses by letter.

1. Which response is the strongest? Why?
2. Which response has the biggest blind spot? What is it missing?
3. What did ALL five responses miss that the council should consider?

Keep your review under 200 words. Be direct.
```

### Step 4: Chairman synthesis

Spawn one final Task sub-agent as chairman (or perform the synthesis yourself using this prompt). It receives everything: the framed question, all 5 advisor responses (de-anonymized), and all 5 peer reviews. The chairman may side against the majority — if 4 of 5 say "do it" but the 1 dissenter's reasoning is strongest, side with the dissenter and explain why. Chairman prompt template:

```
You are the Chairman of an LLM Council. Your job is to synthesize the work of 5 advisors and their peer reviews into a final verdict.

The question brought to the council:
---
[framed question]
---

ADVISOR RESPONSES:

**The Contrarian:**
[response]

**The First Principles Thinker:**
[response]

**The Expansionist:**
[response]

**The Outsider:**
[response]

**The Executor:**
[response]

PEER REVIEWS:
[all 5 peer reviews]

Produce the council verdict using this exact structure:

## Where the Council Agrees
[Points multiple advisors converged on independently. These are high-confidence signals.]

## Where the Council Clashes
[Genuine disagreements. Present both sides. Explain why reasonable advisors disagree.]

## Blind Spots the Council Caught
[Things that only emerged through peer review. Things individual advisors missed that others flagged.]

## The Recommendation
[A clear, direct recommendation. Not "it depends." A real answer with reasoning.]

## The One Thing to Do First
[A single concrete next step. Not a list. One thing.]

Be direct. Don't hedge. The whole point of the council is to give the user clarity they couldn't get from a single perspective.
```

The chairman may disagree with the majority when the reasoning supports it, but must give a real answer — never "it depends" or "consider both sides".

### Step 5: Generate the council report

Save a visual report to the current working directory as `council-report-[timestamp].html`, where `[timestamp]` is one timestamp in `YYYYMMDD-HHMMSS` format, shared by both output filenames. Single self-contained HTML file with inline CSS, containing:

1. The question at the top
2. The chairman's verdict, prominently displayed (this is what most users read — make it clean and scannable)
3. An agreement/disagreement visual — a simple grid, spectrum, or breakdown showing which advisors aligned and which diverged
4. Collapsible sections for each advisor's full response (collapsed by default)
5. A collapsible section for peer review highlights
6. A footer with the timestamp and what was counciled

Styling: white background, subtle borders, system sans-serif font stack, soft accent colors to distinguish advisor sections. Professional briefing document, nothing flashy.

Open the HTML file after generating it with Bash: `open <file>` on macOS, `xdg-open <file>` on Linux; if that fails, print the absolute path.

### Step 6: Save the full transcript

Save `council-transcript-[timestamp].md` in the current working directory (same timestamp as the report), containing:
- The original question
- The framed question
- All 5 advisor responses
- All 5 peer reviews (with the anonymization mapping revealed)
- The chairman's full synthesis

The transcript lets the user (or a future agent) re-run the council later and see how the thinking evolved.

## Output

Every session produces exactly two files:

```
council-report-[timestamp].html    # visual report for scanning
council-transcript-[timestamp].md  # full transcript for reference
```

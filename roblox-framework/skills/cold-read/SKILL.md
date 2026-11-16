---
name: cold-read
description: Cold-read a plan in plans/ - a fresh agent with no context reads it, says back what it would build, and lists every gap; then the user is asked those questions and the answers go into the plan.
argument-hint: "[SystemName, default: the newest plan in plans/]"
disable-model-invocation: true
---

# Cold read a plan

Plan: `$ARGUMENTS`

The point is to see the plan the way a builder who wasn't in this conversation will see it. Whatever you already know about the plan doesn't count. Only what's written down does.

1. **Find the plan.** If a name was given, use `plans/<SystemName>.md`. Otherwise use the newest file in `plans/`. If there's none, say so, suggest `/roblox-framework:plan`, and stop.

2. **Get a cold reader.** Start a **fresh** agent with the Agent tool (general-purpose; never a fork, which would carry this conversation). Send it this, with the plan's path filled in:

   > You are cold-reading a build plan for a Roblox Luau project. You know nothing except what the files say.
   >
   > Read `FRAMEWORK_GUIDE.md` and `<plan path>` in `<project root>`. Then read only the existing files the plan says it changes or depends on. Don't read anything else, and don't write or edit any file.
   >
   > Reply with exactly these three sections:
   >
   > **Readback.** In plain words, what you would build: each piece, what each remote carries, what data is saved, and what the player sees. Use short bullets. Say it as you understood it, even where the plan is vague.
   >
   > **Questions.** Every place where two builders could reasonably build different things: a missing number, an unclear flow step, an edge case with no answer, a piece whose side or home is unclear, or a test that doesn't say what it checks. For each question give:
   > - the plan section it comes from
   > - the question, in one sentence
   > - two to four likely answers, the most sensible one first
   >
   > Order them with the ones that change the most code first. Don't ask about things the guide already decides.
   >
   > **Rule clashes.** Anything in the plan that breaks `FRAMEWORK_GUIDE.md`, quoting the rule. Write "none" if there are none.

3. **Read it back to the user.** Show the reader's readback as it came, under a heading saying it's what a fresh reader understood. Then list its rule clashes, if any.

4. **Ask the questions.** Ask them with AskUserQuestion, up to four per call, the reader's likely answers as the options and its first one marked "(Recommended)". Keep calling until every question is asked. If there are more than twelve, ask the twelve that change the most code and list the rest in the plan's Open questions.

5. **Fold the answers into the plan.** Write each answer into the section it belongs to, not into a Q&A list, and remove anything it settles from Open questions. Fix each rule clash the user agreed to. Add today's date under `Date` as `Cold-read: <YYYY-MM-DD>`. If the plan was `Approved` and an answer changed it, set it back to `Draft` and say so.

6. **Report.**
   - How many questions were asked, and what changed in the plan.
   - What's still open.
   - Then ask whether to approve the plan, or to cold-read it again if a lot changed. Once it's approved, it's built with `/roblox-framework:new-system <SystemName>`.

# Contributing to Whitenoise

Thanks for your interest in contributing to Whitenoise! We're a small but highly motivated team doing our best to build something meaningful. Reviews might take a little time, we appreciate your patience in advance.

Everything in this guide is a suggestion, not a rule. This is open source, you're free to contribute however works for you. We just want to be transparent about what we ideally want to see and what gives your contributions the best chance of being merged, even if we don't always live up to it ourselves.



## Ways to Contribute

Opening a PR is one way to contribute, but not the only one. All of the following are genuinely valuable, especially for people getting familiar with the project.

### 🎨 Review designs and leave feedback in Figma.
Before a feature gets coded, it lives in Figma. Catching a confusing flow or a missing state there costs less than catching it after it's built. Open any of the design files, leave a comment on what's unclear, broken, or missing, and tag @vladimir-krstic. No design tool experience required; user perspective is just as valuable.

### 🔍 Review and QA open PRs.
This is one of the highest-leverage things you can do. Read the diff, pull the branch, and actually run the feature on a device or simulator. Write what you tested: what worked, what felt off, what you couldn't verify. A thorough QA comment on a PR helps the author ship with more confidence and often catches things automated tests miss. Nice to have: review in a physical device

### 🚦Triage issues.
Browse [open issues](https://github.com/marmot-protocol/whitenoise/issues) and help add signal:
- If an issue is unclear, ask a clarifying question.
- If you can reproduce it, say so, include your OS, device, and app version.
- If you've seen the same thing, add your context rather than opening a duplicate. If you find a duplicate, link the two and note which has more detail.
- If an issue no longer applies or was fixed, say so.

### 💻 Open a PR
See the sections below for everything you need to know.

---

## Before You Start

**Fork the repository.** Go to [github.com/marmot-protocol/whitenoise](https://github.com/marmot-protocol/whitenoise), click Fork, and clone your fork locally.

**Check if an issue already exists.** Browse [open issues](https://github.com/marmot-protocol/whitenoise/issues) and look for one that matches your intent. If an issue is assigned, reach out before working on it, we don't want to duplicate effort.

**For significant features, open an issue first.**  New features are welcome, we're open source and genuinely grateful for people's time and effort. But we also have a responsibility to keep the app focused and healthy, and merging is never guaranteed. Changes that skip the issue and design step are much less likely to be merged. This isn't a hard rule, but following that flow gives your PR the best chance of landing. But hey, if this warning is already stopping you from contributing, ignore it. Go ahead and open that PR. Just don't get mad at us if we request changes.

---

## Designs

The full design lives in Figma across three files:

- [00. Foundations](https://www.figma.com/design/CUEbUyUPJhdH8VRrL7JzWl/00.-Foundations) - colors, typography, spacing, and design tokens
- [01. Application Components](https://www.figma.com/design/J9pCZpUhcm0MRs7dFX7LTN/01.-Application-Components) - the design system component library
- [02. Application Design](https://www.figma.com/design/Y12t1SzBbrQ9Q4UTNBSoEs/02.-Application-Design) - full app screens and flows

If you're implementing a UI feature, check the Application Design file first. If something looks wrong or is missing, leave a comment in Figma and tag @vladimir-krstic before writing code.

---

## Pull Requests

### Fork and branch

Work on a branch in your fork. Try to keep branch names descriptive:

```
feat/offline-notice-in-login
fix/message-ordering-bug
docs/update-contributing-guide
```

### Commits
Good commits make reviews easier and history more useful. A few suggestions:

- Think about the reviewer — we're human. If you make a change on something and then change it two commits later in the same PR, the reviewer has to re-read that code twice. Try to structure commits so the review flows naturally from top to bottom.
- Keep commits focused — one logical change per commit. If you find yourself writing "and" in the commit message, consider splitting it.
- Rebase, don't merge master — if your branch falls behind, rebase on top of master rather than merging it in. It keeps history linear and makes the diff easier to review.
- Don't be afraid to squash — if your branch has a lot of noise commits ("wip", "fix typo", "try again"), clean them up before marking the PR ready for review.
- Write a clear subject line — describe what the change does, not what you did. Prefer fix message ordering bug over fixed stuff.
- Use semantic prefixes — feat:, fix:, refactor:, docs:, test:, chore: helps reviewers scan the PR at a glance.


### Draft PRs

If your work is in progress, **open the PR as a draft**. This lets reviewers see what you're building and give early feedback without feeling pressure to approve something incomplete. Convert to "Ready for review" when it's done. Forks fully support GitHub's draft PR feature - use it freely.

### Size guideline

Aim for **~500 lines changed** or fewer. Larger PRs are much harder to review well. We break this rule ourselves sometimes, but try to keep it in mind as a goal. If your change is bigger, try to:
- Split by layer (e.g., Rust API in one PR, Flutter UI in a second)
- Or split by sub-feature
- Add a comment in the PR explaining the split order if the PRs depend on each other

### Description

A good PR description has three things:

1. **What changed** - a short summary of what the code does
2. **Why** - the motivation (link the issue: `Closes #42`)
3. **How you tested it** - exactly what you ran or manually verified

### Screenshots

**Required for any change that affects UI.** Include before and after.

Screenshots catch regressions that tests miss and make reviews much faster. Drag images directly into the GitHub PR description box.

If your change is Rust-only with no UI impact, screenshots are not needed.

### Requesting review

After opening your PR, tag the right reviewer for the type of change:

- **Code review** - tag any devs from [CODEOWNERS](.github/CODEOWNERS) 
- **Design review** - tag @vladimir-krstic

---

## Testing

**Test coverage must not decrease.** The CI will fail if it does. The minimum is 99%.

- Write tests for every code path. Do not use `// coverage:ignore` - the only acceptable exception is compiler-required exhaustive `default` cases in switches that are truly unreachable.
- Test files mirror source structure with `_test.dart` suffix

### Approach for bug fixes

When fixing a bug, write a failing test that reproduces the bug first. Then fix the code until the test passes. This proves the fix and prevents regression.

---

## Good First Issues

Look for issues labeled [`good first issue`](https://github.com/marmot-protocol/whitenoise/issues?q=is%3Aopen+label%3A%22good+first+issue%22). These are self-contained tasks with enough context to get started without deep knowledge of the whole codebase.

Comment on the issue to let us know you're working on it before submitting a PR.

---

## Questions?

Open an issue with the `question` label.

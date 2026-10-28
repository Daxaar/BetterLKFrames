# BetterLKFrames — Development Instructions

## GitHub Issues

GitHub Issues in `Daxaar/BetterLKFrames` are the authoritative development backlog.

For existing CLI access and headless authentication troubleshooting, read [GITHUB-ACCESS.md](GITHUB-ACCESS.md). Reuse existing authentication before starting another login flow.

Before implementing any issue:

1. Read the complete issue description.
2. Read **all issue comments**, not just the initial description.
3. Inspect attached screenshots and other relevant references.
4. Consider later clarifications in comments alongside the original requirements.
5. If requirements conflict or are ambiguous, ask the owner before implementing.

## Issue screenshots

For every GitHub Issue, check `tests/screenshots/<issue-number>/` on the `issue-screenshots` branch for supporting images. Review all screenshots before implementation.

These reference images are not part of the addon and must never be included in development or release ZIPs.

Always check this folder when revisiting an issue or its comments, using the current contents of the `issue-screenshots` branch, to see whether any images have been added or updated since the issue was marked ready for testing.

## Approval and workflow

- Only work on issues carrying the `approved` label.
- Issue approval alone does not authorise starting work; the owner must explicitly instruct you to proceed.
- Mark an issue `in-progress` when starting development.
- After implementing and testing, mark it `needs-testing`.
- Keep the issue open until the owner confirms acceptance.
- Do not introduce unrelated features or fixes without approval.

## Development Round Workflow

At the start of each owner-authorised development round:

1. Identify approved issues in the **Changes Requested** and **Ready** columns.
2. Read each issue's original description, **all subsequent comments**, screenshots and acceptance-testing feedback.
3. Prioritise work using the GitHub `priority:*` labels, addressing critical and blocking defects first.
4. **When issues have equal priority, work on Changes Requested before Ready.** Completing previously attempted work takes precedence over starting new features.
5. Move issues to **In Progress** when development begins.
6. Move issues to **Ready for Testing** only when a testable development build is available.
7. Never close an issue or move it to Done without explicit owner acceptance.
8. Never independently begin another development round without explicit owner authorisation.

The GitHub Project's Priority field is not authoritative. Use the repository's `priority:*` labels instead.

## Development and releases

- Target World of Warcraft 3.3.5a (Interface 30300).
- Use issue-linked commits and pull requests.
- Produce installable development ZIPs through GitHub Actions.
- Never create a stable release without explicit owner approval.
- Do not claim in-game testing unless it has actually been performed.

## Efficiency

- Read relevant source files rather than scanning the entire repository unnecessarily.
- Avoid excessive log output and repeated investigation.
- Record important decisions in repository documentation so future sessions can resume without relying on chat history.

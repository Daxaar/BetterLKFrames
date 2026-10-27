# BetterLKFrames — Development Instructions

## GitHub Issues

GitHub Issues in `Daxaar/BetterLKFrames` are the authoritative development backlog.

Before implementing any issue:

1. Read the complete issue description.
2. Read **all issue comments**, not just the initial description.
3. Inspect attached screenshots and other relevant references.
4. Consider later clarifications in comments alongside the original requirements.
5. If requirements conflict or are ambiguous, ask the owner before implementing.

## Approval and workflow

- Only work on issues carrying the `approved` label.
- Issue approval alone does not authorise starting work; the owner must explicitly instruct you to proceed.
- Mark an issue `in-progress` when starting development.
- After implementing and testing, mark it `needs-testing`.
- Keep the issue open until the owner confirms acceptance.
- Do not introduce unrelated features or fixes without approval.

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

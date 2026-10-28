# Development

Target the original WoW 3.3.5a build 12340 APIs and Lua 5.1. Keep layout changes out of combat, preserve native secure click handlers and restore changed visuals when disabled. Do not add modern client APIs without a verified legacy equivalent. No game server is needed for the mocked tests.

## Test and package

Use Python 3.10+ with a virtual environment:

```bash
python3 -m venv .venv
# Activate the environment using your shell's normal command.
python3 -m pip install -r requirements-dev.txt
python3 tests/run-tests.py
python3 tests/verify-package.py
```

The final command creates dist/BetterLKFrames-0.2.5-dev.zip, its SHA256 file and a source manifest. The ZIP contains only the addon folder with Lua, TOC, original media, license and user docs. Dependencies, local archives, research and test logs are excluded. Generated dist files are local artifacts; attach reviewed ZIP/checksum files to a GitHub release when publishing a release.

`tools/generate-assets.py` uses only Python's standard library. `tools/preview-assets.py` optionally uses Pillow to render a developer contact sheet; it is not an in-game screenshot. Both write only generated addon/developer artifacts.

Development ZIPs for owner acceptance are produced by GitHub Actions from an exact clean commit, with full commit hash and addressed issue numbers. See [DEVELOPMENT.md](DEVELOPMENT.md). Actions artifacts are not formal Releases.

## Commit and push

Read [AGENTS.md](AGENTS.md). Fetch before work, read the entire open approved issue and all comments/references, wait for the owner to start work, then use an issue-linked branch/PR and the agreed issue labels. Keep issues open pending acceptance; use `Refs #N` without automatic closing keywords.

```bash
git status
# Stage only intended source/docs/media/test changes.
git add -- Core.lua README.md
python3 tools/check_repository.py
git diff --cached
git commit -m "Describe the change (Refs #N)"
git push -u origin ISSUE_BRANCH
```

Use your own GitHub-authorized credentials. Private keys must remain outside the checkout; local credential configuration is not committed. Prefer a GitHub no-reply commit email if you do not want a personal email in commit metadata. Fetch/reconcile remote updates normally; do not force-push over others' history.

Run tests and package verification before a release. Update the TOC version, README, changelog and packaging checks together. Check the resulting ZIP in the actual client, especially after frame geometry/event changes.

## Publication boundary

The Git allowlist excludes local dependencies, archives, research, logs, operational reports and generated releases. Never commit WoW SavedVariables/WTF data, account names, screenshots with private information, credentials, tokens, private keys, server configs, database dumps, container volumes or personal machine paths. Inspect text and binary assets before adding them. tools/check_repository.py checks tracked/staged content for common secrets, machine paths, private IPs and unexpected file types; human review remains necessary.

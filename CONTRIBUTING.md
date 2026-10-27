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

The final command creates dist/BetterLKFrames-0.2.1.zip, its SHA256 file and a source manifest. The ZIP contains only the addon folder with Lua, TOC, original media, license and user docs. Dependencies, local archives, research and test logs are excluded. Generated dist files are local artifacts; attach reviewed ZIP/checksum files to a GitHub release when publishing a release.

`tools/generate-assets.py` uses only Python's standard library. `tools/preview-assets.py` optionally uses Pillow to render a developer contact sheet; it is not an in-game screenshot. Both write only generated addon/developer artifacts.

## Commit and push

```bash
git status
# Stage only intended source/docs/media/test changes.
git add -- Core.lua README.md
python3 tools/check_repository.py
git diff --cached
git commit -m "Describe the change"
git push origin main
```

Use your own GitHub-authorized credentials. Private keys must remain outside the checkout; local credential configuration is not committed. Prefer a GitHub no-reply commit email if you do not want a personal email in commit metadata. Fetch/reconcile remote updates normally; do not force-push over others' history.

Run tests and package verification before a release. Update the TOC version, README, changelog and packaging checks together. Check the resulting ZIP in the actual client, especially after frame geometry/event changes.

## Publication boundary

The Git allowlist excludes local dependencies, archives, research, logs, operational reports and generated releases. Never commit WoW SavedVariables/WTF data, account names, screenshots with private information, credentials, tokens, private keys, server configs, database dumps, container volumes or personal machine paths. Inspect text and binary assets before adding them. tools/check_repository.py checks tracked/staged content for common secrets, machine paths, private IPs and unexpected file types; human review remains necessary.

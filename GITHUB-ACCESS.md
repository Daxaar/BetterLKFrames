# GitHub access and headless authentication recovery

Recorded 27 October 2026. This note contains no credentials or device codes. It documents the working setup for future sessions; it does not authorise new development rounds, merges or releases.

## Working setup

Git transport uses the checkout's existing SSH origin and repository-local deploy-key configuration. Keep those keys/configuration intact. SSH deploy keys support Git fetch/push, not the GitHub API used for Issues, pull requests, Actions or Projects.

The standalone GitHub CLI is installed outside PATH. In a terminal, set a convenience variable:

```bash
BLKF_GH="$HOME/.local/lib/betterlkframes-tools/gh-2.103.3/bin/gh"
```

The working API login uses file-based credential storage rather than the desktop keyring, with the additional `project` scope needed to edit the Kanban board. Project access was verified by reading and updating the BetterLKFrames Development board. OAuth authorization is account-based, not restricted to this repository merely because Git pushes use a repository deploy key.

For this headless setup, CLI configuration is under `$HOME/.config/gh/`; the credential file is `hosts.yml`. It contains an unencrypted credential and must remain outside Git and all artifacts. Directory permissions are `700`; credential-file permissions are `600`. These restrict filesystem access but do not encrypt the credential.

This survives reboot and does not require a desktop login or keyring unlock. Access can still stop if authorization is revoked/invalidated, the configuration changes, or another credential overrides it.

## What went wrong

1. The original CLI authorization could access Issues/Actions but lacked Project scopes. Board commands reported missing `read:project`; editing requires `project`.
2. Browser authorization displayed success while the CLI was still waiting at its **Press Enter to open...** prompt. Cancelling the terminal command prevented it from finishing and saving the new authorization. A browser success page alone is insufficient.
3. Refreshed credentials were subsequently stored in the desktop Login keyring. Without a desktop login that keyring was locked. The CLI reported an invalid token / HTTP 401, but `gh auth token` could not retrieve a token at all. Secret Service metadata located the credential in the locked Login collection. This was a credential-retrieval failure, not proof GitHub had revoked a token.
4. A desktop unlock prompt could not run in the assistant's session without a graphical display. A terminal daemon-unlock attempt did not unlock the credential's actual collection. Repeating browser approval did not address that storage problem.
5. Explicit file-based login restored reliable headless access. File permissions and actual Project access were checked afterward.

## Diagnose before reauthorising

Reuse existing authentication first. Do not start repeated device-login flows merely because one command fails.

```bash
"$BLKF_GH" auth status
"$BLKF_GH" api user --jq .login
"$BLKF_GH" project list --owner Daxaar --format json
```

Distinguish missing Project scope from an inaccessible credential or a genuinely invalid/revoked token. Check whether `GH_TOKEN`, `GITHUB_TOKEN` or `GH_CONFIG_DIR` is set without printing their values. An environment token can override the saved login. Inspect credential-file permissions and keyring lock state without printing credential contents. Do not dump `hosts.yml`, raw keyring secrets or `gh auth token` output to chat/logs.

## Recovery used successfully

If the same locked-keyring problem recurs, use the installed CLI's explicit file-storage option:

```bash
"$BLKF_GH" auth login --hostname github.com --web --git-protocol ssh --insecure-storage --scopes project --skip-ssh-key
```

This stores an unencrypted API credential outside the repository. It does not replace the repository's existing deploy key; the SSH-key generation/upload prompt is skipped. Never paste a token, password or device code into chat or repository files.

Complete the terminal and browser steps:

1. Use the current attempt's one-time code privately in GitHub's device authorization page. Clipboard-copy failure is not fatal; manually copy the code if needed.
2. Press **Enter in the terminal** when prompted, even if the browser authorization page was opened manually.
3. Complete the browser authorization, then leave the CLI running until it prints **Authentication complete** and returns to the shell prompt. Do not cancel with Ctrl+C after browser success.
4. Confirm restricted storage and API/board access:

```bash
chmod 700 "$HOME/.config/gh"
chmod 600 "$HOME/.config/gh/hosts.yml"
"$BLKF_GH" auth status
"$BLKF_GH" project list --owner Daxaar --format json
```

If authentication already works and only the Project scope is missing, scope refresh may suffice. However, a refresh can use the secure credential store again; verify the resulting storage/access rather than assuming it remains suitable for headless operation.

## Board identity and workflow

The intended board is [BetterLKFrames Development](https://github.com/users/Daxaar/projects/2), owned by Daxaar, Project number 2. Do not update the unrelated project on the same account.

Follow AGENTS.md for status transitions and explicit owner authorization. Use repository `priority:*` labels, not the Project Priority field. Verify saved board statuses after updates. Restored authentication is not permission to start another development round or to merge, close issues or publish releases.

This developer reference is intentionally excluded from installable addon ZIPs. Never commit runtime configuration, credential files, login screenshots containing codes, keyring exports or access-key material alongside it.

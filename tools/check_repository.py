#!/usr/bin/env python3
"""Review tracked/index files without printing potentially sensitive values."""
from pathlib import Path
import re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
ROOT_FILES={'GITHUB-ACCESS.md','DEVELOPMENT.md','AGENTS.md','.gitignore','BetterLKFrames.toc','CompactParty.lua','Party.lua','Core.lua','OptionsHost.lua','Preview.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Options.lua','README.md','FEATURES.md','PROVENANCE.md','CHANGELOG.md','LICENSE','CONTRIBUTING.md','requirements-dev.txt'}
TEST_FILES={'tests/assertions-029.lua','tests/assertions-compact-auras.lua','tests/assertions-party-windows.lua','tests/assertions-settings.lua','tests/assertions-round.lua','tests/assertions-011.lua','tests/assertions-followups.lua','tests/assertions-issues.lua','tests/mock-wow.lua','tests/assertions.lua','tests/assertions-v11.lua','tests/assertions-020.lua','tests/run-tests.py','tests/verify-package.py','tests/fixtures/cast-data-baseline.lua'}
TOOL_FILES={'tools/generate-assets.py','tools/preview-assets.py','tools/check_repository.py'}
MEDIA={'Media/'+p+'.tga' for p in ['HealthFlat','HealthGradient','HealthEdge','PowerFlat','PowerGradient','PowerEdge','ButtonEdge']}
ALLOWED=ROOT_FILES|TEST_FILES|TOOL_FILES|MEDIA|{'.github/workflows/development.yml'}
PATTERNS={
 'private key':r'-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----',
 'GitHub token':r'\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{30,})\b',
 'AWS access key':r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b',
 'Slack token':r'\bxox[baprs]-[A-Za-z0-9-]{20,}',
 'API key':r'\bAIza[A-Za-z0-9_-]{30,}',
 'credential URL':r'\b[a-zA-Z][a-zA-Z0-9+.-]*://[^\s/@:]+:[^\s/@]+@',
 'credential assignment':r'(?im)^\s*(?:export\s+)?[A-Z0-9_]*(?:PASSWORD|PASSWD|API_KEY|ACCESS_TOKEN|SECRET_KEY|CLIENT_SECRET)\s*[:=]\s*[\x22\x27]?[A-Za-z0-9/+_.=-]{8,}',
 'personal home path':r'/(?:home|Users)/[^/\s]+',
 'personal Windows path':r'\b[A-Za-z]:\\Users\\[^\\\s]+',
 'private IP':r'\b(?:10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})\b',
 'email address':r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
}
def git(*args):return subprocess.check_output(['git','-C',str(ROOT),*args])
def scan(text,name):
 for label,pattern in PATTERNS.items():
  if re.search(pattern,text):raise ValueError(f'{name}: possible {label}; inspect locally (value withheld)')
def check(check_identity=True):
 paths={p.decode() for p in git('ls-files','-z').split(b'\0') if p}
 if paths-ALLOWED:raise ValueError('Unexpected tracked/index file(s): '+', '.join(sorted(paths-ALLOWED)))
 for name in sorted(paths):
  mode=git('ls-files','--stage','--',name).decode().split()[0]
  if mode=='120000':raise ValueError('Symlink refused: '+name)
  data=git('show',':'+name)
  if len(data)>1024*1024:raise ValueError('Oversized file: '+name)
  if name not in MEDIA:scan(data.decode('utf-8'),name)
  p=ROOT/name
  if p.is_symlink():raise ValueError('Worktree symlink refused: '+name)
  if p.is_file() and name not in MEDIA:scan(p.read_text(),name)
 # Check outgoing local commit identity. Read-only CI publishes no source commits.
 if check_identity:
  email=git('config','user.email').decode().strip()
  if not email.endswith('@users.noreply.github.com'):raise ValueError('Use a GitHub no-reply commit email before publication')
 return len(paths)
if __name__=='__main__':
 try:
  count=check(check_identity='--source-only' not in sys.argv)
  print(f'PASS: {count} source/media/docs/test files checked; no recognized secrets, personal paths, private IPs or email addresses.')
 except (ValueError,UnicodeError,subprocess.CalledProcessError) as e:print(str(e),file=sys.stderr);sys.exit(1)

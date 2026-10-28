from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
print('Runtime:',lua.eval('_VERSION'))
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'):
    lua.execute('assert(loadstring(...))', (root/f).read_text())
    print('PASS syntax', f)
lua.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'): lua.execute((root/f).read_text())
lua.execute((root/'tests/assertions.lua').read_text())

lua.execute((root/'tests/assertions-v11.lua').read_text())

lua.execute((root/'tests/assertions-020.lua').read_text())

lua.execute((root/'tests/assertions-issues.lua').read_text())

lua.execute((root/'tests/assertions-followups.lua').read_text())

# The blocking-Apply regression must also exercise a clean login, independent of prior suites.
blocker=LuaRuntime(unpack_returned_tuples=True)
blocker.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'):
    blocker.execute((root/f).read_text())
blocker.execute((root/'tests/assertions-011.lua').read_text())

round_tests=LuaRuntime(unpack_returned_tuples=True)
round_tests.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'):
    round_tests.execute((root/f).read_text())
round_tests.execute((root/'tests/assertions-round.lua').read_text())

settings_tests=LuaRuntime(unpack_returned_tuples=True)
settings_tests.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'):
    settings_tests.execute((root/f).read_text())
settings_tests.execute((root/'tests/assertions-settings.lua').read_text())

followups=LuaRuntime(unpack_returned_tuples=True)
followups.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'):
    followups.execute((root/f).read_text())
followups.execute((root/'tests/assertions-party-windows.lua').read_text())

new_issues=LuaRuntime(unpack_returned_tuples=True)
new_issues.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Party.lua','CompactParty.lua','Preview.lua','OptionsHost.lua','Options.lua'):
    new_issues.execute((root/f).read_text())
new_issues.execute((root/'tests/assertions-compact-auras.lua').read_text())

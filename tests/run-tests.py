from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
print('Runtime:',lua.eval('_VERSION'))
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Options.lua'):
    lua.execute('assert(loadstring(...))', (root/f).read_text())
    print('PASS syntax', f)
lua.execute((root/'tests/mock-wow.lua').read_text())
for f in ('Core.lua','Profiles.lua','Style.lua','Windows.lua','AuraLayout.lua','Snapping.lua','Options.lua'): lua.execute((root/f).read_text())
lua.execute((root/'tests/assertions.lua').read_text())

lua.execute((root/'tests/assertions-v11.lua').read_text())

lua.execute((root/'tests/assertions-020.lua').read_text())

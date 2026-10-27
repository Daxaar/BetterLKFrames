from pathlib import Path
import hashlib,json,zipfile,re,struct
base=Path(__file__).resolve().parents[1]; addon=base;dist=base/'dist'
dist.mkdir(exist_ok=True)
files=sorted(list(addon.glob('*.lua'))+list(addon.glob('*.toc'))+[addon/n for n in ['README.md','FEATURES.md','PROVENANCE.md','CHANGELOG.md','LICENSE','CONTRIBUTING.md']]+list((addon/'Media').glob('*.tga')))
expected={'BetterLKFrames.toc','Core.lua','Profiles.lua','Windows.lua','AuraLayout.lua','Style.lua','Snapping.lua','Options.lua','README.md','FEATURES.md','PROVENANCE.md','CHANGELOG.md','LICENSE','CONTRIBUTING.md'}
assert {p.name for p in files if p.parent==addon}==expected
text=(addon/'BetterLKFrames.toc').read_text()
assert '## Interface: 30300' in text and '## Version: 0.2.1' in text
assert '## SavedVariablesPerCharacter: BetterLKFramesCharDB' in text
for line in text.splitlines():
    if line and not line.startswith('#'): assert (addon/line).is_file(),line
for p in addon.glob('*.lua'):
    text=p.read_text()
    for token in ('C_Timer.','C_UnitAuras.','SetColorTexture(', 'BackdropTemplate', 'UNIT_POWER_UPDATE'):
        assert token not in text,(p.name,token)
for p in files:
    if p.suffix!='.tga':
        for regex in (r'(?i)password\s*=',r'-----BEGIN .*PRIVATE KEY-----',r'gh[pousr]_[A-Za-z0-9]{25,}'):
            assert not re.search(regex,p.read_text()),p.name
old=(base/'tests/fixtures/cast-data-baseline.lua').read_text()
new=(addon/'Core.lua').read_text()
def cast_code(s):return s[s.index('local function castInfo'):s.index('local function auraButton')]
assert old==cast_code(new),'cast event/data logic must remain unchanged'
textures=list((addon/'Media').glob('*.tga'));assert len(textures)==7
for p in textures:
    data=p.read_bytes();header=struct.unpack('<BBBHHBHHHHBB',data[:18]);w,h,depth,descriptor=header[-4:]
    assert depth==32 and descriptor==8 and header[2]==2 and not w&(w-1) and not h&(h-1)
    assert len(data)==18+w*h*4
    assert data[21]==0,'corner must be transparent'
    if 'Gradient' in p.name:
        bottom=data[18+4*(w//2)];top=data[18+4*((h-1)*w+w//2)]
        assert top>bottom+80,'gradient must brighten toward top'
    if 'Edge' in p.name:assert data[18+4*((h//2)*w+w//2)+3]==0,'frame centre must be transparent'
path=dist/'BetterLKFrames-0.2.1.zip'
with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,'BetterLKFrames/'+p.relative_to(addon).as_posix())
with zipfile.ZipFile(path) as z:
    assert z.testzip() is None
    assert set(z.namelist())=={'BetterLKFrames/'+p.relative_to(addon).as_posix() for p in files}
    for p in files:assert z.read('BetterLKFrames/'+p.relative_to(addon).as_posix())==p.read_bytes()
sha=hashlib.sha256(path.read_bytes()).hexdigest()
(path.with_suffix('.zip.sha256')).write_text(sha+'  '+path.name+'\n')
manifest={p.relative_to(addon).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(dist/'BetterLKFrames-0.2.1-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('PASS TOC / legacy API / secret-pattern / 7 RGBA TGA asset / ZIP content and CRC checks')
print('Release:',path.name,'bytes:',path.stat().st_size)
print('SHA256:',sha)

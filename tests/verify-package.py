from pathlib import Path
import argparse,datetime,hashlib,json,zipfile,re,struct,subprocess
parser=argparse.ArgumentParser()
parser.add_argument("--development",action="store_true")
parser.add_argument("--issues",type=int,nargs="+",default=[])
args=parser.parse_args()
base=Path(__file__).resolve().parents[1]; addon=base;dist=base/'dist'
dist.mkdir(exist_ok=True)
files=sorted(list(addon.glob('*.lua'))+list(addon.glob('*.toc'))+[addon/n for n in ['README.md','FEATURES.md','PROVENANCE.md','CHANGELOG.md','LICENSE','CONTRIBUTING.md','DEVELOPMENT.md']]+list((addon/'Media').glob('*.tga')))
expected={'BetterLKFrames.toc','Core.lua','OptionsHost.lua','Preview.lua','Profiles.lua','Windows.lua','AuraLayout.lua','Style.lua','Snapping.lua','Options.lua','README.md','FEATURES.md','PROVENANCE.md','CHANGELOG.md','LICENSE','CONTRIBUTING.md','DEVELOPMENT.md'}
assert {p.name for p in files if p.parent==addon}==expected
text=(addon/'BetterLKFrames.toc').read_text()
assert '## Interface: 30300' in text
version=re.search(r'^## Version: ([0-9A-Za-z.+-]+)$',text,re.M).group(1)
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
metadata=None
commit=subprocess.check_output(['git','-C',str(base),'rev-parse','HEAD'],text=True).strip()
if args.development:
    assert args.issues and all(n>0 for n in args.issues),'Addressed issue numbers required'
    assert not subprocess.check_output(['git','-C',str(base),'status','--porcelain']), 'Development build requires an exact clean commit'
    metadata={'commit':commit,'issues':sorted(set(args.issues)),'version':version,'interface':30300,'in_game_tested':False}
name='BetterLKFrames-dev-'+commit if args.development else 'BetterLKFrames-'+version
path=dist/(name+'.zip')
stamp=int(subprocess.check_output(['git','-C',str(base),'show','-s','--format=%ct','HEAD'],text=True))
# Stable ZIP metadata: the same clean source commit yields the same development ZIP.
date=datetime.datetime.fromtimestamp(stamp,datetime.timezone.utc).timetuple()[:6]
contents={'BetterLKFrames/'+p.relative_to(addon).as_posix():p.read_bytes() for p in files}
if metadata: contents['BetterLKFrames/DEVELOPMENT.json']=(json.dumps(metadata,indent=2)+'\n').encode()
with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
    for entry,data in sorted(contents.items()):
        info=zipfile.ZipInfo(entry,date_time=date);info.compress_type=zipfile.ZIP_DEFLATED
        info.create_system=3;info.external_attr=0o100644<<16
        z.writestr(info,data)
with zipfile.ZipFile(path) as z:
    assert z.testzip() is None
    assert set(z.namelist())==set(contents)
    assert all(not name.lower().endswith(('.png','.jpg','.jpeg')) and '/screenshots/' not in name.lower() for name in z.namelist()), 'Reference screenshots must never enter addon ZIPs'
    for entry,data in contents.items():assert z.read(entry)==data
sha=hashlib.sha256(path.read_bytes()).hexdigest()
(path.with_suffix('.zip.sha256')).write_text(sha+'  '+path.name+'\n')
manifest={p.relative_to(addon).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
if metadata:manifest['DEVELOPMENT.json']=hashlib.sha256(contents['BetterLKFrames/DEVELOPMENT.json']).hexdigest()
(dist/(name+'-manifest.json')).write_text(json.dumps(manifest,indent=2)+'\n')
print('PASS TOC / legacy API / secret-pattern / 7 RGBA TGA asset / ZIP content and CRC checks')
print('Development build:' if args.development else 'Package:',path.name,'bytes:',path.stat().st_size)
print('SHA256:',sha)

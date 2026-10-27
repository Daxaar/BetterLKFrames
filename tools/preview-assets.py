"""Developer contact sheet of generated art, not an in-game screenshot."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageChops
b=Path(__file__).resolve().parents[1];m=b/'Media'
out=Image.new('RGB',(900,270),(44,43,40));d=ImageDraw.Draw(out)
d.text((18,12),'v1.1 procedural texture contact sheet (not an in-game screenshot)',fill='white')
for x,col,name in [(35,(145,123,190),'Class health'),(470,(60,185,210),'Class health')]:
    d.text((x+130,45),name,fill=col)
    for prefix,y,w,h,c in [('Health',72,355,66,col),('Power',145,355,24,(40,60,255))]:
        fill=Image.open(m/(prefix+'Gradient.tga')).convert('RGBA').resize((w,h),Image.Resampling.LANCZOS)
        solid=Image.new('RGBA',fill.size,(*c,255));tint=ImageChops.multiply(fill,solid)
        out.paste(tint,(x,y),tint)
        edge=Image.open(m/(prefix+'Edge.tga')).convert('RGBA').resize((w,h),Image.Resampling.LANCZOS)
        out.paste(edge,(x,y),edge)
    for i in range(6):
        icon=Image.new('RGB',(42,42),(80+20*i,100,140));out.paste(icon,(x+i*50,195))
        edge=Image.open(m/'ButtonEdge.tga').convert('RGBA').resize((44,44),Image.Resampling.LANCZOS)
        out.paste(edge,(x+i*50-1,194),edge)
out.save(b/'tests/texture-contact-sheet-v1.1.png')

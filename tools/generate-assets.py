"""Original procedural 32-bit uncompressed TGA art. No third-party artwork."""
from pathlib import Path
import math,struct
out=Path(__file__).resolve().parents[1]/'Media';out.mkdir(exist_ok=True)
def coverage(x,y,w,h,r,inset=0):
    # Signed distance to an inset rounded rectangle, antialiasing at its boundary.
    rr=max(.1,r-inset);cx=w/2;cy=h/2
    qx=abs(x-cx)-(w/2-inset-rr);qy=abs(y-cy)-(h/2-inset-rr)
    d=math.hypot(max(qx,0),max(qy,0))+min(max(qx,qy),0)-rr
    return max(0,min(1,.5-d))
def write(name,w,h,r,mode):
    data=bytearray(struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,w,h,32,8))
    for y in range(h-1,-1,-1):
        for x in range(w):
            outer=coverage(x+.5,y+.5,w,h,r)
            if mode=='edge':
                inner=coverage(x+.5,y+.5,w,h,r,2.5 if h>16 else 2)
                a=max(0,outer-inner);v=.12+.11*(1-y/max(1,h-1))
            else:
                a=outer
                v=1 if mode=='flat' else .48+.48*(1-y/max(1,h-1))+.04*math.exp(-((y/h-.17)/.13)**2)
            c=int(max(0,min(1,v))*255);data.extend((c,c,c,round(a*255)))
    (out/(name+'.tga')).write_bytes(data)
for prefix,h,r in [('Health',32,6),('Power',16,4)]:
    for suffix,mode in [('Gradient','gradient'),('Flat','flat'),('Edge','edge')]:write(prefix+suffix,128,h,r,mode)
write('ButtonEdge',64,64,6,'edge')
print('Generated 7 original power-of-two RGBA textures')

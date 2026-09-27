from PIL import Image

def process(src, dst, target_h=1000):
    im = Image.open(src).convert("RGBA")
    w,h = im.size
    scale = target_h/h
    im = im.resize((max(1,int(w*scale)), target_h), Image.LANCZOS)
    w,h = im.size
    px = list(im.getdata())
    n = w*h
    bg = bytearray(n)
    for i in range(n):
        r,g,b,a = px[i]
        mx = r if r>g else g
        if b>mx: mx=b
        mn = r if r<g else g
        if b<mn: mn=b
        sat = 0.0 if mx==0 else (mx-mn)/mx
        if mx>135 and sat<0.16:
            bg[i]=1
    removed = bytearray(n)
    stack = []
    for x in range(w):
        for yy in (0,h-1):
            i=yy*w+x
            if bg[i] and not removed[i]:
                removed[i]=1; stack.append(i)
    for y in range(h):
        for xx in (0,w-1):
            i=y*w+xx
            if bg[i] and not removed[i]:
                removed[i]=1; stack.append(i)
    while stack:
        i = stack.pop()
        x = i % w; y = i // w
        if x>0:
            j=i-1
            if bg[j] and not removed[j]: removed[j]=1; stack.append(j)
        if x<w-1:
            j=i+1
            if bg[j] and not removed[j]: removed[j]=1; stack.append(j)
        if y>0:
            j=i-w
            if bg[j] and not removed[j]: removed[j]=1; stack.append(j)
        if y<h-1:
            j=i+w
            if bg[j] and not removed[j]: removed[j]=1; stack.append(j)
    im.putdata([(0,0,0,0) if removed[i] else px[i] for i in range(n)])
    bbox = im.getbbox()
    if bbox: im = im.crop(bbox)
    im.save(dst)
    print(dst, im.size)

T = "C:/Users/VamsiH/AppData/Local/Temp"
D = "D:/FitYaar/FitYaar-Mobile/assets/body"
process(T+"/ai-chat-attachment-11132027937292701899.png", D+"/front.png")
process(T+"/ai-chat-attachment-7107492329422173382.png",  D+"/back.png")

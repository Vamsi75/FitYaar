import re

FILES = {
    'maleFront':   ('D:/FitYaar/rnbh_bodyFront.ts',        '0 0 724 1448'),
    'maleBack':    ('D:/FitYaar/rnbh_bodyBack.ts',         '724 0 724 1448'),
    'femaleFront': ('D:/FitYaar/rnbh_bodyFemaleFront.ts',  '-50 -40 734 1538'),
    'femaleBack':  ('D:/FitYaar/rnbh_bodyFemaleBack.ts',   '756 0 774 1448'),
}

slug_re = re.compile(r'slug:\s*"([\w-]+)"')
path_re = re.compile(r'"([Mm][^"]{15,})"')

def parse(path):
    txt = open(path, encoding='utf-8').read()
    events = []
    for m in slug_re.finditer(txt):
        events.append((m.start(), 'slug', m.group(1)))
    for m in path_re.finditer(txt):
        events.append((m.start(), 'path', m.group(1)))
    events.sort(key=lambda e: e[0])
    out = {}
    cur = None
    for _, kind, val in events:
        if kind == 'slug':
            cur = val
            out.setdefault(cur, [])
        elif kind == 'path' and cur is not None:
            out[cur].append(val)
    return out

def dart_map(name, d):
    lines = [f'const Map<String, List<String>> {name} = {{']
    for slug, paths in d.items():
        lines.append(f"  '{slug}': [")
        for p in paths:
            lines.append(f"    '{p}',")
        lines.append('  ],')
    lines.append('};')
    return '\n'.join(lines)

hdr = '''// GENERATED — do not edit by hand.
// Muscle SVG path data extracted from react-native-body-highlighter
// (https://github.com/HichamELBSI/react-native-body-highlighter), MIT License,
// Copyright (c) 2022 ELABBASSI Hicham. See assets/body/LICENSE-body-highlighter.
//
// Each entry maps a muscle slug to its SVG path 'd' string(s) in that view's
// viewBox coordinate space (see bodyViewBox below: minX, minY, width, height).

class BodyViewBox {
  final double minX, minY, width, height;
  const BodyViewBox(this.minX, this.minY, this.width, this.height);
}
'''

out = [hdr]
vb_lines = ['const Map<String, BodyViewBox> bodyViewBox = {']
for name, (fp, vb) in FILES.items():
    d = parse(fp)
    out.append(dart_map(name, d))
    mnx, mny, w, h = vb.split()
    vb_lines.append(f"  '{name}': BodyViewBox({float(mnx)}, {float(mny)}, {float(w)}, {float(h)}),")
    print(name, 'slugs:', list(d.keys()))
vb_lines.append('};')
out.append('\n'.join(vb_lines))

open('D:/FitYaar/FitYaar-Mobile/lib/features/insights/body_paths.dart','w',encoding='utf-8').write('\n\n'.join(out)+'\n')
print('WROTE body_paths.dart')

#!/usr/bin/env python3
"""Execute the inline scripts of both pages under a stub DOM with a throwing
localStorage. Catches load-time errors (TDZ, missing globals) that a plain
syntax check misses. Run before pushing: python3 scripts/check.py"""
import re, subprocess, sys, tempfile

STUB = '''
const elements = new Map();
const mkEl = (id) => ({
  id, textContent:'', innerHTML:'', hidden:false, disabled:false, value:'', placeholder:'',
  style:{}, dataset:{lang:'sv'}, classList:{toggle(){},add(){},remove(){}},
  addEventListener(){}, appendChild(){}, prepend(){}, querySelector(){ return mkEl('q'); },
  querySelectorAll(){ return []; }, click(){},
});
const def = (k,v) => Object.defineProperty(globalThis, k, { value: v, configurable: true, writable: true });
def('document', {
  title:'', documentElement:{lang:''},
  getElementById: (id) => { if(!elements.has(id)) elements.set(id, mkEl(id)); return elements.get(id); },
  createElement: (t) => mkEl(t),
  querySelectorAll: () => [],
  addEventListener(){},
});
def('window', { PC_CONFIG: { supabaseUrl:'https://x.supabase.co', anonKey:'a', gateUrl:'https://x/collect', eventTitle:'T' }, addEventListener(){} });
def('location', { search: '?k=birk', origin:'https://birkbilder.com', pathname:'/' });
def('localStorage', { getItem(){ throw new Error('strict mode'); }, setItem(){ throw new Error('strict mode'); } });
def('exifr', { parse: async () => ({}) });
def('qrcode', () => ({ addData(){}, make(){}, createSvgTag(){ return ''; } }));
def('navigator', { clipboard:{}, share:null });
def('fetch', async () => ({ ok:true, json: async () => [], headers:{get:()=>null} }));
def('alert', () => {});
'''

failed = False
for page in ['docs/index.html', 'docs/gallery.html']:
    html = open(page).read()
    main = max(re.findall(r'<script>(.*?)</script>', html, re.S), key=len)
    with tempfile.NamedTemporaryFile('w', suffix='.mjs', delete=False) as f:
        f.write(STUB + main + '\nconsole.log("EXECUTED-TO-END");')
        path = f.name
    r = subprocess.run(['node', path], capture_output=True, text=True, timeout=15)
    ok = 'EXECUTED-TO-END' in r.stdout
    print(page, '→', 'OK' if ok else 'FAILED:\n' + r.stderr[:500])
    failed = failed or not ok
sys.exit(1 if failed else 0)

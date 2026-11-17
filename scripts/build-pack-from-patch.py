# SPDX-License-Identifier: AGPL-3.0-only
"""{"İngilizce": "Türkçe"} yama dosyasından GameTranslator oyun paketi (biçim 2: entries + segments + fuzzy) üretir.
Adımlar windows/src/GameTranslator.Core/GamePacks.cs (PackKey) ve PackFuzzy.cs ile birebir aynı.
kullanım: build-pack-from-patch.py yama.json çıktı.json.gz kimlik "Başlık"
"""
import base64, gzip, hashlib, json, re, struct, sys, unicodedata
sys.stdout.reconfigure(encoding='utf-8')

TAG = re.compile(r"<[^<>]{0,40}>")

def canon(text):
    t = TAG.sub(" ", text)
    t = unicodedata.normalize('NFKC', t).replace('İ', 'i̇').lower()
    out, gap = [], False
    for ch in unicodedata.normalize('NFD', t):
        cat = unicodedata.category(ch)
        if cat in ('Mn', 'Mc', 'Me'):
            continue
        if cat in ('Lu', 'Ll', 'Lt', 'Lm', 'Lo', 'Nd', 'Nl', 'No'):
            if gap and out:
                out.append(' ')
            gap = False
            out.append(ch)
        else:
            gap = True
    return ''.join(out)

def key(text):
    c = canon(text)
    return int(hashlib.sha256(c.encode('utf-8')).hexdigest()[:16], 16) if c else None

FOLD = {'l': 'i', '1': 'i', 'ı': 'i', 'j': 'i', '0': 'o', '5': 's', 'æ': 'a', 'ø': 'o', 'œ': 'o', 'ß': 's'}
MIN_LENGTH, MAX_BITS, BITS_PER_GRAM = 16, 256, 3

def folded(text):
    return [FOLD.get(ch, ch) for ch in canon(text) if ch != ' ']

def bits_for(length):
    bits = 64
    while bits < MAX_BITS and length * BITS_PER_GRAM > bits:
        bits *= 2
    return bits

def signature(text):
    runes = folded(text)
    if len(runes) < MIN_LENGTH:
        return None
    length = min(len(runes), 255)
    bits = bits_for(length)
    hashes = set()
    for i in range(len(runes) - 2):
        h = 0xcbf29ce484222325
        for ch in runes[i:i + 3]:
            for b in ch.encode('utf-8'):
                h ^= b
                h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
        hashes.add(h)
    words = [0] * (bits // 64)
    for h in hashes:
        bit = h & (bits - 1)
        words[bit >> 6] |= 1 << (bit & 63)
    return length, b''.join(struct.pack('<Q', w) for w in words)

def clean_tr(text):
    text = TAG.sub('', text)
    return ' '.join(text.split())

SENT = re.compile(r'(?<=[.!?…])\s+(?=["“‘\'(]?[A-ZÇĞİÖŞÜ0-9])')

def sentences(text):
    return [s.strip() for s in SENT.split(text.strip()) if s.strip()]

def usable(en):
    return '{' not in en and '|plural' not in en and canon(en) != ''

def main(src, out, pid, title):
    data = json.load(open(src, encoding='utf-8'))
    entries, segments = {}, {}
    skipped = 0
    for en, tr in data.items():
        if not isinstance(tr, str) or not usable(en):
            skipped += 1
            continue
        tr = clean_tr(tr)
        if not tr:
            continue
        entries[key(en)] = tr
        # Çok cümleli satır: oyun cümleleri ayrı altyazı olarak da gösterebilir. Cümle sayıları tutuyorsa her cümle parça.
        es, ts = sentences(en), sentences(tr)
        if len(es) > 1 and len(es) == len(ts):
            for a, b in zip(es, ts):
                k = key(a)
                if k is not None and canon(a).count(' ') >= 1:
                    segments.setdefault(k, b)
    for k in list(segments):
        if k in entries:
            del segments[k]
    # İmza için İngilizce metin: anahtar → metin
    text_of = {}
    for en in data:
        if usable(en):
            text_of.setdefault(key(en), en)
            es = sentences(en)
            for a in es if len(es) > 1 else []:
                text_of.setdefault(key(a), a)
    order = sorted(set(entries) | set(segments))
    mask = bytearray((len(order) + 7) // 8)
    lengths, blooms = bytearray(), bytearray()
    for i, k in enumerate(order):
        sig = signature(text_of[k])
        if sig is None:
            continue
        mask[i >> 3] |= 1 << (i & 7)
        lengths.append(sig[0])
        blooms += sig[1]
    pack = {
        'format': 2, 'id': pid, 'title': title, 'source': 'kullanıcı yaması',
        'entries': {f'{k:016x}': v for k, v in entries.items()},
        'segments': {f'{k:016x}': v for k, v in segments.items()},
        'fuzzy': {'version': 1, 'count': len(order), 'mask': base64.b64encode(bytes(mask)).decode(),
                  'lengths': base64.b64encode(bytes(lengths)).decode(), 'blooms': base64.b64encode(bytes(blooms)).decode()},
    }
    with gzip.open(out, 'wb') as f:
        f.write(json.dumps(pack, ensure_ascii=False, separators=(',', ':')).encode('utf-8'))
    print(f'satır {len(entries)}, parça {len(segments)}, imza {len(lengths)}, atlanan {skipped}')

if __name__ == '__main__':
    main(*sys.argv[1:5])

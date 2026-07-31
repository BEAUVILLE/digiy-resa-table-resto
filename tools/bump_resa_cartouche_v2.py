from pathlib import Path

path = Path("index.html")
source = path.read_text(encoding="utf-8")
old = 'assets/js/resa-portes-cartouche.js?v=20260731'
new = 'assets/js/resa-portes-cartouche.js?v=20260731-cartouche-v2'

if new in source:
    print("Cartouche v2 déjà référencée")
elif old in source:
    path.write_text(source.replace(old, new, 1), encoding="utf-8")
    print("Index RESA basculé vers la cartouche v2")
else:
    raise SystemExit("Référence de cartouche introuvable dans index.html")

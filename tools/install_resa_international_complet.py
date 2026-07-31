from pathlib import Path

SECONDARY = [
    "fiche.html",
    "reserver.html",
    "inscription-resa.html",
    "catalogue.html",
    "lexique-resa.html",
]

SECONDARY_MARKER = "<!-- DIGIY RESA — pages secondaires internationales 7 langues -->"
SECONDARY_TAGS = """
  <!-- DIGIY RESA — pages secondaires internationales 7 langues -->
  <script src="./assets/js/resa-secondary-i18n-base.js?v=20260731"></script>
  <script src="./assets/js/resa-secondary-i18n-en-es.js?v=20260731"></script>
  <script src="./assets/js/resa-secondary-i18n-de-it.js?v=20260731"></script>
  <script src="./assets/js/resa-secondary-i18n-nl-ar.js?v=20260731"></script>
  <script src="./assets/js/resa-secondary-i18n.js?v=20260731"></script>
"""

INDEX_MARKER = "<!-- DIGIY RESA — cartouche portes internationales -->"
INDEX_TAGS = """
  <!-- DIGIY RESA — cartouche portes internationales -->
  <script src="./assets/js/resa-portes-cartouche.js?v=20260731"></script>
"""


def inject(path: Path, marker: str, tags: str) -> bool:
    if not path.exists():
        print(f"IGNORÉ absent: {path}")
        return False
    source = path.read_text(encoding="utf-8")
    if marker in source:
        print(f"DÉJÀ INSTALLÉ: {path}")
        return False
    if "</body>" not in source:
        raise SystemExit(f"Balise </body> absente dans {path}")
    source = source.replace("</body>", tags + "</body>", 1)
    path.write_text(source, encoding="utf-8")
    print(f"INSTALLÉ: {path}")
    return True


changed = False
changed |= inject(Path("index.html"), INDEX_MARKER, INDEX_TAGS)
for filename in SECONDARY:
    changed |= inject(Path(filename), SECONDARY_MARKER, SECONDARY_TAGS)

# La porte d'inscription générée dans l'état vide de l'index conserve la langue active.
index = Path("index.html")
if index.exists():
    source = index.read_text(encoding="utf-8")
    old = 'href="inscription-resa.html"'
    new = 'href="inscription-resa.html?lang=${lang}"'
    if old in source and new not in source:
        source = source.replace(old, new)
        index.write_text(source, encoding="utf-8")
        changed = True
        print("LANGUE CONSERVÉE: lien inscription dans index.html")

# Le moteur expose la traduction de message pour les canaux directs.
engine = Path("assets/js/resa-secondary-i18n.js")
if engine.exists():
    source = engine.read_text(encoding="utf-8")
    old = 'function translateMessage(value){return String(value||"").split("\\n").map(translateString).join("\\n")}'
    new = old + ';window.DIGIY_RESA_TRANSLATE_MESSAGE=translateMessage'
    if old in source and "DIGIY_RESA_TRANSLATE_MESSAGE" not in source:
        source = source.replace(old, new, 1)
        engine.write_text(source, encoding="utf-8")
        changed = True
        print("TRADUCTEUR GLOBAL: messages directs")

# Le SMS prérempli passe par le traducteur avant l'ouverture de Messages.
inscription = Path("inscription-resa.html")
if inscription.exists():
    source = inscription.read_text(encoding="utf-8")
    old = "window.location.href = buildSmsHref(smsMsg());"
    new = """const message = smsMsg();
        const translatedMessage = typeof window.DIGIY_RESA_TRANSLATE_MESSAGE === \"function\"
          ? window.DIGIY_RESA_TRANSLATE_MESSAGE(message)
          : message;
        window.location.href = buildSmsHref(translatedMessage);"""
    if old in source and "translatedMessage" not in source:
        source = source.replace(old, new, 1)
        inscription.write_text(source, encoding="utf-8")
        changed = True
        print("SMS 7 LANGUES: inscription-resa.html")

print("MODIFICATIONS PRÊTES" if changed else "AUCUNE MODIFICATION NÉCESSAIRE")

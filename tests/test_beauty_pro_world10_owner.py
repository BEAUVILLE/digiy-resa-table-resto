"""DIGIY BEAUTY PRO — vrais écrans propriétaires en 10 langues, sans changer le métier."""
import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
ACCESS=(ROOT/"resa-beauty/acces-proprietaire.html").read_text(encoding="utf-8")
GESTION=(ROOT/"resa-beauty/gestion.html").read_text(encoding="utf-8")
WORLD10=(ROOT/"resa-beauty/world10-pro.js").read_text(encoding="utf-8")

def dictionary():
    begin=WORLD10.index("const rows=")+len("const rows=")
    end=WORLD10.index(";\n const phrase=new Map()",begin)
    return json.loads(WORLD10[begin:end])

class BeautyProWorld10(unittest.TestCase):
    def test_ten_languages_complete_no_duplicate(self):
        rows=dictionary()
        self.assertGreaterEqual(len(rows),80)
        self.assertEqual(len({r[0] for r in rows}),len(rows))
        for row in rows:
            self.assertEqual(len(row),10,row[0])
            self.assertTrue(all(isinstance(s,str) and s.strip() for s in row),row[0])
        self.assertIn('const langs=["fr","en","es","pt","de","it","nl","ar","wo","zh"]',WORLD10)
        lookup={row[0]:row for row in rows}
        for key in ["Prestations & tarifs","Demandes de réservation",
                    "📅 Mon planning sur sept jours","✅ Créneau mis à jour.",
                    "✅ Profil BEAUTY mis à jour.","Nouvelle demande",
                    "RECEVOIR MON ACCÈS","Langue","Lundi","Dimanche"]:
            self.assertIn(key,lookup)
            self.assertNotEqual(lookup[key][0],lookup[key][9],key)

    def test_both_real_owner_pages_load_world10(self):
        for name,html in [("access",ACCESS),("management",GESTION)]:
            self.assertEqual(html.count('<script src="./world10-pro.js" defer></script>'),1,name)
        self.assertIn('id="beautyProWorld10"',WORLD10)
        self.assertIn("MutationObserver",WORLD10)
        self.assertIn("document.documentElement.dir=lang===\"ar\"?\"rtl\":\"ltr\"",WORLD10)

    def test_every_visible_static_label_has_translation_or_is_owned(self):
        keys={row[0] for row in dictionary()}
        owned={"TEST RÉSA BEAUTY · SALY","💇 DIGIY RÉSA BEAUTY",
               "+221 77 000 00 00","Saly","Petite Côte"}
        for name,html in [("access",ACCESS),("management",GESTION)]:
            plain=re.sub(r"<script\b[^>]*>[\s\S]*?</script>","",html,flags=re.I)
            plain=re.sub(r"<style\b[^>]*>[\s\S]*?</style>","",plain,flags=re.I)
            labels={t.strip() for t in re.sub(r"<[^>]+>","|",plain).split("|")
                    if len(t.strip())>2 and re.search(r"[A-Za-zÀ-ÿ]",t)}
            labels|={t for t in re.findall(r'(?:placeholder|aria-label)="([^"]+)"',plain)}
            missing=labels-keys-owned
            self.assertFalse(missing,f"{name}: {sorted(missing)}")

    def test_owner_cannot_silently_fallback_to_saly_test(self):
        for page in (ACCESS,GESTION):
            self.assertNotIn("get('slug')||'test-resa-beauty-saly'",page)
            self.assertIn("^[a-z0-9][a-z0-9-]{0,79}$",page)
            self.assertIn("if(!slug)",page)
        self.assertIn("shouldCreateUser:false",ACCESS)
        self.assertIn("emailRedirectTo:redirect()",ACCESS)
        self.assertIn("encodeURIComponent(slug)+'&lang='",ACCESS)
        self.assertIn("location.replace(target())",ACCESS)
        self.assertIn("p_slug:slug",GESTION)
        self.assertIn("if(!session)",GESTION)
        self.assertIn("digiy_beauty_owner_get_v1",GESTION)
        self.assertIn("Aucun accès propriétaire pour cette fiche.",GESTION)
        self.assertIn('name="robots" content="noindex,nofollow,noarchive"',ACCESS)
        self.assertIn('name="robots" content="noindex,nofollow,noarchive"',GESTION)

    def test_no_business_or_private_data_translated(self):
        self.assertIn('!reverse.has(title.textContent.trim())',WORLD10)
        self.assertIn('.bookingName, .bookingMeta',WORLD10)
        self.assertIn("input, textarea",WORLD10)
        self.assertIn("p_services:clean",GESTION)
        self.assertIn("digiy_beauty_owner_update_v1",GESTION)
        for rpc in ["digiy_beauty_owner_open_week_v1",
                    "digiy_beauty_owner_slots_v1",
                    "digiy_beauty_owner_bookings_v1",
                    "digiy_beauty_owner_set_booking_status_v1",
                    "digiy_beauty_owner_set_slot_status_v1"]:
            self.assertIn(rpc,GESTION)
        for banned in [".rpc(", "fetch(", "XMLHttpRequest", "supabase.createClient", "innerHTML"]:
            self.assertNotIn(banned,WORLD10)

    def test_js_syntax(self):
        result=subprocess.run(["node","--check",str(ROOT/"resa-beauty/world10-pro.js")],
                              capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        for page in (ACCESS,GESTION):
            for attrs,script in re.findall(r"<script\b([^>]*)>([\s\S]*?)</script>",page):
                if "src=" in attrs or not script.strip():continue
                result=subprocess.run(["node","--check","-"],input=script,capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr)

if __name__=="__main__":
    unittest.main()

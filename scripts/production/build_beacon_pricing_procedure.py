"""Builds the Production Beacon Pricing Procedure (one Draft version, V1) from the final HTCDEV design (repo V4)
and swaps every decision table ID for the Production ID.

Usage: python3 build_beacon_pricing_procedure.py <Tier Price ID> <Module Count Price ID> <Multi-Module Discount ID> <out dir>
"""
import re, sys, os, zipfile

REPO = os.path.join(os.path.dirname(__file__), "..", "..", "unpackaged", "main", "default", "expressionSetDefinitions",
                    "Beacon_Pricing_Procedure.expressionSetDefinition-meta.xml")
# Standard Revenue Cloud decision tables in Beacon Production (looked up 2026-11-06).
PROD_IDS = {
    "Price_Book_Entry_Decision_Table_v2": "0lDQ300000003U9MAI",
    "Price_Adjustment_Tier_Decision_Table": "0lDQ300000003VlMAI",
    "Attribute_Based_Adjustment_Decision_Table": "0lDQ300000003YzMAI",
    "Bundle_Based_Adjustment_Decision_Table": "0lDQ300000003abMAA",
    "Contract_Pricing_Volume_Tiers": "0lDQ300000003acMAA",
    "Contract_Pricing_Entries_Decision_Table": "0lDQ300000003dpMAA",
    "Index_Rate_Decision_Table": "0lDQ300000003cEMAQ",
}
tier_id, mc_id, disc_id, out_dir = sys.argv[1:5]
PROD_IDS.update({"Beacon_Tier_Price": tier_id, "Beacon_Module_Count_Price": mc_id, "Beacon_Multi_Module_Discount": disc_id})

s = open(REPO).read()
head = s[: s.index("    <versions>")]
v = [x for x in re.findall(r"    <versions>.*?\n    </versions>", s, re.S) if "<fullName>Beacon_Pricing_Procedure_V4</fullName>" in x][0]

def fix_step(m):
    st = m.group(0)
    api = re.search(r"<name>LookUpApiName</name>\s*<output>false</output>\s*<type>Literal</type>\s*<value>([^<]+)</value>", st)
    if api:
        st, n = re.subn(r"(<name>LookUpId</name>\s*<output>false</output>\s*<type>Literal</type>\s*<value>)[^<]+(</value>)",
                        lambda mm: mm.group(1) + PROD_IDS[api.group(1)] + mm.group(2), st)
        assert n == 1, api.group(1)
    return st

v = re.sub(r"        <steps>.*?\n        </steps>", fix_step, v, flags=re.S)
v = v.replace("Beacon_Pricing_Procedure_V4", "Beacon_Pricing_Procedure_V1").replace("<label>Beacon Pricing Procedure V4</label>", "<label>Beacon Pricing Procedure V1</label>")
v = re.sub(r"<rank>\d+</rank>", "<rank>1</rank>", v)
v = re.sub(r"<versionNumber>\d+</versionNumber>", "<versionNumber>1</versionNumber>", v)
v = re.sub(r"<status>\w+</status>", "<status>Draft</status>", v, count=1)
assert "0lDS9" not in v, "an HTCDEV decision table ID is left"
head = re.sub(r"<description>[^<]*</description>", "<description>Beacon pricing: Revenue Cloud default pricing plus the Beacon steps 16-22 (Number of Users tier price, multi-module discount, module count price).</description>", head, count=1)
doc = head + v + "\n</ExpressionSetDefinition>\n"
import xml.etree.ElementTree as ET; ET.fromstring(doc.encode())
pkg = """<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Beacon_Pricing_Procedure</members>
        <name>ExpressionSetDefinition</name>
    </types>
    <version>65.0</version>
</Package>
"""
os.makedirs(out_dir, exist_ok=True)
zp = os.path.join(out_dir, "Beacon_Pricing_Procedure_PROD.zip")
with zipfile.ZipFile(zp, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("unpackaged/package.xml", pkg)
    z.writestr("unpackaged/expressionSetDefinition/Beacon_Pricing_Procedure.expressionSetDefinition", doc)
print("wrote", zp)

// Beacon pricing – PRODUCTION data load 8 of 8: Module Count prices for Contract Orgs (>200 Heads), the multi-module
// discounts, and each module's price book entry set to its Tier 1 price. Run after scripts 1-7. Safe to re-run.
// Rows: price book | module level | min modules | max modules (17 = no limit) | user band | min tier | max tier | quote total.
// One row is written per exact module count, with Price Per Line = quote total / module count. Upserts on Price Key, safe to re-run.
List<String> rows = new List<String>{
'Contract Orgs (>200 Heads)|Entry|1|1|Up to 5 users|1|2|40000',
'Contract Orgs (>200 Heads)|Entry|1|1|Up to 10 users|3|3|65000',
'Contract Orgs (>200 Heads)|Entry|1|1|Up to 20 users|4|4|80000',
'Contract Orgs (>200 Heads)|Entry|1|1|Up to 50 users|5|5|90000',
'Contract Orgs (>200 Heads)|Entry|1|1|Enterprise|6|6|100000',
'Contract Orgs (>200 Heads)|Starter|2|2|Up to 5 users|1|2|75000',
'Contract Orgs (>200 Heads)|Starter|2|2|Up to 10 users|3|3|100000',
'Contract Orgs (>200 Heads)|Starter|2|2|Up to 20 users|4|4|150000',
'Contract Orgs (>200 Heads)|Starter|2|2|Up to 50 users|5|5|175000',
'Contract Orgs (>200 Heads)|Starter|2|2|Enterprise|6|6|190000',
'Contract Orgs (>200 Heads)|Core|3|4|Up to 5 users|1|2|110000',
'Contract Orgs (>200 Heads)|Core|3|4|Up to 10 users|3|3|150000',
'Contract Orgs (>200 Heads)|Core|3|4|Up to 20 users|4|4|220000',
'Contract Orgs (>200 Heads)|Core|3|4|Up to 50 users|5|5|250000',
'Contract Orgs (>200 Heads)|Core|3|4|Enterprise|6|6|275000',
'Contract Orgs (>200 Heads)|Pro|5|5|Up to 5 users|1|2|150000',
'Contract Orgs (>200 Heads)|Pro|5|5|Up to 10 users|3|3|180000',
'Contract Orgs (>200 Heads)|Pro|5|5|Up to 20 users|4|4|270000',
'Contract Orgs (>200 Heads)|Pro|5|5|Up to 50 users|5|5|320000',
'Contract Orgs (>200 Heads)|Pro|5|5|Enterprise|6|6|350000',
'Contract Orgs (>200 Heads)|Platform|6|17|Up to 5 users|1|2|175000',
'Contract Orgs (>200 Heads)|Platform|6|17|Up to 10 users|3|3|220000',
'Contract Orgs (>200 Heads)|Platform|6|17|Up to 20 users|4|4|320000',
'Contract Orgs (>200 Heads)|Platform|6|17|Up to 50 users|5|5|360000',
'Contract Orgs (>200 Heads)|Platform|6|17|Enterprise|6|6|400000'
};
Map<String, Id> books = new Map<String, Id>();
for (Pricebook2 b : [SELECT Id, Name FROM Pricebook2]) books.put(b.Name, b.Id);
List<Beacon_Module_Count_Price__c> recs = new List<Beacon_Module_Count_Price__c>();
for (String r : rows) {
    List<String> f = r.split('\\|');
    for (Integer n = Integer.valueOf(f[2]); n <= Integer.valueOf(f[3]); n++) {
        Decimal total = Decimal.valueOf(f[7]);
        Beacon_Module_Count_Price__c x = new Beacon_Module_Count_Price__c(Price_Book__c = books.get(f[0]), Module_Level__c = f[1],
            User_Band__c = f[4], Min_Modules__c = n, Max_Modules__c = n, Min_Tier__c = Integer.valueOf(f[5]), Max_Tier__c = Integer.valueOf(f[6]),
            Quote_Total__c = total, Adjustment_Type__c = 'Override', Adjustment_Value__c = (total / n).setScale(2),
            Price_Key__c = f[0] + '|' + f[1] + '|' + f[4] + '|' + n);
        x.put('CurrencyIsoCode', 'GBP');
        recs.add(x);
    }
}
upsert recs Beacon_Module_Count_Price__c.Price_Key__c;
System.debug(recs.size() + ' module count prices upserted');

// Multi-module discount: price book | module count from | to | percent. One row per exact module count.
List<String> disc = new List<String>{ 'Top 1-50 Pharma|2|2|10', 'Top 1-50 Pharma|3|3|20', 'Top 1-50 Pharma|4|17|30',
    '>200 Heads|2|2|10', '>200 Heads|3|3|20', '>200 Heads|4|17|30' };
List<Beacon_Multi_Module_Discount__c> d = new List<Beacon_Multi_Module_Discount__c>();
for (String r : disc) {
    List<String> f = r.split('\\|');
    for (Integer n = Integer.valueOf(f[1]); n <= Integer.valueOf(f[2]); n++) {
        Beacon_Multi_Module_Discount__c x = new Beacon_Multi_Module_Discount__c(Price_Book__c = books.get(f[0]), Min_Modules__c = n,
            Max_Modules__c = n, Adjustment_Type__c = 'Percentage', Adjustment_Value__c = Decimal.valueOf(f[3]), Price_Key__c = f[0] + '|' + n);
        x.put('CurrencyIsoCode', 'GBP');
        d.add(x);
    }
}
upsert d Beacon_Multi_Module_Discount__c.Price_Key__c;
// Price book entries: each module's Annual entry = its Tier 1 price.
Map<String, Decimal> tier1 = new Map<String, Decimal>();
for (Beacon_Tier_Price__c t : [SELECT Price_Book__c, Product__c, Adjustment_Value__c FROM Beacon_Tier_Price__c WHERE Tier__c = 1])
    tier1.put(String.valueOf(t.Price_Book__c) + String.valueOf(t.Product__c), t.Adjustment_Value__c);
List<PricebookEntry> pbes = new List<PricebookEntry>();
for (PricebookEntry e : [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = false]) {
    Decimal p = tier1.get(String.valueOf(e.Pricebook2Id) + String.valueOf(e.Product2Id));
    if (p != null && e.UnitPrice != p) { e.UnitPrice = p; pbes.add(e); }
}
update pbes;
System.debug(d.size() + ' discount rows upserted; ' + pbes.size() + ' price book entries set to Tier 1');

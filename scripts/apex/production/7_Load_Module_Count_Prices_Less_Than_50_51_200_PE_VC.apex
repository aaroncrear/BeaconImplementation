// Beacon pricing – PRODUCTION data load 7 of 8: Module Count prices for <50 Heads, 51-200 Heads and PE-VC.
// Rows: price book | module level | min modules | max modules (17 = no limit) | user band | min tier | max tier | quote total.
// One row is written per exact module count, with Price Per Line = quote total / module count. Upserts on Price Key, safe to re-run.
List<String> rows = new List<String>{
'<50 Heads|Entry|1|1|Up to 3 users|1|1|18000',
'<50 Heads|Entry|1|1|Enterprise|2|6|21000',
'<50 Heads|Starter|2|2|Up to 3 users|1|1|23000',
'<50 Heads|Starter|2|2|Enterprise|2|6|26000',
'<50 Heads|Core|3|4|Up to 3 users|1|1|26000',
'<50 Heads|Core|3|4|Enterprise|2|6|32000',
'<50 Heads|Pro|5|5|Up to 3 users|1|1|32000',
'<50 Heads|Pro|5|5|Enterprise|2|6|38000',
'<50 Heads|Platform|6|17|Up to 3 users|1|1|42000',
'<50 Heads|Platform|6|17|Enterprise|2|6|50000',
'51-200 Heads|Entry|1|1|Up to 3 users|1|1|21000',
'51-200 Heads|Entry|1|1|Up to 10 users|2|3|25000',
'51-200 Heads|Entry|1|1|Enterprise|4|6|35000',
'51-200 Heads|Starter|2|2|Up to 3 users|1|1|26000',
'51-200 Heads|Starter|2|2|Up to 10 users|2|3|31000',
'51-200 Heads|Starter|2|2|Enterprise|4|6|41000',
'51-200 Heads|Core|3|4|Up to 3 users|1|1|32000',
'51-200 Heads|Core|3|4|Up to 10 users|2|3|38000',
'51-200 Heads|Core|3|4|Enterprise|4|6|48000',
'51-200 Heads|Pro|5|5|Up to 3 users|1|1|38000',
'51-200 Heads|Pro|5|5|Up to 10 users|2|3|45000',
'51-200 Heads|Pro|5|5|Enterprise|4|6|55000',
'51-200 Heads|Platform|6|17|Up to 3 users|1|1|50000',
'51-200 Heads|Platform|6|17|Up to 10 users|2|3|60000',
'51-200 Heads|Platform|6|17|Enterprise|4|6|70000',
'PE-VC|Entry|1|1|Up to 5 users|1|2|35000',
'PE-VC|Entry|1|1|Up to 10 users|3|3|60000',
'PE-VC|Entry|1|1|Enterprise|4|6|75000',
'PE-VC|Starter|2|2|Up to 5 users|1|2|60000',
'PE-VC|Starter|2|2|Up to 10 users|3|3|100000',
'PE-VC|Starter|2|2|Enterprise|4|6|120000',
'PE-VC|Core|3|4|Up to 5 users|1|2|80000',
'PE-VC|Core|3|4|Up to 10 users|3|3|135000',
'PE-VC|Core|3|4|Enterprise|4|6|160000',
'PE-VC|Pro|5|5|Up to 5 users|1|2|100000',
'PE-VC|Pro|5|5|Up to 10 users|3|3|150000',
'PE-VC|Pro|5|5|Enterprise|4|6|180000',
'PE-VC|Platform|6|17|Up to 5 users|1|2|120000',
'PE-VC|Platform|6|17|Up to 10 users|3|3|160000',
'PE-VC|Platform|6|17|Enterprise|4|6|200000'
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

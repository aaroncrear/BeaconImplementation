// Pricing Model Rebuild: tier prices for 51-200 Heads (part 3 of 6). Upserts on Price Key, safe to re-run.
String book = '51-200 Heads';
List<String> rows = new List<String>{
'DIS-ONCOLOGY|21000,25000,25000,35000,35000,35000',
'DIS-NEURO|21000,25000,25000,35000,35000,35000',
'DIS-CVRM|21000,25000,25000,35000,35000,35000',
'DIS-I-AND-I|21000,25000,25000,35000,35000,35000',
'DIS-AUTOIMMUNE|21000,25000,25000,35000,35000,35000',
'MOD1-ADC|21000,25000,25000,35000,35000,35000',
'MOD1-BISPECIFIC|21000,25000,25000,35000,35000,35000',
'MOD1-CHECKPOINT|21000,25000,25000,35000,35000,35000',
'MOD1-CYTOKINE|21000,25000,25000,35000,35000,35000',
'MOD1-CELLTX|21000,25000,25000,35000,35000,35000',
'MOD1-GENETX|21000,25000,25000,35000,35000,35000',
'MOD1-RNA|21000,25000,25000,35000,35000,35000',
'MOD2-CANCERVAX|21000,25000,25000,35000,35000,35000',
'MOD2-DDR|21000,25000,25000,35000,35000,35000',
'MOD2-MICROBIOME|21000,25000,25000,35000,35000,35000',
'MOD2-ONCVIRUS|21000,25000,25000,35000,35000,35000',
'MOD2-TPD|21000,25000,25000,35000,35000,35000'
};
Id bookId = [SELECT Id FROM Pricebook2 WHERE Name = :book LIMIT 1].Id;
Map<String, Id> prod = new Map<String, Id>();
for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode != null]) prod.put(p.ProductCode, p.Id);
List<Beacon_Tier_Price__c> recs = new List<Beacon_Tier_Price__c>();
for (String r : rows) {
    List<String> f = r.split('\\|');
    List<String> p = f[1].split(',');
    for (Integer t = 1; t <= 6; t++) {
        Beacon_Tier_Price__c x = new Beacon_Tier_Price__c(Price_Book__c = bookId, Product__c = prod.get(f[0]), Tier__c = t,
            List_Price__c = Decimal.valueOf(p[t - 1]), Price_Key__c = book + '|' + f[0] + '|' + t);
        x.put('CurrencyIsoCode', 'GBP');
        recs.add(x);
    }
}
upsert recs Beacon_Tier_Price__c.Price_Key__c;
System.debug(book + ': ' + recs.size() + ' tier prices upserted');

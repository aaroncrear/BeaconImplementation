// Beacon pricing – PRODUCTION data load 6 of 8: tier prices for Contract Orgs (>200 Heads). Upserts on Price Key, safe to re-run.
String book = 'Contract Orgs (>200 Heads)';
List<String> rows = new List<String>{
'DIS-ONCOLOGY|40000,40000,65000,80000,90000,100000',
'DIS-NEURO|40000,40000,65000,80000,90000,100000',
'DIS-CVRM|40000,40000,65000,80000,90000,100000',
'DIS-I-AND-I|40000,40000,65000,80000,90000,100000',
'DIS-AUTOIMMUNE|40000,40000,65000,80000,90000,100000',
'MOD1-ADC|40000,40000,65000,80000,90000,100000',
'MOD1-BISPECIFIC|40000,40000,65000,80000,90000,100000',
'MOD1-CHECKPOINT|40000,40000,65000,80000,90000,100000',
'MOD1-CYTOKINE|40000,40000,65000,80000,90000,100000',
'MOD1-CELLTX|40000,40000,65000,80000,90000,100000',
'MOD1-GENETX|40000,40000,65000,80000,90000,100000',
'MOD1-RNA|40000,40000,65000,80000,90000,100000',
'MOD2-CANCERVAX|40000,40000,65000,80000,90000,100000',
'MOD2-DDR|40000,40000,65000,80000,90000,100000',
'MOD2-MICROBIOME|40000,40000,65000,80000,90000,100000',
'MOD2-ONCVIRUS|40000,40000,65000,80000,90000,100000',
'MOD2-TPD|40000,40000,65000,80000,90000,100000'
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
            Adjustment_Type__c = 'Override', Adjustment_Value__c = Decimal.valueOf(p[t - 1]), Price_Key__c = book + '|' + f[0] + '|' + t);
        x.put('CurrencyIsoCode', 'GBP');
        recs.add(x);
    }
}
upsert recs Beacon_Tier_Price__c.Price_Key__c;
System.debug(book + ': ' + recs.size() + ' tier prices upserted');

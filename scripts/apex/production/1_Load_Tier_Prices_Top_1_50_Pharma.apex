// Beacon pricing – PRODUCTION data load 1 of 8: tier prices for Top 1-50 Pharma. Upserts on Price Key, safe to re-run.
String book = 'Top 1-50 Pharma';
List<String> rows = new List<String>{
'DIS-ONCOLOGY|88000,88000,155000,265000,375000,495000',
'DIS-NEURO|88000,88000,155000,265000,375000,495000',
'DIS-CVRM|66000,66000,115000,190000,265000,345000',
'DIS-I-AND-I|66000,66000,115000,190000,265000,345000',
'DIS-AUTOIMMUNE|60000,60000,95000,145000,215000,300000',
'MOD1-ADC|60000,60000,95000,145000,215000,300000',
'MOD1-BISPECIFIC|60000,60000,95000,145000,215000,300000',
'MOD1-CHECKPOINT|60000,60000,95000,145000,215000,300000',
'MOD1-CYTOKINE|60000,60000,95000,145000,215000,300000',
'MOD1-CELLTX|60000,60000,95000,145000,215000,300000',
'MOD1-GENETX|60000,60000,95000,145000,215000,300000',
'MOD1-RNA|60000,60000,95000,145000,215000,300000',
'MOD2-CANCERVAX|30000,30000,50000,75000,110000,150000',
'MOD2-DDR|30000,30000,50000,75000,110000,150000',
'MOD2-MICROBIOME|30000,30000,50000,75000,110000,150000',
'MOD2-ONCVIRUS|30000,30000,50000,75000,110000,150000',
'MOD2-TPD|30000,30000,50000,75000,110000,150000'
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

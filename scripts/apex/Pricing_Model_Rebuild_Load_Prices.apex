// Pricing Model Rebuild: loads the Beacon price tables and sets each price book's Pricing Method.
// Run in Developer Console > Debug > Open Execute Anonymous Window, after the Pricing-Model-Rebuild
// metadata is deployed. Safe to run more than once: rows are upserted on Price Key.
// Also backfills Number of Users on existing module Assets from their Current Quantity, so renewal
// quotes created from them get Number of Users.
// Source: Rev Ops price sheets (Beacon Pricing - Update for SF.xlsx and the module count tables).

Map<String, String> pricingMethod = new Map<String, String>{
        'Top 1-50 Pharma' => 'Per Module',
        '>200 Heads' => 'Per Module',
        '51-200 Heads' => 'Module Count',
        '<50 Heads' => 'Module Count',
        'PE-VC' => 'Module Count',
        'Contract Orgs (>200 Heads)' => 'Module Count'
};

// Price book | product code | list price for tiers 1-6
List<String> tierRows = new List<String>{
        'Top 1-50 Pharma|DIS-ONCOLOGY|88000,88000,155000,265000,375000,495000',
        'Top 1-50 Pharma|DIS-NEURO|88000,88000,155000,265000,375000,495000',
        'Top 1-50 Pharma|DIS-CVRM|66000,66000,115000,190000,265000,345000',
        'Top 1-50 Pharma|DIS-I-AND-I|66000,66000,115000,190000,265000,345000',
        'Top 1-50 Pharma|DIS-AUTOIMMUNE|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-ADC|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-BISPECIFIC|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-CHECKPOINT|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-CYTOKINE|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-CELLTX|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-GENETX|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD1-RNA|60000,60000,95000,145000,215000,300000',
        'Top 1-50 Pharma|MOD2-CANCERVAX|30000,30000,50000,75000,110000,150000',
        'Top 1-50 Pharma|MOD2-DDR|30000,30000,50000,75000,110000,150000',
        'Top 1-50 Pharma|MOD2-MICROBIOME|30000,30000,50000,75000,110000,150000',
        'Top 1-50 Pharma|MOD2-ONCVIRUS|30000,30000,50000,75000,110000,150000',
        'Top 1-50 Pharma|MOD2-TPD|30000,30000,50000,75000,110000,150000',
        '>200 Heads|DIS-ONCOLOGY|50000,50000,90000,120000,160000,200000',
        '>200 Heads|DIS-NEURO|50000,50000,90000,120000,160000,200000',
        '>200 Heads|DIS-CVRM|50000,50000,90000,120000,160000,200000',
        '>200 Heads|DIS-I-AND-I|50000,50000,90000,120000,160000,200000',
        '>200 Heads|DIS-AUTOIMMUNE|40000,40000,65000,100000,135000,160000',
        '>200 Heads|MOD1-ADC|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD1-BISPECIFIC|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD1-CHECKPOINT|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD1-CYTOKINE|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD1-CELLTX|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD1-GENETX|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD1-RNA|30000,30000,55000,90000,120000,150000',
        '>200 Heads|MOD2-CANCERVAX|21000,21000,38000,62000,84000,100000',
        '>200 Heads|MOD2-DDR|21000,21000,38000,62000,84000,100000',
        '>200 Heads|MOD2-MICROBIOME|21000,21000,38000,62000,84000,100000',
        '>200 Heads|MOD2-ONCVIRUS|21000,21000,38000,62000,84000,100000',
        '>200 Heads|MOD2-TPD|21000,21000,38000,62000,84000,100000',
        '51-200 Heads|DIS-ONCOLOGY|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|DIS-NEURO|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|DIS-CVRM|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|DIS-I-AND-I|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|DIS-AUTOIMMUNE|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-ADC|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-BISPECIFIC|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-CHECKPOINT|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-CYTOKINE|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-CELLTX|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-GENETX|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD1-RNA|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD2-CANCERVAX|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD2-DDR|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD2-MICROBIOME|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD2-ONCVIRUS|21000,25000,25000,35000,35000,35000',
        '51-200 Heads|MOD2-TPD|21000,25000,25000,35000,35000,35000',
        '<50 Heads|DIS-ONCOLOGY|18000,21000,21000,21000,21000,21000',
        '<50 Heads|DIS-NEURO|18000,21000,21000,21000,21000,21000',
        '<50 Heads|DIS-CVRM|18000,21000,21000,21000,21000,21000',
        '<50 Heads|DIS-I-AND-I|18000,21000,21000,21000,21000,21000',
        '<50 Heads|DIS-AUTOIMMUNE|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-ADC|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-BISPECIFIC|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-CHECKPOINT|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-CYTOKINE|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-CELLTX|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-GENETX|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD1-RNA|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD2-CANCERVAX|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD2-DDR|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD2-MICROBIOME|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD2-ONCVIRUS|18000,21000,21000,21000,21000,21000',
        '<50 Heads|MOD2-TPD|18000,21000,21000,21000,21000,21000',
        'PE-VC|DIS-ONCOLOGY|35000,35000,60000,75000,75000,75000',
        'PE-VC|DIS-NEURO|35000,35000,60000,75000,75000,75000',
        'PE-VC|DIS-CVRM|35000,35000,60000,75000,75000,75000',
        'PE-VC|DIS-I-AND-I|35000,35000,60000,75000,75000,75000',
        'PE-VC|DIS-AUTOIMMUNE|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-ADC|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-BISPECIFIC|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-CHECKPOINT|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-CYTOKINE|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-CELLTX|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-GENETX|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD1-RNA|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD2-CANCERVAX|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD2-DDR|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD2-MICROBIOME|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD2-ONCVIRUS|35000,35000,60000,75000,75000,75000',
        'PE-VC|MOD2-TPD|35000,35000,60000,75000,75000,75000',
        'Contract Orgs (>200 Heads)|DIS-ONCOLOGY|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|DIS-NEURO|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|DIS-CVRM|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|DIS-I-AND-I|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|DIS-AUTOIMMUNE|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-ADC|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-BISPECIFIC|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-CHECKPOINT|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-CYTOKINE|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-CELLTX|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-GENETX|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD1-RNA|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD2-CANCERVAX|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD2-DDR|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD2-MICROBIOME|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD2-ONCVIRUS|40000,40000,65000,80000,90000,100000',
        'Contract Orgs (>200 Heads)|MOD2-TPD|40000,40000,65000,80000,90000,100000'
};

// Price book | level | min modules | max modules | user band | min users | max users | quote total
List<String> moduleCountRows = new List<String>{
        '<50 Heads|Entry|1|1|Up to 3 users|1|3|18000',
        '<50 Heads|Entry|1|1|Enterprise|4||21000',
        '<50 Heads|Starter|2|2|Up to 3 users|1|3|23000',
        '<50 Heads|Starter|2|2|Enterprise|4||26000',
        '<50 Heads|Core|3|4|Up to 3 users|1|3|26000',
        '<50 Heads|Core|3|4|Enterprise|4||32000',
        '<50 Heads|Pro|5|5|Up to 3 users|1|3|32000',
        '<50 Heads|Pro|5|5|Enterprise|4||38000',
        '<50 Heads|Platform|6||Up to 3 users|1|3|42000',
        '<50 Heads|Platform|6||Enterprise|4||50000',
        '51-200 Heads|Entry|1|1|Up to 3 users|1|3|21000',
        '51-200 Heads|Entry|1|1|Up to 10 users|4|10|25000',
        '51-200 Heads|Entry|1|1|Enterprise|11||35000',
        '51-200 Heads|Starter|2|2|Up to 3 users|1|3|26000',
        '51-200 Heads|Starter|2|2|Up to 10 users|4|10|31000',
        '51-200 Heads|Starter|2|2|Enterprise|11||41000',
        '51-200 Heads|Core|3|4|Up to 3 users|1|3|32000',
        '51-200 Heads|Core|3|4|Up to 10 users|4|10|38000',
        '51-200 Heads|Core|3|4|Enterprise|11||48000',
        '51-200 Heads|Pro|5|5|Up to 3 users|1|3|38000',
        '51-200 Heads|Pro|5|5|Up to 10 users|4|10|45000',
        '51-200 Heads|Pro|5|5|Enterprise|11||55000',
        '51-200 Heads|Platform|6||Up to 3 users|1|3|50000',
        '51-200 Heads|Platform|6||Up to 10 users|4|10|60000',
        '51-200 Heads|Platform|6||Enterprise|11||70000',
        'PE-VC|Entry|1|1|Up to 5 users|1|5|35000',
        'PE-VC|Entry|1|1|Up to 10 users|6|10|60000',
        'PE-VC|Entry|1|1|Enterprise|11||75000',
        'PE-VC|Starter|2|2|Up to 5 users|1|5|60000',
        'PE-VC|Starter|2|2|Up to 10 users|6|10|100000',
        'PE-VC|Starter|2|2|Enterprise|11||120000',
        'PE-VC|Core|3|4|Up to 5 users|1|5|80000',
        'PE-VC|Core|3|4|Up to 10 users|6|10|135000',
        'PE-VC|Core|3|4|Enterprise|11||160000',
        'PE-VC|Pro|5|5|Up to 5 users|1|5|100000',
        'PE-VC|Pro|5|5|Up to 10 users|6|10|150000',
        'PE-VC|Pro|5|5|Enterprise|11||180000',
        'PE-VC|Platform|6||Up to 5 users|1|5|120000',
        'PE-VC|Platform|6||Up to 10 users|6|10|160000',
        'PE-VC|Platform|6||Enterprise|11||200000',
        'Contract Orgs (>200 Heads)|Entry|1|1|Up to 5 users|1|5|40000',
        'Contract Orgs (>200 Heads)|Entry|1|1|Up to 10 users|6|10|65000',
        'Contract Orgs (>200 Heads)|Entry|1|1|Up to 20 users|11|20|80000',
        'Contract Orgs (>200 Heads)|Entry|1|1|Up to 50 users|21|50|90000',
        'Contract Orgs (>200 Heads)|Entry|1|1|Enterprise|51||100000',
        'Contract Orgs (>200 Heads)|Starter|2|2|Up to 5 users|1|5|75000',
        'Contract Orgs (>200 Heads)|Starter|2|2|Up to 10 users|6|10|100000',
        'Contract Orgs (>200 Heads)|Starter|2|2|Up to 20 users|11|20|150000',
        'Contract Orgs (>200 Heads)|Starter|2|2|Up to 50 users|21|50|175000',
        'Contract Orgs (>200 Heads)|Starter|2|2|Enterprise|51||190000',
        'Contract Orgs (>200 Heads)|Core|3|4|Up to 5 users|1|5|110000',
        'Contract Orgs (>200 Heads)|Core|3|4|Up to 10 users|6|10|150000',
        'Contract Orgs (>200 Heads)|Core|3|4|Up to 20 users|11|20|220000',
        'Contract Orgs (>200 Heads)|Core|3|4|Up to 50 users|21|50|250000',
        'Contract Orgs (>200 Heads)|Core|3|4|Enterprise|51||275000',
        'Contract Orgs (>200 Heads)|Pro|5|5|Up to 5 users|1|5|150000',
        'Contract Orgs (>200 Heads)|Pro|5|5|Up to 10 users|6|10|180000',
        'Contract Orgs (>200 Heads)|Pro|5|5|Up to 20 users|11|20|270000',
        'Contract Orgs (>200 Heads)|Pro|5|5|Up to 50 users|21|50|320000',
        'Contract Orgs (>200 Heads)|Pro|5|5|Enterprise|51||350000',
        'Contract Orgs (>200 Heads)|Platform|6||Up to 5 users|1|5|175000',
        'Contract Orgs (>200 Heads)|Platform|6||Up to 10 users|6|10|220000',
        'Contract Orgs (>200 Heads)|Platform|6||Up to 20 users|11|20|320000',
        'Contract Orgs (>200 Heads)|Platform|6||Up to 50 users|21|50|360000',
        'Contract Orgs (>200 Heads)|Platform|6||Enterprise|51||400000'
};

// Price book | min modules | max modules | discount percent
List<String> discountRows = new List<String>{
        'Top 1-50 Pharma|2|2|10',
        'Top 1-50 Pharma|3|3|20',
        'Top 1-50 Pharma|4||30',
        '>200 Heads|2|2|10',
        '>200 Heads|3|3|20',
        '>200 Heads|4||30'
};

Map<String, Id> bookIds = new Map<String, Id>();
for (Pricebook2 pb : [SELECT Id, Name FROM Pricebook2 WHERE Name IN :pricingMethod.keySet()]) {
    bookIds.put(pb.Name, pb.Id);
}
Map<String, Id> productIds = new Map<String, Id>();
for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'DIS-%' OR ProductCode LIKE 'MOD%']) {
    productIds.put(p.ProductCode, p.Id);
}
for (String b : pricingMethod.keySet()) {
    if (!bookIds.containsKey(b)) { throw new HandledException('Price book not found: ' + b); }
}

List<Pricebook2> books = new List<Pricebook2>();
for (String b : pricingMethod.keySet()) {
    books.add(new Pricebook2(Id = bookIds.get(b), Pricing_Method__c = pricingMethod.get(b)));
}
update books;

Decimal toNum(String s) { return String.isBlank(s) ? null : Decimal.valueOf(s); }

List<Beacon_Tier_Price__c> tierPrices = new List<Beacon_Tier_Price__c>();
for (String row : tierRows) {
    List<String> f = row.split('\\|');
    if (!productIds.containsKey(f[1])) { throw new HandledException('Product not found: ' + f[1]); }
    List<String> prices = f[2].split(',');
    for (Integer t = 1; t <= 6; t++) {
        Beacon_Tier_Price__c r = new Beacon_Tier_Price__c(
            Price_Book__c = bookIds.get(f[0]), Product__c = productIds.get(f[1]), Tier__c = t,
            List_Price__c = Decimal.valueOf(prices[t - 1]), Price_Key__c = f[0] + '|' + f[1] + '|' + t);
        r.put('CurrencyIsoCode', 'GBP');
        tierPrices.add(r);
    }
}
upsert tierPrices Beacon_Tier_Price__c.Price_Key__c;

List<Beacon_Module_Count_Price__c> mcPrices = new List<Beacon_Module_Count_Price__c>();
for (String row : moduleCountRows) {
    List<String> f = row.split('\\|', -1);
    Beacon_Module_Count_Price__c r = new Beacon_Module_Count_Price__c(
        Price_Book__c = bookIds.get(f[0]), Module_Level__c = f[1], Min_Modules__c = toNum(f[2]), Max_Modules__c = toNum(f[3]),
        User_Band__c = f[4], Min_Users__c = toNum(f[5]), Max_Users__c = toNum(f[6]), Quote_Total__c = toNum(f[7]),
        Price_Key__c = f[0] + '|' + f[1] + '|' + f[4]);
    r.put('CurrencyIsoCode', 'GBP');
    mcPrices.add(r);
}
upsert mcPrices Beacon_Module_Count_Price__c.Price_Key__c;

List<Beacon_Multi_Module_Discount__c> discounts = new List<Beacon_Multi_Module_Discount__c>();
for (String row : discountRows) {
    List<String> f = row.split('\\|', -1);
    discounts.add(new Beacon_Multi_Module_Discount__c(
        Price_Book__c = bookIds.get(f[0]), Min_Modules__c = toNum(f[1]), Max_Modules__c = toNum(f[2]),
        Discount_Percent__c = toNum(f[3]), Price_Key__c = f[0] + '|' + f[1]));
}
upsert discounts Beacon_Multi_Module_Discount__c.Price_Key__c;

// Existing module Assets: Number of Users = Current Quantity (the seat count before this release).
// Each Asset already has one Beacon Subscription per seat, so no extra subscriptions are created.
List<Asset> assetsToBackfill = new List<Asset>();
for (Asset a : [SELECT Id, CurrentQuantity FROM Asset
                WHERE Number_of_Users__c = null AND CurrentQuantity >= 1 AND Product2.Type != 'Bundle']) {
    assetsToBackfill.add(new Asset(Id = a.Id, Number_of_Users__c = Math.floor(a.CurrentQuantity)));
}
update assetsToBackfill;

System.debug('Price books updated: ' + books.size() + ', tier prices: ' + tierPrices.size()
    + ', module count prices: ' + mcPrices.size() + ', discounts: ' + discounts.size() + ', assets backfilled: ' + assetsToBackfill.size());

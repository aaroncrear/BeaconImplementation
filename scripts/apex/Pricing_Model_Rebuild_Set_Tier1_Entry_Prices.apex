// Pricing Model Rebuild: sets each module's price book entry (Annual Subscription) to its Tier 1 price
// from Beacon Tier Price. Run after the tier prices are loaded. The former bundle price books had
// module entries at 0, because the price used to sit on the bundle. Safe to run more than once.
Map<String, Decimal> tier1 = new Map<String, Decimal>();
for (Beacon_Tier_Price__c t : [SELECT Price_Book__c, Product__c, List_Price__c FROM Beacon_Tier_Price__c WHERE Tier__c = 1]) {
    tier1.put(String.valueOf(t.Price_Book__c) + String.valueOf(t.Product__c), t.List_Price__c);
}
List<PricebookEntry> toUpdate = new List<PricebookEntry>();
for (PricebookEntry e : [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry
                         WHERE IsActive = true AND ProductSellingModelId != null AND Pricebook2.IsStandard = false]) {
    Decimal p = tier1.get(String.valueOf(e.Pricebook2Id) + String.valueOf(e.Product2Id));
    if (p != null && e.UnitPrice != p) {
        e.UnitPrice = p;
        toUpdate.add(e);
    }
}
update toUpdate;
System.debug('Price book entries set to Tier 1 price: ' + toUpdate.size());

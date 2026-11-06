// Pricing Model Rebuild: prepares the Module Count and Multi-Module Discount tables for the pricing procedure's
// Price Adjustment Matrix steps. Safe to run more than once.
// 1. Module Count Price: one row per exact module count (1-17) instead of ranges (3-4, 6+), with the user band as a
//    tier range and Adjustment Value = Quote Total / module count (the price on each line).
// 2. Multi-Module Discount: Adjustment Type = Percentage, Adjustment Value = Discount Percent.
Integer maxModules = 17;
List<Beacon_Module_Count_Price__c> rows = [SELECT Price_Book__c, Price_Book__r.Name, Module_Level__c, User_Band__c, Min_Users__c, Max_Users__c,
    Min_Modules__c, Max_Modules__c, Quote_Total__c, Price_Key__c FROM Beacon_Module_Count_Price__c];
Map<String, Beacon_Module_Count_Price__c> out = new Map<String, Beacon_Module_Count_Price__c>();
for (Beacon_Module_Count_Price__c r : rows) {
    Integer lo = r.Min_Modules__c.intValue();
    Integer hi = r.Max_Modules__c == null ? maxModules : r.Max_Modules__c.intValue();
    Decimal minU = r.Min_Users__c;
    Integer minT = minU <= 3 ? 1 : minU <= 5 ? 2 : minU <= 10 ? 3 : minU <= 20 ? 4 : minU <= 50 ? 5 : 6;
    Decimal maxU = r.Max_Users__c;
    Integer maxT = maxU == null ? 6 : maxU <= 3 ? 1 : maxU <= 5 ? 2 : maxU <= 10 ? 3 : maxU <= 20 ? 4 : maxU <= 50 ? 5 : 6;
    for (Integer n = lo; n <= hi; n++) {
        String key = r.Price_Book__r.Name + '|' + r.Module_Level__c + '|' + r.User_Band__c + '|' + n;
        out.put(key, new Beacon_Module_Count_Price__c(Price_Key__c = key, Price_Book__c = r.Price_Book__c,
            Module_Level__c = r.Module_Level__c, User_Band__c = r.User_Band__c, Min_Users__c = r.Min_Users__c,
            Max_Users__c = r.Max_Users__c, Min_Modules__c = n, Max_Modules__c = n, Min_Tier__c = minT, Max_Tier__c = maxT,
            Quote_Total__c = r.Quote_Total__c, Adjustment_Type__c = 'Override',
            Adjustment_Value__c = (r.Quote_Total__c / n).setScale(2)));
    }
}
upsert out.values() Price_Key__c;
List<Beacon_Module_Count_Price__c> old = [SELECT Id FROM Beacon_Module_Count_Price__c WHERE Price_Key__c NOT IN :out.keySet()];
delete old;
List<Beacon_Multi_Module_Discount__c> disc = [SELECT Id, Discount_Percent__c FROM Beacon_Multi_Module_Discount__c];
for (Beacon_Multi_Module_Discount__c d : disc) {
    d.Adjustment_Type__c = 'Percentage';
    d.Adjustment_Value__c = d.Discount_Percent__c;
}
update disc;
System.debug('Module count rows: ' + out.size() + ', old range rows removed: ' + old.size() + ', discount rows: ' + disc.size());

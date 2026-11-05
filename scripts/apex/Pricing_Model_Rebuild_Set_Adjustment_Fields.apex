// Pricing Model Rebuild: fills Adjustment Type (Override) and Adjustment Value (= List Price) on every
// Beacon Tier Price row, for the pricing procedure's Price Adjustment Matrix step. Safe to run more than once.
List<Beacon_Tier_Price__c> rows = [SELECT Id, List_Price__c FROM Beacon_Tier_Price__c];
for (Beacon_Tier_Price__c r : rows) {
    r.Adjustment_Type__c = 'Override';
    r.Adjustment_Value__c = r.List_Price__c;
}
update rows;
System.debug('Rows updated: ' + rows.size());

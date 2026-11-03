// Pricing Model Rebuild: removes the old bundle-based pricing records.
// Run in Developer Console > Debug > Open Execute Anonymous Window, after the Pricing-Model-Rebuild
// metadata is deployed. Safe to run more than once.
//
// What it does:
//   1. Deletes bundle components and component groups for every Bundle product.
//   2. Deletes every seat band (Volume) and multi-year (Term) price adjustment schedule, with their tiers.
//   3. Deletes Bundle products. A bundle still used on an order, asset, opportunity or quote can't be
//      deleted, so it's deactivated instead (IsActive = false) and listed in the debug log.
//   4. Deletes price book entries that have no selling model. An entry still used on a quote,
//      opportunity or order can't be deleted, so it's deactivated instead.
// Set PREVIEW to true to only log what would change.

Boolean PREVIEW = false;

List<Product2> bundles = [SELECT Id, Name FROM Product2 WHERE Type = 'Bundle'];
Set<Id> bundleIds = new Map<Id, Product2>(bundles).keySet();

List<ProductRelatedComponent> components = [SELECT Id FROM ProductRelatedComponent WHERE ParentProductId IN :bundleIds];
List<ProductComponentGroup> groups = [SELECT Id FROM ProductComponentGroup WHERE ParentProductId IN :bundleIds];
List<PriceAdjustmentSchedule> schedules = [
    SELECT Id, Name FROM PriceAdjustmentSchedule
    WHERE (ScheduleType = 'Volume' AND AdjustmentMethod = 'Slab' AND Name LIKE '%Seat Band%')
       OR ScheduleType = 'Term'
];
List<PriceAdjustmentTier> tiers = [SELECT Id FROM PriceAdjustmentTier WHERE PriceAdjustmentScheduleId IN :schedules];
List<PricebookEntry> noModelEntries = [SELECT Id, Product2Id FROM PricebookEntry WHERE ProductSellingModelId = null AND Product2Id NOT IN :bundleIds];

System.debug('Bundles: ' + bundles.size() + ', components: ' + components.size() + ', groups: ' + groups.size()
    + ', schedules: ' + schedules.size() + ', schedule tiers: ' + tiers.size()
    + ', module price book entries with no selling model: ' + noModelEntries.size());
for (PriceAdjustmentSchedule s : schedules) { System.debug('Schedule: ' + s.Name); }
if (PREVIEW) { return; }

delete components;
delete groups;
delete tiers;
delete schedules;

// Bundle products: delete, or deactivate if something still references them.
List<Product2> toDeactivate = new List<Product2>();
Database.DeleteResult[] productResults = Database.delete(bundles, false);
for (Integer i = 0; i < productResults.size(); i++) {
    if (!productResults[i].isSuccess()) {
        System.debug('Kept and deactivated bundle ' + bundles[i].Name + ': ' + productResults[i].getErrors()[0].getMessage());
        toDeactivate.add(new Product2(Id = bundles[i].Id, IsActive = false));
    }
}
update toDeactivate;
// Entries of deactivated bundles are deactivated too, so they can't be added to new quotes.
List<PricebookEntry> bundleEntries = [SELECT Id FROM PricebookEntry WHERE Product2Id IN :bundleIds AND IsActive = true];
for (PricebookEntry e : bundleEntries) { e.IsActive = false; }
update bundleEntries;

// Module price book entries with no selling model: custom price books first, then Standard,
// because a Standard entry can't be deleted while a custom price book still has an entry for it.
List<PricebookEntry> custom = new List<PricebookEntry>();
List<PricebookEntry> standard = new List<PricebookEntry>();
for (PricebookEntry e : [SELECT Id, Pricebook2.IsStandard FROM PricebookEntry WHERE Id IN :noModelEntries]) {
    if (e.Pricebook2.IsStandard) { standard.add(e); } else { custom.add(e); }
}
List<PricebookEntry> entriesToDeactivate = new List<PricebookEntry>();
Integer deletedEntries = 0;
for (List<PricebookEntry> batch : new List<List<PricebookEntry>>{ custom, standard }) {
    Database.DeleteResult[] entryResults = Database.delete(batch, false);
    for (Integer i = 0; i < entryResults.size(); i++) {
        if (entryResults[i].isSuccess()) { deletedEntries++; }
        else { entriesToDeactivate.add(new PricebookEntry(Id = batch[i].Id, IsActive = false)); }
    }
}
update entriesToDeactivate;

System.debug('Done. Bundles deleted: ' + (bundles.size() - toDeactivate.size()) + ', bundles deactivated: ' + toDeactivate.size()
    + ', entries with no selling model deleted: ' + deletedEntries + ', deactivated: ' + entriesToDeactivate.size());

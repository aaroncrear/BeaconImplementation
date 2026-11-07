// Asset Users History – one-time backfill.
// Sets Number of Users and Change in Users on existing Asset Actions, and Number of Users on
// existing Asset State Periods, from the Order Products the actions were created from.
// Same rules as the flow Create Asset Order Event - Mark Order Assets Created:
//   - an action's Number of Users = its Order Product's Number of Users (0 for a cancellation);
//   - Change in Users = that minus the previous action's Number of Users on the same Asset;
//   - a State Period gets the Number of Users of the latest action starting on or before it.
// Set PREVIEW = true to see the changes in the debug log without saving them.
Boolean PREVIEW = false;

List<AssetActionSource> sources = [
    SELECT AssetActionId, AssetAction.AssetId, AssetAction.Type, AssetAction.ActionDate,
           StartDate, ReferenceEntityItemId
    FROM AssetActionSource
    WHERE AssetAction.AssetId != null
    ORDER BY AssetAction.AssetId, AssetAction.ActionDate, StartDate
];

Set<Id> orderItemIds = new Set<Id>();
Set<Id> assetIds = new Set<Id>();
for (AssetActionSource s : sources) {
    if (s.ReferenceEntityItemId != null && s.ReferenceEntityItemId.getSObjectType() == OrderItem.SObjectType) {
        orderItemIds.add(s.ReferenceEntityItemId);
    }
    assetIds.add(s.AssetAction.AssetId);
}
Map<Id, OrderItem> orderItems = new Map<Id, OrderItem>(
    [SELECT Id, Number_of_Users__c FROM OrderItem WHERE Id IN :orderItemIds AND Number_of_Users__c != null]
);

Map<Id, List<AssetStatePeriod>> periodsByAsset = new Map<Id, List<AssetStatePeriod>>();
for (AssetStatePeriod p : [SELECT Id, AssetId, StartDate FROM AssetStatePeriod WHERE AssetId IN :assetIds ORDER BY StartDate]) {
    if (!periodsByAsset.containsKey(p.AssetId)) periodsByAsset.put(p.AssetId, new List<AssetStatePeriod>());
    periodsByAsset.get(p.AssetId).add(p);
}

Map<Id, AssetAction> actionUpdates = new Map<Id, AssetAction>();
Map<Id, AssetStatePeriod> periodUpdates = new Map<Id, AssetStatePeriod>();
Map<Id, Decimal> previousUsers = new Map<Id, Decimal>();

for (AssetActionSource s : sources) {
    OrderItem oi = orderItems.get(s.ReferenceEntityItemId);
    if (oi == null || actionUpdates.containsKey(s.AssetActionId)) continue;
    Id assetId = s.AssetAction.AssetId;
    Decimal users = s.AssetAction.Type == 'Cancel' ? 0 : oi.Number_of_Users__c;
    Decimal prior = previousUsers.containsKey(assetId) ? previousUsers.get(assetId) : 0;
    actionUpdates.put(s.AssetActionId, new AssetAction(
        Id = s.AssetActionId, Number_of_Users__c = users, Change_in_Users__c = users - prior));
    previousUsers.put(assetId, users);
    if (periodsByAsset.containsKey(assetId)) {
        for (AssetStatePeriod p : periodsByAsset.get(assetId)) {
            if (s.StartDate != null && p.StartDate >= s.StartDate) {
                periodUpdates.put(p.Id, new AssetStatePeriod(Id = p.Id, Number_of_Users__c = users));
            }
        }
    }
}

System.debug('Asset Actions to update: ' + actionUpdates.size());
System.debug('Asset State Periods to update: ' + periodUpdates.size());
for (AssetAction a : actionUpdates.values()) System.debug(a);
if (!PREVIEW) {
    update actionUpdates.values();
    update periodUpdates.values();
    System.debug('Saved.');
}

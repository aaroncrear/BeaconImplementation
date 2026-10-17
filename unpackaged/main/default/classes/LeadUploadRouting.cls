/**
 * Decides who owns the Leads created by the Lead Uploader, so partners can be onboarded with
 * configuration only:
 *
 *   1. The uploading user's partner Account names a queue in Lead_Upload_Queue__c, or
 *   2. the Default Queue on the Lead_Upload_Setting__mdt record named Default is used, or
 *   3. if neither is set, the uploading user keeps the Leads.
 *
 * Routing is worked out on the server from the running user, never taken from the browser, so a
 * partner can't send their Leads to someone else's queue.
 *
 * Runs without sharing: partner users can't (and shouldn't need to) read their Account's routing
 * field, the queue list or the custom metadata, and they can't share Leads they no longer own.
 */
public without sharing class LeadUploadRouting {
    public static final String SETTING_NAME = 'Default';

    // Test hooks. HTCDEV has no partner licences, so tests can't create a real partner user.
    @TestVisible private static Lead_Upload_Setting__mdt settingOverride;
    @TestVisible private static Id partnerAccountIdOverride;
    @TestVisible private static Boolean externalUserOverride;

    public class Route {
        public Id partnerAccountId;
        public String queueName; // null means the uploading user keeps the Leads
        public Id queueId;
        public Boolean shareWithUploader = false;
    }

    public class RoutingException extends Exception {}

    /**
     * Works out the route for a new upload by the given user. Throws RoutingException if a
     * queue is configured but doesn't exist or doesn't support Leads.
     */
    public static Route resolve(Id userId) {
        User uploader = getUser(userId);
        Route route = new Route();
        route.partnerAccountId = partnerAccountIdOverride != null ? partnerAccountIdOverride : uploader.AccountId;

        String queueName;
        if (route.partnerAccountId != null) {
            List<Account> partners = [SELECT Lead_Upload_Queue__c FROM Account WHERE Id = :route.partnerAccountId LIMIT 1];
            if (!partners.isEmpty()) {
                queueName = partners[0].Lead_Upload_Queue__c;
            }
        }
        if (String.isBlank(queueName)) {
            Lead_Upload_Setting__mdt setting = getSetting();
            queueName = setting == null ? null : setting.Default_Queue__c;
        }
        applyQueue(route, queueName, uploader);
        return route;
    }

    /**
     * Rebuilds the route stored on an upload when it started, so every batch of the upload goes
     * to the same place even if the configuration changes mid-upload.
     */
    public static Route forUpload(Lead_Upload__c upload, Id userId) {
        Route route = new Route();
        route.partnerAccountId = upload.Partner_Account__c;
        applyQueue(route, upload.Assigned_Queue__c, getUser(userId));
        return route;
    }

    /**
     * Gives the uploading user Read access to Leads that went to a queue. Failures are skipped
     * rather than failing the upload: the Leads exist and are with the right queue either way.
     */
    public static void shareWithUploader(List<Id> leadIds, Id userId) {
        List<LeadShare> shares = new List<LeadShare>();
        for (Id leadId : leadIds) {
            shares.add(new LeadShare(LeadId = leadId, UserOrGroupId = userId, LeadAccessLevel = 'Read'));
        }
        for (Database.SaveResult result : Database.insert(shares, false)) {
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.WARN, 'Lead Uploader share not created: ' + result.getErrors());
            }
        }
    }

    private static void applyQueue(Route route, String queueName, User uploader) {
        if (String.isBlank(queueName)) {
            return;
        }
        route.queueName = queueName.trim();
        List<QueueSobject> queues = [
            SELECT QueueId
            FROM QueueSobject
            WHERE SobjectType = 'Lead' AND Queue.DeveloperName = :route.queueName
            LIMIT 1
        ];
        if (queues.isEmpty()) {
            throw new RoutingException(
                'Lead routing isn\'t set up correctly: there is no Lead queue with the API name "' + route.queueName +
                '". Please contact your Beacon administrator.'
            );
        }
        route.queueId = queues[0].QueueId;

        Lead_Upload_Setting__mdt setting = getSetting();
        Boolean isExternal = externalUserOverride != null ? externalUserOverride : uploader.UserType != 'Standard';
        // Internal users already see every Lead (Public Read/Write/Transfer), so only external users need a share.
        route.shareWithUploader = isExternal && setting != null && setting.Share_With_Uploader__c;
    }

    private static User getUser(Id userId) {
        return [SELECT Id, AccountId, UserType FROM User WHERE Id = :userId LIMIT 1];
    }

    private static Lead_Upload_Setting__mdt getSetting() {
        return settingOverride != null ? settingOverride : Lead_Upload_Setting__mdt.getInstance(SETTING_NAME);
    }
}

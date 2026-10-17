@IsTest
private class LeadUploadControllerTest {
    private static final String PARTNER_QUEUE = 'Test_Lead_Upload_Partner_Queue';
    private static final String DEFAULT_QUEUE = 'Test_Lead_Upload_Default_Queue';

    // Runs each test as the current user with the Beacon - Lead Upload permission set, which
    // grants the Lead Upload FLS that user-mode queries need. Routing starts switched off so
    // tests don't depend on the org's Lead Upload Setting record; routing tests override it.
    private static User uploader() {
        LeadUploadRouting.settingOverride = new Lead_Upload_Setting__mdt(Default_Queue__c = null, Share_With_Uploader__c = false);
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Beacon_Lead_Upload' LIMIT 1];
        List<PermissionSetAssignment> existing = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSet.Id
        ];
        if (existing.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSet.Id);
        }
        return new User(Id = UserInfo.getUserId());
    }

    // Setup objects: call before System.runAs to avoid mixed DML.
    private static Id createLeadQueue(String developerName) {
        Group queue = new Group(Name = developerName, DeveloperName = developerName, Type = 'Queue');
        insert queue;
        insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Lead');
        return queue.Id;
    }

    private static List<Map<String, String>> validRows(Integer count) {
        List<Map<String, String>> rows = new List<Map<String, String>>();
        for (Integer i = 0; i < count; i++) {
            rows.add(validRow(i));
        }
        return rows;
    }

    private static Map<String, String> validRow(Integer i) {
        return new Map<String, String>{
            'FirstName' => 'Test',
            'LastName' => 'Upload ' + i,
            'Company' => 'Upload Co ' + i,
            'Title' => 'Director',
            'Email' => 'lead.upload.' + i + '@uploadtest' + i + '.example.com',
            'Website' => 'https://uploadtest' + i + '.example.com',
            'LeadSource' => 'Own Research',
            'NumberOfEmployees' => '1,250',
            'AnnualRevenue' => '$2,500,000'
        };
    }

    @IsTest
    static void getUploadFieldsReturnsRequiredFields() {
        System.runAs(uploader()) {
            List<LeadUploadController.UploadField> fields = LeadUploadController.getUploadFields();
            Map<String, LeadUploadController.UploadField> byName = new Map<String, LeadUploadController.UploadField>();
            for (LeadUploadController.UploadField field : fields) {
                byName.put(field.apiName, field);
            }
            Assert.isTrue(byName.get('LastName').required, 'Last Name should be required');
            Assert.isTrue(byName.get('Email').required, 'Email should be required');
            Assert.isFalse(byName.get('Phone').required, 'Phone should be optional');
        }
    }

    @IsTest
    static void uploadCreatesLeadsAndCompletes() {
        System.runAs(uploader()) {
            List<Map<String, String>> rows = new List<Map<String, String>>();
            for (Integer i = 0; i < LeadUploadController.MAX_BATCH_SIZE; i++) {
                rows.add(validRow(i));
            }

            Test.startTest();
            Id uploadId = LeadUploadController.startUpload('leads.csv', rows.size());
            List<LeadUploadController.RowResult> results =
                LeadUploadController.uploadLeads(uploadId, JSON.serialize(rows), 2, null);
            String status = LeadUploadController.completeUpload(uploadId, null);
            Test.stopTest();

            Assert.areEqual(rows.size(), results.size(), 'One result per row');
            for (LeadUploadController.RowResult result : results) {
                Assert.isTrue(result.success, 'Row ' + result.rowNumber + ' failed: ' + result.message);
            }
            Assert.areEqual(LeadUploadController.STATUS_COMPLETED, status);

            Lead_Upload__c upload = [
                SELECT Status__c, Total_Rows__c, Success_Count__c, Error_Count__c, Completed_Date__c,
                    Assigned_Queue__c, Partner_Account__c,
                    (SELECT NumberOfEmployees, AnnualRevenue, OwnerId, Partner_Account__c FROM Leads)
                FROM Lead_Upload__c WHERE Id = :uploadId
            ];
            Assert.areEqual(rows.size(), upload.Success_Count__c);
            Assert.areEqual(0, upload.Error_Count__c);
            Assert.isNotNull(upload.Completed_Date__c);
            Assert.areEqual(rows.size(), upload.Leads.size());
            Assert.areEqual(1250, upload.Leads[0].NumberOfEmployees);
            Assert.areEqual(2500000, upload.Leads[0].AnnualRevenue);
            Assert.isNull(upload.Assigned_Queue__c, 'No queue configured');
            Assert.areEqual(UserInfo.getUserId(), upload.Leads[0].OwnerId, 'Uploader keeps Leads when no queue is configured');
            Assert.isNull(upload.Leads[0].Partner_Account__c, 'Internal uploader has no partner account');
        }
    }

    @IsTest
    static void failedRowsAreReportedAndDoNotBlockOthers() {
        System.runAs(uploader()) {
            Map<String, String> missingRequired = validRow(1);
            missingRequired.remove('Company');
            Map<String, String> badNumber = validRow(2);
            badNumber.put('NumberOfEmployees', 'lots');
            Map<String, String> defaultSource = validRow(3);
            defaultSource.remove('LeadSource');
            List<Map<String, String>> rows = new List<Map<String, String>>{ validRow(0), missingRequired, badNumber, defaultSource };

            Test.startTest();
            Id uploadId = LeadUploadController.startUpload('leads.csv', rows.size());
            List<LeadUploadController.RowResult> results =
                LeadUploadController.uploadLeads(uploadId, JSON.serialize(rows), 2, 'Own Research');
            String status = LeadUploadController.completeUpload(uploadId, 'Row,Error\r\n3,Missing');
            Test.stopTest();

            Map<Integer, LeadUploadController.RowResult> byRow = new Map<Integer, LeadUploadController.RowResult>();
            for (LeadUploadController.RowResult result : results) {
                byRow.put(result.rowNumber, result);
            }
            Assert.isTrue(byRow.get(2).success, 'Valid row should succeed');
            Assert.isFalse(byRow.get(3).success, 'Row missing Company should fail');
            Assert.isTrue(byRow.get(3).message.contains('Missing required value'), byRow.get(3).message);
            Assert.isFalse(byRow.get(4).success, 'Row with a bad number should fail');
            Assert.isTrue(byRow.get(5).success, 'Default Lead Source should fill a blank Lead Source: ' + byRow.get(5).message);
            Assert.areEqual(LeadUploadController.STATUS_COMPLETED_WITH_ERRORS, status);

            Lead_Upload__c upload = [SELECT Success_Count__c, Error_Count__c FROM Lead_Upload__c WHERE Id = :uploadId];
            Assert.areEqual(2, upload.Success_Count__c);
            Assert.areEqual(2, upload.Error_Count__c);
            Assert.areEqual(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :uploadId], 'Error file attached');
        }
    }

    @IsTest
    static void allRowsFailingMarksUploadFailed() {
        System.runAs(uploader()) {
            Map<String, String> row = validRow(0);
            row.remove('LastName');
            Id uploadId = LeadUploadController.startUpload('leads.csv', 1);
            LeadUploadController.uploadLeads(uploadId, JSON.serialize(new List<Map<String, String>>{ row }), 2, null);
            Assert.areEqual(LeadUploadController.STATUS_FAILED, LeadUploadController.completeUpload(uploadId, null));
        }
    }

    @IsTest
    static void limitsAreEnforced() {
        System.runAs(uploader()) {
            try {
                LeadUploadController.startUpload('leads.csv', LeadUploadController.MAX_ROWS + 1);
                Assert.fail('More than the maximum rows should be rejected');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('The limit is'), e.getMessage());
            }

            Id uploadId = LeadUploadController.startUpload('leads.csv', LeadUploadController.MAX_ROWS);
            List<Map<String, String>> rows = new List<Map<String, String>>();
            for (Integer i = 0; i <= LeadUploadController.MAX_BATCH_SIZE; i++) {
                rows.add(validRow(i));
            }
            try {
                LeadUploadController.uploadLeads(uploadId, JSON.serialize(rows), 2, null);
                Assert.fail('An oversized batch should be rejected');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('at most'), e.getMessage());
            }

            LeadUploadController.completeUpload(uploadId, null);
            try {
                LeadUploadController.uploadLeads(uploadId, JSON.serialize(new List<Map<String, String>>{ validRow(0) }), 2, null);
                Assert.fail('A finished upload should not accept more rows');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('already finished'), e.getMessage());
            }
        }
    }

    @IsTest
    static void partnerQueueOnAccountRoutesLeads() {
        User runAs = uploader();
        Id partnerQueueId = createLeadQueue(PARTNER_QUEUE);
        createLeadQueue(DEFAULT_QUEUE);
        System.runAs(runAs) {
            Account partner = new Account(Name = 'Lead Upload Partner', Lead_Upload_Queue__c = PARTNER_QUEUE);
            insert partner;
            LeadUploadRouting.partnerAccountIdOverride = partner.Id;
            LeadUploadRouting.externalUserOverride = true;
            LeadUploadRouting.settingOverride = new Lead_Upload_Setting__mdt(Default_Queue__c = DEFAULT_QUEUE, Share_With_Uploader__c = true);

            Test.startTest();
            Id uploadId = LeadUploadController.startUpload('partner.csv', 2);
            List<LeadUploadController.RowResult> results =
                LeadUploadController.uploadLeads(uploadId, JSON.serialize(validRows(2)), 2, null);
            LeadUploadController.completeUpload(uploadId, null);
            Test.stopTest();

            for (LeadUploadController.RowResult result : results) {
                Assert.isTrue(result.success, 'Row ' + result.rowNumber + ' failed: ' + result.message);
            }
            Lead_Upload__c upload = [
                SELECT Assigned_Queue__c, Partner_Account__c, (SELECT OwnerId, Partner_Account__c FROM Leads)
                FROM Lead_Upload__c WHERE Id = :uploadId
            ];
            Assert.areEqual(PARTNER_QUEUE, upload.Assigned_Queue__c, 'Partner queue wins over the default');
            Assert.areEqual(partner.Id, upload.Partner_Account__c);
            Assert.areEqual(2, upload.Leads.size());
            for (Lead lead : upload.Leads) {
                Assert.areEqual(partnerQueueId, lead.OwnerId, 'Lead should be owned by the partner queue');
                Assert.areEqual(partner.Id, lead.Partner_Account__c);
            }
        }
    }

    @IsTest
    static void defaultQueueUsedWhenPartnerHasNone() {
        User runAs = uploader();
        Id defaultQueueId = createLeadQueue(DEFAULT_QUEUE);
        System.runAs(runAs) {
            Account partner = new Account(Name = 'Lead Upload Partner Without Queue');
            insert partner;
            LeadUploadRouting.partnerAccountIdOverride = partner.Id;
            LeadUploadRouting.settingOverride = new Lead_Upload_Setting__mdt(Default_Queue__c = DEFAULT_QUEUE, Share_With_Uploader__c = false);

            Id uploadId = LeadUploadController.startUpload('partner.csv', 1);
            LeadUploadController.uploadLeads(uploadId, JSON.serialize(validRows(1)), 2, null);

            Lead lead = [SELECT OwnerId, Partner_Account__c FROM Lead WHERE Lead_Upload__c = :uploadId];
            Assert.areEqual(defaultQueueId, lead.OwnerId, 'Lead should go to the default queue');
            Assert.areEqual(partner.Id, lead.Partner_Account__c);
        }
    }

    @IsTest
    static void missingQueueBlocksUpload() {
        System.runAs(uploader()) {
            Account partner = new Account(Name = 'Misconfigured Partner', Lead_Upload_Queue__c = 'No_Such_Queue');
            insert partner;
            LeadUploadRouting.partnerAccountIdOverride = partner.Id;
            try {
                LeadUploadController.startUpload('partner.csv', 1);
                Assert.fail('An upload routed to a missing queue should be blocked');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('No_Such_Queue'), e.getMessage());
            }
            Assert.areEqual(0, [SELECT COUNT() FROM Lead_Upload__c], 'No upload record when routing fails');
        }
    }
}

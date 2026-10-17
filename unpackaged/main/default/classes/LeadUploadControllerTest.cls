@IsTest
private class LeadUploadControllerTest {
    // Runs each test as the current user with the Beacon - Lead Upload permission set, which
    // grants FLS on the Lead Upload fields that user-mode DML needs.
    private static User uploader() {
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
                    (SELECT NumberOfEmployees, AnnualRevenue FROM Leads)
                FROM Lead_Upload__c WHERE Id = :uploadId
            ];
            Assert.areEqual(rows.size(), upload.Success_Count__c);
            Assert.areEqual(0, upload.Error_Count__c);
            Assert.isNotNull(upload.Completed_Date__c);
            Assert.areEqual(rows.size(), upload.Leads.size());
            Assert.areEqual(1250, upload.Leads[0].NumberOfEmployees);
            Assert.areEqual(2500000, upload.Leads[0].AnnualRevenue);
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
}

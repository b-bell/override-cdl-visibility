@IsTest
public with sharing class OverrideCdlVisibilityAsyncTest {
    @TestSetup
    static void makeData() {
        Case newCase = new Case(
            Subject = 'New Case Subject',
            Description = 'New Case Description',
            Status = 'New',
            Priority = 'High'
        );

        insert newCase;

        ContentVersion newFile = new ContentVersion(
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );

        insert newFile;

        FeedItem newFeedItem = new FeedItem(
            Body = 'Test FeedItem Body',
            ParentId = newCase.Id
        );

        insert newFeedItem;
    }

    @IsTest
    static void addFileToCase() {
        // Add a file to a case
        ContentVersion testFile = [
            SELECT ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Case testCase = [SELECT Id FROM CAse LIMIT 1];

        ContentDocumentLink linkedFile = new ContentDocumentLink(
            ContentDocumentId = testFile.ContentDocumentId,
            LinkedEntityId = testCase.Id
        );

        Test.startTest();
        insert linkedFile;
        Test.stopTest();

        ContentDocumentLink updatedLinkedFile = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE Id = :linkedFile.Id
        ];

        System.assertEquals(
            'AllUsers',
            updatedLinkedFile.Visibility,
            'File should be visible to all users'
        );
    }

    @IsTest
    static void addFileToAccount() {
        // Add a file to an account
        ContentVersion testFile = [
            SELECT ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingCountry = 'Test Country'
        );

        insert testAccount;

        ContentDocumentLink linkedFile = new ContentDocumentLink(
            ContentDocumentId = testFile.ContentDocumentId,
            LinkedEntityId = testAccount.Id
        );

        Test.startTest();
        insert linkedFile;
        Test.stopTest();

        ContentDocumentLink updatedLinkedFile = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE Id = :linkedFile.Id
        ];
        List<Site> sites = [SELECT Id FROM Site];
        if (sites.size() > 0) {
            System.assertEquals(
                'InternalUsers',
                updatedLinkedFile.Visibility,
                'File should be visible to internal users'
            );
        } else {
            System.assertEquals(
                'AllUsers',
                updatedLinkedFile.Visibility,
                'File should be visible to all users'
            );
        }
    }

    @IsTest
    static void addFileToCaseFeed() {
        // Add a file to a case chatter post
        ContentVersion testFile = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        FeedItem testFeedItem = [SELECT Id FROM FeedItem LIMIT 1];

        FeedAttachment testFeedAttachment = new FeedAttachment(
            FeedEntityId = testFeedItem.Id,
            RecordId = testFile.Id,
            Type = 'CONTENT'
        );

        Test.startTest();
        insert testFeedAttachment;
        Test.stopTest();

        ContentDocumentLink updatedLinkedFile = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testCase.Id
        ];

        List<Site> sites = [SELECT Id FROM Site];
        if (sites.size() > 0) {
            System.assertEquals(
                'InternalUsers',
                updatedLinkedFile.Visibility,
                'File should be visible to internal users'
            );
        } else {
            System.assertEquals(
                'AllUsers',
                updatedLinkedFile.Visibility,
                'File should be visible to all users'
            );
        }
    }

    @IsTest
    static void addFileAndLinkToCaseFeed() {
        // Add a file to a case chatter post
        ContentVersion testFile = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Case testCase = [SELECT Id FROM CAse LIMIT 1];
        FeedItem testFeedItem = [SELECT Id FROM FeedItem LIMIT 1];

        FeedAttachment testFileFeedAttachment = new FeedAttachment(
            FeedEntityId = testFeedItem.Id,
            RecordId = testFile.Id,
            Type = 'CONTENT'
        );

        FeedAttachment testLinkFeedAttachment = new FeedAttachment(
            FeedEntityId = testFeedItem.Id,
            Value = 'https://www.google.com',
            Type = 'LINK'
        );

        Test.startTest();
        insert testFileFeedAttachment;
        insert testLinkFeedAttachment;
        Test.stopTest();
    }
}

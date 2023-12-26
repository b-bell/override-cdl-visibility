@IsTest
public with sharing class OverrideCdlVisibilityAsyncTest {
    @TestSetup
    static void makeData() {
        ContentVersion newFile = new ContentVersion(
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert newFile;

        Account newAccount = new Account(
            Name = 'Test Account',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingCountry = 'Test Country'
        );
        insert newAccount;

        FeedItem newFeedItem = new FeedItem(
            Body = 'Test FeedItem Body',
            ParentId = newAccount.Id
        );
        insert newFeedItem;
    }

    @IsTest
    static void addFileToAccount() {
        // Add a file to an account
        // to ensure visibility is set to All Users
        ContentVersion testFile = [
            SELECT ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

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

        System.assertEquals(
            'AllUsers',
            updatedLinkedFile.Visibility,
            'File should be visible to all users'
        );
    }

    @IsTest
    static void addFileToAccountFeed() {
        // Add a file to an internal account chatter post
        // to ensure visibility is set to Internal Users
        ContentVersion testFile = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
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
            WHERE LinkedEntityId = :testAccount.Id
        ];

        System.assertEquals(
            'InternalUsers',
            updatedLinkedFile.Visibility,
            'File should be visible to internal users'
        );
    }

    @IsTest
    static void addFileAndLinkToAccountFeed() {
        // Add a file and link to an internal account chatter post
        // to ensure visibility is set to Internal Users
        ContentVersion testFile = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
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

        ContentDocumentLink updatedLinkedFile = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testAccount.Id
        ];

        System.assertEquals(
            'InternalUsers',
            updatedLinkedFile.Visibility,
            'File should be visible to internal users'
        );
    }
}

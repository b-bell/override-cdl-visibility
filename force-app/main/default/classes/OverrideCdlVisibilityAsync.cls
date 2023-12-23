public with sharing class OverrideCdlVisibilityAsync implements Queueable {
    // Async class that overrides the default visibility setting
    // for files added directly to a case to All Users.
    // Async is required to check if the file is related to a feed item after
    // the transaction is complete.

    private Map<Id, ContentDocumentLink> contentDocumentLinksMap;

    public OverrideCdlVisibilityAsync(
        Map<Id, ContentDocumentLink> contentDocumentLinksMap
    ) {
        this.contentDocumentLinksMap = contentDocumentLinksMap;
    }

    public void execute(QueueableContext context) {
        if ([SELECT Id FROM Site].size() == 0) {
            // Do not run if org does not have digital experiences enabled
            return;
        }

        List<Override_CDL_SObject__mdt> overrideCdlSObjects = [
            SELECT Id, DeveloperName
            FROM Override_CDL_SObject__mdt
        ];

        if (overrideCdlSObjects.size() == 0) {
            // Do not run if no Override_CDL_SObject__c records exist
            return;
        }

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocumentId, Visibility, LinkedEntityId
            FROM ContentDocumentLink
            WHERE Id IN :contentDocumentLinksMap.keySet()
        ];

        List<ContentDocumentLink> caseContentDocumentLinks = findCaseContentDocumentLinks(
            contentDocumentLinks
        );
        List<Id> linkedEntityIds = getLinkedEntityIds(caseContentDocumentLinks);
        List<FeedAttachment> feedAttachments = getContentFeedAttachments(
            linkedEntityIds
        );
        Map<Id, List<Id>> feedContentDocumentIdsMap = mapFeedContentDocumentIds(
            linkedEntityIds,
            feedAttachments
        );

        for (ContentDocumentLink cdl : caseContentDocumentLinks) {
            if (
                feedContentDocumentIdsMap.isEmpty() ||
                !feedContentDocumentIdsMap.get(cdl.LinkedEntityId)
                    .contains(cdl.ContentDocumentId)
            ) {
                cdl.visibility = 'AllUsers';
            }
        }

        update contentDocumentLinks;
    }

    private List<ContentDocumentLink> findCaseContentDocumentLinks(
        List<ContentDocumentLink> cdls
    ) {
        // Receives a list of CDLs and returns only CDLs that belong to a case
        List<ContentDocumentLink> caseCDLs = new List<ContentDocumentLink>();
        for (ContentDocumentLink cdl : cdls) {
            if (
                cdl.LinkedEntityId.getSObjectType().getDescribe().getName() ==
                'Case'
            ) {
                caseCDLs.add(cdl);
            }
        }
        return caseCDLs;
    }

    private List<Id> getLinkedEntityIds(List<ContentDocumentLink> cdls) {
        // Get linked entity Ids for a list of content document links
        List<Id> linkedEntityIds = new List<Id>();
        for (ContentDocumentLink cdl : cdls) {
            linkedEntityIds.add(cdl.LinkedEntityId);
        }
        return linkedEntityIds;
    }

    private List<FeedAttachment> getContentFeedAttachments(
        List<Id> parentObjectIds
    ) {
        // Get all content attachments for a provided parent objects
        List<FeedAttachment> feedAttachments = [
            SELECT Id, RecordId, FeedEntityId
            FROM FeedAttachment
            WHERE
                FeedEntityId IN (
                    SELECT Id
                    FROM FeedItem
                    WHERE ParentId IN :parentObjectIds
                )
                AND Type = 'Content'
        ];
        return feedAttachments;
    }

    private Map<Id, List<Id>> mapFeedContentDocumentIds(
        List<Id> parentIds,
        List<FeedAttachment> feedAttachments
    ) {
        Map<Id, List<Id>> feedContentDocumentsMap = new Map<Id, List<Id>>();

        Map<Id, FeedItem> feedItemsMap = new Map<Id, FeedItem>(
            [
                SELECT Id, ParentId
                FROM FeedItem
                WHERE ParentId IN :parentIds
            ]
        );

        Map<Id, ContentVersion> contentVersionsMap = getFeedAttachmentContentVersionsMap(
            feedAttachments
        );

        for (FeedAttachment feedAttachment : feedAttachments) {
            // FeedAttachment.RecordId is polymorphic
            // For inline images, RecordId is a ContentDocument ID.
            // For content attachments, RecordId is a ContentVersion ID.
            // For feed items, RecordId is a FeedItem ID.
            if (feedAttachment.RecordId == null) {
                continue;
            }

            String contentDocumentId = '';
            switch on
                feedAttachment.RecordId.getSObjectType()
                    .getDescribe()
                    .getName() {
                when 'ContentDocument' {
                    contentDocumentId = feedAttachment.RecordId;
                }
                when 'ContentVersion' {
                    contentDocumentId = contentVersionsMap.get(
                            feedAttachment.RecordId
                        )
                        .ContentDocumentId;
                }
                when else {
                    continue;
                }
            }

            if (
                feedContentDocumentsMap.containsKey(
                    feedItemsMap.get(feedAttachment.FeedEntityId).ParentId
                )
            ) {
                feedContentDocumentsMap.get(
                        feedItemsMap.get(feedAttachment.FeedEntityId).ParentId
                    )
                    .add(contentDocumentId);
            } else {
                feedContentDocumentsMap.put(
                    feedItemsMap.get(feedAttachment.FeedEntityId).ParentId,
                    new List<Id>{ contentDocumentId }
                );
            }
        }

        return feedContentDocumentsMap;
    }

    private Map<Id, ContentVersion> getFeedAttachmentContentVersionsMap(
        List<FeedAttachment> feedAttachments
    ) {
        // Returns a map of content versions for provided feed attachments
        List<Id> contentVersionIds = new List<Id>();
        for (FeedAttachment feedAttachment : feedAttachments) {
            if (
                feedAttachment.RecordId != null &&
                feedAttachment.RecordId.getSObjectType()
                    .getDescribe()
                    .getName() == 'ContentVersion'
            ) {
                contentVersionIds.add(feedAttachment.RecordId);
            }
        }

        Map<Id, ContentVersion> contentVersionsMap = new Map<Id, ContentVersion>(
            [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :contentVersionIds
            ]
        );

        return contentVersionsMap;
    }
}

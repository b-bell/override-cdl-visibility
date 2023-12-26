# Salesforce Content Document Link Visibility Override

This repository provides an Apex class, `OverrideCdlVisibilityAsync`, which modifies the default visibility setting for files attached to any object in Salesforce to 'All Users'. The class operates asynchronously, allowing it to determine if a file was added as an internal chatter post and maintain that visibility setting.

## Setup

To utilize this code, you need a Salesforce organization with Digital Experiences enabled. You can then incorporate the `OverrideCdlVisibilityAsync` and `OverrideCdlVisibilityAsyncTest` classes, along with the `OverrideCdlVisibilityTrigger` trigger, into your organization's codebase. Using this code as written will override the visibility of all files in your organization. To specify which objects you want to override, please refer to the section on 'Overriding specific SObjects'.

## Functionality

The `OverrideCdlVisibilityAsync` class operates by querying the `ContentDocumentLink` objects that correspond to the IDs in the provided map. It then retrieves the linked entity IDs and the feed attachments associated with those entities. If a `ContentDocumentLink` is not associated with a feed item, its visibility is set to 'AllUsers'. The `ContentDocumentLink` objects are then updated in the database.

## Contributing

We welcome contributions. Please submit a pull request with your changes.

## Overriding specific SObjects

You can specify the SObjects you want to override by adding the following method:

```apex
private List<ContentDocumentLink> filterContentDocumentLinksBySObject(
    List<ContentDocumentLink> cdls
) {
    // Receives a list of CDLs and returns only CDLs that belong to specific SObjects
    List<ContentDocumentLink> filteredCDLs = new List<ContentDocumentLink>();
    for (ContentDocumentLink cdl : cdls) {
        if (
            cdl.LinkedEntityId.getSObjectType().getDescribe().getName() IN
            ('Case')
        ) {
            filteredCDLs.add(cdl);
        }
    }
    return filteredCDLs;
}
```

Then, add this to your `execute` method:
```apex
List<ContentDocumentLink> contentDocumentLinks = filterContentDocumentLinksBySObject(contentDocumentLinks);
```
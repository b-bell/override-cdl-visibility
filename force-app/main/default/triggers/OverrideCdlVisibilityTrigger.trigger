trigger OverrideCdlVisibilityTrigger on ContentDocumentLink (after insert) {
    ID jobID = System.enqueueJob(new OverrideCdlVisibilityAsync(Trigger.newMap));
}
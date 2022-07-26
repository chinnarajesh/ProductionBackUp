trigger InterventionSessionResult on Intervention_Session_Result__c (before insert) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            new InterventionSessionResultTriggerHandler().isBeforeInsert(Trigger.new);
        }
    }
    
}
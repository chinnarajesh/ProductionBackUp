trigger Gradebook_AIBUAUAD on Grade__c (after insert, after delete, after update,  before update, before delete) {
    
    if(TriggerState.isActive('Gradebook_AIBUAUAD')) {
    
    if (!core_triggerUtils.bTriggersDisabled()){
        core_triggerUtils.recursiveHelper(true);
        
        if(Trigger.isDelete && Trigger.isBefore){
            if(!core_triggerUtils.gradeDeletionAllowed){
                for (Grade__c g: trigger.old){
                    if (g.Assignment__c!=null)  g.addError('You cannot delete individual grade records. It may cause problems. Delete the assignment associated with this grade if you wish to remove it.');
                }
            }
            else {
                CT_Gradebook_ManageGradeBook.isbeforedelete(Trigger.OldMap, Trigger.NewMap);
            }
        }
        if(Trigger.isDelete && Trigger.isAfter) {
            CT_Gradebook_ManageGradebook.isAfterDelete(Trigger.OldMap, Trigger.NewMap);
        }
        
        if(!core_triggerUtils.gradeTrigger){
            if(Trigger.isUpdate && Trigger.isBefore){
                CT_Gradebook_ManageGradeBook.isbeforeupdate(Trigger.OldMap, Trigger.NewMap); 
            }
            if(Trigger.isUpdate && Trigger.isAfter){
                CT_Gradebook_ManageGradeBook.isafterupdate(Trigger.OldMap, Trigger.NewMap); 
            }
        }
        
        if (Trigger.isBefore && Trigger.isInsert)
        {
            //CT_Gradebook_ManageGradebook.isBeforeInsert(Trigger.new);
        }
        if (Trigger.isAfter && Trigger.isInsert)
        {
            CT_Gradebook_ManageGradebook.isAfterInsert(Trigger.new);
        }
    }
    }
    
}
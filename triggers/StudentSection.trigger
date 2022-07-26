trigger StudentSection on Student_Section__c (before insert, after insert, before update, after update, before delete, after delete) {
    if (!core_triggerUtils.bTriggersDisabled()){
        try{
            if (trigger.isInsert && trigger.isBefore){
                CT_Student_Section_Utils.processBeforeInsert(trigger.new); 
            }
            if (trigger.isInsert && trigger.isAfter){
                CT_Student_Section_Utils.processAfterInsert(trigger.newMap);
            }
            if (trigger.isUpdate && trigger.isBefore){
                CT_Student_Section_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
            }
            if (trigger.isUpdate && trigger.isAfter){
                CT_Student_Section_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
            }
            if (trigger.isDelete && trigger.isBefore){
                CT_Student_Section_Utils.processBeforeDelete(trigger.oldMap);
            }
            if (trigger.isDelete && trigger.isAfter){
                CT_Student_Section_Utils.processAfterDelete(trigger.oldMap);
            }          
        }
        catch(Exception e){
            List<String> links = new List<String>();
            List<Student_Section__c> sList = (!trigger.isDelete)? trigger.new: trigger.old;
            for(Student_Section__c s: sList){
                if(s.id != null){
                    links.add(s.name + ',' + s.id);
                }
            }
            Global_Error__c ge = Error_Handling.handleError(String.join(links, '; '), 'Student Section', 'Student Section trigger failure', e);
            insert ge;
        }

        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            StudentSectionUtils.fillStudentProgramField(trigger.new, trigger.oldMap);
        }
        if(trigger.isAfter && trigger.isUpdate){    
            StudentSectionUtils.calculateAmountOfTime(trigger.new, trigger.oldMap);
        }
        if(trigger.isAfter && trigger.isDelete){    
            StudentSectionUtils.removeStudentPrograms(trigger.old);
        }
    }   
}
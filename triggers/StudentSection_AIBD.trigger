trigger StudentSection_AIBD on Student_Section__c (before insert, after insert, before update, after update, before delete, after delete) {
    if (!core_triggerUtils.bTriggersDisabled()){
        try{
            if (trigger.isInsert && trigger.isBefore){
                Student_Section_Utils.processBeforeInsert(trigger.new); 
            }
            if (trigger.isInsert && trigger.isAfter){
                    Student_Section_Utils.processAfterInsert(trigger.newMap);
            }
            if (trigger.isUpdate && trigger.isBefore){
                    Student_Section_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
            }
            if (trigger.isUpdate && trigger.isAfter){
                    Student_Section_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
            }
            if (trigger.isDelete && trigger.isBefore){
                    Student_Section_Utils.processBeforeDelete(trigger.oldMap);
            }
            if (trigger.isDelete && trigger.isAfter){
                Student_Section_Utils.processAfterDelete(trigger.oldMap);
            }
        }
        catch(Exception e){
            string links = '';
            List <Student_Section__c> sList;
            if (!trigger.isDelete) sList = trigger.new;
            else sList = trigger.old;
            for(Student_Section__c s: sList){
                if(s.id != null){
                    if(links==''){
                        links = s.name + ',' + s.id;
                    }
                    else{
                        links = links + ';' + s.name + ',' + s.id;
                    }
                }
            }
            Global_Error__c ge = Error_Handling.handleError(links, 'Student Section', 'Student Section trigger failure', e);
            insert ge;
        }
    }
}
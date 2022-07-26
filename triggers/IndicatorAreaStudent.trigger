trigger IndicatorAreaStudent on Indicator_Area_Student__c (before delete, after insert, after update, before insert, before update) {
	if(trigger.isBefore){
		if(trigger.isUpdate){
			for(integer i=0;i<trigger.new.size();i++){
				if(trigger.old[i].Student__c!=trigger.new[i].Student__c){
					trigger.new[i].addError('The student can not be changed after creation.');
				}
				if(trigger.old[i].Indicator_Area__c!=trigger.new[i].Indicator_Area__c){
					trigger.new[i].addError('The indicator area can not be changed after creation.');
				}
			}
		}
		if(trigger.isInsert || trigger.isUpdate){ 
			TriggerUtils.checkReferenceId(trigger.new);
		}
		if(trigger.isDelete){
			SharingUtils.addToStudentCount(trigger.oldMap.keySet(),false);
		}
	} else {
		if(trigger.isInsert){
			Set<ID> toAdd = new Set<ID>();
			for(Indicator_Area_Student__c ias: trigger.new){
				if(ias.Active__c) toAdd.add(ias.id);
			}
			SharingUtils.addToStudentCount(toAdd,true);
		}
		if(trigger.isUpdate){
			Set<ID> toRemove = new Set<ID>();
			Set<ID> toAdd = new Set<ID>();
			for(integer i=0;i<trigger.new.size();i++){
				if(trigger.old[i].Active__c!=trigger.new[i].Active__c){
					if(trigger.new[i].Active__c){
						toAdd.add(trigger.new[i].id);
					} else {
						toRemove.add(trigger.new[i].id);
					}
				}
			}
			SharingUtils.addToStudentCount(toAdd,true);
			SharingUtils.addToStudentCount(toRemove,false);
		}
	}
}
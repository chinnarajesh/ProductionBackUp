trigger Staff_Section on Staff_Section__c (before insert, before update) {
	if (!core_triggerUtils.bTriggersDisabled()){
		Map <Id, Section__c> sectionMap  = new Map <Id, Section__c>();
		Map <Id, Staff__c>  	contactMap = new Map <Id, Staff__c>();
		for (integer i=0; trigger.new.size()>i; i++){
			if (trigger.isInsert||trigger.isUpdate&&(trigger.new[i].staff__c!=trigger.old[i].staff__c||trigger.new[i].Reference_Id__c!=trigger.old[i].Reference_Id__c)){
				sectionMap.put(trigger.new[i].section__c, null);
				contactMap.put(trigger.new[i].staff__c, null);
			}
		}
		if (!sectionMap.isEmpty()){
			for (Section__c s: [select id, name,Time__r.Name__c from Section__c where id in :sectionMap.keySet()]){
				sectionMap.put(s.id, s);
			}
			for (Staff__c s: [select id, individual__r.reference_id__c from Staff__c where id in :contactMap.keySet()]){
				contactMap.put(s.id, s);
			}
			
		}
		for (integer i=0; trigger.new.size()>i; i++){
			if (trigger.isInsert||trigger.isUpdate&&(trigger.new[i].staff__c!=trigger.old[i].staff__c||trigger.new[i].Reference_Id__c!=trigger.old[i].Reference_Id__c)){
				Section__c sect = sectionMap.get(trigger.new[i].section__c);
				Staff__c staff = contactMap.get(trigger.new[i].staff__c);
				trigger.new[i].reference_id__c = staff.Individual__r.reference_id__c+'_'+sect.name+'_'+sect.Time__r.Name__c;
			}
		}
	}	
}
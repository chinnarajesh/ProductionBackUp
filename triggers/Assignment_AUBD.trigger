trigger Assignment_AUBD on Assignment__c (before insert, before update, after insert, after update, before delete) {
if (!core_triggerUtils.bTriggersDisabled()){

	if(Trigger.isUpdate && Trigger.isBefore) {
		Gradebook_ManageAssignments.isbeforeupdate(Trigger.NewMap, Trigger.OldMap);
	}
	if(Trigger.isUpdate && Trigger.isAfter){
		Gradebook_ManageAssignments.isafterupdate(Trigger.NewMap, Trigger.OldMap);
	}
	if(Trigger.isInsert && Trigger.isBefore) {
		Gradebook_ManageAssignments.isbeforeInsert(Trigger.New);
	}
	
	
	if(Trigger.isAfter && Trigger.isInsert){
		Map<String, Section_Standard__c> secStand = new Map<String, Section_Standard__c>();
		Set<Id> assignLibID = new Set<Id>();
		Set<Id> sectionID = new Set<Id>();
		Set<Id> standardID = new Set<Id>();
		Map<Id, Set<Id>> LibToStandard = new Map<Id, Set<Id>>();
		
		//get info
		for(Assignment__c a: Trigger.new){
			if(a.Assignment_Library__c != null){
				assignLibId.add(a.Assignment_Library__c);
				sectionID.add(a.Section__c);
			}
		}
		List<Assignment_Standard__c> assignStandards = [SELECT id, Assignment_Library__c, Standard__c from Assignment_Standard__c 
														WHERE Assignment_Library__c 
														IN: assignLibId];
		
		for(Assignment_Standard__c a: assignStandards){
			standardID.add(a.Standard__c);
			if(libToStandard.containsKey(a.Assignment_Library__c)){
				libToStandard.get(a.Assignment_Library__c).add(a.Standard__c);
			} else {
				libToStandard.put(a.Assignment_Library__c, new Set<Id>{a.Standard__c});
			}
		}
		
		Map<Id, Section__c> sectionMap = new Map<Id, Section__c>([select id, Reference_Id__c from Section__c where Id IN: sectionID]);
		Map<Id, Standard__c> standardMap = new Map<Id, Standard__c>([select id from Standard__c where Id IN: standardID]);
		
		for(Assignment__c a: trigger.new){
			if(a.Assignment_Library__c != null && libToStandard.containsKey(a.Assignment_Library__c)){
				for(Id i: libToStandard.get(a.Assignment_Library__c)){
					string refID = sectionMap.get(a.Section__c).Reference_Id__c + '_' + standardMap.get(i).id;
					secStand.put(refId, new Section_Standard__c(Section__c = a.Section__c, Standard__c = i, Reference_Id__c = refID));
				}
			}
		}
		
		List<Section_Standard__c> existing = [select id, Reference_Id__c from Section_Standard__c where Section__c IN: sectionID];
		
		if(!existing.isEmpty()){
			for(Section_Standard__c s: existing){
				if(secStand.containsKey(s.Reference_Id__c)){
					secStand.remove(s.Reference_Id__c);
				}
			}
		}
		insert secStand.values();
	}
	if (Trigger.isDelete && Trigger.isBefore){
		Gradebook_ManageAssignments.isBeforeDelete(Trigger.oldMap);
	}
}
}
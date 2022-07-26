trigger Enrollment_Tracking on Enrollment_Tracking__c (before insert) {
	if (!core_triggerUtils.bTriggersDisabled()){
		if(trigger.isBefore && trigger.isInsert){
			List<Enrollment_Tracking__c> etUpdateList = new List<Enrollment_Tracking__c>();
			Map<Id, DateTime> studentDateMap = new Map<Id, DateTime>();
			Map<Id, DateTime> studentSectionDateMap = new Map<Id, DateTime>();

			for (Enrollment_Tracking__c et : trigger.new){
				if (et.Student__c!=null && et.Current_Record__c){
					studentDateMap.put(et.Student__c, et.Start_Date__c);
				}
				if (et.Student_Section__c!=null && et.Current_Record__c){
					studentSectionDateMap.put(et.Student_Section__c, et.Start_Date__c);
				}
			}

			for (Enrollment_Tracking__c et: [SELECT 	ID, Current_Record__c, Student__c, Student_Section__c
											FROM Enrollment_Tracking__c 
											WHERE (Student__c in :studentDateMap.keySet() or Student_Section__c in :studentSectionDateMap.keySet())
											AND current_record__c = true]){
				if(et.Student__c != null){
					et.end_date__c 			= studentDateMap.get(et.Student__c);
					et.current_record__c 	= false;
					etUpdateList.add(et);
				} else if(et.Student_Section__c != null){
					et.end_date__c 			= studentSectionDateMap.get(et.Student_Section__c);
					et.current_record__c 	= false;
					etUpdateList.add(et);
				}
			}

			if (!etUpdateList.isEmpty()){
				update etUpdateList;
			}
		}
	}
}
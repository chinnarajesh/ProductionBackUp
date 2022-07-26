Trigger CommunityService on Community_Service__c (before insert, after insert, after update, after delete) {
if (!core_triggerUtils.bTriggersDisabled()){	
    List<Community_Service__c> oldCommunityServiceList = Trigger.old;   
    List<Community_Service__c> newCommunityServiceList = Trigger.new;
    Map<Id, Student__c> studentMap = new Map<Id, Student__c>();
    Set<Id> studentIdSet = new Set<Id>();

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
	    
	    for (Community_Service__c newCommunityService : newCommunityServiceList) {
	        studentIdSet.add(newCommunityService.Student__c);
	    }
	    
	    studentMap = new Map<Id, Student__c>([SELECT s.Id, s.Service_Hours_YTD__c FROM Student__c s WHERE s.Id IN: studentIdSet]);
    	
    	if (Trigger.isInsert) {
        
	        for (Community_Service__c newCommunityService : newCommunityServiceList) {

	        	if (studentMap.get(newCommunityService.Student__c).Service_Hours_YTD__c == null) {
	            	studentMap.get(newCommunityService.Student__c).Service_Hours_YTD__c = 0;
	        	}

	        	studentMap.get(newCommunityService.Student__c).Service_Hours_YTD__c += newCommunityService.Service_Hours_Completed__c;
	        	
	        }
        
    	} else if (Trigger.isUpdate) {
        
	        for (Integer i = 0; i < oldCommunityServiceList.size(); i++) {
	            studentMap.get(oldCommunityServiceList[i].Student__c).Service_Hours_YTD__c += (newCommunityServiceList[i].Service_Hours_Completed__c - oldCommunityServiceList[i].Service_Hours_Completed__c);
	        }
        
    	}
    	
    } else if (Trigger.isAfter && Trigger.isDelete) {
		
		for (Community_Service__c oldCommunityService : oldCommunityServiceList) {
	        studentIdSet.add(oldCommunityService.Student__c);
	    }
	    
	    studentMap = new Map<Id, Student__c>([SELECT s.Id, s.Service_Hours_YTD__c FROM Student__c s WHERE s.Id IN: studentIdSet]);
		
        for (Community_Service__c oldCommunityService : oldCommunityServiceList) {
            studentMap.get(oldCommunityService.Student__c).Service_Hours_YTD__c -= oldCommunityService.Service_Hours_Completed__c; 
        }
		
    }

    upsert studentMap.values();
	}
}
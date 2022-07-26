trigger Session on Session__c (before delete) {
	if (!core_triggerUtils.bTriggersDisabled()){
		Set <Id> delSessIdSet = new Set <Id>();
		Map <Id, Boolean> sessionBooleanMap = new Map <Id, Boolean>();
		for (Session__c sess: trigger.old){
			delSessIdSet.add(sess.id);
		}
		for (Session__c s: [select id, (select id from Attendance__r limit 1)  from Session__c where id in:delSessIdSet ]){
			sessionBooleanMap.put(s.id, true);
			for(Attendance__c a: s.Attendance__r){
				sessionBooleanMap.put(s.id, false);
			}
		}
		for (Session__c sess: trigger.old){
			if (!sessionBooleanMap.get(sess.id)){
				trigger.oldMap.get(sess.id).addError('Please delete all related Attendance records before deleting Sessions');
			}
		}
	}
}
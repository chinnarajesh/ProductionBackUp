trigger Homework_AIAUAD on HW_Tracker__c (after delete, after insert, after update) {
	if (!core_triggerUtils.bTriggersDisabled()){
		if (Trigger.isInsert || Trigger.isUpdate) {
			Homework_ManageHomework.updateStats(Trigger.NewMap);
		}
	}
}
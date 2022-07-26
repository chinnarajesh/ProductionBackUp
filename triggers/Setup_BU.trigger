trigger Setup_BU on Setup__c (before insert, after insert, before update, after update){
	if (!core_triggerUtils.bTriggersDisabled()){
		if(trigger.isInsert && Trigger.isBefore){
			Setup_Utils.deactivateOldSetups(trigger.new,null);
		} else if(Trigger.isInsert && Trigger.isAfter){
			if(core_triggerUtils.setupDataCloningEnabled){
				Setup_Utils.cloneOldSetupConfiguration(Trigger.new);
			}
		}else if (Trigger.isUpdate && Trigger.isBefore){
			Setup_Utils.deactivateOldSetups(Trigger.new, Trigger.oldMap);
			Setup_Utils.validateData(Trigger.new, Trigger.oldMap);
			Points_Utils.createScheduleRecords(Trigger.oldmap,Trigger.newMap);
		} else if (Trigger.isUpdate && Trigger.isAfter){
			Setup_Utils.recalculateStandardGrades(trigger.new, trigger.oldMap);
		}
	}
}
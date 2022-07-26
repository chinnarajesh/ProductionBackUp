trigger StudentProgramTrigger on Student_Program__c (before insert, before update) {
	if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
		StudentProgramUtils.updateFields(Trigger.new);
	}
}
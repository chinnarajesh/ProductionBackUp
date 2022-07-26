trigger Assessment_BI on Assesment__c (before insert) {
	if (!core_triggerUtils.bTriggersDisabled()){
		if(trigger.isBefore && trigger.isInsert){
			Set<Id> studentSFID = new Set<Id>();
			
			for(Assesment__c a:trigger.new){
				if(a.Student__c != null){
					studentSFID.add(a.Student__c);
				}
			}
			
			if(!studentSFID.isEmpty()){
				Map<Id, Student__c> studentIDMap = new Map<Id, Student__c>([select id, Student_Id__c, Individual__c from Student__c where id IN: studentSFID]);
				for(Assesment__c a: trigger.new){
					try{
						a.Student_Id__c = studentIDMap.get(a.Student__c).Student_Id__c;
						if(a.Year_Over_Year__c){
							a.Contact__c = studentIDMap.get(a.Student__c).Individual__c;
						}
					}catch (Exception e){
						a.addError('Error linking to student record. Please check provided information.');
						break;
					}
				}
			}
		}
	}
}
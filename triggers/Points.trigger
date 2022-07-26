trigger Points on Points__c (after insert, after update, after delete) {
	if (!core_triggerUtils.bTriggersDisabled()){
		 if (trigger.isInsert || trigger.isUpdate){
		 	if(trigger.isBefore){
		 		for(Points__c p:trigger.new){
		 			if(p.Points__c == null){
		 				p.Points__c.AddError('Please enter a point value.');
		 			}
		 		}
		 	}
		 	Points_Utils.updatePointsBalance(trigger.newMap);
		 }
		 if (trigger.isDelete){
		    Points_Utils.updatePointsBalance(trigger.oldMap); 
		 }
	}
}
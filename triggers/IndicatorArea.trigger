trigger IndicatorArea on Indicator_Area__c (after update) {
	private String deactivateIndicatorArea = '';
	
	deactivateIndicatorArea += '(';
	for(Integer i = 0; i < trigger.new.size(); i++) {
		if(trigger.new[i].Active__c == false) {
			if(trigger.new.size() > 1 && i != trigger.new.size()-1) {
				deactivateIndicatorArea += '\'' + String.escapeSingleQuotes(trigger.new[i].ID) + '\',';
			}
			else {
				deactivateIndicatorArea += '\'' + String.escapeSingleQuotes(trigger.new[i].ID) + '\'';
			}
		}
	}
	deactivateIndicatorArea += ')';
	
	if(deactivateIndicatorArea.length() > 2) {
		Batch_DeactivateData bdd = new Batch_DeactivateData(null);
		bdd.objectDeactivationOrder = new List<String> {
			'Indicator_Area_Student__c',
			'Student_Section__c',
			'Staff_Section__c',
			'Section__c',
			'Account_Program__c',
			'Program__c'
		};
		
		bdd.defaultObjectQueryMap = new Map<String,String>{
			'Indicator_Area_Student__c'=>'SELECT ID, Active__c FROM Indicator_Area_Student__c WHERE Indicator_Area__c IN ' + deactivateIndicatorArea,
			'Student_Section__c'=>'SELECT ID, Active__c, Archived__c FROM Student_Section__c WHERE Section__r.RecordType.Name=\'Intervention Section\' AND Section__r.Program__r.Indicator_Area__c IN ' + deactivateIndicatorArea,
			'Staff_Section__c'=>'SELECT ID, Is_Active__c, Archived__c FROM Staff_Section__c WHERE Section__r.RecordType.Name=\'Intervention Section\' AND Section__r.Program__r.Indicator_Area__c IN ' + deactivateIndicatorArea,
			'Section__c'=>'SELECT ID, Active__c, Archived__c FROM Section__c WHERE RecordType.Name=\'Intervention Section\' AND Program__r.Indicator_Area__c IN ' + deactivateIndicatorArea,
			'Account_Program__c'=>'SELECT ID, Active__c FROM Account_Program__c WHERE Program__r.Indicator_Area__c IN ' + deactivateIndicatorArea,
			'Program__c' => 'Select ID, Active__c FROM Program__c WHERE Indicator_Area__c IN ' + deactivateIndicatorArea
		};
		
		bdd.query = bdd.defaultObjectQueryMap.get(bdd.objectDeactivationOrder[0]);
		bdd.processObject = bdd.objectDeactivationOrder[0];
		
		Database.executeBatch(bdd);	
	}
}
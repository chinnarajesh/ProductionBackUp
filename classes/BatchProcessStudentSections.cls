global class BatchProcessStudentSections implements Database.Batchable<sObject> {
	
	String query = 'SELECT Id, Archived__c FROM Student_Section__c';
	
	global BatchProcessStudentSections() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Student_Section__c> scope) {
		for(Student_Section__c ss: scope){
			ss.Archived__c = !ss.Archived__c;
		}
		update scope;

		for(Student_Section__c ss: scope){
			ss.Archived__c = !ss.Archived__c;
		}
		update scope;		
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
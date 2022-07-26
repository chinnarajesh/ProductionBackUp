global class GradebookUtilizationBatch implements Database.Batchable<sObject>,Database.Stateful{
	public String query;
	public String email;
	public DateTime daystart;
	public DateTime dayend;
	Integer year = system.now().year();
    Integer month = system.now().month();
    Integer day = system.now().day();
	
	global GradebookUtilizationBatch () {
		Integer year = system.now().year();
	    Integer month = system.now().month();
	    Integer day = system.now().day();
	    daystart = datetime.newInstance(year, month, day, 0, 0, 0);
	    dayend = datetime.newInstance(year, month, day, 23, 59, 59);
	}


	global database.querylocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Section__c> scope){
		
		List<Section__c> sList = new List<Section__c>();
		for(Section__c s:scope){
			List<Grade__c> gradeList = new List<Grade__c>();
			List<Grade__c> totgradeList = new List<Grade__c>();
			gradeList = [select Id, Name from Grade__c where Student_Section__r.Section__c = :s.Id AND LastModifiedDate > :daystart AND LastModifiedDate < :dayend];
			totgradeList = [select Id, Name from Grade__c where Student_Section__r.Section__c = :s.Id ];		
		
			if(totgradeList.size()>0){
				if(gradeList.size()>0){
					s.of_Consecutive_Days_without_Grades__c =0;
				}
				else{
					s.of_Consecutive_Days_without_Grades__c ++;
				}
				
				sList.add(s);
			}
		}
		
		try{
			update sList;
		}
		catch(exception e){
			system.debug('#### There was an error updating the section with the missed Grade days.');
		}
	}
	
	global void finish(Database.BatchableContext BC){
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
        TotalJobItems, CreatedBy.Email
        from AsyncApexJob where Id =:BC.getJobId()];
         
    	if(a.NumberOfErrors>0){
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        String[] toAddresses = new String[] {a.CreatedBy.email};
	        mail.setToAddresses(toAddresses);
	        mail.setSubject('Errors during Update of Sections');
	        
		   	mail.setPlainTextBody
	   		('The batch Apex job processed ' + a.TotalJobItems +
	   		' batches with '+ a.NumberOfErrors + ' failures.');
	  		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    	}
	} 
	
}
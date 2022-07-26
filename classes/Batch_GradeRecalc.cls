global class Batch_GradeRecalc implements Database.Batchable<sObject>{
	   global String query;
		
	   global Database.QueryLocator start(Database.BatchableContext BC){
	      return Database.getQueryLocator(query);
	   }
	
	   global void execute(Database.BatchableContext BC, List<Grade__c> scope){	
	   	//Batch query needs to include Grade_Update__c, ID, Student_Section__r.Student__c, Standard__c, Student_Section__r.Student__r.Setup__r.Law_of_Decaying_Average_Weight__c
	   		List<Grade__c> gList = new List<Grade__c>();
	   		for(Grade__c g : scope){
	   			g.Grade_Update__c = !g.Grade_Update__c;
	   			//g.exclude_From_Section_Grade__c = !g.Assignment__r.Include_in_final_grade__c; Should not be considered the same; exclude is specifically used for 'drop' grades US2794
	   			gList.add(g);
	   		}
	   		core_triggerUtils.calculationTriggerUpdate(true);
	   		update gList;
	   		core_triggerUtils.calculationTriggerUpdate(false);	
	   }
	
	   global void finish(Database.BatchableContext BC){
	   		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
	        						 TotalJobItems, CreatedBy.Email
	        						 from AsyncApexJob where Id =:BC.getJobId()];
	        
	        // Send an email to the Apex job's submitter notifying of job completion.  
	    
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        String[] toAddresses = new String[] {a.CreatedBy.Email};
	        mail.setToAddresses(toAddresses);
	        mail.setSubject('Grade Recalculation - ' + a.Status);
	        
		   	mail.setPlainTextBody
	   		('The Grade Recalculation job processed ' + a.TotalJobItems +
	   		' batches with '+ a.NumberOfErrors + ' failures.');
	  		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	   }
}
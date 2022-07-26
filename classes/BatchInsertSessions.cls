global class BatchInsertSessions implements Database.Batchable<sObject>, Database.Stateful{
	public String query;
	public ID setupId;
	public ID rpId;
	public Data_Load_Log__c log;
	public List<HoldingObj__c> holdingSource {get;set;}
	public Set <Id> scheduleDayIds;
	
	global BatchInsertSessions(ID setup, ID reportingPeriod){
		if(setup!=null){
			setupId = setup;
			query = 'SELECT ID,Day__c,Schedule_Template__c,Reporting_Period__c,Schedule_Template__r.Setup__r.School__c FROM Schedule_Day__c WHERE Schedule_Template__r.Setup__c =\'' +setupId+'\'';
			log = new Data_Load_Log__c(Status__c='Pending', Setup__c=setupId, Type__c='Session', Class_Name__c='Scheduler_HoldingProcessor');
			if(reportingPeriod!=null){
				rpId = reportingPeriod;
				query +=' AND Reporting_Period__c =\'' +rpId+'\'';
				log.Reporting_Period__c = rpId;
			}
			insert log;
		}
	}
	
	global BatchInsertSessions(Set <ID> sdIds){
		scheduleDayIds = sdIds;
		 query='SELECT ID,Day__c,Schedule_Template__c,Reporting_Period__c,Schedule_Template__r.Setup__r.School__c FROM Schedule_Day__c WHERE id in :scheduleDayIds';
		 log = new Data_Load_Log__c(Status__c='Pending', Type__c='Session', Class_Name__c='Scheduler_HoldingProcessor');
			insert log;
	} 
	
	global Database.QueryLocator start(Database.BatchableContext BC){
   		log.Status__c = 'Running';
   		log.Batch_ID__c = BC.getJobId();
		log.Total_Records__c = 0;
		log.Failed_Records__c = 0;
		log.Start_Time__c = System.now();
		log.Start_Time_Text__c = log.Start_Time__c.format('MM/dd/yyyy hh:mm a');
		update log;
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Schedule_Day__c> scope){	
		Scheduler_CreateSessions pub = new Scheduler_CreateSessions(scope,holdingSource);
		sched_RefreshSessionsAfterPublish.firstRun = false;
		List<Database.UpsertResult> records;
		if(pub.pList.size() > 0)
			records = pub.createSessionsForPeriods(scope);
		else
			records = pub.createSessionsForScheduledSects(scope);
		pub.publishScheduleDays(scope);
     	
     	log.Total_Records__c += records.size();
    	for(Database.UpsertResult res: records){
    		if(!res.isSuccess()){
    			log.Failed_Records__c++;
    			log.Messages__c += ', '+res.getErrors()[0].getMessage();
    		}
    	}
	}

	global void finish(Database.BatchableContext BC){
		log.Status__c = 'Completed';
		log.End_Time__c = System.now();
		log.End_Time_Text__c = log.End_Time__c.format('MM/dd/yyyy hh:mm a');
		update log;
	}
}
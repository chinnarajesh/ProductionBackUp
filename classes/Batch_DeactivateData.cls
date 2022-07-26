global class Batch_DeactivateData implements Database.Batchable<sObject>, Database.Stateful{
	private final ID currentYearID = CYUtil.getCurrentYearID();
	public String query;
	public boolean continueAfter;
	public String processObject;
	Data_Load_Log__c log;
	Boolean hasHadErrors = false;

	//tracks errors back over batch. This allows later batches to be marked completed but have the overall process fail.
	public boolean hasHadErrorsBefore = false;

	//defines the order of processing for deactivation, each object is deactivated in turn, with it's own log
	public List<String> objectDeactivationOrder			{get;set;}
	//This holds the default queries for each object processed by the deaction process
	public Map<String, String> defaultObjectQueryMap	{get;set;}
	
	global Batch_DeactivateData(ID logID){
		populateDeactivationProcessData();
		this.continueAfter = true;
		this.query = defaultObjectQueryMap.get(objectDeactivationOrder[0]);
		this.processObject = objectDeactivationOrder[0];
		initLogs(logID);
	}

	global Batch_DeactivateData(ID logid, String processObject, boolean continueAfter){
		populateDeactivationProcessData();
		this.continueAfter = continueAfter;
		this.processObject = processObject;
		initLogs(logID);
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		try{
			if(query == null){
			if(defaultObjectQueryMap.containsKey(processObject)) {
				query = defaultObjectQueryMap.get(processObject);
			} else {
				throw new CYUtil.InterventionsException('Unable to find query for provided object. Process aborted.');
			}
			}
			log.Batch_ID__c = BC.getJobId();
			log.Status__c = 'In Progress';
			updateLog();
			return Database.getQueryLocator(query);
		} catch(Exception e){
			handleException(e,'start');
			throw e;
		}
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope){
   		try{
   			for(sObject s:scope){
				try {
					if(s.get('Active__c') != null){
						s.put('Active__c',false);
					}
				}
				catch(Exception e) {
					
				}
				try {
					if(s.get('Archived__c') != null){
						s.put('Archived__c', true);
					}
				}
				catch(Exception e) {
					
				}
				try {
					if(s.get('Active__c') != null){
						s.put('Active__c', false);
					}
				}
				catch(Exception e) {
					
				}

				try{
					if(s.get('Is_Active__c') != null){
						s.put('Is_Active__c', false);
					}
				} catch(Exception e){}
				//If you need to work with addtional fields, add them here.
				//If you want that field to be processed on only one object type, getSObjectType() should work
			}
			Database.SaveResult[] results = DMLManager.updateAsUser(scope,false);
			processDMLResults(results);

			updateLog();
   		} catch(Exception e){
			handleException(e,'execute');
			throw e;
		}
		
	}
	
	global void finish(Database.BatchableContext BC) {
		try{
			if(continueAfter){
				startNextBatch();
			}

			if(!hasHadErrors){
				log.Status__c = 'Completed';
			} else {
				log.Status__c = 'Failed';
			}
			
			log.End_Time__c = system.now();
			updateLog();
		} catch(Exception e){
			handleException(e,'finish');
			throw e;
		}
		
	}

	private void initLogs(ID logID){
		//indicator area deactivation doesn't use logging, so we bypass
		if(logID == null){ 
			log = new Data_Load_Log__c();
			log.Failed_Records__c = 0;
			log.Total_Records__c = 0;
			log.Processed_Records__c = 0;
			return;
		}
		try{
			log = [select Batch_ID__c, Class_Name__c, End_Time__c, Failed_Records__c, Messages__c,
					Start_Time__c, Status__c, Total_Records__c, Type__c, Processed_Records__c
				from Data_Load_Log__c
				where ID =: logID];
			log.Failed_Records__c = 0;
			log.Messages__c ='';
			log.Start_Time__c = system.now();
			log.Total_Records__c = 0;
			log.Processed_Records__c = 0;
			log.Processed_Record_Type__c = processObject;
		}catch(System.QueryException e){
			throw new CyUtil.InterventionsException('Unable to find the provided log.');
		}
		updateLog();
	}

	private void updateLog(){
		if(log.id != null){
			if(log.Messages__c.length() > 32000){
				log.Messages__c = log.Messages__c.subString(0,31000);
			}
			try{
				DMLManager.updateAsUser(new Data_Load_Log__c[]{log});
			} catch(DMLManager.CRUDException e){
				throw new CyUtil.InterventionsException('User lacks permissions to update Data Load Logs.');
			} catch(DMLManager.FLSException e){
				throw new CyUtil.InterventionsException('User lacks permissions to update Data Load Logs.');
			} catch(System.DMLException e){
				throw new CYUtil.InterventionsException('Unexpected exception while updating runtime log.');
			}
		}
	}

	private void processDMLResults(Database.SaveResult[] results){
		for(Database.SaveResult r:results){
			if(!r.isSuccess()){
				log.Messages__c += 'DML Failed for '+r.getID()+': '+r.getErrors()[0].getMessage()+'\n';
				log.Failed_Records__c++;
			} else {
				log.Processed_Records__c++;
			}
			log.Total_Records__c++;
		}
	}

	private void startNextBatch(){
		String nextObject;
		Data_Load_Log__c newLog = new Data_Load_Log__c();

		for(Integer i=0;i<objectDeactivationOrder.size();i++){
			if(objectDeactivationOrder[i] == processObject){
				if(i != objectDeactivationOrder.size()-1){
					nextObject = objectDeactivationOrder[i+1];
				}
				else {
					continueAfter = false;
				}
			}
		}
		
		if(continueAfter) {
			if(nextObject != null && log.ID != null){		
				newLog.Type__c = 'Interventions Data Deactivation';
				newLog.Status__c = 'Pending';
				newLog.Failed_Records__c = 0;
				newLog.Total_Records__c = 0;
				newLog.Processed_Records__c = 0;
				newLog.Reporting_Period__c = currentYearID;
					
				try{
					DMLManager.insertAsUser(new List<Data_Load_Log__c>{newLog});
				} catch(DMLManager.CRUDException e){
					throw new CyUtil.InterventionsException('User lacks permissions to update Data Load Logs.');
				} catch(DMLManager.FLSException e){
					throw new CyUtil.InterventionsException('User lacks permissions to update Data Load Logs.');
				} catch(System.DMLException e){
					throw new CyUtil.InterventionsException('Failed to make new log for next batch.');
				}
			}
	
			Batch_DeactivateData batch = new Batch_DeactivateData(newLog.id,nextObject,continueAfter);
			batch.objectDeactivationOrder = objectDeactivationOrder;
			batch.defaultObjectQueryMap = defaultObjectQueryMap;
			batch.hasHadErrorsBefore = hasHadErrorsBefore;
			Database.executeBatch(batch);
		} else if(log.id != null && !hasHadErrorsBefore) {
			List<EOY_Progress__c> eoyProgress = [select id, Is_Complete__c from EOY_Progress__c where Module_Name__c='Interventions' and Year__c =: currentYearID limit 1];
			if(!eoyProgress.isEmpty()){
				eoyProgress[0].Is_Complete__c = true;
				try{
					update eoyProgress;
				} catch(System.DMLException e){
					throw new CYUtil.InterventionsException('Unable to update EOY Progress.');
				}
			}
		}
	}

	private void populateDeactivationProcessData(){
		objectDeactivationOrder = new List<String>{
			'Student_Section__c',
			'Staff_Section__c',
			'Section__c',
			'Indicator_Area_Student__c',
			'Account_Program__c'
		};

		//because we need to escape querried IDs apparently
		String escapedYear = String.escapeSingleQuotes(currentYearID);

		defaultObjectQueryMap = new Map<String,String>{
			'Student_Section__c'=>'select id, Active__c, Archived__c '+
												'from Student_Section__c '+
												'where Section__r.Time__c = \''+escapedYear+'\' '+
												'and Section__r.RecordType.Name=\'Intervention Section\' '+
												'and Archived__c = false',
			'Staff_Section__c'=>'select id, Is_Active__c, Archived__c '+
												'from Staff_Section__c '+
												'where Section__r.Time__c = \''+escapedYear+'\' '+
												'and Section__r.RecordType.Name=\'Intervention Section\' '+
												'and Archived__c = false',
			'Section__c'=>'select id, Active__c, Archived__c '+
										'from Section__c '+
										'where Time__c = \''+escapedYear+'\' '+
										'and RecordType.Name=\'Intervention Section\' '+
										'and Archived__c = false',
			'Indicator_Area_Student__c'=>'select id, Active__c '+
											'from Indicator_Area_Student__c '+
											'where Student__r.School_Year__c = \''+escapedYear+'\' '+
											'and Active__c = true',
			'Account_Program__c'=>'select id, Active__c '+
									'from Account_Program__c '+
									'where Current_Year_ID__c = \''+escapedYear+'\' '+
									'and Active__c = true'
		};
	}

	private void handleException(Exception e, String location){
		system.debug(e.getMessage()+e.getStackTraceString());
		log.Messages__c += 'Exception: '+e.getMessage()+e.getStackTraceString();
		updateLog();
		hasHadErrors = true;
		hasHadErrorsBefore = true;
		throw e;
	}	
}
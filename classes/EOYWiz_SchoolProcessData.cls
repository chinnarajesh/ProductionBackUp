public with sharing class EOYWiz_SchoolProcessData {
	public EOY_Progress__c schoolProgress {get; set;}
	public ID EOYrecordType {get; set;}
	
	//passed in parameters
	private String EOYID {get; set;}
	private String activeYear {get; set;}
	private String nextYear {get; set;}
	
	public List<Data_Load_Log__c> dataLogs {get; set;}
	
	public ID batchID {get; set;}
	public String sectionLogID {get; set;}
	public String staffSectionLogID {get; set;}
	public String studentSectionLogID {get; set;}
	public String studentLogID {get; set;}
	public Boolean batchComplete {get; set;}
	
	public static String warning1 = 'There is data that needs to be deactivated.';
	public static String error1 = 'Error! There was a problem with initialzation. Please start from the EOY home page.';
	
	private Boolean initializationError {get; set;}
	private Boolean isLoading;
	
	public EOYWiz_SchoolProcessData() {
		schoolProgress = new EOY_Progress__c();
		EOYID = '';
		activeYear = apexPages.currentPage().getParameters().get('activeYear');
		nextYear = apexPages.currentPage().getParameters().get('nextYear');
		
		dataLogs = new List<Data_Load_Log__c>();
		
		batchComplete = true;
		initializationError = false;
		
		EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
		
		initialize();
	}

	private void initialize() {
		getSchoolProgress();
		isLoading = true;
		getDataLogs();
		isLoading = false;
	}
	
	public pageReference gotoSchoolSnapshots() {
		pageReference p = new pageReference('/apex/EOYWiz_SchoolSnapshots');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);    
		return p;       
	}
	
	public pageReference gotoSchoolPurgeEOYData() {
		pageReference p = new pageReference('/apex/EOYWiz_SchoolPurgeEOYData');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);    
		return p;       
	}
	
	public void setLastModified() {
		user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
		String timeZone = UserInfo.getTimeZone().getID();
		schoolProgress.School_Process_Data_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
		try{
			upsert schoolProgress;
		} catch(Exception e){
			Error_Handling.errorMessage('Failed to updated last modified date:'+e);
		}
	}
	
	public void processData() {
		//changes make the log ids no longer needed, so you get 4 nulls
		try{
			Batch_SchoolProcessData batch = new Batch_SchoolProcessData(schoolProgress.Setup__c, activeYear, null, null, null, null);
			batchID = Database.executeBatch(batch);
		} catch(Exception e){
			insert Error_Handling.handleError('','EOYWiz_SchoolProcessData','Failed to start Batch_SchoolProcessData',e);
			Error_Handling.errorMessage('Error while trying to start process data batch.');
			return;
		}
		
		setLastModified();
		batchComplete = false;
		Error_Handling.infoMessage('Started batch job.');
	}
	
	private void getSchoolProgress() {
		if(!initializationError) {
			EOYID = apexPages.currentPage().getParameters().get('selectedProgress');
			if(EOYID != null) {
				system.debug('eoyID: ' + EOYID);
				schoolProgress = [SELECT ID, School_Process_Data_Completed__c, School_Process_Data_Last_Modified__c, School__c, School__r.Name, Setup__c, Year__c, Setup__r.Processed_EOY_Data__c FROM EOY_Progress__c WHERE ID =: EOYID AND RecordTypeID =: EOYrecordType];
			}
			else {
				initializationError = true;
				apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, error1));
			}
		}
	}

	public void getDataLogs() {
		List<Data_Load_Log__c> logs;
		dataLogs = new List<Data_Load_Log__c>();
		try {
			logs = [SELECT ID, Type__c, Total_Records__c, Status__c, Start_Time__c, Start_Time_Text__c, Setup__c, Setup__r.School__c, 
							Setup__r.School__r.Name, Messages__c, Failed_Records__c, End_Time__c, End_Time_Text__c, Class_Name__c, LastModifiedDate, Batch_ID__c 
							FROM Data_Load_Log__c 
							WHERE Class_Name__c = 'Batch_SchoolProcessData' 
							AND Setup__c =: schoolProgress.Setup__c ORDER BY createdDate DESC];
		} catch(Exception e) {
			Error_Handling.errorMessage(e.getMessage());
			return;
		}
		//always assume the batch is complete
		batchComplete = true;
		if(logs.isEmpty()){
			Error_Handling.warningMessage(warning1);
			return;
		}

		boolean hasErrors = false;
		if(batchID == null){
			batchID = logs[0].Batch_ID__c;
		}

		for(Data_Load_Log__c d : logs) {
			if(d.Batch_ID__c == batchID){
				dataLogs.add(d);
				if(d.Status__c == 'Failed' && !hasErrors){
					hasErrors = true;
					Error_Handling.errorMessage('One or more of the batches below have failed. Please review the messages in the table below for assistance in resolving the failure. You will not be able to continue until this error is resolved.');
				}
				if(d.Status__c != 'Completed' && d.Status__c != 'Failed' && batchComplete){
					batchComplete = false;
					Error_Handling.infoMessage('The batch is still running.');
				} 
			}
		}

		if(batchComplete && !hasErrors){
			Error_Handling.infoMessage('The batch is complete.');
			getSchoolProgress();
		} else if(batchComplete && hasErrors){
			Error_Handling.warningMessage(warning1);
		}
	}
}
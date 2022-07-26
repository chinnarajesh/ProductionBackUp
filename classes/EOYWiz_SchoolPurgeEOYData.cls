public with sharing class EOYWiz_SchoolPurgeEOYData {
	public EOY_Progress__c schoolProgress {get; set;}
	public ID EOYrecordType {get; set;}

	private String EOYID {get; set;}
	private String activeYear {get; set;}
	private String nextYear {get; set;}

	public ID batchID {get; set;}
	public List<Data_Load_Log__c> dataLogs {get; set;}
	public Set<ID> dataLogIDs {get; set;}

	public Boolean batchComplete {get; set;}
	private Boolean initializationError {get; set;}

	public static String error1 = 'Error! There was a problem with initialzation. Please start from the EOY home page.';

	public EOYWiz_SchoolPurgeEOYData() {
		schoolProgress = new EOY_Progress__c();
		EOYID = '';
		activeYear = apexPages.currentPage().getParameters().get('activeYear');
		nextYear = apexPages.currentPage().getParameters().get('nextYear');

		dataLogs = new List<Data_Load_Log__c>();
		dataLogIDs = new Set<ID>();

		batchComplete = true;
		initializationError = false;

		EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');

		initialize();
	}

	private void initialize() {
		getSchoolProgress();
		if(!initializationError) {
			getDataLogs();
		}
	}

	public pageReference gotoSchoolProcessData() {
		pageReference p = new PageReference('/apex/EOYWiz_SchoolProcessData');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);
		return p;
	}

	public pageReference gotoSchoolPurgeHistoricalData() {
		pageReference p = new PageReference('/apex/EOYWiz_SchoolPurgeHistoricalData');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);
		return p;
	}

	public void setLastModified() {
		String timeZone = UserInfo.getTimeZone().getID();
		schoolProgress.School_Purge_EOY_Data_Last_Modified__c = UserInfo.getName() + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
		try{
			upsert SchoolProgress;
		} catch(Exception e){
			system.debug('Failed to updated last modified date:'+e);
		}
		
	}

	public void purgeEOYData(){
		try{
			Batch_SchoolPurgeEOYData batch = new Batch_SchoolPurgeEOYData((String)schoolProgress.Setup__c, activeYear, null, 0);
			batchID = Database.executeBatch(batch);
		} catch(Exception e){
			insert Error_Handling.handleError('','EOYWiz_SchoolPurgeEOYData','Failed to initialize Batch_SchoolPurgeEOYData', e);
			Error_Handling.errorMessage('An error occured while starting the batch.');
			return;
		}
		

		setLastModified();
		batchComplete = false;
		apexPages.addMessage(new apexPages.Message(apexPages.Severity.INFO, 'Started batch job'));
	}

	private void getSchoolProgress() {
		if(!initializationError) {
			EOYID = apexPages.currentPage().getParameters().get('selectedProgress');
			if(EOYID != null) {
				system.debug('eoyID: ' + EOYID);
				schoolProgress = [SELECT ID, School_Purge_EOY_Data_Completed__c, School_Purge_EOY_Data_Last_Modified__c, School__c, School__r.Name, Setup__c, Year__c, Setup__r.Purged_EOY_Data__c FROM EOY_Progress__c WHERE ID =: EOYID AND RecordTypeID =: EOYrecordType];
			}
			else {
				initializationError = true;
				apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, error1));
			}
		}
	}

	public void getDataLogs(){
		List<Data_Load_Log__c> logs;
		try {
			logs = [SELECT ID, Type__c, Total_Records__c, Status__c, Start_Time__c, Start_Time_Text__c, Setup__c, Setup__r.School__c,
							Setup__r.School__r.Name, Messages__c, Failed_Records__c, End_Time__c, End_Time_Text__c, Class_Name__c, LastModifiedDate, Batch_ID__c
						FROM Data_Load_Log__c
						WHERE Class_Name__c = 'Batch_SchoolPurgeEOYData'
						AND Setup__c =: schoolProgress.Setup__c ORDER BY createdDate DESC];
		}catch(Exception e) {
			Error_Handling.errorMessage('Failure retriving data logs: ' + e.getMessage());
			return;
		}

		for(Data_Load_Log__c log:logs){
			system.debug(log);
		}

		batchComplete = true;
		boolean hasErrors = false;
		if(logs.isEmpty()){
			Error_Handling.infoMessage('Please Purge EOY Data here.');
			return;
		}
 
		if(batchID == null){
			batchID = logs[0].Batch_ID__c;
		}
		dataLogs = new List<Data_Load_Log__c>();
		for(Data_Load_Log__c d : logs){
			if(d.Batch_ID__c == batchID){
				dataLogs.add(d);
				if(d.Status__c != 'Completed'){
					if(d.Status__c == 'Failed' && !hasErrors){
						hasErrors = true;
						Error_Handling.errorMessage('One or more of the batches below have failed. Please review the messages in the table below for assistance in resolving the failure.');
					} else if(d.Status__c != 'Failed' && batchComplete){
						batchComplete = false;
						Error_Handling.infoMessage('The batch is still running.');
					}
				}
			} else if(d.Batch_ID__c == null){
				Error_Handling.infoMessage('The batch is still running.');
				batchComplete = false;
			}
		}

		if(batchComplete){
			Error_Handling.infoMessage('The batch is complete.');
			getSchoolProgress();
		}
	}
}
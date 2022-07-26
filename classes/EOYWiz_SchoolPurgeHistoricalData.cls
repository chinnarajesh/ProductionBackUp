public with sharing class EOYWiz_SchoolPurgeHistoricalData {
	public EOY_Progress__c schoolProgress {get; set;}
	public ID EOYrecordType {get;set;}
	
	//passed in parameters
	private String EOYID {get;set;}
	private String activeYear {get;set;}
	private String nextYear {get;set;}
	
	public ID batchID {get;set;}
	public List<Data_Load_Log__c> dataLogs {get; set;}
	public Set<ID> dataLogIDs {get;set;}
	
	public Boolean batchComplete {get;set;}
	public Boolean allEOYCompleted {get;set;}
	private Boolean initializationError {get;set;}
	
	public static String error1 = 'Error! There was a problem with initialzation. Please start from the EOY home page.';
		
	public EOYWiz_SchoolPurgeHistoricalData() {
		schoolProgress = new EOY_Progress__c();
		EOYID = '';
		activeYear = apexPages.currentPage().getParameters().get('activeYear');
		nextYear = apexPages.currentPage().getParameters().get('nextYear');
		
		dataLogs = new List<Data_Load_Log__c>();
		dataLogIDs = new Set<ID>();
		
		batchComplete = true;
		allEOYCompleted = false;
		initializationError = false;
		
		EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
		
		initialize();
	}
	
	private void initialize() {
		getSchoolProgress();
		if(!initializationError) {
			getDataLogs();
			if(schoolProgress.School_Purge_Historical_Data_Completed__c && !enoughDataValidation()) {
				Error_Handling.infoMessage('No data will be purged because you don\'t have old enough data. This step is now complete.');
			}
		}
	} 
	
	public pageReference gotoSchoolPurgeEOYData() {
		pageReference p = new PageReference('/apex/EOYWiz_SchoolPurgeEOYData');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);
		return p;
	}
	
	public pageReference gotoEOYLanding() {
		pageReference p = new pageReference('/apex/EOYWiz_Landing');
		p.setRedirect(true);
		return p;       
	}
	
	public void setLastModified() {
		user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
		String timeZone = UserInfo.getTimeZone().getID();
		schoolProgress.Purge_Historical_Data_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
		try{
			upsert SchoolProgress;
		} catch(Exception e){
			Error_Handling.errorMessage('Failed to updated last modified date:'+e);
		}
		
	}   
	
	public void purgeHistoricalData() {
		if(enoughDataValidation()) {
			Batch_SchoolPurgeHistoricalData batch = new Batch_SchoolPurgeHistoricalData(schoolProgress.Setup__c, null, 0);
			batchID = Database.executeBatch(batch);
			batchComplete = false;
			
			setLastModified();
			
			Error_Handling.infoMessage('Started batch job');
		} else { //there's not enough data to even perform historical data
			Error_Handling.infoMessage('No data will be purged because you don\'t have old enough data. This step is now complete.');
			setLastModified();
			
			Setup__c tSetup = core_SoqlUtils.getSetupById(schoolProgress.Setup__c);
			tSetup.Purged_Two_Years_Old_Data__c = true;
			update tSetup;
			
			getSchoolProgress();
			updateEOYProgress();
				
			allEOYCompleted = allEOYProcessCompleted();
		}
	}   
	
	private void getSchoolProgress() {
		if(!initializationError) {
			EOYID = apexPages.currentPage().getParameters().get('selectedProgress');
			if(EOYID != null) {
				schoolProgress = [SELECT ID, School_Purge_Historical_Data_Completed__c, Purge_Historical_Data_Last_Modified__c, School__c, School__r.Name, Setup__c, Year__c, Year__r.Name__c, Setup__r.Purged_Two_Years_Old_Data__c FROM EOY_Progress__c WHERE ID =: EOYID AND RecordTypeID =: EOYrecordType];   
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
						WHERE Class_Name__c = 'Batch_SchoolPurgeHistoricalData'
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
			Error_Handling.infoMessage('Please Purge Historical Data here.');
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
			allEOYCompleted = allEOYProcessCompleted();
		}
	}
	
	public void updateEOYProgress() {
		schoolProgress.School_Purge_Historical_Data_Completed__c = schoolProgress.Setup__r.Purged_Two_Years_Old_Data__c;
		update schoolProgress;
	}
	
	public Boolean allEOYProcessCompleted() {
		Set<ID> activeSchools = new Set<ID>();
		for(Setup__c s : [SELECT ID, School__c FROM Setup__c WHERE Active__c = true]) {
			activeSchools.add(s.School__c);
		}
		
		for(EOY_Progress__c e : [SELECT ID, School__c, School_Grade_Span_Completed__c, School_Student_Promotional_Completed__c, School_Next_Year_Students_Completed__c, School_Snapshots_Completed__c, School_Process_Data_Completed__c, School_Purge_EOY_Data_Completed__c, School_Purge_Historical_Data_Completed__c, Setup__c, Year__c FROM EOY_Progress__c WHERE School__c IN: activeSchools AND Setup__c != null AND Year__c =: activeYear and RecordType.Name = 'EOY']) {
			//the instance that a school does not have all of the steps completed, return false, else return true;
			if(!(e.School_Grade_Span_Completed__c &&
			   e.School_Student_Promotional_Completed__c &&
			   e.School_Next_Year_Students_Completed__c &&
			   e.School_Snapshots_Completed__c && 
			   e.School_Process_Data_Completed__c &&
			   e.School_Purge_EOY_Data_Completed__c && 
			   e.School_Purge_Historical_Data_Completed__c)
				) {
				return false;
			}
		}
		return true;
	}
	
	private Boolean enoughDataValidation() {
		Picklist_Value__c yearPLV = [SELECT ID FROM Picklist_Value__c WHERE Type__c = 'Time' AND Name='Year' AND RecordType.Name='Time' LIMIT 1];
		List<Time_Element__c> yearList = [SELECT ID, Date_Start_Date__c, End_Date__c, New_School_Year__c, Current__c FROM Time_Element__c WHERE Picklist_Value__c =: yearPLV.ID ORDER BY Date_Start_Date__c DESC];

		return yearList.size() > 3;  
	}   
}
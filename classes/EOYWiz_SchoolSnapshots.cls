public with sharing class EOYWiz_SchoolSnapshots {

	//School Progress
	public EOY_Progress__c schoolProgress {get; set;}
	public String EOYID {get; set;}
	public ID EOYrecordType {get; set;}
	
	public Time_Element__c activeYear {get; set;}
	public Time_Element__c nextYear {get; set;}
	
	public Map<String, ID> summaryRecordTypes {get; set;}
	public Map<String, ID> childRecordTypes {get; set;}
	
	
	private Boolean initializationError {get; set;}
	public Boolean batchComplete {get; set;}
	
	public Map<ID, Snapshot_Log__c> schoolSnapshotLogs {get; set;}
	
	//inefficient but exact
	public transient List<Snapshot_Summary__c> schoolSummary {get; set;}
	public transient List<Snapshot_Summary__c> cohortSummary {get; set;}
	public transient List<Snapshot_Summary__c> studentSummary {get; set;}
	public transient List<Snapshot_Child__c> sectionSummary	{get; set;}
	
	public transient Set<ID> schoolSummarySet {get; set;}
	public transient Set<ID> cohortSummarySet {get; set;}
	public transient Set<ID> studentSummarySet {get; set;}
	
	public List<thousandLimitSummaryWrapper> thousandStudentBlocks {get; set;}
	public List<thousandLimitChildWrapper> thousandSectionBlocks {get; set;}
	private final Integer listLimit = 999;
	
	public List<Data_Load_Log__c> dataLogs {get; set;}
	public Set<ID> dataLogIDs {get; set;}
	private ID batchId;
	private ID cohortBatchId;
	
	public EOYWiz_SchoolSnapshots() {
		schoolProgress = new EOY_Progress__c();
		EOYID = '';
		
		activeYear = new Time_Element__c();
		nextYear = new Time_Element__c();
		dataLogs = new List<Data_Load_Log__c>();
		dataLogIDs = new Set<ID>();

		EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');

		initializationError = false;
		initialize();
	}
	
	private void initialize() {
		populateYearInformation();
		getSchoolProgress();
		if(!initializationError){
			summaryRecordTypes = getSnapshotRecordTypes('Snapshot_Summary__c');
			childRecordTypes = getSnapshotRecordTypes('Snapshot_Child__c');
			isBatchComplete();
			schoolSnapshotLogs = new Map<ID, Snapshot_Log__c>();
		}
	}
	
	public pageReference gotoSchoolNextYearStudents() {
		pageReference p = new pageReference('/apex/EOYWiz_SchoolNextYearStudents');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', (String)activeYear.ID);
		p.getParameters().put('nextYear', (String)nextYear.ID);
		p.setRedirect(true);
		return p;       
	}
	
	public pageReference gotoSchoolProcessData() {
		pageReference p = new pageReference('/apex/EOYWiz_SchoolProcessData');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', (String)activeYear.ID);
		p.getParameters().put('nextYear', (String)nextYear.ID);
		p.setRedirect(true);
		return p;       
	}
	
	public void setLastModified() {
		user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
		String timeZone = UserInfo.getTimeZone().getID();
		schoolProgress.School_Snapshots_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);

		try{
			upsert schoolProgress;
		} catch(Exception e){
			Error_Handling.errorMessage('Failed to updated last modified date:'+e);
		}
		
	}
	
	public void getSchoolProgress() {
		EOYID = apexPages.currentPage().getParameters().get('selectedProgress');        
		if(EOYID != null || EOYID != '') {
			system.debug('eoyID: ' + EOYID);
			schoolProgress = [SELECT ID, School_Snapshots_Completed__c, School_Process_Data_Completed__c, School_Snapshots_Last_Modified__c, School__c, School__r.Name, Setup__c FROM EOY_Progress__c WHERE ID =: EOYID AND Year__c =: activeYear.ID AND RecordTypeID =: EOYrecordType];
		}else{
			//should display an error message here
			initializationError = true;
		}       
	}
	
	private void populateYearInformation() {
		String activeYearID = apexPages.currentPage().getParameters().get('activeYear');
		String nextYEarID = apexPages.currentPage().getParameters().get('nextYear');
		try {
			for(Time_Element__c y : [SELECT ID, Name__c, Date_Start_Date__c, End_Date__c, Current__c, New_School_Year__c FROM Time_Element__c WHERE ID =: activeYearID OR ID =: nextYearID]) {
				if(y.Current__c) {
					activeYear = y;
				} else if(y.New_School_Year__c) {
					nextYear = y;
				}
			}   
		} catch(Exception e) {
			initializationError = true;
		}
	}
	
	private Map<String,Id> getSnapshotRecordTypes(String sType) {
		Map<String,Id> rmap = core_SoqlUtils.getRecordTypesBySobject(sType);
		Map<String,Id> newMap = new Map<String,Id>();
		for (String key : rmap.keySet()) {
			newMap.put(key.replace('_', ' '), rmap.get(key));
		}   
		return newMap;
	}   
	
	//grab parameters from schoolProgress
	public void getSnapshotLogAndSummary() {
		//clear the lists, this gets called to reset the tables with the page actionPoller
		schoolSummary = new List<Snapshot_Summary__c>();
		cohortSummary = new List<Snapshot_Summary__c>();
		studentSummary = new List<Snapshot_Summary__c>();
		sectionSummary = new List<Snapshot_Child__c>();
		ID schoolSummaryID;
		schoolSummarySet = new Set<ID>();
		cohortSummarySet = new Set<ID>();
		studentSummarySet = new Set<ID>();
		
		try {
			schoolSnapshotLogs = new Map<ID, Snapshot_Log__c>([SELECT ID, Is_Final__c, Period_End__c, Period_Start__c, School__c, Setup__c, Snapshot_Taken__c, Snapshot_Type__c FROM Snapshot_Log__c WHERE School__c =: schoolProgress.School__c AND Setup__c =: schoolProgress.Setup__c AND Is_Final__c = true]); 
		}
		catch(Exception e) {
			//we are in big trouble, how did fail the query?
		}
		
		if(schoolSnapshotLogs != null) {
			for(Snapshot_Summary__c summary : 
							[SELECT ID, Name, Average_Class_Size__c, Average_GPA__c, Behavior_Points__c, Cohort__c, Community_Service_Hours__c, 
								Contact__c, Credit_Earned_Career__c, Credit_Earned_YTD__c, Daily_Attendance__c, Excused_Absences__c, Free_Breakfasts__c, 
								Free_Lunches__c, Full_Price_Breakfasts__c, Full_Price_Lunches__c, In_School_Suspension_Days__c, In_School_Suspensions__c, 
								Instructional_Time_Lost__c, Negative_Behavior__c, Neutral_Behavior__c, Out_School_Suspension_Days__c, Out_School_Suspensions__c, 
								Paycheck_Points__c, Positive_Behavior__c, Reduced_Price_Breakfasts__c, Reduced_Price_Lunches__c, Reenrollment_Rate__c, School__c, 
								Snapshot_ID__c, Student__c, Students_droppedout_from_original_List__c, Students_retained_from_original_list__c, 
								Students_transferred_from_Current_Year__c, Students_transferred_from_Original_list__c, Students_withdrawn_from_original_list__c, 
								Student_Teacher_Ratio__c, Summary_Type__c, Total_Count_of_Students_today__c, Total_Original_Students_In_Cohort__c, 
								Total_Students_In_Cohort__c, Unexcused_Absences__c, Unexcused_Tardies__c, RecordTypeID 
							FROM Snapshot_Summary__c 
							WHERE Snapshot_ID__c IN: schoolSnapshotLogs.KeySet() 
							AND (recordTypeID =: summaryRecordTypes.get('Cohort') OR recordTypeID =: summaryRecordTypes.get('School Summary'))]) {
				if(summary.RecordTypeID == summaryRecordTypes.get('School Summary')) {
					schoolSummary.add(summary);
					schoolSummarySet.add(summary.ID);
					if(schoolSummaryID == null) {
						schoolSummaryID = summary.ID;
					}
				}
				else if(summary.RecordTypeID == summaryRecordTypes.get('Cohort')) {
					cohortSummary.add(summary);
					cohortSummarySet.add(summary.ID);
				} else {
					system.debug('*~*~* Unknown recordtype for snapshot summary, summary.RecordTypeID: ' + summary.RecordTypeID);
				}
			}
			getThousandStudentBlocks();
		}
		
		getThousandSectionBlocks(schoolSummaryID);
	}

	public void isBatchComplete(){
		List<Data_Load_Log__c> logs;
		try {
			logs = [SELECT ID, Type__c, Total_Records__c, Status__c, Start_Time__c, Start_Time_Text__c, Setup__c, Setup__r.School__c, Batch_ID__c,
							Setup__r.School__r.Name, Messages__c, Failed_Records__c, End_Time__c, End_Time_Text__c, Class_Name__c, LastModifiedDate
						FROM Data_Load_Log__c 
						WHERE (Class_Name__c = 'BatchSnapshot' OR Class_Name__c = 'Batch_CohortSnapshot') 
						AND Setup__c =: schoolProgress.Setup__c ORDER BY createdDate DESC];
		}
		catch(Exception e) {
			Error_Handling.errorMessage(e.getMessage());
		}

		batchComplete = true;
		if(logs.isEmpty()){
			Error_Handling.infoMessage('Please create school snapshots.');
			return;
		}

		//Currently there are 4 batches linked one after another:
		//Batch_Snapshots -> Batch_SchoolSnapshotSessionCalcs -> Batch_SchoolSnapshotAttendanceCalc -> Batch_CohortSnapshot
		//The first 3 generate 4 logs, the last one generates it's own log with it's own batch id.
		batchID = null;
		boolean hasErrors = false;
		dataLogs = new List<Data_Load_Log__c>();
		for(Data_Load_Log__c d : logs){
			//chorts always run last, so it should be the first log out if it exists
			if(d.Class_Name__c == 'Batch_CohortSnapshot' && batchId == null && cohortBatchId == null){
				cohortBatchId = d.Batch_ID__c;
			} else if(batchId == null && d.Class_Name__c == 'BatchSnapshot'){
				batchId = d.Batch_ID__c;
			}

			if(d.Batch_ID__c != batchID && d.Batch_ID__c != cohortBatchId){
				continue;
			} else {
				if(d.Status__c != 'Completed' && d.Status__c != 'Failed'){
					Error_Handling.infoMessage('The batch is still running');
					batchComplete = false;
				} else if (d.Status__c == 'Failed' && !hasErrors){
					hasErrors = true;
					batchComplete = d.End_Time__c != null;
					Error_Handling.errorMessage('One or more of the batches below have failed. Please review the messages in the table below for assistance in resolving the failure. You may continue with the EOY process if desired.');
				}
				dataLogs.add(d);
			}
		}
		
		if(batchComplete){
			if(!hasErrors)
				Error_Handling.infoMessage('The batch is complete.');
			getSchoolProgress();
			getSnapshotLogAndSummary();
		}
	}

	//we're doing this here because the batches don't have to complete properly to advance. 
	public void updateProgess(){
		schoolProgress.School_Snapshots_Completed__c = true;
		update schoolProgress;
	}
	
	public void getDataLogs() {
		isBatchComplete();
	}
	
	public void deletePreviousSnapshots(){
		List<Snapshot_Summary__c> summaries = [SELECT ID FROM Snapshot_Summary__c WHERE ID IN: schoolSummarySet];
		if(!summaries.isEmpty()){
			delete summaries;
		}
		summaries = null; //clear this just in case we're low on heap.

		for(Snapshot_Summary__c cs : [SELECT ID FROM Snapshot_Summary__c WHERE ID IN: cohortSummarySet]) {
			delete cs;
		}
		for(List<Snapshot_Summary__c> ss : [SELECT ID FROM Snapshot_Summary__c WHERE ID IN: studentSummarySet]) {
			delete ss;
		}

		List<Snapshot_Log__c> logs = [SELECT ID FROM Snapshot_Log__c WHERE ID IN: schoolSnapshotLogs.KeySet() AND Is_FInal__c = TRUE];
		if(!logs.isEmpty()){
			delete logs;
		}	
	}
	
	public void runBatchJob() {
		BatchSnapshot.isFinal = true;
		try{
			BatchSnapshot run = new BatchSnapshot((String)schoolProgress.Setup__c);
			batchID = Database.executeBatch(run, 1);
		}catch(Exception e){
			insert Error_Handling.handleError('','EOYWiz_SchoolSnapshots','An error occured while trying to start the batch.',e);
			Error_Handling.errorMessage('An error occured while trying to start the batch.');
			return;
		}
		
		cohortBatchId = null;
		setLastModified();
		batchComplete = false;
		updateProgess();
		Error_Handling.infoMessage('Started Batch job');
	}
	
	public class thousandLimitSummaryWrapper {
		public transient Snapshot_Summary__c [] summary {get; set;}
		public integer blockNumber {get; set;}
		
		public thousandLimitSummaryWrapper (Snapshot_Summary__c [] sl, Integer i) {
			summary = sl;
			blockNumber = i;
		}
	}
	
	public thousandLimitSummaryWrapper[] getThousandStudentBlocks() {
		thousandStudentBLocks = new thousandLimitSummaryWrapper[] {};
		
		integer counter = 0;
		integer loopcount = 0;
		Snapshot_Summary__c[] local = new Snapshot_Summary__c[] {};    	
		
		for(List<Snapshot_Summary__c> ls : [SELECT ID, Name, Average_Class_Size__c, Average_GPA__c, Behavior_Points__c, Cohort__c, Community_Service_Hours__c, Contact__c, Credit_Earned_Career__c, Credit_Earned_YTD__c, Daily_Attendance__c, Excused_Absences__c, Free_Breakfasts__c, Free_Lunches__c, Full_Price_Breakfasts__c, Full_Price_Lunches__c, In_School_Suspension_Days__c, In_School_Suspensions__c, Instructional_Time_Lost__c, Negative_Behavior__c, Neutral_Behavior__c, Out_School_Suspension_Days__c, Out_School_Suspensions__c, Paycheck_Points__c, Positive_Behavior__c, Reduced_Price_Breakfasts__c, Reduced_Price_Lunches__c, Reenrollment_Rate__c, School__c, Snapshot_ID__c, Student__c, Students_droppedout_from_original_List__c, Students_retained_from_original_list__c, Students_transferred_from_Current_Year__c, Students_transferred_from_Original_list__c, Students_withdrawn_from_original_list__c, Student_Teacher_Ratio__c, Summary_Type__c, Total_Count_of_Students_today__c, Total_Original_Students_In_Cohort__c, Total_Students_In_Cohort__c, Unexcused_Absences__c, Unexcused_Tardies__c, RecordTypeID FROM Snapshot_Summary__c WHERE Snapshot_ID__c IN: schoolSnapshotLogs.KeySet() AND recordTypeID =: summaryRecordTypes.get('Student Summary')]) {
			for(Snapshot_Summary__c s : ls) {
				studentSummarySet.add(s.ID);
				if(counter < listLimit) {
					local.add(s);
					counter++;
				}
				else {
					loopCount++;
					local.add(s);
					thousandStudentBlocks.add(new thousandLimitSummaryWrapper(local, loopCount));
					local = new Snapshot_Summary__c []{};
					counter = 0;
				}	 			
			}
		}

		//DE3554
		loopCount++;
		thousandStudentBlocks.add(new thousandLimitSummaryWrapper(local, loopCount));
			  
		return thousandStudentBlocks; 	    
	}
	
	public class thousandLimitChildWrapper {
		public transient Snapshot_Child__c [] children {get; set;}
		public integer blockNumber {get; set;}
		
		public thousandLimitChildWrapper (Snapshot_Child__c [] sl, Integer i) {
			children = sl;
			blockNumber = i;
		}
	}        
	
	public thousandLimitChildWrapper[] getThousandSectionBlocks(ID schoolSummaryID) {
		thousandSectionBLocks = new thousandLimitChildWrapper[] {};
		
		integer counter = 0;
		integer loopcount = 0;
		Snapshot_Child__c[] local = new Snapshot_Child__c[] {};    	
		String sectionRTID = core_SoqlUtils.getRecordTypesBySobject('Snapshot_Child__c').get('Section');
		if(schoolSummaryID != null) {
			for(List<Snapshot_Child__c> children : [SELECT ID, Name, Section__c, Assigned_Staff__c, Average_GPA__c FROM Snapshot_Child__c WHERE Snapshot_Summary__c =: schoolSummaryID AND RecordTypeID =: sectionRTID]) {		
				for(Snapshot_Child__c s : children) {
					if(counter < listLimit) {
						local.add(s);
						counter++;
					}
					else {
						
						loopCount++;
						local.add(s);
						thousandSectionBlocks.add(new thousandLimitChildWrapper(local, loopCount));
						local = new Snapshot_Child__c []{};
						counter = 0;
					}	 			
				}
			}
		}       
		
		//DE3554   
		loopCount++;
		thousandSectionBlocks.add(new thousandLimitChildWrapper(local, loopCount));
	
		return thousandSectionBlocks; 	    
	}
}
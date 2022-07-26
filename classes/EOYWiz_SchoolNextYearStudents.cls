public with sharing class EOYWiz_SchoolNextYearStudents {
	public EOY_Progress__c schoolProgress {get; set;}
	public ID EOYrecordType {get; set;}

	//passed in parameters
	private String EOYID {get; set;}
	private String activeYear {get; set;}
	private String nextYear {get; set;}

	public List<thousandLimitWrapper> thousandBlocks {get; set;}
	private final Integer listLimit = 999;
	public List<Data_Load_Log__c> dataLogs {get; set;}

	public ID batchID {get; set;}
	public ID logID {get; set;}
	public Boolean batchComplete {get; set;}

	private Boolean initializationError {get; set;}

	public EOYWiz_SchoolNextYearStudents() {
		schoolProgress = new EOY_Progress__c();
		activeYear = apexPages.currentPage().getParameters().get('activeYear');
		nextYear = apexPages.currentPage().getParameters().get('nextYear');
		EOYID = apexPages.currentPage().getParameters().get('selectedProgress');

		dataLogs = new List<Data_Load_Log__c>();

		batchComplete = true;
		initializationError = false;

		EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');

		initialize();
	}

	private void initialize(){
		//load EOY Progress
		getSchoolProgress();
		//populate student list
		getNextYearStudents();
		//load data logs and display status messages
		getDataLogs();
	}

	public pageReference gotoSchoolStudentPromotional() {
		pageReference p = new pageReference('/apex/EOYWiz_SchoolStudentPromotional');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);
		return p;
	}

	public pageReference gotoSchoolSnapshots() {
		pageReference p = new pageReference('/apex/EOYWiz_SchoolSnapshots');
		p.getParameters().put('selectedProgress', EOYID);
		p.getParameters().put('activeYear', activeYear);
		p.getParameters().put('nextYear', nextYear);
		p.setRedirect(true);
		return p;
	}

	public void setLastModified() {
		String timeZone = UserInfo.getTimeZone().getID();
		String userName = UserInfo.getFirstName()+' '+ UserInfo.getLastName();
		schoolProgress.School_Next_Year_Students_Last_Modified__c = userName+' '+dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);

		try{
			upsert schoolProgress;
		} catch(Exception e){
			Error_Handling.errorMessage('Failed to updated last modified date:'+e);
		}
		
	}

	private void getSchoolProgress() {
		if(!initializationError) {
			if(EOYID != null) {
				system.debug('eoyID: ' + EOYID);
				try{
					schoolProgress = [SELECT ID, School_Next_Year_Students_Completed__c, School_Next_Year_Students_Last_Modified__c, School__c, School__r.Name, Setup__c, Setup__r.Students_Created__c, Year__c FROM EOY_Progress__c WHERE ID =: EOYID AND RecordTypeID =: EOYrecordType];
				} catch(System.QueryException e){
					initializationError = true;
					Error_Handling.errorMessage('The system was unable to find a EOY Progress record for your school for the current year. Please start from the EOY home page.');
				}
			} else {
				initializationError = true;
				Error_Handling.errorMessage('Error: There was a problem with initialization. Please start from the EOY home page.');
			}
		}
	}

	public void getNextYearStudents() {
		getThousandBlocks();
	}

	public void getDataLogs(){
		List<Data_Load_Log__c> logs = new List<Data_Load_Log__c>();
		dataLogs = new List<Data_Load_Log__c>();
		try{
			logs = [select id, Type__c, Total_Records__c, Status__c, Start_Time__c, Start_Time_Text__c,
							Setup__c, Setup__r.School__c, Setup__r.School__r.Name, Messages__c, Failed_Records__c,
							End_Time__c, End_Time_Text__c, Class_Name__c, LastModifiedDate, Batch_ID__c
						from Data_Load_Log__c
						WHERE Class_Name__c ='Batch_CreateStudents'
						AND Setup__c =: schoolProgress.Setup__c
						ORDER BY createdDate DESC];
		} catch (System.DMLException e){
			Error_Handling.errorMessage('Failed to get logs from last run.');
		}

		//assume the batch is not running until the logs say otherwise.
		batchComplete = true;
		if(logs.isEmpty()){
			Error_Handling.warningMessage('Please create students for next year here.');
			return;
		}

		//we're only keeping the logs from the last run, so we want the last created batch id.
		if(batchId == null){
			batchID = logs[0].Batch_ID__c;
		}

		boolean hasErrors = false;
		for(Data_Load_Log__c d : logs) {
			if(d.Batch_ID__c != batchID){
				continue;
			} else {
				if(d.Status__c != 'Completed' && d.Status__c != 'Failed'){
					Error_Handling.infoMessage('The batch is still running');
					batchComplete = false;
				} else if (d.Status__c == 'Failed' && !hasErrors){
					hasErrors = true;
					batchComplete = d.End_Time__c != null;
					Error_Handling.errorMessage('One or more of the batches below have failed. Please review the messages in the table below for assistance in resolving the failure. You will not be able to continue until this error is resolved.');
				}
				dataLogs.add(d);
				break;
			}
		}

		if(batchComplete){
			if(!hasErrors)
				Error_Handling.infoMessage('The batch is complete.');
			getSchoolProgress();
			getNextYearStudents();
		}
	}

	public void processNextYearStudent() {
		try{
			Batch_CreateStudents batch = new Batch_CreateStudents(null, (String)schoolProgress.Setup__c, nextYear);
			batchID = Database.executeBatch(batch);
		} catch(Error_Handling.schoolForceException e){
			Error_Handling.errorMessage('The grade span field for your current setup has not been defined. Please define a grade span before continuing.');
			return;
		} catch(Exception e){
			Error_Handling.errorMessage('An error occured while trying to start the batch.');
			return;
		}
		setLastModified();
		batchComplete = false;
		Error_Handling.infoMessage('Started batch job.');
	}

	public class thousandLimitWrapper {
		public Student__c [] students {get; set;}
		public integer blockNumber {get; set;}

		public thousandLimitWrapper (Student__c [] sl, Integer i) {
			students = sl;
			blockNumber = i;
		}
	}

	public thousandLimitWrapper[] getThousandBlocks() {
		thousandBLocks = new thousandLimitWrapper[] {};

		integer counter = 0;
		integer loopcount = 0;
		Student__c[] local = new Student__c[] {};

		Set<String> studentIDs = new Set<String>();
		for(Student__c s : [SELECT ID, Student_ID__c, School_Year__c FROM Student__c WHERE Setup__c =: schoolProgress.Setup__c]) {
			studentIDs.add(s.Student_ID__c);
		}

		for(List<Student__c> ls : [SELECT ID, Student_ID__c, Name, School_Year__c, School_Year__r.Name__c, School__c, Grade__c FROM Student__c WHERE School_Year__c =: nextYear AND Student_ID__c IN: studentIDs]) {
			for(Student__c s : ls) {
				if(counter < listLimit) {
					local.add(s);
					counter++;
				}
				else {
					loopCount++;
					local.add(s);
					thousandBlocks.add(new thousandLimitWrapper(local, loopCount));
					local = new Student__c []{};
					counter = 0;
				}
			}
		}

		loopCount++;
		thousandBlocks.add(new thousandLimitWrapper(local, loopCount));

		return thousandBlocks;
	}
}
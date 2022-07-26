global with sharing class Gradebook_RunReportCardsController {
	/* PAGE CONTROLS */
	//represents the page being on the home page
	public boolean bHome				{get;set;}
	//represents the page being on the GPA batch page
	public boolean bGPA					{get;set;}
	//represenets the page being on the document generation page
	public boolean bDoc					{get;set;}
	//represents the page being on the schedule generation page
	public boolean bSched				{get;set;}
	//represents the generation page being in search mode
	public boolean bSearch				{get;set;}
	//represents whether this generation is in student mode
	//the only time this will be false is when staff schedules are generated
	public boolean bStudent						{get;set;}
	//used by the section/school level student filter to store the 
	public String selectedSectionSchool	{get;set;}
	//used by the school level student filter, it keeps a copy of the selected document type
	public String optionDocument		{get;set;}

	/*GPA BATCH CONTROLS*/
	//sent to the GPA batch, it toggles the final flag for final grades
	public boolean bIsFinal				{get;set;}
	//this holds the current/past batch jobs for display on the status list
	public List<AsyncApexJob> gpaJobs	{get;set;}

	/*DOCUMENT OPTIONS*/
	//used during generation, this toggles the show in portal field on student reporting periods
	public boolean bShowInPortal					{get;set;}
	//used to filter students, this adds inactive students to the generation list
	public boolean bIncludeInactiveStudents			{get;set;}
	//sent to the report card controller, this adds inactive student sections to generated cards
	public boolean bIncludeInactiveStudentSections	{get;set;}
	//sent to the report card controller, this adds student sections have have section grades, but are inactive
	public boolean bIncludeTransferedSections		{get;set;}
	
	//list of all reporting periods in use by schools
	//used to build javascript map to prepopulate start and end dates
	public List<String> reportingPeriods			{get;set;}

	/* DOCUMENT GENERATION */
	private Integer lastGeneratedCount = 0;
	private String baseStudentQuery = 'SELECT id, Individual__c, Name, Grade__c,Home_Language__c,Setup__c,Setup__r.Year__r.Name__c,School__r.Name,Student_Last_Name__c,Student_ID__c FROM Student__c';
	private String baseStaffQuery = 'SELECT id, Name, Organization__c, Organization__r.Name, ID__c, Staff_Last_Name__c, Reference_Id__c FROM Staff__c';


	/*DOCUMENT WRAPPERS */
	//holds the list of schools displayed on the generation page
	public List<Gradebook_RunReportCardsWrapper.schoolWrapper> schools					{get;set;}
	//list of sections used by the section modal
	public List<Gradebook_RunREportCardsWrapper.sectionWrapper> sectionDisplayWrapper	{get;set;}
	//field wrapper for the school level filter options
	public Student__c searchOptionWrapper												{get;set;}
	//field wrapper for the student level search filter
	public Student__c studentSearchWrapper												{get;set;}
	//field wrapper for the staff level search filter
	public Staff__c staffSearchWrapper												{get;set;}
	//holds the set of students to generate
	public List<Gradebook_RunReportCardsWrapper.personWrapper> peopleToGenerate		{get;set;}
	//the students returned by the student search
	public List<Gradebook_RunReportCardsWrapper.personWrapper> searchResults			{get;set;}
	private Map<ID, Time_Element__c> rpMap;

	/* SINGLE STUDENT GENERATION */
	//denotes that the controller is for single student generation
	public boolean bSingle												{get;set;}
	public List<Student_Reporting_Period__c> studentReportingPeriods	{get;set;}
	public String selectedReportingPeriod								{get;set;}
	public String lastTranscript										{get;set;}


	/*AWS INFORMATION */
	private S3.AmazonS3 as3; //used to communicate data to the S# servers
	public boolean useS3 {get;set;} //has AS3 been setup?
	private Set<String> bucketNames; //list of all current buckets
	private String ownerID; //the owner id of the AS3 instance.

	/*GENERATION HELPERS*/
	private boolean oneWithErrors = false;
	private Set<ID> selectedPeople;
	private Document_Log__c log;
	private Set<String> exceptionBuckets = new Set<String>();

	public Gradebook_RunReportCardsController(){
		gotoHome();
		bIsFinal = false;
		bSingle = false;
	}

	/* ACTION METHODS */
	public void gotoHome(){
		bHome = true;
		bGPA = false;
		bDoc = false;
		bSched = false;
		bSearch = false;
		bStudent = true;
	}

	public void gotoGPA(){
		bHome = false;
		bGPA = true;
		refreshJobInfo();
	}

	public void gotoDocumentGeneration(){
		bHome = false;
		bDoc = true;

		setupDocumentGeneration();
	}
	
	public void gotoScheduleGeneration(){
		bHome = false;
		bSched = true;
		
		setupDocumentGeneration();
	}

	public void runGPA(){
		Gradebook_Final_GPA_Batch b = new Gradebook_Final_GPA_Batch();
		b.query = 'Select ID, Setup__c ,Setup__r.Term__c from Student__c where Active__c = true AND setup__c !=null ';
		b.isFinal = bIsFinal;
		b.showInPortal = false;
		string jobid = database.executeBatch(b,1); //Only do 1 student at a time
		refreshJobInfo();
	}

	public void refreshJobInfo(){
		ID gpaBatchClassID = [select id from ApexClass where Name LIKE '%Final_GPA_Batch' limit 1].id;
		gpaJobs = new List<AsyncApexJob>(); //initalize the list to prevent NPE if query returns 0
		gpaJobs = [select id,CompletedDate,Status,TotalJobItems,NumberOfErrors,JobItemsProcessed,CreatedDate
					from AsyncApexJob
					where ApexClassId =:gpaBatchClassID
					and JobType = 'BatchApex' //each batch call generates two entries, the batch, and the batch worker
					and (CompletedDate >=: system.today() or CompletedDate = null)
					order by CreatedDate desc
					limit 5];
	}

	public void includeInactiveSetups(){
		try{
			writelog('Loading inactive setups.');
			loadSchools(false,bDoc,null);
		} catch (Exception e){
			schools = new List<Gradebook_RunReportCardsWrapper.schoolWrapper>();
			errorMessage('A critical exception occured while loading school information. See the document log for more information.','FATAL:'+e.getTypeName()+':'+e.getStackTraceString());
		}
		saveLog();
	}

	public void showCurrentSections(){
		for(Gradebook_RunReportCardsWrapper.schoolWrapper s:schools){
			if(selectedSectionSchool == s.recordID){
				s.loadSections();
				if(s.sections.isEmpty()){
					sectionDisplayWrapper = new List<Gradebook_RunReportCardsWrapper.sectionWrapper>();
					errorMessage('There are no sections available for this setup.',null);
				} else {
					sectionDisplayWrapper = s.sections;
				}
				break;
			}
		}
	}

	public void hideCurrentSections(){
		for(Gradebook_RunReportCardsWrapper.schoolWrapper s:schools){
			if(selectedSectionSchool == s.recordID){
				s.sections = sectionDisplayWrapper;
				sectionDisplayWrapper = new List<Gradebook_RunReportCardsWrapper.sectionWrapper>();
				break;
			}
		}
		system.debug(schools[0].searchOptionWrapper.Setup__r.Id);
	}

	public void loadAdditionalOptions(){
		for(Gradebook_RunReportCardsWrapper.schoolWrapper s:schools){
			if(selectedSectionSchool == s.recordID){
				searchOptionWrapper = s.searchOptionWrapper;
				optionDocument = s.selectedDocument;
				break;
			}
		}
	}

	public void saveAdditionalOptions(){
		for(Gradebook_RunReportCardsWrapper.schoolWrapper s:schools){
			if(selectedSectionSchool == s.recordID){
				s.searchOptionWrapper = searchOptionWrapper;
				break;
			}
		}
	}

	public void startSearch(){
		toggleSearch(true);
	}
	
	public void exitSearch(){
		toggleSearch(false);
	}
	
	private void toggleSearch(boolean toggle){
		bSearch = toggle;
		peopleToGenerate = new List<Gradebook_RunReportCardsWrapper.personWrapper>();
		studentSearchWrapper = new Student__c();
		staffSearchWrapper = new Staff__c();
	}

	public void removeStudentsFromGeneration(){
		List<Gradebook_RunReportCardsWrapper.personWrapper> holder = new List<Gradebook_RunReportCardsWrapper.personWrapper>();
		for(Gradebook_RunReportCardsWrapper.personWrapper sw:peopleToGenerate){
			if(!sw.selected){
				holder.add(sw);
			} else {
				selectedPeople.remove((bStudent?sw.student.id:sw.staff.id));
			}
		}
		peopleToGenerate = holder;
	}

	public void addStudentsToGeneration(){
		for(Gradebook_RunReportCardsWrapper.personWrapper sw:searchResults){
			if(sw.selected && !selectedPeople.contains((bStudent?sw.student.id:sw.staff.id))){
				if(selectedPeople.size()<1000){
					sw.selected = false;
					peopleToGenerate.add(sw);
					selectedPeople.add((bStudent?sw.student.id:sw.staff.id));
				} else {
					infoMessage('You have selected more then 1000 '+(bStudent?'students':'staff')+' to generate. Only the first 1000 '+(bStudent?'students':'staff')+' will be generated.',null);
				}
			}
		}
	}

	public void searchPeople(){
		searchResults = new List<Gradebook_RunReportCardsWrapper.personWrapper>();
		List<sObject> people = queryPeople();
		if(people == null){
			return;
		} else if (people.isEmpty()){
			errorMessage('Your search did not return any results. Please refine your search and try again.',null);
		} else {
			for(sObject s: people){
				if(bSearch){
					if(bStudent) searchResults.add(new Gradebook_RunReportCardsWrapper.personWrapper((Student__c) s));
					else  searchResults.add(new Gradebook_RunReportCardsWrapper.personWrapper((Staff__c) s));
				} else {
					if(bStudent) peopleToGenerate.add(new Gradebook_RunReportCardsWrapper.personWrapper((Student__c) s));
					else  peopleToGenerate.add(new Gradebook_RunReportCardsWrapper.personWrapper((Staff__c) s));
					selectedPeople.add((ID) s.get('id'));
				}
			}
		}
	}

	public void startGeneration(){
		if(bSingle){
			Gradebook_RunReportCardsWrapper.personWrapper student = peopleToGenerate[0];
			Gradebook_RunReportCardsWrapper.schoolWrapper school = schools[0];
			if(school.selectedDocument != 'Transcript'){
				for(Student_Reporting_Period__c srp:studentReportingPeriods){
					if(srp.id == selectedReportingPeriod){
						student.srp = srp;
					}	
				}
				
				student.log = setupDocumentLog(student, school.selectedDocument, student.srp.id, student.srp.Time__r.Name__c);
			} else {
				student.log = setupDocumentLog(student, school.selectedDocument, null, null);
			}
			insert student.log;
			system.debug(student.log);
			peopleToGenerate[0] = student;
		} else {
			//if we're generating without selecting, then we need to load the kids.
			if(!bSearch) searchPeople();
			//view state saver
			searchResults = new List<Gradebook_RunReportCardsWrapper.personWrapper>();
				
			if(peopleToGenerate.isEmpty()){
				ApexPages.getMessages().clear();
				errorMessage('No '+(bStudent?'students':'staff')+' were eligible for generation using the current filters. Please refine your filters and try again.',null);
				return;
			}
			
			try{
				setupStudentReportingPeriods();
			} catch (Exception e){
				peopleToGenerate.clear();
				errorMessage('An unexpected error occured when trying to setup the batch. Please see the log for more information.','FATAL:'+e.getMessage() +':'+ e.getStackTraceString());
				saveLog();
			}
		}
	}

	public void generateBatch(){
		List<String> documentNames = new List<String>();
		Map<String, Attachment> documentMap = new Map<String, Attachment>();
		Integer startingPoint = lastGeneratedCount;
		List<Gradebook_RunReportCardsWrapper.personWrapper> processedStudents = new List<Gradebook_RunReportCardsWrapper.personWrapper>();
		Map<ID,Gradebook_RunReportCardsWrapper.schoolWrapper> schoolMap = getSchoolWrapperMap();
		//This process once had limits based one the callouts, but with changes to the callout limits, as well as
		//the conversion of getContentAsPDF in Summer 15, we're removing them, and going with a flat 10 per batch
		while(lastGeneratedCount-startingPoint <= 9 && lastGeneratedCount < peopleToGenerate.size()){ //limit to sets of 10 when S3 being disabled would allow for more
			Gradebook_RunReportCardsWrapper.personWrapper student = peopleToGenerate[lastGeneratedCount];
			string bucketName;
			if(useS3){
				bucketName = checkbucketName(schoolMap.get((bStudent?student.student.School__c:student.staff.Organization__c)));
				//if the system couldn't create a new bucket because it was too close to the callout limit
				if(bucketName == '-1')
					break;
				//if the system created the bucket, but we need to start over to verify callout limits
				else if(bucketName == '0')
					continue;
			}
			
			//US2929 - Need to generate english cards when generating spanish cards
			boolean generateEnglishCard = false;
			if(bStudent) generateEnglishCard = (student.student.Home_language__c!= null && student.student.Home_Language__c.contains('Spanish')) && (!student.log.Document_Type__c.contains('Transcript') && !student.log.Document_Type__c.contains('Schedule'));

			PageReference pdfPage = generateDocReference(student, false, (bStudent ? schoolMap.get(student.student.School__c) : schoolMap.get(student.staff.Organization__c)));
			Attachment document = generateDocument(student, pdfPage);

			if(useS3 && document != null && bucketNames.contains(bucketName)){
				student.log.Transmitted_to_S3__c = uploadToS3(document, bucketName, student.log);
			}

			documentNames.add(document.Name);
			documentMap.put((bStudent?student.student.id:student.staff.id), document);
			if(student.srp != null){
				student.srp.Most_Recent_Document_Created__c = student.log.Document_Type__c;
			}

			if(generateEnglishCard){
				//EE 6/13 pdf doesn't need school wrapper b/c Schedule generation should never hit this section
				pdfPage = generateDocReference(student, true, null);
				document = generateDocument(student, pdfPage);
				document.Name = document.Name.replace('.pdf','.English.pdf');
				documentNames.add(document.Name);
				documentMap.put(student.student.id+'English', document);
			}
			lastGeneratedCount++;
			processedStudents.add(student);
		}
		
		//static variables don't actually carry over between this page and the report cards
		//page, so I've found a way to "trick" the report cards page into inserting the logs,
		//but now we have to requery for them.
		Map<ID, Document_Log__c> logMap = new Map<ID, Document_Log__c>();
		Set<String> docSet = documentMap.keySet();
		ID logID = log.id;

		String docLogQuery = 'select id, Status__c, Student__c, Staff__c, Error_Message__c,Document_Type__c, Student__r.School__c, Staff__r.Organization__c from Document_Log__c where (Student__c IN:docSet OR Staff__c IN :docSet)';
		if(!bSingle)
			docLogQuery += ' and Document_Log__c =: logId';
		else{
			docLogQuery += ' order by createdDate desc limit 1';
		}
		for(Document_Log__c d:Database.query(docLogQuery)){
			system.debug(d);
			if(bSched){
				d.Status__c = 'Complete';
			}
			logMap.put((bStudent?d.Student__c:d.Staff__c), d);
		}

		//cards replace their old versions, so we need to find those ids
		for(Attachment a:[select id, Name, ParentID from Attachment where Name IN: documentNames]){
			//the error checking here is mostly to prevent null pointers if student ids change
			if(a.Name.contains('.English.pdf')){
				if(documentMap.containsKey(a.ParentID+'English'))
					documentMap.get(a.ParentID+'English').ID = a.id;
			} else if(documentMap.containsKey(a.ParentID)) {
				documentMap.get(a.ParentID).ID = a.id;
			}
		}
		
		upsert documentMap.values();
		
		List<Student_Reporting_Period__c> srps = new List<Student_Reporting_Period__c>();
		List<Document_Log__c> logs = new List<Document_Log__c>();
		String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
		//process everything and ready for inserting
		for(Gradebook_RunReportCardsWrapper.personWrapper student:processedStudents){
			Document_Log__c cardLog = logMap.get((bStudent?student.student.id:student.staff.id));
			cardLog.Name = student.log.Name;

			if(useS3 && student.log.Transmitted_to_S3__c == false){
				cardLog.Error_Message__c += student.log.Error_Message__c;
				cardLog.Status__c = 'Complete - With Warnings';
			} else if(useS3) {
				cardLog.Transmitted_to_S3__c = true;
			}
			oneWithErrors = cardLog.Status__c.contains('Warnings')||cardLog.Status__c.contains('Failed')||oneWithErrors;
			student.log = cardLog;
			
			student.attachmentID = documentMap.get((bStudent?student.student.id:student.staff.id)).id;
			if(student.srp != null){
				student.srp.Attachment_ID__c  = student.attachmentID;
				if(student.srp.Most_Recent_Document_Created__c != 'Transcript'){
					//EE 6/13 don't touch these fields during schedule creation
					if(!bSched){
						if(student.srp.Most_Recent_Document_Created__c.contains('Card') || student.srp.Most_Recent_Document_Created__c.contains('Schedule'))
							student.srp.Attachment_Link__c = baseURL + '/' + student.srp.Attachment_ID__c;
						else
							student.srp.Latest_Progress_Report__c = baseURL + '/' + student.srp.Attachment_ID__c;
						student.srp.Show_In_Portal__c = bShowInPortal;
						student.srp.Report_Card_Created__c = true;
					}
					srps.add(student.srp);
				}
			} else if(bSingle) {
				lastTranscript = student.attachmentID;
			}
			logs.add(student.log);
		}

		if(srps.size()>0) upsert srps;
		if(logs.size()>0) upsert logs;

		//now that we've updated the logs, we need to blank the error messages out. It takes too much memory to keep in storage.
		for(Gradebook_RunReportCardsWrapper.personWrapper student:processedStudents){
			student.log.Error_Message__c = null;
		}

		if(lastGeneratedCount == peopleToGenerate.size()){
			log.Status__c = (oneWithErrors)?'Complete - With Warnings':'Complete';
		}
		if(!bSingle){
			saveLog();
		} else {
			if(schools[0].selectedDocument != 'Transcript') {
				for(Student_Reporting_Period__c srp:studentReportingPeriods){
					if(srp.id == selectedReportingPeriod){
						srp = processedStudents[0].srp;
					}
				}
			}
			lastGeneratedCount = 0;
			if(processedStudents[0].log.Status__c == 'Complete'){
				infoMessage('The document was generated successfully', null);
			} else if(processedStudents[0].log.Status__c == 'Complete - With Warnings'){
				warningMessage('The document was generated successfully, but contains warnings.');
			} else if (processedStudents[0].log.Status__c == 'Failed'){
				errorMessage('The document failed to generate.', null);
			}
		}
	}

	public void abortBatch(){
		List<Document_Log__c> logs = new List<Document_Log__c>();
		for(Integer i=lastGeneratedCount;i<peopleToGenerate.size();i++){
			peopleToGenerate[i].log.Status__c = 'Aborted';
			logs.add(peopleToGenerate[i].log);
		}
		upsert logs;
		log.Status__c = 'Aborted';
		saveLog();
	}

	public void cleanup(){
		if(bSched){
			//EE 6/19 delete all child logs to save space
			List<Document_Log__c> logs = new List<Document_Log__c>();
			for(Gradebook_RunReportCardsWrapper.personWrapper person: peopleToGenerate)
				logs.add(person.log);
			delete logs;
		}
		peopleToGenerate = new List<Gradebook_RunReportCardsWrapper.personWrapper>();
		selectedPeople = new Set<ID>();
		lastGeneratedCount = 0;
		setupLog();
	}

	public void setupSingleGeneration(){
		bSingle = true;
		bDoc = true;
		setupLog(); //this isn't really used, just no NPEs then
		useS3 = setupAS3();
		ID studentID = ApexPages.currentPage().getParameters().get('student');
		Student__c student = Database.query(baseStudentQuery+' WHERE ID =: studentID');

		studentReportingPeriods = Gradebook_ReportCard_Utils.getStudentReportingPeriodList(new Set<ID>{studentID}, null);
		Setup__c setup = Gradebook_ReportCard_Utils.getSetupInfo(student.Setup__c);
		loadSchools(null,bDoc,setup);
		if(schools.size()>0){
			schools[0].selectedDocument = schools[0].allowedDocuments[0].getValue();
			schools[0].selected = true;
		}
		peopleToGenerate = new List<Gradebook_RunReportCardsWrapper.personWrapper>{new Gradebook_RunReportCardsWrapper.personWrapper(student)};
		List<Attachment> transcripts = [select id from Attachment where ParentID =: student.ID and Name LIKE '%Transcript%' order by CreatedDate limit 1];
		if(!transcripts.isEmpty())
			lastTranscript = transcripts[0].id;
	}

	/* HELPER METHODS */
	private void setupDocumentGeneration(){
		setupLog();
		if(useS3 == null)
			useS3 = setupAS3();
		
		bShowInPortal = false;
		bIncludeInactiveStudents = false;
		bIncludeInactiveStudentSections = false;
		bIncludeTransferedSections = false;
		
		selectedPeople = new Set<ID>();
		peopleToGenerate = new List<Gradebook_RunReportCardsWrapper.personWrapper>();

		try{
			loadSchools(true,bDoc,null);
		} catch (Exception e){
			schools = new List<Gradebook_RunReportCardsWrapper.schoolWrapper>();
			errorMessage('A critical exception occured while loading school information.See the document log for more information.','FATAL:'+e.getTypeName()+':'+e.getStackTraceString());
			saveLog();
		}			
	}

	private boolean setupAS3(){
		boolean isSetup = true;
		bucketNames = new Set<String>();
		try{
			S3_Credentials_Name__c serverName = S3_Credentials_Name__c.getOrgDefaults();
			if((serverName == null || serverName.server_Name__c==null) && !Test.isRunningTest()){
				infoMessage('No AS3 server information has been found.','Setup of AS3 has failed: No AS3 server information found.');
				return false;
			}
			String serverCredName = serverName.server_Name__c;

			
			AWSKeys credentials;
			try {
				credentials = new AWSKeys(serverCredName);
			} catch (AWSKeys.AWSKeysException e){
				infoMessage('Error connecting to AS3 server.','Setup of AS3 has failed: No login information matches the provided server name. Please make sure the name of the server matches the name of an AWSKey record and that the key and secret have values.');
				isSetup = false;
			}

			//don't make the callouts if we're running tests
			if(!test.isRunningTest() && isSetup){	
				as3 = new S3.AmazonS3(credentials.key,credentials.secret);

				S3.ListAllMyBucketsResult allBuckets;
				try {
					allBuckets = as3.ListAllMyBuckets(as3.key,Datetime.now(),as3.signature('ListAllMyBuckets',Datetime.now()));
					writelog('AS3 communication successful. Login information is correct.');
				} catch (System.CalloutException e){
					infoMessage('Login to AS3 failed.','Setup of AS3 has failed: Unable to login to AS3 with the given credentials. Check the AS3 login information.');
					isSetup = false;
				}
				
				if(isSetup){
					S3.ListAllMyBucketsList bucketList = allBuckets.Buckets;
					OwnerId = allBuckets.Owner.Id;
					S3.ListAllMyBucketsEntry[] buckets = bucketList.Bucket;

					if(buckets!=null){
						for(S3.ListAllMyBucketsEntry bucket: buckets){
							writeLog('Found AS3 bucket'+bucket.name);
							bucketNames.add(bucket.name);
						}
					}
				}
			} else if(test.isRunningTest()){
				bucketNames.add('Test');
			}
		} catch (Exception e){
			infoMessage('An unexpected exception occurred while setting up the AS3 connection. See the document log for more information.', 'Unexpected exception in AS3 setup: '+e.getTypeName()+':'+e.getMessage());
		}
		if(!isSetup)
			infoMessage('Setup of AS3 has failed. Documents will not be uploaded to AS3.',null);
		else{
			log.Transmitted_to_S3__c = true;
			infoMessage('AS3 setup complete. Documents will be transmitted to AS3.','AS3 setup complete. Documents will be transmitted to AS3.');
		}
		//unit tests should always return true
		return isSetup||Test.isRunningTest();
	}

	private void loadSchools(boolean filterInactive, boolean checkDocuments, Setup__c singleSetup){
		List<Setup__c> setups;
		if(!bSingle) setups = Gradebook_ReportCard_Utils.getDocumentSchools(filterInactive);
		else setups = new List<Setup__c>{singleSetup};
		Set<Id> termIds = new Set<ID>();
		for(Setup__c s:setups){
			if(checkDocuments && s.Evaluation_Documents__c==null){
				writeLog('Setup with ID '+s.id+' was excluded because there are no document types selected.');
			}
			else termIds.add(s.Term__c);
		}
		rpMap = new Map<ID, Time_Element__c>();
		Map<ID, List<Time_Element__c>> termRPMap = new Map<ID, List<Time_Element__c>>();
		for(Time_Element__c rp:Gradebook_ReportCard_Utils.getReportingPeriods(termIDs)){
			rpMap.put(rp.id, rp);
			if(termRPMap.containsKey(rp.Parent_Time_Element__c)){
				termRPMap.get(rp.Parent_Time_Element__c).add(rp);
			} else {
				termRPMap.put(rp.Parent_Time_Element__c, new List<Time_Element__c>{rp});
			}
		}
		reportingPeriods = Gradebook_ReportCard_Utils.populateTimeList(rpMap);

		schools = new List<Gradebook_RunReportCardsWrapper.schoolWrapper>();
		for(Setup__c s:setups){
			if(termRPMap.containsKey(s.Term__c)){
				if(!checkDocuments || (checkDocuments && s.Evaluation_Documents__c != null))
					schools.add(new Gradebook_RunReportCardsWrapper.schoolWrapper(s,bDoc,termRPMap.get(s.Term__c)));
			} else {
				writeLog('Setup with ID '+s.id+' was excluded because no valid reporting periods were found for its term.');
			}
		}

		if(schools.isEmpty()){
			errorMessage('No valid setups were found. Please check your configuration.','Error: All setups have been excluded. Please check there are Evaluation Documents listed on your setup record.');
		}
	}

	private List<sObject> queryPeople(){
		boolean schoolSelected = false;
		boolean hasError = false;
		Set<ID> transcriptSetups = new Set<ID>();
		Set<ID> selectedSections = new Set<ID>();
		Set<ID> allSectionSetups = new Set<ID>();
		List<Student__c> selectedStudentFilters = new List<Student__c>();
		List<Staff__c> selectedStaffFilters = new List<Staff__c>();

		//We need to know which schools to query students for
		for(Gradebook_RunReportCardsWrapper.schoolWrapper sw:schools){
			if(sw.selected){
				schoolSelected = true;
				if(bStudent) selectedStudentFilters.add(sw.searchOptionWrapper);
				else selectedStaffFilters.add(sw.staffOptionWrapper);
				if(sw.selectedDocument == 'Transcript'){
					transcriptSetups.add(sw.setup.id);
				}
				if(sw.selectedDocument == 'Schedule' && sw.selectedTime == 'all'){
					Date startDate = Date.parse(sw.startDate);
					Date endDate = Date.parse(sw.endDate);
					if(startDate > endDate){
						errorMessage('The Start Date is after the End Date for '+sw.displayName+'.  Please correct these fields before proceeding.',null);
						hasError = true;
					}
				}
				//allSectionSetups will be populated with setup IDs for students and school IDs for staff
				getSectionQueryData(sw,selectedSections,allSectionSetups);
			}
		}

		if(!schoolSelected || hasError){
			if(!schoolSelected) errorMessage('You must select at least one school.',null);
			return null;
		}
		Set<ID> peopleIDs = new Set<ID>();
		if(!selectedSections.isEmpty()){
			if(bStudent) peopleIDs = queryStudentSections(selectedSections, selectedStudentFilters);
			else peopleIDs = queryStaffSections(selectedSections, selectedStaffFilters);
		}

		/*
			1. Include all the students identifed as part of the section filters. These have already been filtered so the set should only contain valid students.
			2. If they selected all the sections, then just include all the kids for that setup. This is a bit 
			questionable as it could also include students that have no student sections, but that case is a bit extreme (they're in the system, but don't attend class?).
			3. Transcript schools get the same treatment as their multi-year status means that you may want to be able to generate transcripts for kids that might not have scheduled yet (during start of year).
			4. Then the school level filters go in. There is one filter set for each selected school.
			5. The specific student filters if bSearch = true
		*/
		String query= (bStudent ? baseStudentQuery : baseStaffQuery)+
				' WHERE (ID IN: peopleIDs';//1
		//2
		if(!allSectionSetups.isEmpty()){
			if(bStudent) query+=' OR Setup__c IN: allSectionSetups';
			else query+=' OR Organization__c IN: allSectionSetups';
		}
		//3
		if(!transcriptSetups.isEmpty()){
			query+= ' OR (Setup__c IN: transcriptSetups AND Individual__r.Student__c != null)';
		}
		query += ')' + ((bIncludeInactiveStudents)?'':' AND Active__c=true');
		query += ' AND ID NOT IN: selectedPeople';
		
		//4
		if(!bSearch){
			string schoolFilters;
			if(bStudent) schoolFilters = buildSchoolFilter(selectedStudentFilters);
			else schoolFilters = buildSchoolFilter(selectedStaffFilters);
			if(schoolFilters != ''){
				query += ' AND ('+schoolFilters+')';
			}
		}
		//5
		if(bSearch){
			if(bStudent) query += buildQueryFieldSet(studentSearchWrapper, false);
			else query += buildQueryFieldSet(staffSearchWrapper,false);
		}
		query += ' order by '+(bStudent ?'School__c':'Organization__c')+', Name LIMIT 1001';
		log.Query__c +=(bStudent?'Student Search: ':'Staff Search: ')+query+'\n';
		saveLog();
		system.debug('~~~~~ query: '+query);

		List<sObject> people = Database.query(query);
		if(people.size() == 1001){
			if(bSearch)
				infoMessage('Your search returned more then 1000 results. Only the first 1000 are displayed.',null);
			else
				infoMessage('The total number of '+(bStudent?'students':'staff')+' returned using your options exceeds 1000. Only the first 1000 '+(bStudent?'students':'staff')+' will be generated.',null);
			people.remove(1000);
		}
		return people;
	}

	private Set<ID> queryStudentSections(Set<ID> selectedSections, List<Student__c> filters){
		Set<ID> studentIDs = new Set<ID>();
		String query=
			'select id, Student__c'+
			' from Student_Section__c'+
			' where Section__c IN: selectedSections'+
			//exclude inactive SS, but if we want inactive kids, then we want inactive SS too
			(((bIncludeInactiveStudentSections && !bIncludeInactiveStudents)||bIncludeInactiveStudents)?'':' AND Active__c = true');
			query += ' AND Student__c NOT IN: selectedPeople';
		//this is why I modualized the filters so I could basically use one set of code to make the filter
		//sets for both the students and the student sections
		if(!bSearch){
			String schoolFilter = buildSchoolFilter(filters).replace('AND ', 'AND Student__r.').replace('Setup__c', 'Student__r.Setup__c');
			if(schoolFilter != '')
				query += ' AND ('+schoolFilter+')';
		}

		if(bSearch){
			query += buildQueryFieldSet(studentSearchWrapper, false).replace('AND ','AND Student__r.');
		}
		log.Query__c += 'Student section query: ' + query + '\n';
		saveLog();
		system.debug(query);
		for(Student_Section__c ss:Database.query(query)){
			studentIds.add(ss.Student__c);
		}
		return studentIDs;
	}
	
	private Set<ID> queryStaffSections(Set<ID> selectedSections, List<Staff__c> filters){
		Set<ID> staffIDs = new Set<ID>();
		String query = 'Select id, Staff__c FROM Staff_Section__c WHERE Section__c IN :selectedSections AND Is_Active__c=true AND Staff__c NOT IN :selectedPeople';
		if(!bSearch){
			String schoolFilter = buildSchoolFilter(filters);
			if(schoolFilter!='') query += ' AND ('+schoolFilter+')';
		}
		else{
			query += buildQueryFieldSet(staffSearchWrapper,false);
		}
		log.Query__c += 'Staff section query: '+query+'\n';
		saveLog();
		system.debug(query);
		for(Staff_Section__c ss: database.query(query)) staffIDs.add(ss.Staff__c);
		return staffIDs;
	}

	private String buildSchoolFilter(List<Student__c> selectedSearchFilters){
		String schoolFilterQuery = '';
		for(Student__c s:selectedSearchFilters){
			if(s.Setup__r.ID != null){
				String fieldFilters = buildQueryFieldSet(s, true);
				//this check is a performance boost for the query. Adding all these OR sub-conditions slows it down alot.
				if(fieldFilters != ''){
					schoolFilterQuery += (schoolFilterQuery == '')?'(':' OR (';
					schoolFilterQuery += 'Setup__c = \''+s.Setup__r.ID+'\'';
					schoolFilterQuery += fieldFilters;
					schoolFilterQuery += ')';
				}
			}
		}
		return schoolFilterQuery;
	}
	
	private String buildSchoolFilter(List<Staff__c> selectedSearchFilters){
		String schoolFilterQuery = '';
		for(Staff__c s:selectedSearchFilters){
			String fieldFilters = buildQueryFieldSet(s, true);
			//this check is a performance boost for the query. Adding all these OR sub-conditions slows it down alot.
			if(fieldFilters != ''){
				schoolFilterQuery += (schoolFilterQuery == '')?'(':' OR (';
				schoolFilterQuery += 'Organization__c = \''+s.Organization__c+'\'';
				schoolFilterQuery += fieldFilters;
				schoolFilterQuery += ')';
			}
		}
		return schoolFilterQuery;
	}

	private String buildQueryFieldSet(Student__c s, boolean schoolLevel){
		String query = '';

		query += ((s.Alternate_Language__c)?' AND Alternate_Language__c=true':'');
		query += ((s.Gifted__c)?' AND Gifted__c=true':'');
		query += ((s.Grades_Overridden__c)?' AND Grades_Overridden__c=true':'');
		query += ((s.IEP_Program__c)?' AND IEP_Program__c=true':'');
		query += ((s.Immigrant__c)?' AND Immigrant__c=true':'');
		query += ((s.Special_Ed__c)?' AND Special_Ed__c=true':'');
		query += ((s.X504_Plan__c)?' AND X504_Plan__c=true':'');
		query += ((s.ELL__c)? ' AND ELL__c=true':'');
		query += ((s.Retained_in_a_previous_grade_level__c)?' AND Retained_in_a_previous_grade_level__c=true':'');

		if(schoolLevel && s.Setup__r.Grade_Span__c!=null && s.Setup__r.Grade_Span__c!=''){
			string gradeFilter = '';
			for(String g:s.Setup__r.Grade_Span__c.split(';')){
				gradeFilter += ((gradeFilter=='')?'':',')+'\''+g+'\'';
			}
			query += ' AND Grade__c IN ('+gradeFilter+')';
		}

		if(!schoolLevel){
			query += ((s.Student_First_Name__c != null)?' AND Student_First_Name__c LIKE \'%'+s.Student_First_Name__c+'%\'':'');
			query += ((s.Student_Last_Name__c != null)?' AND Student_Last_Name__c LIKE \'%'+s.Student_Last_Name__c+'%\'':'');
			query += ((s.Student_ID__c != null)?' AND Student_ID__c LIKE \'%'+s.Student_ID__c+'%\'':'');
			query += ((s.Date_of_Birth__c != null)?' AND Date_of_Birth__c='+StringUtils.getQueryDate(s.Date_of_Birth__c.format()):'');
			query += ((s.Grade__c != null)?' AND Grade__c =\''+s.Grade__c+'\'':'');
			query += ((s.Entry_Date__c != null)?' AND Entry_Date__c ='+StringUtils.getQueryDate(s.Entry_Date__c.format()):'');
			query += ((s.Race_Multi__c != null)?' AND Race_Multi__c'+StringUtils.buildMutliSelectQuery(s.Race_Multi__c.split(';')):'');
			query += ((s.Gender__c != null)?' AND Gender__c=\''+s.Gender__c+'\'':'');
		}
		
		return query;
	}
	
	private String buildQueryFieldSet(Staff__c s, boolean schoolLevel){
		String query = '';
		
		if(!schoolLevel){
			query += ((s.First_Name_Staff__c != null)?' AND First_Name_Staff__c LIKE \'%'+s.First_Name_Staff__c+'%\'':'');
			query += ((s.Staff_Last_Name__c != null)?' AND Staff_Last_Name__c LIKE \'%'+s.Staff_Last_Name__c+'%\'':'');
			query += ((s.ID__c != null)?' AND ID__c LIKE \'%'+s.ID__c+'%\'':'');
		}
		
		return query;
	}

	private void setupStudentReportingPeriods(){
		//need to know what reporting periods to generate for
		List<Document_Log__c> studentLogs = new List<Document_Log__c>();
		Map<ID, Gradebook_RunReportCardsWrapper.schoolWrapper> generatingSetups = getSchoolWrapperMap();
		String srpFilter = '';
		for(Gradebook_RunReportCardsWrapper.schoolWrapper sw:schools){
			if(sw.selected){
				if(sw.selectedDocument != 'Transcript'){
					srpFilter += srpFilter == ''?'(':' OR (';
					srpFilter += 'Student__r.Setup__c=\''+sw.setup.id+'\' AND Time__c =\''+sw.selectedReportingPeriod+'\')';
				}
			}
		}

		Map<ID, Student_Reporting_Period__c> srpMap = new Map<ID, Student_Reporting_Period__c>();
		if(srpFilter != '' && bStudent){
			srpMap = Gradebook_ReportCard_Utils.getStudentReportingPeriods(selectedPeople, srpFilter);
			log.Query__c+='Student Reporting Periods filter: '+srpFilter;
		}
		for(Gradebook_RunReportCardsWrapper.personWrapper s:peopleToGenerate){
			Gradebook_RunReportCardsWrapper.schoolWrapper sw = (bStudent?generatingSetups.get(s.student.School__c):generatingSetups.get(s.staff.Organization__c));
			String reportingPeriodName = rpMap.get(sw.selectedReportingPeriod).Name__c;
			if(bStudent){
				if(srpMap.containsKey(s.student.id)){
					s.srp = srpMap.get(s.student.id);
					reportingPeriodName = s.srp.Time__r.Name__c;
				} else {
					//basically this generates a new srps for kids without them. The transcript srps are memory only, but the report card ones will be inserted (later).
					//self repairing module for the win
					//EE - *like*
					s.srp = new Student_Reporting_Period__c(Time__c = rpMap.get(sw.selectedReportingPeriod).ID, Time__r = rpMap.get(sw.selectedReportingPeriod), Student__c=s.student.id);
				}
			}
			s.log = setupDocumentLog(s, sw.selectedDocument,(s.srp!=null)?s.srp.id:null,reportingPeriodName);
			
			//this works with memory references, insert this list, then the IDs are on each individual log on each student wrapper
			studentLogs.add(s.log);
		}
		log.Status__c = 'In Progress';
		try{
			insert studentLogs;
			saveLog();
		} catch(System.DMLException e){
			errorMessage('An exception occured when trying to save the individual student logs. The completion status of some students may not be available.','DML Exception while saving student logs:' +e.getMessage()+':'+e.getStackTraceString());
		}
	}

	private Document_Log__c setupDocumentLog(Gradebook_RunReportCardsWrapper.personWrapper person, String documentType, ID srpID, String reportingPeriodName){
		Document_Log__c slog =
			new Document_Log__c(
				Log__c = '',
				Error_Message__c = '', 
				Document_Log__c = log.id, 
				Document_Type__c= documentType,
				Reporting_Period_Name__c = reportingPeriodName,
				Status__c = 'In Queue', 
				RecordTypeId = core_soqlUtils.getRecordTypesBySobject('Document_Log__c').get(documentType=='Transcript'?'Transcript':'Report_Card'),
				Student_Reporting_Period__c = srpID);
		if(bStudent){
			slog.Student__c = person.student.id;
			slog.Name = person.student.Name+'-'+reportingPeriodName+'-'+documentType;
		}
		else{
			slog.Staff__c = person.staff.id;
			slog.Name = person.staff.Name+'-'+reportingPeriodName+'-'+documentType;
		}
		if(slog.Document_Type__c != 'Transcript' && bStudent && slog.Student_Reporting_Period__c == null){
			slog.Status__c = 'In Queue - With Warnings';
			slog.Error_message__c = 'No student reporting period object located for the selected reporting period. Please make sure that you have run the final grade batch at least once.';
			writeLog('Student ' +person.student.id+' will generate with a pregeneration warning.');
		}
		return slog;
	}

	private String checkBucketName(Gradebook_RunReportCardsWrapper.schoolWrapper school){
		String bucketName;
		
		if(school.selectedDocument.contains('Transcript')){
			bucketName = school.setup.Year__r.Name__c+'.'+school.setup.School__r.Name;
		} else{
			bucketName = school.setup.Year__r.Name__c+'.'+rpMap.get(school.selectedReportingPeriod).Name__c+'.'+school.setup.School__r.Name;
		}
		if(school.selectedDocument.contains('Schedule')){
			if(bStudent)
				bucketName += '.StudentSchedules';
			else
				bucketName += '.StaffSchedules';
		}
		bucketName = bucketName.replace('\'', '').replace(' ', '');

		if(!bucketNames.contains(bucketName) && !exceptionBuckets.contains(bucketName)){
			if(Limits.getCallouts() < Limits.getLimitCallouts()-5){
				boolean created = createBucket(bucketName);
				if(created){
					bucketNames.add(bucketName);
					return '0';
				} else {
					exceptionBuckets.add(bucketName);
				}
			} else {
				return '-1';
			}
		}
		return bucketName;
	}

	private boolean createBucket(String bucketName){
		try{
			Datetime now = Datetime.now();
			//This performs the Web Service call to Amazon S3 and creates a new bucket - which is like a folder
			S3.CreateBucketResult createBucketReslt = as3.CreateBucket(bucketName,null,as3.key,now,as3.signature('CreateBucket',now));
		} catch(System.CalloutException e){
			errorMessage('Failed to create new bucket on AS3. Not all documents may be uploaded.','Failed to create new AS3 bucket ' + bucketName+'. All documents that would have been included in this bucket will not be uploaded.');
			writeError('S3 Bucket Callout Exception:'+e.getMessage());
			return false;
		} catch(Exception e){
			errorMessage('An unknown exception occured when creating a new bucket on AS3. Not all documents may be uploaded.','Failed to create new AS3 bucket ' + bucketName+'. All documents that would have been included in this bucket will not be uploaded.');
			writeError('S3 Bucket Callout Exception:'+e.getMessage());
			return false;
		}
		return true;
	}

	private PageReference generateDocReference(Gradebook_RunReportCardsWrapper.personWrapper student, boolean languageOverride, Gradebook_RunReportCardsWrapper.schoolWrapper school){
		PageReference pdfPage;

		if(student.log.Document_Type__c.contains('Transcript')){
			pdfPage = Page.Transcript;
			pdfPage.getParameters().put('student',student.student.Id);
			pdfPage.getParameters().put('contactId',student.student.Individual__c);
			pdfPage.getParameters().put('logID',student.log.id);
			
			//US3281 passing to transcript page
			pdfPage.getParameters().put('Official', string.valueOf(school.bOfficialTranscript));
		} else if(student.log.Document_Type__c.contains('Schedule')){
			pdfPage = Page.pdfSchedule;
			pdfPage.getParameters().put('bPreSelect','true');
			if(bStudent) pdfPage.getParameters().put('selectedID',student.student.id);
			else pdfPage.getParameters().put('selectedID',student.staff.Reference_Id__c);
			pdfPage.getParameters().put('scheduleType',(bStudent?'student':'staff'));
			pdfPage.getParameters().put('bAutoGenerate','true');
			pdfPage.getParameters().put('dateType',school.selectedTime);
			pdfPage.getParameters().put('startDate',StringUtils.getQueryDate(school.startDate));
			pdfPage.getParameters().put('endDate',StringUtils.getQueryDate(school.endDate));
			system.debug('~~~~~ URL '+pdfPage.getURL());
		} else {
			pdfPage = Page.Report_Card;
			pdfPage.getParameters().put('studentId',student.student.Id);
			pdfPage.getParameters().put('rpId', student.srp.Time__c);
			pdfPage.getParameters().put('incInactiveSS', string.valueOf(bIncludeInactiveStudentSections));
			pdfPage.getParameters().put('incInactiveS', string.valueOf(bIncludeInactiveStudents));
			pdfPage.getParameters().put('incTranSS', string.valueOf(bIncludeTransferedSections));
			pdfPage.getParameters().put('bPR', String.valueOf(student.log.Document_Type__c.contains('Progress')));
			pdfPage.getParameters().put('bOC',string.valueOf(student.log.Document_Type__c.contains('Elementary')));
			pdfPage.getParameters().put('logID',student.log.id);
			//US2929
			if(languageOverride)
				pdfPage.getParameters().put('langOvr','true');
		}
		pdfPage.setRedirect(true);

		return pdfPage;
	}

	private Attachment generateDocument(Gradebook_RunReportCardsWrapper.personWrapper student,PageReference pdfPage){
		blob pdfBlob;
		Attachment document;
		if(test.isRunningTest()){
			pdfBlob = blob.valueOf('TestData');
		}else{
			try{
				pdfBlob = pdfPage.getContentAsPDF();
			}catch(System.VisualForceException e){
				writeLog('Generation for '+(bStudent?'student '+student.student.id:'staff '+student.staff.id)+' has failed. VisualForceException: '+e.getMessage());
				pdfBlob = null;
			}
		}

		if(pdfBlob != null){
			if(student.log.Document_Type__c != 'Transcript'){
				String docName=student.log.Reporting_Period_Name__c+'.';
				if(bStudent)
					docName+=student.student.Setup__r.Year__r.Name__c+'.'+student.student.School__r.Name+'.'+
						student.student.Grade__c+'.'+student.student.Student_Last_Name__c +'.'+
						student.student.Student_Id__c+'.';
				else
					docName+=student.staff.Organization__r.Name+'.'+student.staff.Staff_Last_Name__c+'.'+
						student.staff.ID__c+'.';
				docName+=student.log.Document_Type__c+'.pdf';
				document =  new Attachment(
					parentId = (bStudent?student.student.id:student.staff.id), 
					name=docName,
					body = pdfBlob);
			} else {
				document =  new Attachment(
					parentId = student.student.id, 
					name= student.student.Setup__r.Year__r.Name__c+'.'+student.student.School__r.Name+'.'+
						student.student.Grade__c+'.'+student.student.Student_Last_Name__c +'.'+
						student.student.Student_Id__c+'.'+'Transcript.pdf',
					body = pdfBlob);
			}
		}
		return document;
	}

	private boolean uploadToS3(Attachment document, String bucketName, Document_Log__c studentLog){
		try{
			String docBody = EncodingUtil.base64Encode(document.body);
			Datetime now = Datetime.now();
			Boolean putObjResult = as3.REST_PutObject_ACL(bucketName, document.Name, null, docBody, docBody.length(), 'public-read', as3.key, now, as3.secret, ownerID);
			return putObjResult;
		} catch(AWSKeys.AWSKeysException e){
			studentlog.Error_Message__c += 'Transmission exception while uploading to AS3:\n'+e.getMessage()+'\n';
			writeError('Document for student '+studentLog.Student__c+' failed to upload to AS3. See their individual log for more details.');
			return false;
		} catch(Exception e){
			studentlog.Error_Message__c += 'Transmission exception while uploading to AS3:\n'+e.getMessage()+'\n';
			writeError('Document for student '+studentLog.Student__c+' failed to upload to AS3. See their individual log for more details.');
			return false;
		}
		return true;
	}
	
	private void getSectionQueryData(Gradebook_RunReportCardsWrapper.schoolWrapper sw, Set<ID> selectedSections, Set<ID> allSections){
		//now grab their sections
		if(sw.sections == null || sw.sections.isEmpty()){
			if(bStudent) allSections.add(sw.setup.id); 
			else allSections.add(sw.schoolId);
		} else {
			Set<ID> schoolSections = new Set<ID>();
			for(Gradebook_RunReportCardsWrapper.sectionWrapper secWrapper: sw.sections){
				if(secWrapper.selected){
					schoolSections.add(secWrapper.section.id);
				}
			}
			//if they selected all the sections, then don't include those in the filter (query row limits)
			//they will get picked up in the student search, which is the important one
			if(sw.sections.size() != schoolSections.size()){
				selectedSections.addAll(schoolSections);
			} else {
				if(bStudent) allSections.add(sw.setup.id); 
				else allSections.add(sw.schoolId);
			}
		}
	}
	
	private Map<ID,Gradebook_RunReportCardsWrapper.schoolWrapper> getSchoolWrapperMap(){
		Map<ID,Gradebook_RunReportCardsWrapper.schoolWrapper> generatingSetups = new Map<ID,Gradebook_RunReportCardsWrapper.schoolWrapper>();
		for(Gradebook_RunReportCardsWrapper.schoolWrapper sw:schools){
			if(sw.selected){
				generatingSetups.put(sw.schoolId, sw);
			}
		}
		return generatingSetups;
	}

	/* ERROR UTILS */
	private void errorMessage(String message, String logMessage){
		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, message));
		if(logMessage != null)
			writeError(logMessage);
	}

	private void infoMessage(String message, String logMessage){
		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, message));
		if(logMessage != null)
			writeLog(logMessage);
	}
	private void warningMessage(String message){
		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, message));
	}

	private void setupLog(){
		ID batchRTID = core_soqlUtils.getRecordTypesBySobject('Document_Log__c').get('Batch');
		log = new Document_Log__c(RecordTypeId = batchRTID, Log__c='', Error_Message__c='', Name='Batch '+system.now(), Query__c = '');
	}

	private void writeLog(String message){
		log.Log__c += message+'\n';
	}

	private void writeError(String message){
		log.Error_Message__c += message+'\n';
	}

	private void saveLog(){
		try{
			if(log.Error_Message__c.length() > 32768){
				log.Error_Message__c = log.Error_Message__c.left(32767);
			}
			if(log.Log__c.length()> 32768){
				log.Log__c = log.Log__c.left(32767);
			}

			upsert log;
		} catch (System.DMLException e){
			system.debug(e);
		}
	}
}
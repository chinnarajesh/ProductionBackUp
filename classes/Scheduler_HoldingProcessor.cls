global without sharing class Scheduler_HoldingProcessor implements Database.Batchable<SObject>, Database.Stateful {
	public static boolean bAutoCreateUsers = false;
	global Data_Load_Log__c 					log;
	 
	private List<HoldingObj__c> 				batch;
	private transient Map<Id,HoldingObj__c> 	batchById;
	private transient Map<String,Account> 		schoolsByDBN;
	private transient Map<String,Contact> 		staffByExternalId;
	private transient Map<String,Staff__c> 		staffSchoolByExternalIdDBN;
	private transient Map<String,Contact> 		studentsByExternalId;
	private transient Map<String,Section__c> 	sectionsByKey;
	private transient Map<String,Student__c> 	studentSchoolGradesByKey;
	private transient Map<String,Set<String>> 	gradesBySchoolDBN;
	private  Map<String,Course__c> 				coursesByKey;
	private transient Map<String, Room__c>		roomsByKey;
	private  Map <Id, Course__c> 				courseById;
	private transient Map<String, Time_Element__c> 		yearNameMap; //This map is used to connect Student__c records to the appropriate Year
	private transient Map<String,Student_Section__c> 	studentSectionsByKey;
	private transient Map<String, Section__c> 	scheduleGroupsbyKey;
	private transient Map<Id, Map<String,Course_Weightings__c>> 	courseWeightingsByCourse;
	private transient Map<Id, Map<String, Time_Element__c>> 		sectionReportingPeriodMap;
	
	public String 				query;
	global String				mode;
	global String 				schoolDbn; 
	public core_SetupWrapper 	cSetup;
	global Id					reportingPeriod;
	global boolean				continueBatch;
	
	global Scheduler_HoldingProcessor() {
		log = new Data_Load_Log__c(Status__c='Pending', Class_Name__c='Scheduler_HoldingProcessor');
		insert log;
		continueBatch = false;
	} 	
	
	public static string processQueryForPropagator(string mode, core_SetupWrapper cSetup, String schoolDbn){
		string queryToProcess;
		if (mode == 'Staff'){
		queryToProcess ='SELECT Class_Id__c, Class_Name__c, Grade_Level__c, Reference_Id__c,  ' + 
				'First_Name__c, Last_Name__c, Network__c, Password__c, ' +
				'School_Dbn__c, Propagated__c, School_Name__c, Staff_Code__c, Email__c, ' +
				'Staff_ID__c, Subject__c, Username__c, Source_System__c, Course_Name__c, Period__c, ' +
								'Record_Attendance__c, Daily_Attendance__c, Phone__c, Address__c, City__c, ' +
								'State__c, Zip__c, Age__c, Sex__c, Reporting_Period_Id__c, Room__c , School_Year__c ' + 
			'FROM HoldingObj__c '+
			'WHERE Type__c =\'Staff\'';
		}
		else {
			queryToProcess= 'SELECT Admission_Date__c, Class_Id__c, Disability_Flag__c, DOB__c, Reference_Id__c, ' +
				'ELL__c, Ethnic_Cde__c, First_Name__c, Grade_Level__c, Last_Name__c, ' + 
				'Lep_Flag__c, Network_Code__c, Password__c, School_Dbn__c, Sex__c,  ' + 
				'Source_System__c, Student_Id__c, Student_Propagated__c, School_Propagated__c, ' +
				'Section_Propagated__c, Course_Name__c, Period__c,  Email__c, ' +
				'Record_Attendance__c, Daily_Attendance__c, Phone__c, Address__c, City__c, Propagated__c,  ' +
				'State__c, Zip__c, Age__c, Class_Name__c,  Reporting_Period_Id__c, Room__c , School_Year__c ' +
			'FROM HoldingObj__c '+
			'WHERE Type__c =\'Student\'';
		}
		if (cSetup!=null){
			queryToProcess+=' AND School_Dbn__c =\''+String.escapeSingleQuotes(cSetup.school.Reference_Id__c)+'\''; //If based on setup pass in School DBN or Reference ID
			queryToProcess+=' AND School_Year__c =\''+String.escapeSingleQuotes(cSetup.setup.year__r.Name__c)+'\''; //If based on setup pass in School Year Name
				}
		else if (schoolDbn!=null){
			queryToProcess+=' AND School_Dbn__c =\''+String.escapeSingleQuotes(schoolDbn)+'\''; //School DBN if loading flat roster 
		}
		queryToProcess+=' AND Propagated__c = false';
		return queryToProcess;
	}
	  
	global Database.QueryLocator start(Database.BatchableContext ctx) {
		try{
			query = Scheduler_HoldingProcessor.processQueryForPropagator(mode, cSetup, schoolDBN);
			if(cSetup!=null) log.Setup__c = cSetup.setup.id;
			if(reportingPeriod!=null) log.Reporting_Period__c = reportingPeriod;
			log.Batch_ID__c = ctx.getJobId();
			log.Status__c = 'Running';
			log.Type__c = mode;
			log.Total_Records__c = 0;
			log.Failed_Records__c = 0;
			log.Start_Time__c = System.now();
			log.Start_Time_Text__c = log.Start_Time__c.format('MM/dd/yyyy hh:mm a');
			update log;
		    return Database.getQueryLocator(query); 
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.Id+'; Reporting Period, '+reportingPeriod, 'Propagator', 'QueryLocator error during '+mode+' propagation', e);
			insert ge;
			return null;
		}
    }
	
	global void execute(Database.BatchableContext ctx, List<SObject> scope) {
		try{
			CT_core_TriggerUtils.scheduler=true;//US1250 need to set the flag for Scheduler
			batch = (HoldingObj__c[])scope;
			batchById = new Map<Id,HoldingObj__c>(batch);
			schoolsByDBN = new Map<String,Account>();
			staffByExternalId = new Map<String,Contact>();
			studentsByExternalId  = new Map<String,Contact> ();
			staffSchoolByExternalIdDBN =  new Map<String,Staff__c>();
			studentSchoolGradesByKey = new Map <String, Student__c>();
			sectionsByKey = new Map<String,Section__c>();
	        coursesByKey = new Map<String,Course__c>();
	        gradesBySchoolDBN = new Map<String,Set<String>>();
			courseWeightingsByCourse = new Map <Id, Map <String, Course_Weightings__c>>();
			studentSectionsByKey = new Map<String,Student_Section__c> ();
	        sectionReportingPeriodMap = new Map <Id, Map<String, Time_Element__c>>();
	        yearNameMap = new Map <String, Time_Element__c>();
	        roomsByKey = new Map <String, Room__c>();
	        courseById = new Map <Id, Course__c>();
	        scheduleGroupsbyKey= new Map <String, Section__c>();
	        clearErrors();
	         if (mode=='Staff'){    
	            	processSchoolYearMap();
				processSchools();
				processCourses();
				processSections(mode);
				processStaff();
				processStaffSchools();
				processStaffSections();
				if (Test.isRunningTest() || Scheduler_HoldingProcessor.bAutoCreateUsers) {
			        	createStaffUsers(staffByExternalId.values());
			        }
	            }
	            else {
	            	system.debug('this is a student load');
	            	processSchoolYearMap();
	            	processSchools();
	            	processCourses();
	            	processSections(mode);
					processStudentContacts();
					processStudentSchools();
	     	 	 	processStudentSections();
	     	 	 	//PU 09/18/11 - Moving section grades creation to triger
	     	 	 	//processStudentSectionGrades();
	            }
	        
	        // Save Propogated flags and/or error messages
	        update batchById.values();
	        
	        log.Total_Records__c += batch.size();
	        countFailures();
		}
		catch(Exception e){
			if(cSetup != null){
				Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.Id+'; Reporting Period, '+reportingPeriod, 'Propagator', 'error during '+mode+' propagation', e);
				insert ge;
			}
			System.debug(e);
			
		}
	}
	
	global void finish(Database.BatchableContext ctx) {
		log.Status__c = 'Completed';
		log.End_Time__c = System.now();
		log.End_Time_Text__c = log.End_Time__c.format('MM/dd/yyyy hh:mm a');
		update log;
		
		if(continueBatch){
			if(mode=='Staff'){
				//run student propagator
				Scheduler_HoldingProcessor shp = new Scheduler_HoldingProcessor();
				shp.continueBatch = true;
				shp.cSetup = cSetup;
				shp.mode = 'Student';
				shp.reportingPeriod = reportingPeriod;
				Database.executeBatch(shp);
			}
			else{
				//run session propagator
				BatchInsertSessions pubSess = new BatchInsertSessions(cSetup.setup.id, reportingPeriod);
				pubSess.holdingSource = [SELECT id FROM HoldingObj__c WHERE Reporting_Period_Id__c=:reportingPeriod 
					AND School_DBN__c=:cSetup.setup.School__r.Reference_Id__c AND School_Year__c=:cSetup.setup.Year__r.Name__c];
				Database.executeBatch(pubSess, 50);
			}
		}
	}
	
	private void processSchoolYearMap(){
		Set <String> yearNameSet = new Set <String>();
		 for (HoldingObj__c holder : batch) {
		 	if (holder.School_Year__c!=null){
		 		yearNameSet.add(holder.school_year__c);
		 	}
		 }
		 if (!yearNameSet.isEmpty()){
		 	for (Time_Element__c te: [select id, name__c from Time_Element__c where name__c in: yearNameSet and Picklist_Value__r.Name='Year']){
		 		yearNameMap.put(te.name__c, te);
		 	}
		 }
	}
	
	private void processStaff() {
		system.debug('process staff');
		//Iterate over each HOS, add staff to the staff list
        for (HoldingObj__c holder : batch) {
        	String staffId = ImportUtils.stripLeadingZeroes(holder.Staff_ID__c);
            if (!staffByExternalId.containsKey(staffId)) {
	            Contact staff = ImportMappers.createStaffMapper().generate(holder);
	            staffByExternalId.put(staffId, staff);
            }

        }
        processErrors(
				staffByExternalId.values(),
				Database.upsert(staffByExternalId.values(), Contact.Reference_ID__c, false),
				Contact.Holding_Source__c);
	}
	
	private void processStaffSections() {
		system.debug('process staff sections');
		//Iterate over each hos, create new Staff/Section object and Staff/School object
        Map<String,Staff_Section__c> staffSectionsByKey = new Map<String,Staff_Section__c>();
        Map<String,Staff__c> staffSchoolsByKey = new Map<String,Staff__c>();
        // Joiners for special sections (ELL and Disability)
        
        for (HoldingObj__c holder : batch) {
        	String staffSectionKey = ImportUtils.createStaffSectionKey(holder);
        	if ((staffSectionKey != null) && !staffSectionsByKey.containsKey(staffSectionKey)) {
        		system.debug('hooray!  in the right if');
	        	Staff_Section__c staffSection = ImportMappers.createStaffSectionMapper().generate(holder);
	        	staffSectionsByKey.put(staffSectionKey, staffSection);
        	}
        }
        
        processErrors(
        		staffSectionsByKey.values(),
        		Database.upsert(staffSectionsByKey.values(), Staff_Section__c.Reference_Id__c, false),
        		Staff_Section__c.Holding_Source__c);
	}
	
	private void processStaffSchools() {
		system.debug('process staff schools');
        Map<String,Staff__c> staffSchoolsByKey = new Map<String,Staff__c>();
        
        for (HoldingObj__c holder : batch) {
        	String staffSchoolKey = ImportUtils.createStaffSchoolKey(holder);
        	if ((staffSchoolKey != null) && !staffSchoolsByKey.containsKey(staffSchoolKey)) {
        		Staff__c staffSchool = ImportMappers.createStaffSchoolMapper().generate(holder);
        		staffSchoolsByKey.put(staffSchoolKey, staffSchool);
        	}
        }
        
        processErrors(
        		staffSchoolsByKey.values(),
        		Database.upsert(staffSchoolsByKey.values(),Staff__c.Reference_Id__c, false),
        		Staff__c.Holding_Source__c);
	}
	
	private void processCourses() {
		system.debug('process courses');
		//Iterate over each HOS, add staff to the staff list
		Set <String> courseKeys = new Set<String>();
		Set <String> roomKeys = new Set<String>();
		Set <String> groupKeys = new Set <String>();
        for (HoldingObj__c holder : batch) {
            String courseKey = holder.Course_Name__c;
            String roomKey = importUtils.createRoomKey(holder);
            String groupKey = importUtils.createScheduleGroupKey(holder);
            System.debug('-------GroupKey------------'+groupKey);
            courseKeys.add(courseKey);
            roomKeys.add(roomKey);
            groupKeys.add(groupKey);
        }
        for (Course__c course: [select id, name, reference_id__c, number_of_reporting_periods__c,Homework_Based__c from Course__c where Name in :courseKeys and RecordType.Name = 'Course']){
        	
            coursesByKey.put(course.name, course);
            courseById.put(course.id, course);
        }
        for (Room__c room: [select id, name, Reference_Id__c from Room__c where Reference_Id__c in: roomKeys]){
        	roomsByKey.put(room.reference_Id__c, room);
        }
        //Start US1254 Updates
        ID grpSectionRtId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group');
        for (Section__c sg: [select id, name, Reference_Id__c from Section__c where Reference_Id__c in :groupKeys and RecordType.DeveloperName='Schedule_Group']){
        	scheduleGroupsbyKey.put(sg.Reference_Id__c, sg);
        }
         //End US1254 Updates

	}
	
	private void processSections(String mode) {
		Set <String> secRefKeys = new Set<String>();
		//Iterate over each HOS, add staff to the staff list
        for (HoldingObj__c holder : batch) {System.debug('$$$$$Batch$$$'+batch);
            String sectionKey = ImportUtils.createClassSectionKey(holder);
            String roomKey = 	ImportUtils.createRoomKey(holder);
            String groupKey;
            if (cSetup!=null) {
            	if (cSetup.setup.group_based__c) groupKey = ImportUtils.createScheduleGroupKey(holder);
            }
            else groupKey = null;
            
            if ((sectionKey != null) && !sectionsByKey.containsKey(sectionKey)) {
            	Section__c section = new Section__c();
            	if (mode=='Staff'){
            		section = ImportMappers.createSectionMapper().generate(holder,yearNameMap.get(holder.School_Year__c));
            	}else{
            		section = ImportMappers.createSectionMapper().generateForStudent(holder,yearNameMap.get(holder.School_Year__c));
            	}	         
            	if (RoomKey!=null && roomsByKey.containsKey(roomKey)) section.Room__c = roomsByKey.get(roomKey).id;
            	if(holder.Course_Name__c != null){
            		section.Course__c = coursesByKey.get(holder.Course_Name__c).Id;
            	 	section.Number_of_Reporting_Periods__c = String.valueOf(coursesByKey.get(holder.Course_Name__c).number_of_reporting_periods__c);
            	 	section.Active__c = cSetup.setup.Active__c;
					/*PU Populate Homework_Based__c flag on section if the setup is  Standards_ONLY_Gradebook__c*/
	            	if(cSetup.setup.Standards_ONLY_Gradebook__c)
	            	section.Homework_Based__c = coursesByKey.get(holder.Course_Name__c).Homework_Based__c;
	            	
	            	/* Need to get the Group Id*/  
	            	string SchedulerRefKey; 
	            	System.debug('----Schedule Groups By Key-------'+scheduleGroupsbyKey);
	            	/*PN 10/11 Scheduler Rerference Id is still needed on Section to connect schedule groups with sections; scheduler_SoqlUtils. getGroupsBySections*/
	            	  if (groupKey!=null){
	            	  	if (scheduleGroupsbyKey.get(groupKey)!=null){  //Specific logic needed for group based schools to get session information
	            			SchedulerRefKey =schoolsByDBN.get(holder.school_dbn__c).id+'-'+scheduleGroupsbyKey.get(groupKey).id+'-'+section.course__c+'-'+holder.Reporting_Period_Id__c;
	            			section.scheduler_reference_Id__c = SchedulerRefKey;
	            		
	            			section.Schedule_Group__c = scheduleGroupsbyKey.get(groupKey).id;
	            			system.debug('Sect.schedule_group__c'+section.Schedule_Group__c);
	            			system.debug('Sect'+scheduleGroupsbyKey.get(groupKey));
	            		}
	            	  }
	            	secRefKeys.add(section.Reference_Id__c);
            	}
            	sectionsByKey.put(sectionKey, section);
        	}
        }
		System.debug('==> In original batch processor, upserting sections '+sectionsByKey.values());
       	processErrors(
				sectionsByKey.values(),
				Database.upsert(sectionsByKey.values(), Section__c.Reference_Id__c, false),
				Section__c.Holding_Source__c);
			
		updateSectionReportingPeriods(secRefKeys,batch[0].Reporting_Period_Id__c);
			
	}
	/*  PU 09/23/11 - Updating the record type on Section_ReportingPeriod__c to published*/
	private void updateSectionReportingPeriods(Set<String> refKeys,Id repPeriod){ 
		
		List<Section_ReportingPeriod__c>  sectionRpList = new  List<Section_ReportingPeriod__c>();
		for(Section_ReportingPeriod__c secRp : [SELECT ReferenceId__c,Id FROM Section_ReportingPeriod__c
												        WHERE Section__r.Reference_Id__c in: refKeys 
		 										        AND Time__c =: repPeriod
		 										        order by Section__c]){
		 	secRp.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('Published');
		 	sectionRpList.add(secRp); 
		}
		try{
			if(sectionRpList.size() > 0) 
				update sectionRpList;
		}
		catch(Exception ex){
		 	System.debug(ex);
		}
	}
	private void processSchools() {
		system.debug('process schools');
		for (HoldingObj__c holder : batch) {
            if(!schoolsByDBN.containsKey(holder.School_Dbn__c)) {
	            Account school = ImportMappers.createSchoolMapper().generate(holder);
	            schoolsByDBN.put(holder.School_Dbn__c, school);
            }
        }
		processErrors(
				schoolsByDBN.values(),
				Database.upsert(schoolsByDBN.values(), Account.Reference_Id__c, false),
				Account.Holding_Source__c);
	}
	
	private void clearErrors(){
		for (HoldingObj__c ho: batchById.values()){
			ho.error_message__c = null;
			ho.Propagated__c = true;
		}
		
	}
	
	private void processErrors(List<SObject> records, List<Database.UpsertResult> results, Schema.SobjectField sourceField) {
		System.assertEquals(records.size(), results.size(), 'Records and results arrays must of equal size');
		for (Integer i=0;i<results.size();i++) {
			system.debug('results~~~'+results);
			if (!results[i].isSuccess()) {
				Id holdingId = (Id)records[i].get(sourceField);
				if (batchById.get(holdingId).propagated__c) { //only run if propagated is true which is set by default at start of batch
					// Do not overwrite previous error message as it's most likely the root cause.
					system.debug('ho~~~'+batchById.get(holdingId));
					batchById.get(holdingId).Propagated__c = false;
					if (batchById.get(holdingId).Error_Message__c==null){
						HoldingObj__c tempHo=  batchById.get(holdingId);
						tempHo.error_Message__c = results[i].getErrors()[0].getMessage();
						system.debug('tempHo~~'+tempHo);
						batchById.put(holdingId, tempHo);
					}
					//else {
						//batchById.get(holdingId).Error_Message__c+= ';' +results[i].getErrors()[0].getMessage();
					//}
				}
			}
		}
	}
	
	private void countFailures() {
		for (HoldingObj__c staff : batch) {
			if (staff.Propagated__c == false) {
				log.Failed_Records__c++;
			}
		}
	}			
	
	private void createStaffUsers(List<Contact> staffs) {
		staffs = [SELECT Name, LastName, FirstName, User_Name__c, User__c, Reference_ID__c FROM Contact WHERE Id IN :staffs];
		List<User> users = new List<User>();
		for (Contact staff : staffs) {
			if (staff.User__c == null) {
				users.add(createUser(staff));
			}
		}
		insert users;
		
		staffs = new List<Contact>();
		// Now update the User lookup on Staff__c records.
		for (User usr : users) {
			staffs.add(new Contact(Reference_Id__c=usr.Reference_Id__c,User__c=usr.Id));
		}
		upsert staffs reference_Id__c; 
	}
	
	private User createUser(Contact staffContact) {
		User usr = new User(IsActive=true);
		usr.Alias = staffContact.FirstName.substring(0,1) + staffContact.LastName;
		if (usr.Alias.length() > 4) {
			usr.Alias = usr.Alias.substring(0,4);
		}
		usr.Email = 'nycdoedev@gmail.com';
		usr.EmailEncodingKey = 'UTF-8';
		usr.FirstName = staffContact.FirstName;
		usr.LastName =staffContact.LastName; 
		usr.LanguageLocaleKey = 'en_US';
		usr.LocaleSidKey = 'en_US'; 
				usr.ProfileId = [select id from Profile where Name ='Standard User'].id;
		usr.TimeZoneSidKey = 'America/Los_Angeles';
		usr.Username = staffContact.User_Name__c + '@schools.nyc.gov.dev';
		if (Test.isRunningTest()) usr.Username +='x';
		usr.Reference_Id__c = staffContact.Reference_Id__c;
		return usr;
	}
	
	private void processStudentSchools(){ 
		//Primary External Key for Student is Reference_Id__c
		core_triggerUtils.studentTriggerUpdate(true);
		for (HoldingObj__c holder : batch) {
			holder.Propagated__c = true;
			holder.Error_Message__c = null;	
			String studentSchoolGradeKey = ImportUtils.createStudentSchoolGradeKey(holder);
        	if ((studentSchoolGradeKey != null) && !studentSchoolGradesByKey.containsKey(studentSchoolGradeKey)) {
            	Student__c student = ImportMappers.createStudentSchoolGradeMapper().generate(holder, cSetup.setup.School__r.RecordType.Name == 'Summer School');
            	if (yearNameMap.get(holder.school_year__c)!=null){
            		student.School_Year__c = yearNameMap.get(holder.school_year__c).id; //Map the string name value for the year to the actual time element value
            	}
            	if(cSetup!=null) {
            		student.Setup__c = cSetup.setup.id;
            		student.Active__c = cSetup.setup.Active__c;
            	}
            	studentSchoolGradesByKey.put(studentSchoolGradeKey, student);
	        	Set<String> grades = gradesBySchoolDBN.get(holder.School_Dbn__c);
	        	if (grades == null) {
	        		grades = new Set<String>();
	        		gradesBySchoolDBN.put(holder.School_Dbn__c, grades);
	        	}
	        	grades.add(ImportUtils.normalizeGrade(holder.Grade_level__c));
        	}
        }
		processErrors(
				studentSchoolGradesByKey.values(),
				Database.upsert(studentSchoolGradesByKey.values(), Student__c.Reference_Id__c, false),
				Student__c.Holding_Source__c);
		core_triggerUtils.studentTriggerUpdate(true);	
	}
	
	private void processStudentContacts() {
		//Primary External Key for Contacts is Reference_Id__c
		core_triggerUtils.studentTriggerUpdate(false);
		for (HoldingObj__c holder : batch) {
		
        	if (!studentsByExternalId.containsKey(holder.Student_Id__c)) {
        		Contact studentContact = ImportMappers.createStudentContactMapper().generate(holder);
	        	studentsByExternalId.put(holder.Student_Id__c, studentContact); 
        	}
        }
		processErrors(
				studentsByExternalId.values(),
				Database.upsert(studentsByExternalId.values(), Contact.Reference_Id__c, false),
				Contact.Holding_Source__c);
		core_triggerUtils.studentTriggerUpdate(true);	
	}

	private void processStudentSections() {
		core_triggerUtils.studentTriggerUpdate(false);
		// Create the StudentSection Joiners
		List<Student_Section__c> studentSections = new List<Student_Section__c>();
	 	for (HoldingObj__c holder : batch) {
			Section__c section = sectionsByKey.get(ImportUtils.createClassSectionKey(holder));
        	
        	Account school = schoolsByDBN.get(holder.School_Dbn__c);
        	String studentSchoolGradeKey = ImportUtils.createStudentSchoolGradeKey(holder);
        	Student__c student = studentSchoolGradesByKey.get(studentSchoolGradeKey);
        	if (student != null) {
        		if (section != null) {
					Student_Section__c studentSection = new Student_Section__c();
					studentSection.Student__c = student.Id;
					studentSection.Section__c = section.Id;
					studentSection.Holding_Source__c = holder.id;
					studentSection.Reference_ID__c = ImportUtils.createStudentSectionKey(holder);
					studentSections.add(studentSection);
					studentSectionsByKey.put(studentSection.Reference_ID__c,studentSection );
        		}			
        	}
        }
        processErrors(
				studentSections,
				Database.upsert(studentSections, student_section__c.Reference_ID__c , false), 
				Student_Section__c.Holding_Source__c); 

    	core_triggerUtils.studentTriggerUpdate(true);
	}
}
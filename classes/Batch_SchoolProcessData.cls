global with sharing class Batch_SchoolProcessData implements Database.Batchable<SObject>, Database.Stateful {
	global String setupID;
	global String yearID;
	global Boolean processedEOYDataCompleted;
	global String sectionLogID;
	global String staffSectionLogID;
	global String studentSectionLogID;
	global String studentLogID;
	private List<Setup__c> setups	{get; set;}
	private List<ID> schools		{get; set;}
	public Map<String, Data_Load_Log__c> logs;

    public static final Set<String> legalSectionRT = new Set<String>{'Gradebook Group', 'Published', 'Unpublished', 'Schedule Group'};	
	
	global Batch_SchoolProcessData(String sID, String yID, String sectionLog, String staffSectionLog, String studentSectionLog, String studentLog) {
		setupID = sID;
		yearID = yID;
		sectionLogID = sectionLog;
		staffSectionLogID = staffSectionLog;
		studentSectionLogID = studentSectionLog;
		studentLogID = studentLog;
		Setups = new List<Setup__c>();
		Schools = new List<ID>();
		Setup__c mainSetup = core_SoqlUtils.getSetupById(setupID);
		Setups.add(mainSetup);
		Schools.add(mainSetup.School__c);

		logs = new Map<String, Data_Load_Log__c>();
		List<String> logTypes = new List<String>{'Student__c','Section__c','Staff_Section__c','Student_Section__c'};
		for(String s:logTypes){
			logs.put(s, new Data_Load_Log__c(
				Status__c = 'Processing',
				Type__c = s,
				Messages__c = '',
				Setup__c = mainsetup.id,
				Total_Records__c = 0,
				Failed_Records__c = 0,
				Processed_Records__C = 0,
				Class_Name__c = 'Batch_SchoolProcessData'
			));
		}

		insert logs.values();
		
		//US3517 search for child setups of main account, also used for updating the setup records in the finish method
		for(Setup__c setup : [SELECT ID, School__c, Processed_EOY_Data__c FROM Setup__c WHERE School__r.ParentID =: mainSetup.School__c]) {
			Setups.add(setup);
			Schools.add(setup.School__c);
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext ctx) {
		try {
			String query = 'Select ID, Active__c, Archived__c FROM Section__c ';
			query += 'WHERE Time__c =\'' + yearID + '\' ';
			query += 'AND School__c IN: Schools ';
			query += 'AND RecordType.Name IN: legalSectionRT ';

			for(Data_Load_Log__c log:logs.values()){
				log.Status__c = 'Running';
				log.Start_Time__c = System.now();
				log.Start_Time_Text__c = System.now().format('MM/dd/yyyy hh:mm a');
				log.Batch_ID__c = ctx.getJobId();
			}
			return Database.getQueryLocator(query);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in start method.',e);
			for(Data_Load_Log__c log:logs.values()){
				log.Status__c = 'Failed';
				log.Messages__c = 'Failure when starting deactivation process. Please contact support for assistance in resolving this issue.\n';
			}
		} finally{
			update logs.values();
		}

		return Database.getQueryLocator('select id from Section__c where ID = null');
	}
	
	global void execute(Database.BatchableContext ctx, List<SObject> scope) {
		List<Section__c> sectionBatch = (Section__c[])scope;
		Set<ID> sectionID = new Set<ID>();
		for(Section__c s : sectionBatch) {
			sectionID.add(s.ID);
		}

		deactivateSections(sectionBatch, logs.get('Section__c'));
		deactivateStaffSections(sectionID, logs.get('Staff_Section__c'));
		deactivateStudentSections(sectionID, logs.get('Student_Section__c'), logs.get('Student__c'));
		
		processAndStoreLogs();
	}
	
	global void finish(Database.BatchableContext ctx){
			deactivateRemainingStudents(logs.get('Student__c'));
			deactivateRemainingStudentSections(logs.get('Student_Section__c'));
			//There's no real good way of doing this at this time, so I'm not implementing it. 
			//At some point it might be worth it if the schools start having issues with random staff sections not getting processed.
			//deactivateRemainingStaffSections();

			boolean hasFailures = false;
			for(Data_Load_Log__c log:logs.values()){
				if(log.Status__c != 'Failed'){
					log.Status__c = 'Completed';
				} else{
					hasFailures = true;
				}
			}

			//this is one of the few places we would want to throw the exception, that's our only way to know it failed at this point.
			//at this point, if we have failures, we need to mark the status as failed
			if(!hasFailures){
				try{
					for(Setup__c s : setups) {
						s.Processed_EOY_Data__c = true;
					}
					update setups;
				} catch(Exception e){
					insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in section deactivation',e);
					for(Data_Load_Log__c log:logs.values()){
						log.Status__c = 'Failed';
						Log.Messages__c += 'Failure marking data deactivation complete on setup. Please contact support for assistance in resolving this issue.\n';
					}
					processAndStoreLogs();
				}

				try{
					List<EOY_Progress__c> progresses = [select id, School_Process_Data_Completed__c from EOY_Progress__c where Setup__c IN:setups and Year__c=:yearID and RecordType.Name = 'EOY'];
					for(EOY_Progress__c progress: progresses){
						progress.School_Process_Data_Completed__c = true;
					}
					update progresses;
				} catch(Exception e){
					insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in update EOY Progress on completion',e);
					for(Data_Load_Log__c log:logs.values()){
						log.Status__c = 'Failed';
						Log.Messages__c += 'Failure marking data deactivation complete on EOY Progress. Please contact support for assistance in resolving this issue.\n';
					}
					processAndStoreLogs();
				}
			}
			
			try{
				processAndStoreLogs();
			}catch(Exception e){
				throw e;
			}
	}

	private void processDMLResults(List<Database.SaveResult> results, Data_Load_Log__c log){
		for(Integer i = 0; i < results.size(); i++) {
			if(!results[i].isSuccess()) {
				log.Failed_Records__c++;
				log.Messages__c += results[i].getErrors()[0].getMessage() + '\n';
			} else {
				log.Processed_Records__c++;
			}
		}
	}
	
	private void deactivateSections(List<Section__c> sections, Data_Load_Log__c log){
		try{
			for(Section__c s : sections) {
				s.Active__c = false;
				s.Archived__c = true;
			}
			log.Total_Records__c += sections.size();
			processDMLResults(Database.update(sections,false),log);			
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in section deactivation',e);
			log.Failed_Records__c += sections.size();
			Log.Messages__c += 'Unexpected failure in section deactivation. Please contact support for assistance in resolving this issue.\n';
		}
	}
	
	private void deactivateStaffSections(Set<ID> sID, Data_Load_Log__c log){
		List<Staff_Section__c> staffSections;
		try{
			staffSections = [SELECT Archived__c,Reference_Id__c,Staff__r.Reference_Id__c,Is_Active__c,Section__r.Time__r.Name__c FROM Staff_Section__c WHERE Section__c IN: sID];
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in staff section retrieval',e);
			log.Failed_Records__c += 1;
			Log.Messages__c += 'Unexpected failure in staff section retrieval. Please contact support for assistance in resolving this issue.\n';
		}
		
		try{
			deactivateStaffSections(staffSections, log);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in staff section deactivation',e);
			log.Failed_Records__c += staffSections.size();
			Log.Messages__c += 'Unexpected failure in staff section deactivation. Please contact support for assistance in resolving this issue.\n';
		}
	}

	private void deactivateStaffSections(List<Staff_Section__c> staff, Data_Load_Log__c log){
		log.Total_Records__c += staff.size();

		if(staff.size() > (Limits.getLimitDMLRows()-Limits.getDMLRows())){
			log.Failed_Records__c += staff.size();
			log.Messages__c += 'The number of records required for processing exceeds the limits for the current batch.';
			return;
		}

		for(Staff_Section__c ss:staff){
			ss.Is_Active__c = false;
			ss.Archived__c = true;
		}
			
		if(staff.size() > 0){
			core_triggerUtils.deactivate = true;
			processDMLResults(database.update(staff,false),log);
			core_triggerUtils.deactivate = false;
		}
	}
	
	private void deactivateStudentSections(Set<ID> sID, Data_Load_Log__c ssLog, Data_Load_Log__c studentLog){
		List<Student_Section__c> studentSections;
		try{
			studentSections = [SELECT ID, Active__c, Archived__c, Student__c, Student__r.Archived__c, Student__r.Active__c, Student__r.Reference_Id__c FROM Student_Section__c WHERE Section__c IN: sID];
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in student section retrieval',e);
			ssLog.Failed_Records__c += 1;
			ssLog.Messages__c += 'Unexpected failure in student section retrieval. Please contact support for assistance in resolving this issue.\n';
		}
		
		List<Student__c> students = new List<Student__c>();
		Set<ID> studentIds = new Set<ID>();
		for(Student_Section__c ss:studentSections){
			if(ss.Student__c != null && !studentIDs.contains(ss.Student__c)){ //who's been deleting students?
				students.add(new Student__c(ID=ss.Student__c));
				studentIDs.add(ss.Student__c);
			}
		}

		try{
			deactivateStudentSections(studentSections, ssLog);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in student section deactivation',e);
			ssLog.Failed_Records__c += studentSections.size();
			ssLog.Messages__c += 'Unexpected failure in student section deactivation. Please contact support for assistance in resolving this issue.\n';
		}
		try{
			deactivateStudents(students, studentLog);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in student deactivation',e);
			studentLog.Failed_Records__c += students.size();
			studentLog.Messages__c += 'Unexpected failure in student deactivation. Please contact support for assistance in resolving this issue.\n';
		}
	}

	public void deactivateStudentSections(List<Student_Section__c> studentSections, Data_Load_Log__c log){
		if(studentSections.size() > 0){
			if(studentSections.size() > (Limits.getLimitDMLRows()-Limits.getDMLRows())){
				log.Failed_Records__c += studentsections.size();
				log.Messages__c += 'The number of records required for processing exceeds the limits for the current batch.';
				return;
			}

			for(Student_Section__c ss:studentSections){
				ss.Active__c = false;
				ss.Archived__c = true;
			}

			core_triggerUtils.studentSectionTriggerUpdate(false);
			core_triggerUtils.b = true;
			log.Total_Records__c += studentSections.size();
			processDMLResults(database.update(studentSections,false),log);
			core_triggerUtils.b = false;
			core_triggerUtils.studentSectionTriggerUpdate(true);		
		}
	}

	public void deactivateStudents(List<Student__c> students, Data_Load_Log__c log){
		if(students.size()>0){
			if(students.size() > (Limits.getLimitDMLRows()-Limits.getDMLRows())){
				log.Failed_Records__c += students.size();
				log.Messages__c += 'The number of records required for processing exceeds the limits for the current batch.';
				return;
			}

			for(Student__c s:students){
				s.Active__c = false;
				s.Archived__c = true;
			}

			core_triggerUtils.mealsTrigger = true;
			core_triggerUtils.studentTriggerUpdate(false);
			log.Total_Records__c += students.size();
			processDMLResults(database.update(students,false),log);
			core_triggerUtils.studentTriggerUpdate(true);
			core_triggerUtils.mealsTrigger = false;
		}
	}

	public void deactivateRemainingStudents(Data_Load_Log__c log){
		List<Student__c> students;
		try{
			students = [SELECT ID, Active__c, Archived__c FROM Student__c WHERE Setup__c IN: Setups AND Archived__c = false];
			deactivateStudents(students, log);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in remaining student deactivation',e);
			log.Failed_Records__c += students != null?students.size():1;
			log.Messages__c += 'Unexpected failure in unprocessed student deactivation. Please contact support for assistance in resolving this issue.\n';
		}
	}

	public void deactivateRemainingStudentSections(Data_Load_Log__c log){
		List<Student_Section__c> studentSections;
		try{
			studentSections = [select id, Active__c, Archived__c from Student_Section__c where (Student__r.Setup__c IN: Setups or Student__c = null) and Archived__c = false and Section__r.RecordTypeID IN: legalSectionRT];
			deactivateStudentSections(studentSections, log);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolProcessData','Failure in remaining student section deactivation',e);
			log.Failed_Records__c += studentSections != null?studentSections.size():1;
			log.Messages__c += 'Unexpected failure in unprocessed student section deactivation. Please contact support for assistance in resolving this issue.\n';
		}
	}

	public void processAndStoreLogs(){
		for(Data_Load_Log__c log:logs.values()){
			if(log.Messages__c.length() > 32000){
				log.Messages__c = log.Messages__c.subString(0,31999);
			}
			if(log.Failed_Records__c>0){
				log.Status__c = 'Failed';
			}
		}
		update logs.values();
	}
}
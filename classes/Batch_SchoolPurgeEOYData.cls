global with sharing class Batch_SchoolPurgeEOYData implements Database.Batchable<SObject>, Database.Stateful {

	public String setupID;
	public String yearID;
	public Integer mode;
	public String batchId;
	public Map<String, String> pcDisplayName {get; set;}

	public Data_Load_Log__c log;

	private String activeTerm {get; set;}
	private Date startDate {get; set;}
	private Date endDate {get;set;}
	private String currentSchool {get; set;}
	private String currentYear {get; set;}
	private String currentSetup {get; set;}
	private Set<String> USI_IDs {get; set;}
	private Set<String> behaviorIDs {get; set;}
	private List<Setup__c> setups {get; set;}
	private List<ID> schools {get; set;}
	private List<ID> terms {get; set;}

	global Batch_SchoolPurgeEOYData(String sID, String yID, String tLog, Integer m) {
		populateDisplayName();

		batchID = tlog;
		setupID = sID;
		yearID = yID;
		mode = m;
		setups = new List<Setup__c>();
		schools = new List<ID>();
		terms = new List<ID>();

		Setup__c mainSetup = core_SoqlUtils.getSetupById(setupID);
		setups.add(mainSetup);
		schools.add(mainSetup.School__c);
		terms.add(mainSetup.Term__c);

		startDate = mainSetup.Term__r.Date_start_date__c;
		endDate = mainSetup.Term__r.End_Date__c;

		//US3518 search for child setups of main account, also used for updating the setup records in the finish method
		for(Setup__c setup : [SELECT ID, School__c, Term__c, Term__r.Date_start_date__c, Term__r.End_Date__c FROM Setup__c WHERE School__r.ParentID =: mainSetup.School__c]) {
			setups.add(setup);
			schools.add(setup.School__c);
			terms.add(setup.Term__c);

			if(setup.Term__r.End_Date__c != null) {
				if(setup.Term__r.End_Date__c > endDate) {
					endDate = setup.Term__r.End_Date__c;
				}
			}
		}

		log = new Data_Load_Log__c(
			Setup__c = mainSetup.ID,
			Type__c = pcDisplayName.get(getObjectString(mode)),
			Status__c = 'Pending',
			Class_Name__c = 'Batch_SchoolPurgeEOYData',
			Total_Records__c = 0, 
			Failed_Records__c = 0,
			Processed_Records__c = 0,
			Messages__c = ''
		);

        insert log;
	}

	global Database.QueryLocator start(Database.BatchableContext ctx){
		try{
			String query = setQuery();

			if(batchId == null)
				batchId = ctx.getJobId();

			log.Start_Time__c = system.now();
			log.Start_Time_Text__c = system.now().format('MM/dd/yyyy hh:mm a');
			log.Status__c = 'Running';
			log.Batch_ID__c = batchId;

			return Database.getQueryLocator(query);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolPurgeEOYData','Failure starting batch for mode '+mode,e);
			log.Status__c = 'Failed';
			log.Messages__c += 'Error in during batch start. Please contact support for assistance in resolving this issue.\n';
		} finally{
			processAndStoreLogs();
		}
		return Database.getQueryLocator('select id from '+getObjectString(mode)+' where ID = null');
	}

	global void execute(Database.BatchableContext ctx, List<SObject> scope){
		try{
		   Purged_Object__c po = getPOSetting(mode);

			system.debug('Processing mode: '+mode);
			system.debug('Using purge settings:'+po);

			if(po.Purged_EOY__c) {
				List<Database.deleteResult> results;

				if(mode == 0) results = database.delete((List<Alert__c>)scope,false);
				else if(mode == 1) results = database.delete((List<Assesment__c>)scope,false);
				else if(mode == 2) results = database.delete((List<Assignment__c>)scope,false);
				else if(mode == 3) results = database.delete((List<Attendance__c>)scope,false);
				else if(mode == 4) results = database.delete((List<Attendance_Tracking__c>)scope,false);
				else if(mode == 5) results = database.delete((List<Awards__c>)scope,false);
				else if(mode == 6) results = database.delete((List<Consequence__c>)scope,false);
				//skip mode 7 (Student_Behavior__c), as they're processed during step 8
				else if(mode == 8){//Behavior_Incident__c
					Set<ID> setupIds = (new Map<ID, Setup__c>(setups)).keyset();
					List<Student_Behavior__c> sbToDelete = new List<Student_Behavior__c>();
					Set<ID> toDelete = new Set<ID>();

					//converts a List<sObject> into a Set<ID> in one line
					toDelete = (new Map<ID, Behavior_Incident__c>((List<Behavior_Incident__c>) scope)).keyset();

					//Our goal is to delete only incidents which have students from the processed school
					//if there are students from other schools we need to keep the incident
					for(Student_Behavior__c sb : [SELECT ID, Student__r.Setup__c, Behavior_Incident__c FROM Student_Behavior__c WHERE Behavior_Incident__c IN: scope]) {
						if(!setupIds.contains(sb.Student__r.Setup__c)){
							toDelete.remove(sb.Behavior_Incident__c);
						} else {
							sbToDelete.add(sb);
						}

					}
					if(!sbToDelete.isEmpty()){
						results = Database.delete(sbToDelete,false);
					}
					if(!toDelete.isEmpty()){
						results.addAll(Database.delete(new List<ID>(toDelete), false));
					}
					
				}
				else if(mode == 9) results = database.delete((List<Daily_Meal_Summary__c>)scope,false);
				else if(mode == 10) results = database.delete((List<External_Resources__c>)scope,false);
				else if(mode == 11) results = database.delete((List<Grade__c>)scope,false);
				else if(mode == 12) results = database.delete((List<HW_Tracker__c>)scope,false);
				else if(mode == 13) results = database.delete((List<HW_Assignment__c>)scope,false);
				else if(mode == 14) results = database.delete((List<Meal_Transaction__c>)scope,false);
				else if(mode == 15) results = database.delete((List<Media__c>)scope,false);
				else if(mode == 16) results = database.delete((List<Period__c>)scope,false);
				else if(mode == 17) results = database.delete((List<Points__c>)scope,false);
				else if(mode == 18) results = database.delete((List<Proactive_Attendance__c>)scope,false);
				else if(mode == 19) results = database.delete((List<Proactive_Demographics__c>)scope,false);
				else if(mode == 20) results = database.delete((List<Schedule_Day__c>)scope,false);
				else if(mode == 21) results = database.delete((List<Schedule_Group__c>)scope,false);
				else if(mode == 22) results = database.delete((List<Schedule_Template__c>)scope,false);
				else if(mode == 23) results = database.delete((List<Scheduled_Section__c>)scope,false);
				else if(mode == 24) results = database.delete((List<Session__c>)scope,false);
				else if(mode == 25) results = database.delete((List<Standard_Grade__c>)scope,false);
				else if(mode == 26) results = database.delete((List<Strand_Grade__c>)scope,false);
				else {
					//nothing to see here
				}
				if(results != null){
					log.Total_Records__c += results.size();
					for(Integer i = 0; i < results.size(); i++) {
						if(!results[i].isSuccess()) {
							log.Failed_Records__c++;
							log.Messages__c += results[i].getErrors()[0].getMessage() + '\n';
						} else {
							log.Processed_Records__c++;
						}
					}
				}
				
			}
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_SchoolPurgeEOYData','Failure in deleting during mode '+mode,e);
			log.Failed_Records__c += scope.size();
			log.Messages__c += 'Failure processing records for deletion. Please contact support for assistance in resolving this issue.\n';
		} finally{
			processAndStoreLogs();
		}
	}

	global void finish(Database.BatchableContext ctx) {
		mode++;

		while(mode == 16 || mode == 20 || mode == 21 || mode == 22 || mode == 23){
			mode++;
		}

		if(getObjectString(mode) != null){
			//Get ready for the next batch
			try{
				if(log.Status__c != 'Failed')
					log.Status__c = 'Completed';
				log.End_Time__c = system.now();
				log.End_Time_Text__c = system.now().format('MM/dd/yyyy hh:mm a');
				Batch_SchoolPurgeEOYData newBatch = new Batch_SchoolPurgeEOYData(setupID, yearID, batchId==null?ctx.getjobId():batchId, mode);
				Database.executeBatch(newBatch);
			} catch(Exception e){
				insert Error_Handling.handleError('','Batch_SchoolPurgeEOYData','Failure starting next batch for mode '+mode,e);
				log.Status__c = 'Failed';
				log.Messages__c += 'Failure starting next batch.Please contact support for assistance in resolving this issue.\n';
			} finally {
				processAndStoreLogs();
			}	
		} else {
			try{
				Setup__c tSetup = core_SoqlUtils.getSetupById(setupID);
				tSetup.Purged_EOY_Data__c = true;
				update tSetup;

				List<EOY_Progress__c> progresses = [select id, School_Purge_EOY_Data_Completed__c from EOY_Progress__c where Setup__c =:tSetup.ID and Year__c =: yearID and RecordType.Name = 'EOY'];
				for(EOY_Progress__c progress:progresses){
					progress.School_Purge_EOY_Data_Completed__c = true;
				}
				update progresses;

				log.Status__c = 'Completed';
				log.End_Time__c = system.now();
				log.End_Time_Text__c = system.now().format('MM/dd/yyyy hh:mm a');
			} catch(Exception e){
				insert Error_Handling.handleError('','Batch_SchoolPurgeEOYData','Failure updating batch status',e);
				log.Status__c = 'Failed';
				log.Messages__c += 'Failure updating setup status on successful completion.\n';
			} finally {
				processAndStoreLogs();
			}
		}
	}

	private String setQuery() {
		currentYear = yearID;
		String returnQuery = 'SELECT ID FROM ' + String.escapeSingleQuotes(getObjectString(mode));

		if(mode == 0) {  //Alert__c
			returnQuery += ' WHERE Expiration_Date__c <=: endDate AND Expiration_Date__c >=: startDate';
			returnQuery += ' AND School__c IN: Schools';
		}
		else if(mode == 1) {  //Assesment__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
			returnQuery += ' AND Year_Over_Year__c = false';
		}
		else if(mode == 2) {  //Assignment__c
			returnQuery += ' WHERE Section__r.Time__c =: currentYear';
			returnQuery += ' AND Section__r.School__c IN: Schools';
		}
		else if(mode == 3) {  //Attendance__c
			returnQuery += ' WHERE Session__r.Time__r.Parent_Time_Element__c IN: Terms';
			returnQuery += ' AND Session__r.Section__r.School__c IN: Schools';
		}
		else if(mode == 4) {  //Attendance_Tracking__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
		}
		else if(mode == 5) {  //Awards__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
		}
		else if(mode == 6) {  //Consequence__c
			returnQuery += ' WHERE Student__r.Behavior_Incident__r.Preserve__c = False AND Student__r.Student__r.Setup__c IN: Setups';
		}
		else if(mode == 7) { //Student_Behavior__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups AND Behavior_Incident__r.Preserve__c = false';
		}
		else if(mode == 8) {  //Behavior_Incident__c
			returnQuery += ' WHERE Preserve__c = false AND ID IN (SELECT Behavior_Incident__c FROM Student_Behavior__c WHERE Student__r.Setup__c IN: Setups)';
		}
		else if(mode == 9) {  //Daily_Meal_Summary__c
			//more specific, lucky can do some time/date manipulation checking
			returnQuery += ' WHERE School__c IN: Schools AND Summary_Date__c <=: endDate AND Summary_Date__c >=: startDate';
		}
		else if(mode == 10) {  //External_Resources__c
			returnQuery += ' WHERE Section__r.Time__c =: currentYear';
		}
		else if(mode == 11) {  //Grade__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
		}
		else if(mode == 12) {  //HW_Tracker__c
			returnQuery += ' WHERE Student__r.School__c IN: Schools AND Student__r.Setup__c IN: Setups';
		}
		//HW_Assignment__c is the dead object
		else if(mode == 13) {  //HW_Assignment__c
			returnQuery += ' WHERE Section__r.Reporting_Period__r.Parent_Time_Element__c IN: Terms';
			returnQuery += ' AND Section__r.School__c IN: Schools';
		}
		else if(mode == 14) {  //Meal_Transaction__c
			returnQuery += ' WHERE Student__r.School__c IN: Schools';
			returnQuery += ' AND Student__r.School_Year__c =: currentYear';
		}
		else if(mode == 15) {  //Media__c
			returnQuery += ' WHERE Section__r.Time__c =: currentYear';
		}
		//dependency on Schedule Template, if Periods are deleted, delete Schedule Templates
		else if(mode == 16) {  //Period__c
			returnQuery += ' WHERE Schedule_Template__r.Setup__c IN: Setups';
		}
		else if(mode == 17) {  //Points__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
		}
		else if(mode == 18) {  //Proactive_Attendance__c
			USI_IDs = new Set<String>();
			for(Student__c s : [SELECT ID, Legacy_ID__c FROM Student__c WHERE Setup__c IN: Setups]) {
				USI_IDs.add(s.Legacy_ID__c);
			}
			returnQuery += ' WHERE USI_ID__c IN: USI_IDs';
		}
		else if(mode == 19) {  //Proactive_Demographics__c
			USI_IDs = new Set<String>();
			for(Student__c s : [SELECT ID, Legacy_ID__c FROM Student__c WHERE Setup__c IN: Setups]) {
				USI_IDs.add(s.Legacy_ID__c);
			}
			returnQuery += ' WHERE USI_ID__c IN: USI_IDs';
		}
		else if(mode == 20) {  //Schedule_Day__c
			returnQuery += ' WHERE Schedule_Template__r.Setup__c IN: Setups';
		}
		else if(mode == 21) {  //Schedule_Group__c
			returnQuery += ' WHERE Setup__c IN: Setups';
		}
		else if(mode == 22) {  //Schedule_Template__c
			returnQuery += ' WHERE Setup__c IN: Setups';
		}
		else if(mode == 23) {  //Scheduled_Section__c
			returnQuery += ' WHERE Reporting_Period__r.Parent_Time_Element__c IN: Terms';
			returnQuery += ' AND Account__c IN: Schools';
		}
		else if(mode == 24) {  //Session__c
			//returnQuery += ' WHERE Time__r.Parent_Time_Element__c =: activeTerm';
			returnQuery += ' WHERE Section__r.Time__c =: currentYear';
			returnQuery += ' AND Section__r.School__c IN: Schools';
		}
		else if(mode == 25) {  //Standard_Grade__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
		}
		else if(mode == 26) { //Strand_Grade__c
			returnQuery += ' WHERE Student__r.Setup__c IN: Setups';
		}
		else { //invalid mode
			return null;
		}
		return returnQuery;
	}

	private String getObjectString(Integer i) {
		if(i == 0) return 'Alert__c';
		else if(i == 1) return 'Assesment__c';
		else if(i == 2) return 'Assignment__c';
		else if(i == 3) return 'Attendance__c';
		else if(i == 4) return 'Attendance_Tracking__c';
		else if(i == 5) return 'Awards__c';
		else if(i == 6) return 'Consequence__c';
		else if(i == 7) return 'Student_Behavior__c';
		else if(i == 8) return 'Behavior_Incident__c';
		else if(i == 9) return 'Daily_Meal_Summary__c';
		else if(i == 10) return 'External_Resources__c';
		else if(i == 11) return 'Grade__c';
		else if(i == 12) return 'HW_Tracker__c';
		else if(i == 13) return 'HW_Assignment__c';
		else if(i == 14) return 'Meal_Transaction__c';
		else if(i == 15) return 'Media__c';
		else if(i == 16) return 'Period__c';
		else if(i == 17) return 'Points__c';
		else if(i == 18) return 'Proactive_Attendance__c';
		else if(i == 19) return 'Proactive_Demographics__c';
		else if(i == 20) return 'Schedule_Day__c';
		else if(i == 21) return 'Schedule_Group__c';
		else if(i == 22) return 'Schedule_Template__c';
		else if(i == 23) return 'Scheduled_Section__c';
		else if(i == 24) return 'Session__c';
		else if(i == 25) return 'Standard_Grade__c';
		else if(i == 26) return 'Strand_Grade__c';
		else {
			return null;
		}
	}

	private void populateDisplayName() {
		pcDisplayName = new Map<String, String>{
			'Alert__c'=>'Alert for Portal',
			'Assesment__c'=>'Assessment',
			'Assignment__c'=>'Assignment',
			'Attendance__c'=>'Attendance',
			'Attendance_Tracking__c'=>'Attendance Tracking',
			'Awards__c'=>'Award',
			'Awards__c'=>'Award',
			'Behavior_Incident__c'=>'Behavior',
			'Consequence__c'=>'Consequence',
			'Daily_Meal_Summary__c'=>'Daily Meal Summary',
			'External_Resources__c'=>'External Resource',
			'Grade__c'=>'Grade',
			'HW_Tracker__c'=>'Homework',
			'HW_Assignment__c'=>'HW Assignment',
			'Meal_Transaction__c'=>'Meal Transaction',
			'Media__c'=>'Media',
			'Period__c'=>'Period',
			'Points__c'=>'Points',
			'Proactive_Attendance__c'=>'Proactive Attendance',
			'Proactive_Demographics__c'=>'Proactive Demographics',
			'Schedule_Day__c'=>'Schedule Day',
			'Schedule_Template__c'=>'Schedule Template',
			'Scheduled_Section__c'=>'Scheduled Section',
			'Session__c'=>'Session',
			'Standard_Grade__c'=>'Standard Grade',
			'Strand_Grade__c'=>'Strand Grade',
			'Student_Behavior__c'=>'Student/Behavior'
		};
	}

	private Purged_Object__c getPOSetting(Integer m) {
		Purged_Object__c returnPO = [SELECT ID, Name, Name__c, Purged_EOY__c FROM Purged_Object__c WHERE Name__c =: getObjectString(m) LIMIT 1];
		return returnPO;
	}

	public void processAndStoreLogs(){
		if(log.Messages__c.length() > 32000){
			log.Messages__c = log.Messages__c.subString(0,31999);
		}
		if(log.Failed_Records__c>0){
			log.Status__c = 'Failed';
		}

		upsert log;
	}
}
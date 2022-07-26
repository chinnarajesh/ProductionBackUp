global class Batch_ProcessEOYData implements Database.Batchable<SObject>, Database.Stateful{
	global String								query;
	private Map<String,Data_Load_Log__c>		log;
	private transient Map<Id,Section__c> sectionMap;
	private transient Map<Id,Student_Section__c> studentSectionMap;
	private transient Map<Id,Staff_Section__c> staffSectionMap;
	private transient Map<Id,Student__c> studentMap;
	private List<Section__c> 					sectionBatch;
	private List<Student__c> 					studentBatch;
	global String								setupId;
	global String								mode;
	global String								className;
	global core_SetupWrapper 	cSetup;
	global Boolean bFlag;
	global Boolean continueBatch;
	
	
	global Batch_ProcessEOYData(String md) { 
		mode = md;
		log = new Map<String,Data_Load_Log__c>();
		if(mode == 'Student__c'){
			log.put('Student__c', new Data_Load_Log__c(Type__c='Student__c',Status__c='Pending',Class_Name__c ='Batch_ProcessEOYData'));
		}
		else if(mode == 'Section__c'){
			log.put('Staff_Section__c', new Data_Load_Log__c(Type__c='Staff_Section__c',Status__c='Pending',Class_Name__c ='Batch_ProcessEOYData'));
			log.put('Student_Section__c', new Data_Load_Log__c(Type__c='Student_Section__c',Status__c='Pending',Class_Name__c ='Batch_ProcessEOYData'));
			log.put('Section__c', new Data_Load_Log__c(Type__c='Section__c',Status__c='Pending',Class_Name__c ='Batch_ProcessEOYData'));	
		}
		
		insert log.values();
		continueBatch = false;
	} 
	
	public static String processQuery(String currYear,String schoolId,String m){
		string queryToProcess;
		if(m == 'Section__c'){
		queryToProcess = 'Select s.of_Time_by_Medium_of_Instruction__c, s.of_Students__c, s.of_Missing_Homework__c, s.of_Late_Homework__c,'+ 
				 's.of_Homework_Completed__c, s.of_Homework_Assignments__c, s.of_Consecutive_Days_without_Grades__c, s.isGroup__c,'+
				 's.Type__c, s.Time__c, s.Text_Color__c, s.Teachers__c, s.Staff__c, s.Show_in_portal__c, s.Section__c, s.Section_Number__c,'+
				 's.School__c, s.Scheduler_Reference_Id__c, s.Schedule_Group__c, s.Period__c, s.Medium_of_Instruction__c, s.Maximum_of_Seats__c,'+
				 's.MEP_Session_Type__c, s.Legacy_ID__c, s.Is_Section__c, s.Homework_Based__c, s.Homeroom__c, s.Holding_Source__c, s.Has_Homework__c,'+
				 's.Grade_Scale__c, s.Grade_Level__c, s.Exclude_From_Storing_Final_Grades__c, s.Exclude_From_GPA__c, s.Exclude_From_Attendance__c,'+
				 's.Daily_Attendance__c, s.Course__c, s.Active__c,s.Archived__c From Section__c s ';
		if(schoolId!=null && currYear!= null ){
			queryToProcess+=' WHERE s.Time__c =\''+currYear+'\'';
			queryToProcess +=' AND s.School__c=\''+schoolId+'\'';
		}
		}
		else if(m == 'Student__c'){
				queryToProcess = ' SELECT Id,Reference_Id__c, Archived__c, Active__c,School_Year__r.Name__c,Intent_to_Return_Following_Year__c, Grade__c,Individual__c FROM Student__c';
			if(schoolId!=null && currYear!= null ){
				queryToProcess+='  WHERE School_Year__c=\''+currYear+'\'';
				queryToProcess +='AND School__c=\''+schoolId+'\'';
			}
		}
		System.debug('$$$$queryToProcess$$$$'+queryToProcess);
		return queryToProcess;
	}
	
	global Database.QueryLocator start(Database.BatchableContext ctx) {
		try{
			System.debug('$$$$Mode$$$$'+mode);
			System.debug('setup$$$$'+setupId);
			if(setupId !=null){
				cSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'');
				query = Batch_ProcessEOYData.processQuery(cSetup.setup.Year__c,cSetup.setup.School__c,mode);
				if(className == 'EOY')
					cSetup.setup.Processed_EOY_Data__c = true;
				else
					cSetup.setup.Data_Activated__c = true;
				update cSetup.setup;
			}
			else	{	
				query = Batch_ProcessEOYData.processQuery(null,null,mode);
			}
				System.debug('$$$$Query$$$$'+query);
			
			
			for(Data_Load_Log__c d: log.values()){
				if(cSetup!=null){
					 d.Setup__c = cSetup.setup.id;
				}
				d.Batch_ID__c = ctx.getJobId();
				d.Status__c = 'Running';
				d.Total_Records__c = 0;
				d.Failed_Records__c = 0;
				d.Start_Time__c = System.now();
				d.Start_Time_Text__c = d.Start_Time__c.format('MM/dd/yyyy hh:mm a');
			}
			update log.values();
		    return Database.getQueryLocator(query); 
		}
		catch(Exception e){
			return null;
		}
	}
	
	global void execute(Database.BatchableContext ctx, List<SObject> scope) {
		try{	
			if(mode == 'Section__c'){
				
				sectionBatch = (Section__c[])scope;
				System.debug('batch Sizze $$$$'+ sectionBatch.size());
				
				processSections();
				processStaffSections();
				processStudentSections();
			}
			else if(mode == 'Student__c'){
				System.debug('SCOPE $$$$'+ scope.size());
				studentBatch = (Student__c[])scope;
				processStudents();
				
			}	
		} catch(Exception e){
		
		}
	}

	global void finish(Database.BatchableContext ctx) {	
		for(Data_Load_Log__c d:log.values()){
			d.Status__c = 'Completed';
			d.End_Time__c = System.now();
			d.End_Time_Text__c = d.End_Time__c.format('MM/dd/yyyy hh:mm a');
		}
		update log.values();
		
		if(continueBatch && mode=='Student__c'){
			Batch_ProcessEOYData  processEOYBatch = new Batch_ProcessEOYData('Section__c');
			processEOYBatch.setupId = setupId;
			processEOYBatch.bFlag = true;
			Database.executeBatch(processEOYBatch,10);
		}
	
	}
	
	private void processSections() {
		 sectionMap = new Map<Id,Section__c>();
		// List<Sobject> temp;
		
		for(Section__c sec : sectionBatch){
			if(className == 'EOY'){
				if(sec.Active__c){
					sec.Active__c = bFlag;
					sec.Archived__c = !bFlag;
				}
			}
			else{
				sec.Active__c = bFlag;
				sec.Archived__c = !bFlag;
			}
			sectionMap.put(sec.Id,sec);
		}
		System.debug('$$$$$SECTIONS SIZE'+sectionMap.values().size());
		if(sectionMap.values().size() > 0){
			processErrors(sectionMap.values(),database.update(sectionMap.values(),false));
		}
	
	}
	
	private void processStudents() {
		 studentMap = new Map<Id,Student__c>();
		 System.debug('$$$$$studentBatch'+studentBatch);
		 
		 for(Student__c stu : studentBatch){ 
		 	if(className == 'EOY'){
				 if(stu.Active__c){	
					stu.Active__c = bFlag;
					stu.Archived__c = !bFlag;
					studentMap.put(stu.Individual__c,stu);
					}
		 	}
		 	else{
		 		stu.Active__c = bFlag;
				stu.Archived__c = !bFlag;
				studentMap.put(stu.Individual__c,stu);
		 	}
		 }
		 
		 if(className != 'EOY'){
		 	List<Contact> updateContacts = new List<Contact>();
			for(Contact con: [SELECT Student__c FROM Contact WHERE Id in: studentMap.keyset()]){
				con.Student__c = studentMap.get(con.Id).Id;
				updateContacts.add(con);
			}
			
			if(updateContacts.size() > 0){
				SchoolForce_Settings__c sf = SchoolForce_Settings__c.getOrgDefaults();
				sf.Triggers_Disabled__c = true;
				upsert sf;
				update updateContacts;
				
				sf.Triggers_Disabled__c = false;
				update sf;
			}
		}
		System.debug('$$$$$STUDENTS SIZE'+studentMap.values().size());
		if(studentMap.values().size() > 0){
			//deactivate trigger
			core_triggerUtils.mealsTrigger = true;
			core_triggerUtils.studentTriggerUpdate(false);
			processErrors(studentMap.values(),database.update(studentMap.values(),false));
			core_triggerUtils.studentTriggerUpdate(true);
		}
	
	}
	
	private void processStudentSections() {
		 studentSectionMap = new Map<Id,Student_Section__c>();
		 studentMap = new Map<Id,Student__c>();
		 
		for(Student_Section__c stusec : [SELECT Archived__c,Section__r.Time__r.Name__c,Student__c,Student__r.Archived__c,Student__r.Active__c,Student__r.Reference_Id__c,Active__c FROM Student_Section__c WHERE Section__c in:sectionMap.keyset()]){
			if(className == 'EOY'){
				if(stusec.Active__c){
					stusec.Active__c = bFlag;
					stusec.Archived__c = !bFlag;
				}
			}
			else{
				stusec.Active__c = bFlag;
				stusec.Archived__c = !bFlag;
			}	
			studentSectionMap.put(stusec.Id,stusec);	
			
		}
		System.debug('$$$$$STUDENT SECTONS SIZE'+studentSectionMap.values().size());
		if(studentSectionMap.values().size() > 0){
			//deactivate trigger
			core_triggerUtils.studentSectionTriggerUpdate(false);
			core_triggerUtils.b = true;
			processErrors(studentSectionMap.values(),database.update(studentSectionMap.values(),false));
			core_triggerUtils.studentSectionTriggerUpdate(true);
			core_triggerUtils.b = false;
		}
		
	}
	
	private void processStaffSections() {
		 staffSectionMap = new Map<Id,Staff_Section__c>();
		 
		for(Staff_Section__c staffsec : [SELECT Archived__c,Reference_Id__c,Staff__r.Reference_Id__c,Is_Active__c,Section__r.Time__r.Name__c FROM Staff_Section__c WHERE Section__c in:sectionMap.keyset() AND Section__r.Is_Section__c = true]){
			if(className == 'EOY'){
				if(staffsec.Is_Active__c){
					staffsec.Is_Active__c = bFlag;
					staffsec.Archived__c = !bFlag;
				}
			}
			else{
				staffsec.Is_Active__c = bFlag;
				staffsec.Archived__c = !bFlag;
			}
		/*	PU: Since scheduling is done before EOY process staff sections should always have year appended to them, updated triggers and import utils to append year in the reference ID 
		if(!staffsec.Reference_Id__c.contains(staffsec.Section__r.Time__r.Name__c))
				staffsec.Reference_Id__c +='-'+staffsec.Section__r.Time__r.Name__c;
				*/
			staffSectionMap.put(staffsec.Id,staffsec);	

		}
		System.debug('$$$$$STAFF SECTONS SIZE'+staffSectionMap.values().size());
		core_triggerUtils.deactivate = true;
		if(staffSectionMap.values().size() > 0){
			//deactivate trigger
			processErrors(staffSectionMap.values(),database.update(staffSectionMap.values(),false));
		}
		core_triggerUtils.deactivate = false;
	}
	

	private void processErrors(List<SObject> records, List<Database.SaveResult> results) {
		String sobjName = '';
		System.assertEquals(records.size(), results.size(), 'Records and results arrays must of equal size');
		if (String.valueOf(records[0].getSObjectType()).contains('SchoolForce')){
        	sobjName = String.valueOf(records[0].getSObjectType()).replace('SchoolForce__','');
         }
         else
         	sobjName = String.valueOf(records[0].getSObjectType());
		log.get(sobjName).Total_Records__c = records.size();
		for (Integer i=0;i<results.size();i++) {
			if (!results[i].isSuccess()) {
				log.get(sobjName).Failed_Records__c++;
				for(Database.Error err: results[i].getErrors()){
					if(log.get(sobjName).Messages__c!='' && log.get(sobjName).Messages__c!=null)
						log.get(sobjName).Messages__c+='\n';
					log.get(sobjName).Messages__c+=results[i].getId()+' - '+err.getMessage();
				}
				if(className == 'EOY')
					cSetup.setup.Processed_EOY_Data__c = false;
				else
					cSetup.setup.Data_Activated__c = false;
			}
		}
		
		update log.values();
		update cSetup.setup;
	}
	
}
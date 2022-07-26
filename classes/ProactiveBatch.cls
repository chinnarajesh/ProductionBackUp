global class ProactiveBatch implements Database.Batchable<sObject>{
	
	
	
	public List<String> errors = new List<String>();
	String query;
	Boolean demographics;
	Boolean attendance;
	Date startDate;
	Date endDate;
	String schoolId;
	String userId;
	Boolean err;
    
    global ProactiveBatch(String uI, String q, Boolean att, Boolean demo, Date startD, Date endD, String sId){
        query = q;
        attendance = att;
        demographics = demo;
        startDate = startD;
        endDate = endD;
        schoolId = sId;
        userId = uI;
        err = false;
    }
	
	global database.queryLocator start(Database.BatchableContext BC) {
		
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope) {	
		
		if(attendance == null && demographics == null){
			if(query == 'SELECT Id FROM Proactive_Attendance__c'){
				List<Proactive_Attendance__c> proAttList = (List<Proactive_Attendance__c>)scope;
				delete proAttList;
			}else if(query == 'SELECT Id FROM Proactive_Demographics__c'){
				List<Proactive_Demographics__c> proDemoList = (List<Proactive_Demographics__c>)scope;
				delete proDemoList;
			}
		}else {
		List<Attendance__c> attendanceList = (List<Attendance__c>)scope;
		system.debug('attendance: ' + attendanceList);
		Set<Id> studentIds = new Set<Id>();
		for(Attendance__c a : attendanceList){
			studentIds.add(a.Student__c);
		}
		
		List<Proactive_Demographics__c> proactiveDemo = [SELECT Id, USI_ID__c FROM Proactive_Demographics__c];
		Set<String> checkDups = new Set<String>();
		for(Proactive_Demographics__c usi : proactiveDemo){
			checkDups.add(usi.USI_ID__c);
		}
		
		//
		//Query for active students
		//
		List<Student__c> studentList = [SELECT Student_Last_Name__c, Student_First_Name__c, Student__c, Address__c, 
			City__c, State__c, Zip_Code__c, Gender__c, Ethnicity__c, Race__c, Date_of_Birth__c, Grade__c, 
			Entry_Date__c, Exit_Date__c, School__c, School__r.Name, Homeroom__c, Staff__c, Original_Graduation_Year__c,
			DC_Resident__c, Exit_Reason__c, Entry_Type__c, School_Year__r.Name__c, Immigrant__c, ELL__c, ELL_Hours__c, 
			SPED_School__r.Setup__r.School__r.Name, Special_Education_Level__c, Title_1_Status__c, ELL_Level__c,
			Special_Ed__c, Special_Education_Hours__c, Student__c.Student_Id__c, Lunch_Status__c, Meals_Category__c, Legacy_Id__c
			FROM Student__c WHERE School__c = :SchoolId AND Active__c = true];
		
		system.debug('students: ' + studentList);
		//
		//end student query
		//
		
		//
		//query Parent/guardian info
		//
		List<Student_PG__c>	studentPGList = [SELECT Id, PG_Relationship__c, PG_First_Name__c, PG_Last_Name__c, PG_Middle_Name__c,
			Student__c, Student_c__c, Primary_Contact__c, Parent_Guardian_c__c, P_G_Phone__c, P_G_Personal_Phone__c,
			 PGCellPhone__c FROM Student_PG__c WHERE Student__c IN:studentIds AND Primary_Contact__c = true];
		system.debug('Parents: ' + studentPGList);
		//
		//end query
		//
		
		List<Proactive_CS__c> pgRelList = [SELECT Id, Name_Type__c, Proactive_PG_Relationship__c, SF_PG_Relationship__c,
			Proactive_Student_Entry__c, SF_Student_Entry__c, Proactive_Attendance_Status__c, Proactive_Attendance_Type__c, 
			SF_Attendance_Status__c, SF_Attendance_Type__c, Proactive_Student_Exit__c, SF_Student_Exit__c, 
			Proactive_TitleI__c, SF_TitleI__c, SF_SPED_School__c, Proactive_SPED_School__c FROM Proactive_CS__c];
		
		Map<Id, List<Student_PG__c>> pgMap = new Map<Id, List<Student_PG__c>>();
		for(Student_PG__c mapPG : studentPGList){
			if(!pgMap.containsKey(mapPG.Student__c)){
				pgMap.put(mapPG.Student__c, new List<Student_PG__c>());
			}
			pgMap.get(mapPG.Student__c).add(mapPG);
		}
		
		//
		//Demographics SPED School Map start
		//
		Map<String, Proactive_CS__c> spedSchoolMap = new Map<String, Proactive_CS__c>();
		for(Proactive_CS__c mapRel3 : pgRelList){
			if(mapRel3.Name_Type__c == 'SPED'){
				if(!spedSchoolMap.containsKey(mapRel3.SF_SPED_School__c)){
					spedSchoolMap.put(mapRel3.SF_SPED_School__c, mapRel3);
				}
			}
		}
		//
		//Demographics SPED School Map end
		//
		
		//
		//Demographics TitleI Map start
		//
		Map<String, Proactive_CS__c> titleIMap = new Map<String, Proactive_CS__c>();
		for(Proactive_CS__c mapRel2 : pgRelList){
			if(mapRel2.Name_Type__c == 'TitleI'){
				if(!titleIMap.containsKey(mapRel2.SF_TitleI__c)){
					titleIMap.put(mapRel2.SF_TitleI__c, mapRel2);
				}
			}
		}
		//
		//Demographics TitleI Map end
		//
		
		//
		//Demographics relationship Map start
		//
		Map<String, Proactive_CS__c> pgRelationship = new Map<String, Proactive_CS__c>();
		for(Proactive_CS__c mapRel : pgRelList){
			if(mapRel.SF_PG_Relationship__c != null){
				if(!pgRelationship.containsKey(mapRel.SF_PG_Relationship__c)){
					pgRelationship.put(mapRel.SF_PG_Relationship__c, mapRel);
				}
			}
		}
		//
		//DemoGraphics Relationship Map End
		//
		
		//
		//Demographics Entry Code Map start
		//
		Map<String, Proactive_CS__c> pgEntry = new Map<String, Proactive_CS__c>();
		for(Proactive_CS__c mapRel1 : pgRelList){
			if(mapRel1.Name_Type__c == 'Entry'){
				if(!pgEntry.containsKey(mapRel1.SF_Student_Entry__c)){
					pgEntry.put(mapRel1.SF_Student_Entry__c, mapRel1);
				}
			}
		}
		//
		// Demographics Entry code Map End
		//
		
		//
		//Demographics Exit Code Map start
		//
		Map<String, Proactive_CS__c> pgExit = new Map<String, Proactive_CS__c>();
		for(Proactive_CS__c mapRel2 : pgRelList){
			if(mapRel2.Name_Type__c == 'Exit'){
				if(!pgExit.containsKey(mapRel2.SF_Student_Exit__c)){
					pgExit.put(mapRel2.SF_Student_Exit__c, mapRel2);
				}
			}
		}
		//
		// Demographics Exit code Map End
		//
		
		List<Student_PG__c> PGList = new List<Student_PG__c>();
		List<Proactive_Attendance__c> proAttList = new List<Proactive_Attendance__c>();
		List<Proactive_Demographics__c> proDemoList = new List<Proactive_Demographics__c>();
		
		Proactive_CS__c demoPG = new Proactive_CS__c();
		Proactive_CS__c demoEntry = new Proactive_CS__c();
		Proactive_CS__c demoExit = new Proactive_CS__c();
		Proactive_CS__c demoTitleI = new Proactive_CS__c();
		Proactive_CS__c demoSPEDSchool = new Proactive_CS__c();
		List<Proactive_CS__c> attCodeList = new List<Proactive_CS__c>();
		try {	
		for(Attendance__c  c : attendanceList){
			if(attendance){
				if(c.Daily__c){
					Proactive_Attendance__c proAtt = new Proactive_Attendance__c();
					proAtt.USI_ID__c = c.Student__r.Legacy_Id__c;
					proAtt.Last_Name__c = c.Student__r.Student_Last_Name__c;
					proAtt.First_Name__c = c.Student__r.Student_First_Name__c;
					proAtt.Attendance_Date__c = c.Session_Date__c;
					
					if((!c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						!c.Picklist_Value__r.is_Unexcused__c && c.Picklist_Value__r.is_Early_Departure__c) || 
						(!c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Unexcused__c && 
						!c.Picklist_Value__r.is_Suspension__c && c.Picklist_Value__r.Is_Early_Departure__c) ||
						(!c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						!c.Picklist_Value__r.is_Unexcused__c && !c.Picklist_Value__r.is_Early_Departure__c && 
						c.Picklist_Value__r.Category__c == 'Present')){
							proAtt.Attendance_Type__c = 'Present';
							proAtt.Attendance_Status__c = 'NA';
					}else if(!c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						!c.Picklist_Value__r.is_Unexcused__c && !c.Picklist_Value__r.is_Early_Departure__c && 
						c.Picklist_Value__r.Category__c == 'Absent'){
							proAtt.Attendance_Type__c = 'Absent';
							proAtt.Attendance_Status__c = 'Excused';
					}else if(!c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						c.Picklist_Value__r.is_Unexcused__c && !c.Picklist_Value__r.is_Early_Departure__c && 
						c.Picklist_Value__r.Category__c == 'Absent'){
							proAtt.Attendance_Type__c = 'Absent';
							proAtt.Attendance_Status__c = 'Unexcused';
					}else if(c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						c.Picklist_Value__r.is_Unexcused__c && !c.Picklist_Value__r.is_Early_Departure__c){
							proAtt.Attendance_Type__c = 'Tardy';
							proAtt.Attendance_Status__c = 'NA';
					}else if(c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						c.Picklist_Value__r.is_Unexcused__c && c.Picklist_Value__r.is_Early_Departure__c){
							proAtt.Attendance_Type__c = 'Tardy';
							proAtt.Attendance_Status__c = 'Unexcused';
					}else if((c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						!c.Picklist_Value__r.is_Unexcused__c && !c.Picklist_Value__r.is_Early_Departure__c) || 
						(c.Picklist_Value__r.is_Tardy__c && !c.Picklist_Value__r.is_Suspension__c && 
						!c.Picklist_Value__r.is_Unexcused__c && c.Picklist_Value__r.is_Early_Departure__c)){
							proAtt.Attendance_Type__c = 'Tardy';
							proAtt.Attendance_Status__c = 'Excused';
					}else if(c.Picklist_Value__r.is_Suspension__c && c.Picklist_Value__r.Category__c == 'In School Suspension'){
						proAtt.Attendance_Type__c = 'Present';
						proAtt.Attendance_Status__c = 'Suspended';
					}else if(c.Picklist_Value__r.is_Suspension__c && c.Picklist_Value__r.Category__c == 'Out of School Suspension'){
						proAtt.Attendance_Type__c = 'Absent';
						proAtt.Attendance_Status__c = 'Suspended';
					}
					
					proAttList.add(proAtt);
				}	
			}
		}
		for(Student__c b : studentList){
			if(demographics){
				Proactive_Demographics__c proDemo = new Proactive_Demographics__c();
				proDemo.Last_Name__c = b.Student_Last_Name__c;
				proDemo.First_Name__c = b.Student_First_Name__c;
				proDemo.Middle_Initial__c = b.Student__c;
				proDemo.Address__c = b.Address__c;
				proDemo.City__c = b.City__c;
				proDemo.State__c = b.State__c;
				proDemo.Zip_Code__c = b.Zip_Code__c;
				if(b.Gender__c == 'Male' || b.Gender__c == 'M'){
					proDemo.Gender__c = 'M';
				}else if(b.Gender__c == 'Female' || b.Gender__c == 'F'){
					proDemo.Gender__c = 'F';
				}
				if(b.Ethnicity__c == 'Hispanic / Latino'){
					proDemo.Ethnicity__c = 'Y';
				}else if(b.Ethnicity__c == 'Non-Hispanic / Latino'){
					proDemo.Ethnicity__c = 'N';
				}
				if(b.Race__c == 'American Indian or Alaskan Native'){
					proDemo.Race__c = '998';
				}else if(b.Race__c == 'African American'){
					proDemo.Race__c = '1000';
				}else if(b.Race__c == 'Asian'){
					proDemo.Race__c = '999';
				}else if(b.Race__c == 'Hispanic or Latino'){
					proDemo.Race__c = '1002';
				}else if(b.Race__c == 'White'){
					proDemo.Race__c = '1002';
				}
				
				proDemo.Date_of_Birth__c = b.Date_of_Birth__c;
				proDemo.Grade__c = b.Grade__c;
				
				PGList = pgMap.get(b.Id);
				
				if(PGList != null){
					proDemo.Contact_First_Name__c = PGList[0].PG_First_Name__c;
					proDemo.Contact_Last_Name__c = PGList[0].PG_Last_Name__c;
					proDemo.Contact_Middle_Initial__c = PGList[0].PG_Middle_Name__c;
					demoPG = pgRelationship.get(PGList[0].PG_Relationship__c);
					if(demoPG != null){
						proDemo.Contact_Relationship__c = demoPG.Proactive_PG_Relationship__c;
					}
					proDemo.Contact_Phone__c = PGList[0].P_G_Phone__c;
				}
				demoTitleI = titleIMap.get(b.Title_1_Status__c);
				if(demoTitleI != null){
					proDemo.Title1_Status__c = demoTitleI.Proactive_TitleI__c;
				}
				if(b.Special_Ed__c){
					proDemo.Special_Education__c = 'Y';
				}else{
					proDemo.Special_Education__c = 'N';
				}
				proDemo.SPED_Level__c = b.Special_Education_Level__c;
				proDemo.SPED_Hours__c = b.Special_Education_Hours__c;
				demoSPEDSchool = spedSchoolMap.get(b.School__r.Name);
				if(b.Special_Ed__c && demoSPEDSchool != null){
					proDemo.SPED_School__c = demoSPEDSchool.Proactive_SPED_School__c;
				}
				if(b.ELL__c){
					proDemo.ELL_Status__c = 'Y';
				}else {
					proDemo.ELL_Status__c = 'N';
				}
				if(b.Immigrant__c){
					proDemo.Immigrant__c = 'Y';
				}else{
					proDemo.Immigrant__c = 'N';
				}
				String year = b.School_Year__r.Name__c;
				
				proDemo.School_Year__c = b.School_Year__r.Name__c.substring(b.School_Year__r.Name__c.length()-4);
				proDemo.Entry_Date__c = b.Entry_Date__c;
				demoEntry = pgEntry.get(b.Entry_Type__c);
				if(demoEntry != null){
					proDemo.Entry_Code__c = demoEntry.Proactive_Student_Entry__c;
				}
				proDemo.Exit_Date__c = (Date)b.Exit_Date__c;
				demoExit = pgExit.get(b.Exit_Reason__c);
				if(demoExit != null){
					proDemo.Exit_Code__c = demoExit.Proactive_Student_Exit__c;
				}
				proDemo.DC_Resident__c = b.DC_Resident__c;
				proDemo.Original_Graduation_Year__c = b.Original_Graduation_Year__c;
				proDemo.Teacher__c = b.Staff__c;
				proDemo.Homeroom__c = b.Homeroom__c;
				proDemo.School_Name__c = b.School__r.Name;
				proDemo.USI_ID__c = b.Legacy_Id__c;
				
				if(!checkDups.contains(proDemo.USI_ID__c)){
					proDemoList.add(proDemo);
				}
			}
		}
		if(proAttList.size() > 0){
			insert proAttList;
		}
		if(proDemoList.size() > 0){
			insert proDemoList;
		}
		}catch(Exception e){
			err = true;
		}
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		if(query != 'SELECT Id FROM Proactive_Attendance__c' || query != 'SELECT Id FROM Proactive_Demographics__c'){
		EmailTemplate eTemp = [Select Id From EmailTemplate WHERE DeveloperName = 'Proactive_Notification'];
		if(err != true){
			User userEmail = [SELECT Id, Email FROM User WHERE Id = :userId];
			String uEmail = userEmail.Email;
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(new List<String>{uEmail});
			mail.setReplyTo('Schoolforce-dev@acumensolutions.com');
			mail.setSenderDisplayName('Schoolforce Support');
			mail.setTemplateId(eTemp.Id);
			mail.setTargetObjectId(userId);
			mail.setSaveAsActivity(false);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}else{
			User userEmail = [SELECT Id, Email FROM User WHERE Id = :userId];
			String uEmail = userEmail.Email;
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(new List<String>{uEmail});
			mail.setReplyTo('Schoolforce-dev@acumensolutions.com');
			mail.setSenderDisplayName('Schoolforce Support');
			mail.setSubject('Proactive Processor Error!');
			mail.setPlainTextBody('The Proactive Processor has encountered an error, Please try again or contact your system administrator.');
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
		}
		
	}

}
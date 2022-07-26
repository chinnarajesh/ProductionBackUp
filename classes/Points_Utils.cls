public with sharing class Points_Utils {
	
	public static void updatePointsBalance(Map <Id, Points__c> newMap){
		Set<String> studentIds = new Set<String>();
		Map<String,Student__c> updateStudents = new Map<String,Student__c>();
		Date refreshDate;
		Boolean pointsReset = true;
		Setup__c setup;
					
		Date weekStartDate = system.today().toStartofWeek();
		 for(Points__c p: newMap.values()){
		 	studentIds.add(p.Student__c);
		 }
		 
		 if(studentIds!=null){
		 	Integer i = 0;
		 	for(Student__c s: core_SoqlUtils.getStudents(studentIds)){
		 		updateStudents.put(s.Id,s);
		 		if(i == 0){
		 			refreshDate = s.Setup__r.Points_Reset_Date__c;
		 			setup = s.Setup__r;
		 		}
		 		i++;
		 	}
		 }
		List<Schedule__c> firstResetDate = [SELECT Date__c FROM Schedule__c WHERE Setup__c =:setup.Id order by Date__c asc LIMIT 1];
		if(firstResetDate!=null && !firstResetDate.isEmpty()){
			if(System.today()< firstResetDate[0].date__c){
				pointsReset = false;
				refreshDate = setup.Term__r.Date_Start_Date__c;
			}
		}
		else{
			pointsReset = false;
			refreshDate = setup.Term__r.Date_Start_Date__c;
		}
		 
		Map<String,Decimal> studentCurrentPointsBalanceMap = Points_SoqlUtils.getCurrentBalance(refreshDate, System.today(), studentIds);
		Map<String,Decimal> studentWeekToDatePointsBalanceMap = Points_SoqlUtils.getCurrentBalance(weekStartDate, System.today(), studentIds);
		Decimal resetValue = setup.Points_Reset_Value__c;
		 for(String s: studentIds){
		 	if(studentCurrentPointsBalanceMap.get(s)!=null)
		 		updateStudents.get(s).Today_s_Points_Balance__c = studentCurrentPointsBalanceMap.get(s) + ((resetValue != null && pointsReset)?resetValue:0);
		 	
		 	if(studentWeekToDatePointsBalanceMap.get(s)!=null)
		 		updateStudents.get(s).Week_To_Date_Points_Balance__c = studentWeekToDatePointsBalanceMap.get(s)+((resetValue != null && pointsReset)?resetValue:0);
		 	
		 }
		 
		 update updateStudents.values();
	}
	
	public static void updatePointsBalance(List<Student__c> studentsList){
		List<Student__c> updateStudents = new List<Student__c>();
		 for(Student__c s: studentsList){
		 		s.Today_s_Points_Balance__c = s.Setup__r.Points_Reset_Value__c; 
		 		s.Week_To_Date_Points_Balance__c = s.Setup__r.Points_Reset_Value__c;
		 	
		 		updateStudents.add(s);	 
		 }
		 
		 update updateStudents; 
	}
	
	public static Set<String> getSetupsForReset(){
	 	Set<String> setupIds = new Set<String>();
	 	for(Schedule__c sc:[SELECT Id, Setup__c FROM Schedule__c WHERE Date__c =: System.today()]){
	 		setupIds.add(sc.Setup__c);
	 	}
		return setupIds;
	}
	
	public static void deleteOldSchedule(Set<String> setupIds){
		try{
			List<Schedule__c> oldschedules = [SELECT Id FROM Schedule__c WHERE Setup__c in: setupIds];
			if(oldschedules != null)
				delete oldschedules;
		}
		catch(Exception ex){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error updating new schedule'));
    		Global_Error__c ge = Error_Handling.handleError('Setup, '+setupIds+ 'Points Reset Schedule Config', 'Error deleting setup old schedules', ex);
			insert ge;
		}
	
	}
	
	public static void createScheduleRecords(Map<Id,Setup__c> oldsetups,Map<Id,Setup__c> newsetups){
		Set<String> setupsIds = new Set<String>();
		Map<String,Schedule__c> pointsScheduleMap ;
		Integer k;
		for(Setup__c s: newsetups.values()){
			//setupsIds.add(s.Id);
			if((s.Schedule_Start_Date__c!=null && s.Schedule_Start_Date__c!=null && s.Points_Frequency__c!=null )&&(s.Schedule_Start_Date__c!=oldsetups.get(s.Id).Schedule_Start_Date__c || s.Schedule_End_Date__c!=oldsetups.get(s.Id).Schedule_End_Date__c || s.Points_Frequency__c!=oldsetups.get(s.Id).Points_Frequency__c || s.Days__c !=oldsetups.get(s.Id).Days__c)){
				if(s.Schedule_Start_Date__c > s.Schedule_End_Date__c)
					s.addError('Start Date cannot be later than End Date. Please enter a valid date.');
				setupsIds.add(s.Id);
				System.debug('$$SetupDays'+s.Days__c);
				if(s.Points_Frequency__c == 'Weekly'){
					k=0;
					List<Integer> dayValues = core_DateUtils.returnWeekDays(s.Days__c.split(';'));
					pointsScheduleMap = new Map<String,Schedule__c>();	
					for(Date startDate = s.Schedule_Start_Date__c;startDate <= s.Schedule_End_Date__c;startDate= startDate.addDays(7)){
						System.debug('StartDate$$$$'+startDate.format());
						for(Integer i: dayValues){System.debug('StartDate$$$$'+startDate.format());
							if(startDate.toStartofWeek().addDays(i) >= s.Schedule_Start_Date__c && startDate.toStartofWeek().addDays(i) <= s.Schedule_End_Date__c){
								Date d = startDate.toStartofWeek().addDays(i);
								pointsScheduleMap.put(s.Id+'_'+d.format(),new Schedule__c(Setup__c=s.Id,Reference_Id__c=s.Id+'_'+d.format(),Date__c = d));
								if(k==0){
									s.Points_Reset_Date__c = d;
									k++;
									System.debug('s.Points_Reset_Date__c$$$$'+s.Points_Reset_Date__c);
								}
							}
						}
					}
				}
				else if(s.Points_Frequency__c == 'Monthly'){
						k=0;
						pointsScheduleMap = new Map<String,Schedule__c>();	
						for(Date startDate = s.Schedule_Start_Date__c;startDate <= s.Schedule_End_Date__c;startDate=startDate.addmonths(1)){
							for(String day: s.Days__c.split(';')){   
								Date monthdate;
								if(day == 'last' || day=='Last'){ 
									Integer lastDay = date.daysInMonth(startDate.Year(), startDate.month());
									
									monthdate = date.newinstance(startDate.year(), startDate.month(), lastDay);
								}
								else{	
									monthdate = date.newinstance(startDate.year(), startDate.month(), Integer.valueOf(day));
								}
								if(monthdate >= s.Schedule_Start_Date__c && monthdate <= s.Schedule_End_Date__c){
									pointsScheduleMap.put(s.Id+'_'+monthdate.format(),new Schedule__c(Setup__c=s.Id,Reference_Id__c=s.Id+'_'+monthdate.format(),Date__c = monthdate));
									if(k==0){
												s.Points_Reset_Date__c = monthdate;
												k++;
									}
								}
							}
						}
					}
					
		}
		}
		System.debug('$$@@@SetupIDs2'+setupsIds); 
		System.debug('$$SetupIDs2'+setupsIds.size());
		if(setupsIds.size() > 0){
			Points_Utils.deleteOldSchedule(setupsIds);
			System.debug('Deleted&&&&&&&&&&'); 
		}
		if(pointsScheduleMap!=null && !pointsScheduleMap.values().isEmpty())
			upsert pointsScheduleMap.values();
			
	}
	
		public static void pointsNotifications (ID UserID){
		User u = [select id, Email from User where id =: UserID];
		
		List<Threshold__c> thresholds = [select Cumulative__c, Notification__r.Setup__c, Notification__r.Grade__c, Notification__r.Setup__r.School__r.Name
										from Threshold__c
										where Notification__r.Module__c = 'Points'
										and Notification__r.Start_Date__c <= today
										and Notification__r.End_Date__c >= today
										order by Cumulative__c];
		if(!thresholds.isEmpty()){
			Set<Id> setups = new Set<ID>();
			boolean hasNullSetup = false;
			for(Threshold__c t:thresholds){
				if(t.Notification__r.Setup__c == null){
					hasNullSetup = true;
					break;
				} else {
					setups.add(t.Notification__r.Setup__c);
				}
			}
			
			string query = 'select id, Name, Setup__c, Today_s_Points_Balance__c,Grade__c'+
							' From Student__c'+
							' Where Active__c = true'+
							' and Today_s_Points_Balance__c >=' + thresholds[0].Cumulative__c;
			query += (hasNullSetup)?'':(' and Setup__c in: setups');
			query += ' order by Name';
			system.debug(query);
			List<Student__c> students = Database.query(query);
			
			string emailbody = '';
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setUseSignature(false);
			system.debug(u.Email);
			email.setToAddresses(new List<String>{String.valueOf(u.Email)});
			email.setSubject('Points Notifications for ' + system.today().format());
			
			for(Threshold__c t:thresholds){
				if(t.Notification__r.Setup__c == null){
					emailbody += 'All Schools: ';
				} else {
					emailbody += t.Notification__r.Setup__r.School__r.Name + ': ';
				}
				emailbody += 'Students Over ' + t.Cumulative__c + ' Points: \n';
				
				Set<String> grades = new Set<String>();
				if(t.Notification__r.Grade__c != null){
					grades = new Set<String>(StringUtils.splitAndTrim(t.Notification__r.Grade__c, ';'));
				}
				for(Student__c s:students){
					if(s.Today_s_Points_Balance__c >= t.Cumulative__c){
						if(grades.isEmpty() || grades.contains(s.Grade__c)){
							emailbody += '\t' + s.Name + '\n';
						}
					}
				}
				emailbody += '\n';
			}
			email.setPlainTextBody(emailbody);
			Messaging.SendEmailResult[] results = new Messaging.SendEmailResult[]{};
			results.addAll(Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email}, false));
			
			for(Messaging.SendEmailResult result:results){
				if(!result.isSuccess()){ //note: this is a method, not a field.
					system.debug(result.getErrors()[0].getMessage());
					Error_Handling.schoolForceException e = new Error_Handling.schoolforceexception();
				}	
			}
		}
	}
	
	@isTest
	private static void testPointsNotifications(){
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = TestDataSetupUtil_v2.term.Date_Start_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = TestDataSetupUtil_v2.term.End_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Monthly';
        TestDataSetupUtil_v2.activeSetUp.Points_Reset_Value__c = 0;
        TestDataSetupUtil_v2.activeSetUp.Days__c = '1';
        update TestDataSetupUtil_v2.activeSetUp;
		List<Picklist_Value__c> cats = testDataSetupUtil_v2.createPointsCats(null);
		
		string refID = (String)testDataSetupUtil_v2.studentsList[0].id+(String)cats[0].id+String.valueOf(system.today())+'';
		Points__c point = new Points__c(Student__c = testDataSetupUtil_v2.studentsList[0].id
										,Points_Date__c = system.today()
										,Points__c = 35
						 				,Staff__c = testDataSetupUtil_v2.teachersList[0].id
										,Category__c = cats[0].id
										,Reference_Id__c = refID);
		
		insert point;
		
		Notification__c notification = new Notification__c(Module__c = 'Points'
										,Setup__c = testDataSetupUtil_v2.activeSetUp.id
										,Start_Date__c = system.today().addDays(-7)
										,End_Date__c = system.today().addDays(7)
										,Grade__c = '1;2;3;4;5;6;7;8;9;10;11;12');
		
		insert notification;
		
		Threshold__c thresh = new Threshold__c(Notification__c = notification.id
										,Cumulative__c = 30);
										
		insert thresh;
		
		Test.startTest();
			Points_Utils.pointsNotifications(testDataSetupUtil_v2.staffUsersList[0].id);
		Test.stopTest();
	}
}
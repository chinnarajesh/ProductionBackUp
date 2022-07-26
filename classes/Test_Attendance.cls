@isTest
private class Test_Attendance{
	static List<Picklist_Value__c> pvl;
	static List<Notification__c> n;
	
	//setup test data
	static void setupSessions(){
		Date startDate = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		for (Section__c sect: testDataSetupUtil_v2.sectionsList){
			for(integer i=0;i<10;i++){
				testDataSetupUtil_v2.semester.Date_Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(i);
				if (!sect.daily_attendance__c) testDataSetupUtil_v2.getSessions(10,testDataSetupUtil_v2.semester,sect.Id, i);
				else testDataSetupUtil_v2.getSessions(10,testDataSetupUtil_v2.semester,sect.Id,  null);
				testDataSetupUtil_v2.semester.Date_Start_Date__c = startDate;
			}
		}
	}
	
	static void setup(){
		core_triggerUtils.studentTriggerUpdate(false); 
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);
		
		pvl = testDataSetupUtil_v2.createDefaultAttendanceTypes(testDataSetupUtil_v2.activeSetup);
		
		system.debug('~~~~~ staff user: '+testDataSetupUtil_v2.staffUsersList[1]);
		n  =  new List<Notification__c>();
		n.add(new Notification__c(Name = 'TestTardy6',Daily_Tracking__c = true,Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c,End_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(2),Picklist_Value__c = pvl[4].Id,Setup__c =  testDataSetupUtil_v2.activeSetUp.id,Grade__c = '6'));
		n.add(new Notification__c(Name = 'TestTardy5',Daily_Tracking__c = true,Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c,End_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(2),Picklist_Value__c = pvl[4].Id,Setup__c =  testDataSetupUtil_v2.activeSetUp.id,Grade__c = '5'));
		//Put one in future
		n.add(new Notification__c(Name = 'TestUA6',Daily_Tracking__c = true,Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c,End_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(2),Picklist_Value__c = pvl[2].Id,Setup__c =  testDataSetupUtil_v2.activeSetUp.id,Grade__c = '6'));
		n.add(new Notification__c(Name = 'TestUA5',Daily_Tracking__c = true,Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c,End_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(2),Picklist_Value__c = pvl[2].Id,Setup__c =  testDataSetupUtil_v2.activeSetUp.id,Grade__c = '5'));
		n.add(new Notification__c(Name = 'TestUA62',Daily_Tracking__c = true,Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c,End_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(10),Picklist_Value__c = pvl[2].Id,Setup__c =  testDataSetupUtil_v2.activeSetUp.id,Grade__c = '6'));
		//Test Map works in Notification Processing
		n.add(new Notification__c(Name = 'Test Tardy 6 2', Daily_Tracking__c  = true, Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c,End_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(30), Picklist_Value__c = pvl[4].Id , 
		Setup__c =  testDataSetupUtil_v2.activeSetUp.id, Parental_Notification__c = TRUE, Grade__c = '6'));
		insert n;

		Threshold__c tn  =  new Threshold__c(Notification__c = n[0].Id,Consecutive__c = 0,Cumulative__c = 2);
		insert tn;
		
		tn  =  new Threshold__c(Notification__c = n[0].Id,Consecutive__c = 1,Cumulative__c = 2);
		insert tn;
	}
	
	/*
	static testMethod void test_DailyAttendance(){
			setup();
			testDataSetupUtil_v2.sectionsList[1].daily_attendance__c=true;
			update testDataSetupUtil_v2.sectionsList;
			testDataSetupUtil_v2.activeSetup.cascade_daily_attendance__c = true;
			update testDataSetupUtil_v2.activeSetup;
			system.assertEquals(true, [select cascade_daily_attendance__c from Setup__c where id =:testDataSetupUtil_v2.activeSetup.id ].cascade_daily_attendance__c);
			setupSessions();
			test.startTest();
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
				PageReference p = Page.Attendance;
				test.setCurrentPage(p);
			 Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
			  AttendanceController testac = new AttendanceController ();
				testac.timeEl.Date_Start_Date__c = testdate;  
				system.debug('~~~~~ attStartDate: '+testac.timeEl.Date_Start_Date__c);
				testac.getSectList(); 
				testac.section = testac.sectionList[0].Id;
				system.debug('~~~~~ sessions: '+[SELECT id FROM Session__c WHERE Section__c = :testac.section and Session_Date__c = :testdate and Record_Attendance__c = true]);
				testac.retrieveStudents();
				List<AttendanceWrapper> testaw = testac.atnWrapList; 
				system.debug('~~~~~ student list: '+testaw);
				//Move this to DataSetup once we know where to set it...
				Section__c usection = [Select Id from Section__c where Id = :testac.section];
				//we need one of the sections to be a daily attendance section...we'll set the first one for now
				usection.Daily_Attendance__c = true;
				usection.Record_Attendance__c = true;
				update usection;
				
				Id tstudentId = testaw[0].studID;
				Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
				update tests;
					 
				testac.getSectList(); 
				testac.section = testac.sectionList[0].Id;
				testac.retrieveStudents();
				//List<AttendanceWrapper> testaw = testac.atnWrapList; 
				testaw = testac.atnWrapList; 
				
				testaw[0].statusVal = pvl[2].Name ; //2 represents the absent value
				//Set a time which should fail
				testaw[0].te.Start_Time__c = testac.selectedSession.Start_DateTime__c.addMinutes(30);
				
				testac.save(); //should trigger error
		}
	}
	
	static testMethod void test_AttendanceController(){
		setup();
		setupSessions();
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
		 	Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
			AttendanceController testac = new AttendanceController ();
			testac.timeEl.Date_Start_Date__c = testdate;  
			system.debug('~~~~~ attStartDate: '+testac.timeEl.Date_Start_Date__c);
			testac.getSectList(); 
			testac.section = testac.sectionList[0].Id;
			testac.retrieveStudents();
			List<AttendanceWrapper> testaw = testac.atnWrapList; 
			system.debug(testaw);
			//Move this to DataSetup once we know where to set it...
			Section__c usection = [Select Id from Section__c where Id = :testac.section];
			//we need one of the sections to be a daily attendance section...we'll set the first one for now
			usection.Daily_Attendance__c = true;
			usection.Record_Attendance__c = true;
			update usection;
			
			Id tstudentId = testaw[0].studID;
			Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
			update tests;
			
			test.startTest();
				testac.getSectList(); 
				testac.section = testac.sectionList[0].Id;
				testac.retrieveStudents();
				//List<AttendanceWrapper> testaw = testac.atnWrapList; 
				testaw = testac.atnWrapList; 
				
				testaw[0].statusVal = pvl[2].Name ; //2 represents the absent value
				//Set a time which should fail
				testaw[0].te.Start_Time__c = testac.selectedSession.Start_DateTime__c.addMinutes(30);
				
				testac.save(); //should trigger error
				//reset trigger helper
				core_triggerUtils.recursiveHelper(false); 
				//remove time
				testaw[0].atn.Arrival_Time__c = null;
				//save again with success
				testac.save();
		   
	 Attendance_Tracking__c [] checkat = [
	Select Id, Notification__c, 
	Consecutive__c, Cumulative__c 
	FROM Attendance_Tracking__c where Student__c = :tstudentId];
	//Should only be two, since two Notification's tracking UA, over different times for 6th Grade and UA
	system.assertequals(2, checkat.size());
 //   system.debug('notifications: '+n);
	system.assertequals(n[2].Id, checkat[0].Notification__c);
	system.assertequals(1,checkat[0].Consecutive__c);
	system.assertequals(1,checkat[0].Cumulative__c);
	
	//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false); 
	
	//now change to different status for same day
	AttendanceController testacu = new AttendanceController ();
	testacu.timeEl.Date_Start_Date__c = testdate;  
	testacu.getSectList(); 
	testacu.section = testac.sectionList[0].Id;
   // system.debug('XX1' + testacu.section);
	testacu.retrieveStudents();
	List<AttendanceWrapper> testawu = testacu.atnWrapList;
	testawu[0].statusVal = pvl[4].Name; //now 4 to represent tardy
	//check no time set
  
	testacu.save();
   
	//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false); 
	
   //test fail when outside time parameters
	testawu[0].atn.Arrival_Time__c = testac.selectedSession.Start_DateTime__c.adddays(-2);
	testacu.save();
		//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false); 
	
	//Set a valid time
	testawu[0].atn.Arrival_Time__c = testac.selectedSession.Start_DateTime__c.addminutes(30);
	 //testawu[0].atn.Arrival_Time__c = testdate.addDays(1);
	  // testawu[0].atn.Arrival_Time__c =   testawu[0].atn.Arrival_Time__c.addMinutes(30);
	   system.debug('~~~~~ arrivalTime: '+testawu[0].atn.Arrival_Time__c);
	testacu.save();
		//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false); 
	
	//Select Attendance Tracking Records created by trigger
	Attendance_Tracking__c [] checkatu = [
			Select Id, Notification__c, Consecutive__c, 
			Cumulative__c from Attendance_Tracking__c 
			WHERE Student__c = :tstudentId order by CreatedDate ASC];
			system.debug('~~~~~ Check T Writes' + checkatu);
	//Should now be five, even though UA ones were reset to zero
	system.assertequals(4, checkatu.size());
	//old one now reset to zero
	system.assertequals(0,checkatu[0].Consecutive__c);
	system.assertequals(0,checkatu[0].Cumulative__c);
	//new one set to 1
	system.assertequals(1,checkatu[2].Consecutive__c);
	system.assertequals(1,checkatu[2].Cumulative__c);
	
	 Test.stopTest(); 
   
					   
		}
	}
	*/
	
	static testMethod void test_validation(){
		setup();
		setupSessions();
		Test.startTest();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
			//check departure validation code
		 	Date testdate2 = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(2);
		
			AttendanceController testacdep = new AttendanceController ();
			testacdep.timeEl.Date_Start_Date__c = testdate2;  
			testacdep.getSectList(); 
			testacdep.section = testacdep.sectionList[0].Id;
			system.debug('~~~~~ sessions: '+[SELECT id, Start_DateTime__c, End_DateTime__c, Session_Date__c FROM Session__c WHERE Section__c = :testacdep.section]);
			testacdep.retrieveStudents();
			List<AttendanceWrapper> testawdep = testacdep.atnWrapList; 
			testawdep[0].Statusval = pvl[3].Name ;
			//Set only a arrival time which cause save to fail
			testawdep[0].atn.Arrival_Time__c = testacdep.selectedSession.Start_DateTime__c.addminutes(30);
			testacdep.save();
			//reset trigger helper
			core_triggerUtils.recursiveHelper(false); 
			//fix arrival time and add departure
			testawdep[0].atn.Departure_Time__c = testacdep.selectedSession.Start_DateTime__c.addminutes(30);
			testawdep[0].atn.Arrival_Time__c = null;
			//save again
			testacdep.save();
		   //reset trigger helper
			core_triggerUtils.recursiveHelper(false); 
			core_triggerUtils.studentTriggerUpdate(true);
		}
		Test.stopTest();
	}
	
	/*
	static testMethod void test_AttendanceController_2(){
		setup();
		setupSessions();
	test.startTest();
		Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
		 
			AttendanceController testac = new AttendanceController ();
				testac.timeEl.Date_Start_Date__c = testdate;  
				testac.getSectList(); 
				testac.section = testac.sectionList[0].Id;
				testac.retrieveStudents();
				List<AttendanceWrapper> testaw = testac.atnWrapList; 
				//Move this to DataSetup once we know where to set it...
				Section__c usection = [Select Id from Section__c where Id = :testac.section];
				//we need one of the sections to be a daily attendance section...we'll set the first one for now
					 usection.Daily_Attendance__c = true;
					 usection.Record_Attendance__c = true;
					 update usection;
   
   //Tardy Tests
	 AttendanceController testac2 = new AttendanceController ();
	testac2.timeEl.Date_Start_Date__c = testdate;  
	
	testac2.getSectList(); 
	testac2.section = testac2.sectionList[0].Id;
	testac2.retrieveStudents();
	List<AttendanceWrapper> testaw2 = testac2.atnWrapList; 
	Id tstudentId = testaw2[0].atn.Student__c;
	Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
	update tests;
	testaw2[0].Statusval = pvl[0].Name;
	testaw2[0].atn.picklist_value__c = pvl[0].id;
	//Set arrival time = 30 mins after day 2 of daily start time
	testaw2[0].atn.Arrival_Time__c = testac2.selectedSession.Start_DateTime__c.addminutes(30);
	//testaw2[0].te.StartTime__c = testac2.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
	system.debug('~~~~~ Check bstat 1: ' + testaw2[0]); 
	testac2.save();
 
	
		}
	}
	
	static testMethod void test_AttendanceController_3(){
		setup();
				setupSessions();
	test.startTest();
		Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
		 	
	
	//Change Time to only 15 on same day
	
	AttendanceController testac2u = new AttendanceController ();
	testac2u.timeEl.Date_Start_Date__c = testdate;  
	
	testac2u.getSectList(); 
	testac2u.section = testac2u.sectionList[0].Id;
	testac2u.retrieveStudents();   
	
	List<AttendanceWrapper> testaw2u = testac2u.atnWrapList; 
		Attendance__c atn = new Attendance__c(Picklist_Value__c=pvl[4].id, Student__c=testaw2u[0].atn.student__c, Session__c=testac2u.selectedSession.id, Arrival_Time__c = testac2u.selectedSession.Start_DateTime__c.addminutes(30));
 			insert atn;
		 atn = [SELECT id, time_lost_rollup__c FROM Attendance__c WHERE Student__c=:testaw2u[0].atn.student__c AND Session__c=:testac2u.selectedSession.id];
	system.assertequals(30, atn.time_lost_rollup__c);
	testaw2u[0].Statusval = pvl[4].Name;
	testaw2u[0].te.StartTime__c = testac2u.selectedSession.Start_DateTime__c.addminutes(15).format('h:mm a');
	testaw2u[0].atn.Arrival_Time__c = testac2u.selectedSession.Start_DateTime__c.addminutes(15);
	testac2u.save();
	}
	}
	*/
	
	static testMethod void test_AttendanceNotifications(){
 		setup();
		setupSessions();
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			
			Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
	 
			AttendanceController testac = new AttendanceController ();
			testac.timeEl.Date_Start_Date__c = testdate;  
			testac.getSectList(); 
			testac.section = testac.sectionList[0].Id;
			testac.retrieveStudents();
			List<AttendanceWrapper> testaw = testac.atnWrapList; 
			//Move this to DataSetup once we know where to set it...
			Section__c usection = [Select Id from Section__c where Id = :testac.section];
			//we need one of the sections to be a daily attendance section...we'll set the first one for now
			usection.Daily_Attendance__c = true;
			usection.Record_Attendance__c = true;
			update usection;
			
			test.startTest();
				//Check Consecutive Day
				AttendanceController testac16 = new AttendanceController ();
				testac16.timeEl.Date_Start_Date__c =  testdate.adddays(2);	
				testac16.getSectList(); 
				testac16.section = testac16.sectionList[0].Id;
				testac16.retrieveStudents();
				List<AttendanceWrapper> testaw16 = testac16.atnWrapList; 
				Id tstudentId = testaw16[0].studID;
				Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
				update tests;
				testaw16[0].Statusval = pvl[4].Name; //4 represents the tardy value
				//Set arrival time = 30 mins after day 2 of daily start time
				testaw16[0].te.StartTime__c = testac16.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
				
				testac16.save();
				//we need to reset the trigger helper
				core_triggerUtils.recursiveHelper(false); 
				
				//Create one for next day as well
			   // AttendanceController testac16a = new AttendanceController ();
				testac16.timeEl.Date_Start_Date__c = testdate.adddays(3);  
				testac16.getSectList(); 
				testac16.section = testac16.sectionList[0].Id;
				testac16.retrieveStudents();
				 testaw16 = testac16.atnWrapList; 
				testaw16[0].Statusval = pvl[4].Name; //4 represents the tardy value
				//Set arrival time = 30 mins after day 2 of daily start time
				testaw16[0].te.StartTime__c = testac16.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
				testac16.save();
				//we need to reset the trigger helper
				core_triggerUtils.recursiveHelper(false); 
				
				
				Attendance_ManageStudentAttendance.processnotifications(testdate.adddays(2), false);
				
				Attendance_Tracking__c [] checkatn  =  [
				Select Id, Notification__c, Admin_Notifications_cons__c, 
				Admin_Notifications_cuml__c from Attendance_Tracking__c where 
				Student__c  =  :tstudentId AND  Notification__c  =  :n[0].Id];
				system.assertnotequals(null, checkatn[0].Admin_Notifications_cons__c);
				
				
				//Test Parental Notifications Code
				 Attendance_ManageStudentAttendance.processnotifications(testdate.adddays(2), true);
				 
				
				 test.stopTest();
  }  //end run as
} //end test 3

	static testMethod void test_AttendanceNotifications_2(){
		setup();
		setupSessions();
		Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
		PageReference p = Page.Attendance;
		test.setCurrentPage(p);
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			AttendanceController testac = new AttendanceController();
			testac.timeEl.Date_Start_Date__c = testdate;  
			testac.getSectList();
			system.debug('~~~~~ section: '+testac.section);
			testac.section = testac.sectionList[0].Id;
			testac.retrieveStudents();
			List<AttendanceWrapper> testaw = testac.atnWrapList; 
			//Move this to DataSetup once we know where to set it...
			Section__c usection = [select id from Section__c where ID =:testac.section];
			//we need one of the sections to be a daily attendance section...we'll set the first one for now
			usection.Daily_Attendance__c = true;
			usection.Record_Attendance__c = true;
			update usection;
				
			test.startTest();
				//Check Consecutive Day
				AttendanceController testac16 = new AttendanceController();
				testac16.timeEl.Date_Start_Date__c = testdate.adddays(2);  
				testac16.getSectList();
				testac16.section = testac16.sectionList[0].Id;
				testac16.retrieveStudents();
				List<AttendanceWrapper> testaw16 = testac16.atnWrapList;
				Id tstudentId = testaw16[0].studID;
				Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
				update tests;
				testaw16[0].Statusval = pvl[4].Name;  //First Tardy
				//Set arrival time = 30 mins after day 2 of daily start time
				testaw16[0].te.StartTime__c = testac16.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
				testac16.save();
				//we need to reset the trigger helper
				core_triggerUtils.recursiveHelper(false); 
				//Create one for next day as well
			   // AttendanceController testac16a = new AttendanceController ();
				testac16.timeEl.Date_Start_Date__c = testdate.adddays(3);  
				testac16.getSectList(); 
				testac16.section = testac16.sectionList[0].Id;
				testac16.retrieveStudents();
				 testaw16 = testac16.atnWrapList; 
				testaw16[0].Statusval = pvl[4].Name;   //Still Tardy
				//Set arrival time = 30 mins after day 2 of daily start time
				testaw16[0].te.StartTime__c = testac16.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
				testac16.save();
				//we need to reset the trigger helper
				core_triggerUtils.recursiveHelper(false);
				 
				//Check Rollbacks
				testaw16[0].Statusval = pvl[2].Name;   //Next Unexcused Absence
				//Should prevent save with UA Status and Arrival Time
				testaw16[0].te.StartTime__c = testac16.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
				testac16.save();
			test.stopTest();
		}
	}

	static testMethod void test_AttendanceController_Fails(){
		setup();
		setupSessions();
	test.startTest();
		Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
		 
			AttendanceController testac = new AttendanceController ();
				testac.timeEl.Date_Start_Date__c = testdate;  
				testac.getSectList(); 
				testac.section = testac.sectionList[0].Id;
				testac.retrieveStudents();
				List<AttendanceWrapper> testaw = testac.atnWrapList; 
				//Move this to DataSetup once we know where to set it...
				Section__c usection = [Select Id from Section__c where Id = :testac.section];
				//we need one of the sections to be a daily attendance section...we'll set the first one for now
					 usection.Daily_Attendance__c = true;
					 usection.Record_Attendance__c = true;
					 update usection;
					 
					 Id tstudentId = testaw[0].studID;
					 Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
					  update tests;
					 
	//Test Complete Fail
   Session__c [] deletesession = [Select Id from Session__c where Session_Date__c = :testdate.adddays(3)];
   
	AttendanceController testaccfail = new AttendanceController ();
	testaccfail.timeEl.Date_Start_Date__c = testdate.adddays(3);  
	testaccfail.getSectList(); 
	testaccfail.retrieveStudents();
	//reset trigger helper
   
	testaccfail.timeEl.Date_Start_Date__c = testdate.adddays(2);  
	testaccfail.getSectList(); 
	
	testaccfail.section = testaccfail.sectionList[0].Id;
	testaccfail.retrieveStudents();
	List<AttendanceWrapper> testaw16 = testaccfail.atnWrapList; 
	testaw16[0].Statusval = pvl[0].Name;
	//Set arrival time = 30 mins after day 2 of daily start time
	testaw16[0].te.StartTime__c = testaccfail.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
	//now selectin section to cause error
	
	Section__c dels = [Select Id from Section__c where Id = :testaccfail.section];
	system.assert(dels.id != null);
	delete dels;
	testaccfail.save();
	core_triggerUtils.recursiveHelper(false);
	core_triggerUtils.studentTriggerUpdate(true); 
	
}


}
static testMethod void test_Attendance_Part2(){
		setup();
				setupSessions();
		  test.startTest();
		Date testdate = TestDataSetupUtil_v2.semester.date_start_Date__c;
		system.runAs(TestDataSetupUtil_v2.staffUsersList[1]){
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
		 
			AttendanceController testac = new AttendanceController ();
				testac.timeEl.Date_Start_Date__c = testdate;  
				testac.getSectList(); 
				testac.section = testac.sectionList[0].Id;
				testac.retrieveStudents();
				List<AttendanceWrapper> testaw = testac.atnWrapList; 
				//Move this to DataSetup once we know where to set it...
				Section__c usection = [Select Id from Section__c where Id = :testac.section];
				//we need one of the sections to be a daily attendance section...we'll set the first one for now
					 usection.Daily_Attendance__c = true;
					 usection.Record_Attendance__c = true;
					 update usection;
					 
					 Id tstudentId = testaw[0].studID;
					 Student__c tests = new Student__c (Id = tstudentId, grade__c = '6');
					  update tests;
					 

//Check Consecutive Day

	
	AttendanceController testac16 = new AttendanceController ();
	testac16.timeEl.Date_Start_Date__c = testdate.adddays(2);  
	testac16.getSectList(); 
	testac16.section = testac16.sectionList[0].Id;
	testac16.retrieveStudents();
	List<AttendanceWrapper> testaw16 = testac16.atnWrapList; 
	testaw16[0].Statusval = pvl[4].Name;
	//Set arrival time = 30 mins after day 2 of daily start time
	testaw16[0].te.StartTime__c = testac16.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
	testac16.save();
	//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false); 
	
	Attendance_ManageStudentAttendance.processnotifications(testdate.adddays(2), false);
	
	Attendance_Tracking__c [] checkatn  =  [
	Select Id, Notification__c, Admin_Notifications_cons__c, 
	Admin_Notifications_cuml__c from Attendance_Tracking__c where 
	Student__c  =  :tstudentId AND  Notification__c  =  :n[0].Id];
	system.assertnotequals(null, checkatn[0].Admin_Notifications_cons__c);
	
	
	//Test Parental Notifications Code
	 Attendance_ManageStudentAttendance.processnotifications(testdate.adddays(2), true);
	}
}
	/*
	static testMethod void test_refreshYear(){
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		
		test.startTest();
		Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c;
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			PageReference p = Page.Attendance;
			test.setCurrentPage(p);
			
			AttendanceController testac = new AttendanceController ();
			testac.yearId =testDataSetupUtil_v2.masterYear.Id ;
			testac.schoolId =testDataSetupUtil_v2.school.Id;  
			testac.reloadYear();
			test.stopTest();
			system.assertnotequals(0, testac.sectionList.size());
		}
	}
	*/
 
} //end class
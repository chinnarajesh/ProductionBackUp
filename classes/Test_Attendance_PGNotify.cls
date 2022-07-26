@isTest
private class Test_Attendance_PGNotify{

	static List<Picklist_Value__c> pvl;
	static List<Notification__c> n;
	static testMethod void test_AttendancePNotifier(){
		core_triggerUtils.studentTriggerUpdate(false); 
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);

		Date startDate = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		for (Section__c sect: testDataSetupUtil_v2.sectionsList){
			for(integer i=0;i<10;i++){
				testDataSetupUtil_v2.semester.Date_Start_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(i);
				if (!sect.daily_attendance__c) testDataSetupUtil_v2.getSessions(10,testDataSetupUtil_v2.semester,sect.Id, i);
				else testDataSetupUtil_v2.getSessions(10,testDataSetupUtil_v2.semester,sect.Id,  null);
				testDataSetupUtil_v2.semester.Date_Start_Date__c = startDate;
			}
		}
		
		pvl = testDataSetupUtil_v2.createDefaultAttendanceTypes(testDataSetupUtil_v2.activeSetup);
		
		List <Value__c> tvalues = new List<Value__c> ();
		tvalues.add(new Value__c (Setup__c = testDataSetupUtil_v2.activeSetUp.id, Communication_Type__c = 'SMS', Language__c = 'English', Type__c = 'Tardy Alerts', Text_Alert__c = 'TEST ALERT 1'));
		tvalues.add(new Value__c (Setup__c = testDataSetupUtil_v2.activeSetUp.id, Communication_Type__c = 'SMS', Language__c = 'English', Type__c = 'Attendance Alerts', Text_Alert__c = 'TEST ALERT 1'));
		tvalues.add(new Value__c (Setup__c = testDataSetupUtil_v2.activeSetUp.id, Communication_Type__c = 'SMS', Language__c = 'Spanish', Type__c = 'Tardy Alerts', Text_Alert__c = 'ES TEST ALERT 1'));
		tvalues.add(new Value__c (Setup__c = testDataSetupUtil_v2.activeSetUp.id, Communication_Type__c = 'SMS', Language__c = 'Spanish', Type__c = 'Attendance Alerts', Text_Alert__c = 'ES TEST ALERT 1'));
		insert tvalues;

List<Notification_Settings__c> ns = [Select Reply_To__c from Notification_Settings__c];

if (ns.size() == 0) {
	ns.add(new Notification_Settings__c (Reply_To__c = 'testschoolforce@acumensolutions.com', Subject__c =  'SchoolForce Notification', Display_Name__c = 'SchoolForce Test'));
	insert ns;
}
 
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

	testac.getSectList();
	testac.section = testac.sectionList[0].Id;
	testac.retrieveStudents();
	testaw = testac.atnWrapList;
	testaw[0].Statusval = pvl[4].Name;
	//Set arrival time = 30 mins after day 2 of daily start time
	testaw[0].te.StartTime__c = testac.selectedSession.Start_DateTime__c.addminutes(30).format('h:mm a');
	testac.save();
	//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false);

	testac.timeEl.Date_Start_Date__c = testdate.adddays(1);
	testac.getSectList();
	testac.section = testac.sectionList[0].Id;
	testac.retrieveStudents();
	testaw = testac.atnWrapList;
	testaw[0].Statusval = pvl[2].Name;
	//Set arrival time = 30 mins after day 2 of daily start time
	testaw[0].te.StartTime__c = null;
	testac.save();
	//we need to reset the trigger helper
	core_triggerUtils.recursiveHelper(false);


	Attendance_PGNotification pgn1  =  new Attendance_PGNotification('Tardy Alerts');
	pgn1.query  =  core_SoqlUtils.getMainTardyQuery(testdate, true) ;
	Database.executeBatch(pgn1,1);

	Attendance_PGNotification pgn2  =  new Attendance_PGNotification('Attendance Alerts');
	pgn2.query  =  core_SoqlUtils.getMainAbsentQuery(testdate.adddays(1), true) ;
	Database.executeBatch(pgn2,1);


	test.stoptest();
	//check date set
	Attendance__c [] testda  =  [
	Select Id, Date_Time_of_Parental_Notification__c
	FROM Attendance__c where Student__c  =  :tstudentId];
	system.debug('testda'+testda);
	system.assertnotequals(null, testda[0].Date_Time_of_Parental_Notification__c);
	system.assertnotequals(null, testda[1].Date_Time_of_Parental_Notification__c);


	}//end run as
	} //end test
	} //end test class
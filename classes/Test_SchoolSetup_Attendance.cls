@isTest
public with sharing class Test_SchoolSetup_Attendance {
	public static SchoolSetup_Attendance controller			{get;set;}
	public static integer globalErrors						{get;set;}
	public static List<Picklist_Value__c> attendanceValues	{get;set;}
	public static Value__c testValue						{get;set;}
	public static Notification__c testNotification			{get;set;}
	public static Threshold__c testThreshold				{get;set;}
	
	public static testMethod void testConstructor(){
		TestDataSetupUtil_v2.setUPCoreData(1);
		PageReference page = new PageReference('/apex/SchoolSetup_Attendance');
		Test.setCurrentPage(page);
		
		Test.startTest();
			controller = new SchoolSetup_Attendance();
			system.assertEquals(SetupWizard_Utils.NO_SETUP_MESSAGE, ApexPages.getMessages()[0].getSummary());
			page = new PageReference('/apex/SchoolSetup_Attendance?setupId='+testDataSetupUtil_v2.activeSetUp.id);
			Test.setCurrentPage(page);
			controller = new SchoolSetup_Attendance();
			system.assertEquals(testDataSetupUtil_v2.activeSetup.id,controller.cSetup.setup.id);
		Test.stopTest();
	}
	
	/********************************* SETUP CONFIGURATION *********************************/
	public static testMethod void testSaveConfiguration(){
		setupData();
		
		Test.startTest();
			controller.cSetup.setup.Cascade_Daily_Attendance__c = true;
			controller.saveConfiguration();
			
			Setup__c testSetup = [SELECT Cascade_Daily_Attendance__c FROM Setup__c WHERE id=:TestDataSetupUtil_v2.activeSetup.id];
			system.assertEquals(true,testSetup.Cascade_Daily_Attendance__c);
			
			//controller.cSetup.setup = new Setup__c();
			//controller.saveConfiguration();
			//system.assertEquals('There was an error saving the configuration to the system.',ApexPages.getMessages()[0].getSummary());
			//system.assertEquals(globalErrors+1,getNumGlobalErrors());
		Test.stopTest();
	}
	
	/********************************* ATTENDANCE VALUE CONFIGURATION *********************************/
	public static testMethod void testSetPicklistValue(){
		setupData();
		ID attendanceRecordType = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance');
		
		Test.startTest();
			controller.setPicklistValue();
			system.assertEquals(attendanceRecordType,controller.modalValue.RecordTypeId);
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,controller.modalValue.Setup__c);
			system.assert(controller.bShowAttendance);
			system.assert(!controller.bShowMessages);
			system.assert(!controller.bShowNotifications);
			system.assert(!controller.bShowThresholds);
			
			Picklist_Value__c testPV = attendanceValues[0];
			controller.selectedPV = null;
			controller.setPicklistValue();
			//assert a new value is created, and selected picklist is not displayed
			system.assertEquals(null,controller.modalValue.id);
			
			controller.selectedPV = testPV.id;
			controller.setPicklistValue();
			system.assertEquals(testPV.id,controller.modalValue.id);
			
			testPV.Setup__c = null;
			update testPV;
			//have to refresh values
			controller = new SchoolSetup_Attendance();
			controller.selectedPV = testPV.id;
			controller.setPicklistValue();
			//since testValue has null setup, a message should be displayed
			system.assertEquals('This is an org-wide attendance value and may be in use by other schools.  Please edit with caution.',ApexPages.getMessages()[0].getSummary());
			
			//break it
			controller.selectedPV = TestDataSetupUtil_v2.activeSetUp.id;
			controller.setPicklistValue();
			system.assertEquals('This attendance value is not available to be edited.',ApexPages.getMessages()[1].getSummary());
		Test.stopTest();
	}
	
	public static testMethod void testSaveStatus(){
		setupData();
		
		Test.startTest();
			controller.saveStatus();
			system.assertEquals('There was an error saving the attendance value to the system.',ApexPages.getMessages()[0].getSummary());
			system.assertEquals(globalErrors+1,getNumGlobalErrors());
			
			controller.selectedPV = attendanceValues[0].id;
			controller.setPicklistValue();
			controller.modalValue.Name = 'Change Att Value';
			controller.saveStatus();
			Picklist_Value__c testPv = [SELECT id, Name FROM Picklist_Value__c WHERE id=:attendanceValues[0].id];
			system.assertEquals('Change Att Value',testPv.Name);
			system.assertEquals('Attendance value saved!',ApexPages.getMessages()[1].getSummary());
			system.assertEquals(attendanceValues.size(),controller.attendanceValues.size());
			
			controller.selectedPV = null;
			controller.setPicklistValue();
			controller.modalValue.Name = 'Test Att Value';
			controller.saveStatus();
			List<Picklist_Value__c> results = [SELECT id FROM Picklist_Value__c WHERE Setup__c=:TestDataSetupUtil_v2.activeSetUp.id AND RecordTypeId = :core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance')];
			system.assertEquals(attendanceValues.size()+1, results.size());
			system.assertEquals(results.size(), controller.attendanceValues.size());
		Test.stopTest();
	}
	
	/********************************* PARENT NOTIFICATION CONFIGURATION *********************************/
	public static testMethod void testSetMessage(){
		setupData();
		
		Test.startTest();
			controller.setMessage();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,controller.modalMessage.Setup__c);
			system.assert(!controller.bShowAttendance);
			system.assert(controller.bShowMessages);
			system.assert(!controller.bShowNotifications);
			system.assert(!controller.bShowThresholds);
			
			controller.selectedMV = null;
			controller.setMessage();
			//assert a new value is created, and selected message is not displayed
			system.assertEquals(null,controller.modalMessage.id);
			
			controller.selectedMV = testValue.id;
			controller.setMessage();
			system.assertEquals(testValue.id,controller.modalMessage.id);
			
			//break it
			controller.selectedMV = TestDataSetupUtil_v2.activeSetUp.id;
			controller.setMessage();
			system.assertEquals('This parent notification is not available to be edited.',ApexPages.getMessages()[0].getSummary());
		Test.stopTest();
	}
	
	public static testMethod void testSaveMessage(){
		setupData();
		
		Test.startTest();
			controller.saveMessage();
			system.assertEquals('There was an error saving the parent notification to the system.',ApexPages.getMessages()[0].getSummary());
			system.assertEquals(globalErrors+1,getNumGlobalErrors());
			
			controller.selectedMV = testValue.id;
			controller.setMessage();
			controller.modalMessage.Text_Alert__c = 'needs to start showing up for class.';
			controller.saveMessage();
			Value__c testMV = [SELECT id, Text_Alert__c FROM Value__c WHERE id=:testValue.id];
			system.assertEquals('needs to start showing up for class.',testMV.Text_Alert__c);
			system.assertEquals('Parent notification saved!',ApexPages.getMessages()[1].getSummary());
			system.assertEquals(1,controller.messageValues.size());
			
			controller.selectedMV = null;
			controller.setMessage();
			controller.modalMessage = testValue.clone(false);
			controller.modalMessage.Text_Alert__c = 'will be expelled if this continues.';
			controller.saveMessage();
			//only 1 message allowed per Language/Communication Type/Alert Type
			//validate system will update old value if new value created with same combo
			system.assertEquals('A parent notification for '+testValue.Language__c+' '+testValue.Communication_Type__c+' '+(testValue.Type__c=='Attendance Alerts'?'Absent':'Tardy')+' Alerts already exists and has been updated.',ApexPages.getMessages()[2].getSummary());
			system.assertEquals(1,controller.messageValues.size());
			testMV = [SELECT id, Text_Alert__c FROM Value__c WHERE id=:testValue.id];
			system.assertEquals('will be expelled if this continues.',testMV.Text_Alert__c);
			
			controller.setMessage();
			controller.modalMessage.Type__c = 'Tardy Alerts';
			controller.modalMessage.Communication_Type__c = 'Email';
			controller.modalMessage.Language__c = 'English';
			controller.modalMessage.Text_Alert__c = 'was late for class today.';
			controller.saveMessage();
			system.assertEquals(2,controller.messageValues.size());
			
		Test.stopTest();
	}
	
	/********************************* ADMIN NOTIFICATION CONFIGURATION *********************************/
	public static testMethod void testSetNotification(){
		setupData();
		
		Test.startTest();
			controller.setNotification();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,controller.modalNotification.Setup__c);
			system.assertEquals('Attendance',controller.modalNotification.Module__c);
			system.assert(!controller.bShowAttendance);
			system.assert(!controller.bShowMessages);
			system.assert(controller.bShowNotifications);
			system.assert(!controller.bShowThresholds);
			
			controller.selectedNotification = null;
			controller.setNotification();
			//assert a new value is created, and selected notification is not displayed
			system.assertEquals(null,controller.modalNotification.id);
			
			controller.selectedNotification = testNotification.id;
			controller.setNotification();
			system.assertEquals(testNotification.id,controller.modalNotification.id);
			
			//break it
			controller.selectedNotification = TestDataSetupUtil_v2.activeSetUp.id;
			controller.setNotification();
			system.assertEquals('This notification is not available to be edited.',ApexPages.getMessages()[0].getSummary());
		Test.stopTest();
	}
	
	public static testMethod void testSaveNotification(){
		setupData();
		
		Test.startTest();
			controller.saveNotification();
			system.assertEquals('There was an error saving the notification to the system.',ApexPages.getMessages()[0].getSummary());
			system.assertEquals(globalErrors+1,getNumGlobalErrors());
			
			controller.selectedNotification = testNotification.id;
			controller.setNotification();
			controller.modalNotification.Start_Date__c = system.today().addDays(-30);
			controller.saveNotification();
			Notification__c testNot = [SELECT id, Start_Date__c FROM Notification__c WHERE id=:testNotification.id];
			system.assertEquals(system.today().addDays(-30),testNot.Start_Date__c);
			system.assertEquals('Notification saved!',ApexPages.getMessages()[1].getSummary());
			system.assertEquals(1,controller.notificationValues.size());
			
			controller.selectedNotification = null;
			controller.setNotification();
			controller.modalNotification.Picklist_Value__c = attendanceValues[1].id;
			controller.modalNotification.Grade__c = '5';
			controller.modalNotification.Start_Date__c = system.today().addDays(-30);
			controller.modalNotification.End_Date__c = system.today().addDays(30);
			controller.saveNotification();
			system.assertEquals(2, controller.notificationValues.size());
		Test.stopTest();
	}
	
	public static testMethod void testSetThreshold(){
		setupData();
		
		Test.startTest();
			controller.setThreshold();
			system.assertEquals('There was an error associating the threshold to a notification.  Please try again.',ApexPages.getMessages()[0].getSummary());
			
			controller.selectedNotification = testNotification.id;
			controller.setThreshold();
			system.assertEquals(testNotification.id,controller.modalThreshold.Notification__c);
			system.assert(!controller.bShowAttendance);
			system.assert(!controller.bShowMessages);
			system.assert(!controller.bShowNotifications);
			system.assert(controller.bShowThresholds);
			
			controller.selectedThreshold = null;
			controller.setThreshold();
			//assert a new value is created, and selected threshold is not displayed
			system.assertEquals(null,controller.modalThreshold.id);
			
			controller.selectedThreshold = testThreshold.id;
			controller.setThreshold();
			system.assertEquals(testThreshold.id,controller.modalThreshold.id);
			
			//break it
			controller.selectedThreshold = TestDataSetupUtil_v2.activeSetUp.id;
			controller.setThreshold();
			system.assertEquals('This threshold is not available to be edited.',ApexPages.getMessages()[1].getSummary());
		Test.stopTest();
	}
	
	public static testMethod void testSaveThreshold(){
		setupData();
		
		Test.startTest();
			controller.saveThreshold();
			system.assertEquals('There was an error saving the threshold to the system.',ApexPages.getMessages()[0].getSummary());
			system.assertEquals(globalErrors+1,getNumGlobalErrors());
			
			controller.selectedNotification = testNotification.id;
			controller.selectedThreshold = testThreshold.id;
			controller.setThreshold();
			controller.modalThreshold.Cumulative__c = 10;
			controller.saveThreshold();
			Threshold__c testThresh = [SELECT id, Cumulative__c FROM Threshold__c WHERE id=:testThreshold.id];
			system.assertEquals(10,testThresh.Cumulative__c);
			system.assertEquals('Threshold saved!',ApexPages.getMessages()[1].getSummary());
			system.assertEquals(1,controller.notificationValues[0].Thresholds__r.size());
			
			controller.selectedThreshold = null;
			controller.setThreshold();
			controller.modalThreshold.Consecutive__c = 20;
			controller.modalThreshold.Cumulative__c = 20;
			controller.modalThreshold.Time_Lost__c = 200;
			controller.saveThreshold();
			system.assertEquals(2,controller.notificationValues[0].Thresholds__r.size());
		Test.stopTest();
	}
	
	private static void setupData(){
		TestDataSetupUtil_v2.setupCoreData(1);
		attendanceValues = TestDataSetupUtil_v2.createDefaultAttendanceTypes(TestDataSetupUtil_v2.activeSetup);
		testValue = new Value__c(Setup__c=TestDataSetupUtil_v2.activeSetUp.id,Language__c='English',Type__c='Attendance Alerts',Communication_Type__c='Email',Text_Alert__c='was not here today.');
		insert testValue;
		testNotification = new Notification__c(Setup__c=TestDataSetupUtil_v2.activeSetUp.id,Module__c='Attendance',Picklist_Value__c=attendanceValues[0].id,Grade__c='1;2;3;4;5;6;7;8;9;10;11;12',Daily_Tracking__c=true,Start_Date__c=system.today(),End_Date__c=system.today().addDays(30));
		insert testNotification;
		testThreshold = new Threshold__c(Notification__c=testNotification.id,Consecutive__c=5,Cumulative__c=5,Time_Lost__c=50);
		insert testThreshold;
		PageReference page = new PageReference('/apex/SchoolSetup_Attendance?setupId='+testDataSetupUtil_v2.activeSetUp.id);
		Test.setCurrentPage(page);
		controller = new SchoolSetup_Attendance();
		
		globalErrors = getNumGlobalErrors();
	}
	
	private static integer getNumGlobalErrors(){
		List<Global_Error__c> ges = [SELECT id FROM Global_Error__c];
		return ges.size();
	}
}
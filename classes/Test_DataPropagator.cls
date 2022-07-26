@isTest
public with sharing class Test_DataPropagator {

	private static List<HoldingObj__c> batch;
	
	testMethod static void testExecute() {
		   testDataSetupUtil_v2.setUPCoreData(5);
		setUp(testDataSetupUtil_v2.semester.Id);
		setUp2();
		Test.StartTest();
		Scheduler_HoldingProcessor target = new Scheduler_HoldingProcessor();
		target.mode = 'Staff';
		target.cSetup = new core_SetupWrapper(TestDataSetupUtil_v2.activeSetup,''); 
		    		string staffquery = Scheduler_HoldingProcessor.processQueryForPropagator(target.mode, null, 'TESTSCHL1');
		List <HoldingObj__c> staffList = database.Query(staffquery);
		target.log.Total_Records__c = 0;
		target.log.Failed_Records__c = 0; 
		target.execute(null, staffList);
		
		Scheduler_HoldingProcessor shp = new Scheduler_HoldingProcessor();
    		shp.mode = 'Student'; //Set the mode to student so it kicks off specific student processing
    		shp.cSetup = new core_SetupWrapper(TestDataSetupUtil_v2.activeSetup,''); 
    		string query = Scheduler_HoldingProcessor.processQueryForPropagator(shp.mode, null, 'TESTSCHL1');
		List <HoldingObj__c> hoList = database.Query(query);
		
		shp.log.Total_Records__c = 0;
		shp.log.Failed_Records__c=0;
		shp.execute(null, hoList);
		Test.stopTest();				
	}

	private static void setUp(Id rpid) {
		system.debug('$$$$RPID$$$'+rpId);
	
		
		batch = new List<HoldingObj__c>();
		HoldingObj__c hos = new HoldingObj__c();
		hos.Type__c='Student';
		hos.Student_ID__c = 'BATCH-TEST-1';
		hos.First_Name__c = 'Jon';
		hos.Last_Name__c = 'Doe';
		hos.Sex__c = 'M';
		hos.School_Dbn__c = 'TESTSCHL1';
		hos.Class_Id__c = 'CLS-1';
		hos.Course_Name__c = 'Course';
		hos.Reporting_Period_Id__c = rpid;
		hos.School_Year__c ='123456';
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		hos = new HoldingObj__c();
		hos.Type__c='Student';
		hos.Student_ID__c = 'BATCH-TEST-2';
		hos.First_Name__c = 'Amy';
		hos.Last_Name__c = 'Smith';
		hos.Sex__c = 'F';
		hos.School_Dbn__c = 'TESTSCHL1';
		hos.Class_Id__c = 'CLS-1';
		hos.ELL__c = 'y';
		hos.Course_Name__c = 'Course';
		hos.Reporting_Period_Id__c = rpid;
				hos.School_Year__c ='123456';
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		hos = new HoldingObj__c();
		hos.Type__c='Student';
		hos.Student_ID__c = 'BATCH-TEST-3';
		hos.First_Name__c = 'John';
		hos.Last_Name__c = 'Adams';
		hos.Sex__c = 'M';
		hos.School_Dbn__c = 'TESTSCHL1';
		hos.Class_Id__c = 'CLS-1';
		hos.Disability_Flag__c = 'y';
		hos.Course_Name__c = 'Course';  
		hos.Reporting_Period_Id__c = rpid;
				hos.School_Year__c ='123456';
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		insert batch;
	}
	

	
	testMethod static void testExecute2() {
		setUp2();
		
		Test.startTest();	
		Scheduler_HoldingProcessor target = new Scheduler_HoldingProcessor();
		target.mode = 'Staff';
		target.log.Total_Records__c = 0;
		target.log.Failed_Records__c = 0;
		target.execute(null, batch);
		Test.stopTest();
		
		Account school = [SELECT Id FROM Account WHERE Reference_Id__c = :batch[0].School_DBN__c];
		//Role__c role = [SELECT Id FROM Role__c WHERE Role_Name__c = :batch[0].Staff_Code__c];
		
		Contact staff = [SELECT LastName, FirstName, Holding_Source__c, User__c, User__r.LastName FROM Contact WHERE Reference_Id__c = :batch[0].Staff_ID__c];
		System.assertEquals(batch[0].Id, staff.Holding_Source__c);
		System.assert(staff.User__c != null);
		//System.assertEquals(batch[0].Last_Name__c, staff.User__r.LastName);
		
		//System.assertEquals(1, [SELECT count() FROM Staff_School__c WHERE School__c = :school.Id AND Role__c = :role.Id AND Staff__c = :staff.Id]);
	}
	
	testMethod static void testFinish2() {
		/* Tests deactivation of Staff*/
		setUp2();
		
		Contact staff = new Contact(LastName='Doe',Is_Active__c=true,FirstName='John',User_Name__c='testdoe');
		User usr = createUser(staff);
		insert usr;
		staff.User__c = usr.Id;
		insert staff;
		
				
		Scheduler_HoldingProcessor target = new Scheduler_HoldingProcessor();
		target.mode = 'Staff';
		target.finish(null);
		usr = [SELECT IsActive FROM User WHERE Id = :usr.Id];
		System.assert(!staff.Active__c);
	}
	
	private static void setUp2() {
		batch = new List<HoldingObj__c>();

		
		HoldingObj__c hos = new HoldingObj__c(School_DBN__c='TST123');
		hos.Type__c='Staff';
		hos.First_Name__c = 'John';
		hos.Last_Name__c = 'Smith';
		hos.Staff_ID__c='TST123';
		hos.Staff_Code__c = 'TST Teacher';
		hos.Class_Id__c = 'TST999';
		hos.CLass_Name__c = 'Class 999';
		hos.Network__c = 'TST-NET';
		hos.Username__c = 'TST1';
				hos.School_Dbn__c = 'TESTSCHL1';
		hos.Course_Name__c = 'Course1';
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		hos = new HoldingObj__c(School_DBN__c='TST123');
		hos.Type__c='Staff';
		hos.First_Name__c = 'Anne';
		hos.Last_Name__c = 'Porter';
		hos.Staff_ID__c='0TST123';
		hos.Staff_Code__c = 'TST Administrator';
		hos.Class_Id__c = 'TST878';
		hos.CLass_Name__c = 'Class 878';
		hos.Network__c = 'TST-NET';
		hos.Username__c = 'TST2';
				hos.School_Dbn__c = 'TESTSCHL1';
		hos.Course_Name__c = 'Course1';
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		hos = new HoldingObj__c(School_DBN__c='TST123');
		hos.Type__c='Staff';
		hos.First_Name__c = 'Mary';
		hos.Last_Name__c = 'Jane';
		hos.Staff_ID__c='0TST124';
		hos.Staff_Code__c = 'TST Teacher';
		hos.Class_Id__c = 'TST878';
		hos.CLass_Name__c = 'Class 878';
		hos.Network__c = 'TST-NET';
		hos.Username__c = 'TST3';
				hos.School_Dbn__c = 'TESTSCHL1';
		hos.Course_Name__c = 'Course1';
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		insert batch;
	}
	
	public static User createUser(Contact staffContact) {
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
		//usr.ProfileId = Reading_Tracker_Settings__c.getInstance().Staff_Profile_Id__c;
		usr.TimeZoneSidKey = 'America/Los_Angeles';
		usr.Username = staffContact.User_Name__c + '@schools.nyc.gov.dev';
		usr.Reference_Id__c = staffContact.Reference_Id__c;
		//usr.FederationIdentifier = staffContact.User_Name__c;
		return usr;
	}
	
	testMethod static void testExecute_SectionGrades() {
		setUp_SectionGrades();

		Test.startTest();
		Scheduler_HoldingProcessor shp = new Scheduler_HoldingProcessor();
    		shp.mode = 'Student'; //Set the mode to staff so it kicks off specific Staff processing
    		shp.cSetup = new core_SetupWrapper(TestDataSetupUtil_v2.activeSetup,''); 
    		string query = Scheduler_HoldingProcessor.processQueryForPropagator(shp.mode, null, 'TESTSCHL1');
		List <HoldingObj__c> hoList = database.Query(query);
		
		shp.log.Total_Records__c = 0;
		shp.log.Failed_Records__c=0;
		shp.execute(null, hoList);
		Test.stopTest();
		
		//Account school = [SELECT Id, Name FROM Account WHERE Holding_Source__c = :batch[0].Id];
		//Student__c student = [SELECT Id, Name, Student_First_Name__c, Gender__c, School__c FROM Student__c WHERE Holding_Source__c = :batch[0].Id];
		//Student__c student = [SELECT Id, Name, Student_First_Name__c, Gender__c, School__c FROM Student__c ];
		//System.assertEquals(school.Id, student.School__c);
		
		//String classKey = ImportUtils.createClassSectionKey(batch[0]);
		//system.debug('classKey:'+classKey);
		//Section__c classSection = [SELECT Id, Name FROM Section__c WHERE Reference_Id__c = :classKey];
		//List<Student_Section__c> studentSections = [SELECT Id FROM Student_Section__c WHERE Section__c = :classSection.Id AND Student__r.School__c = :school.Id];
		//System.assertEquals(3, studentSections.size());
				
	}
	
	private static void setUp_SectionGrades() {
		batch = new List<HoldingObj__c>();
		TestDataSetupUtil_v2.setUPCoreData(5);
		Time_Element__c sem = 		TestDataSetupUtil_v2.semester;

		
		
	batch = new List<HoldingObj__c>();
		HoldingObj__c hos = new HoldingObj__c();
		hos.Type__c='Student';
		hos.Student_ID__c = 'BATCH-TEST-1';
		hos.First_Name__c = 'Jon';
		hos.Last_Name__c = 'Doe';
		hos.Sex__c = 'M';
		hos.School_Dbn__c = 'TESTSCHL1';
		hos.Class_Id__c = 'CLS-1';
		hos.Course_Name__c = 'Course';
				hos.School_Year__c ='123456';
		hos.Reporting_Period_Id__c=sem.id;
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		hos = new HoldingObj__c();
		hos.Type__c='Student';
		hos.Student_ID__c = 'BATCH-TEST-2';
		hos.First_Name__c = 'Amy';
		hos.Last_Name__c = 'Smith';
		hos.Sex__c = 'F';
		hos.School_Dbn__c = 'TESTSCHL1';
		hos.Class_Id__c = 'CLS-1';
				hos.School_Year__c ='123456';
		hos.ELL__c = 'y';
		hos.Course_Name__c = 'Course';
		hos.Reporting_Period_Id__c=sem.id;
		hos.Reference_Id__c=ImportUtils.createClassSectionKey(hos);
		batch.add(hos);
		
		hos = new HoldingObj__c();
		hos.Type__c='Student';
		hos.Student_ID__c = 'BATCH-TEST-3';
		hos.First_Name__c = 'John';
		hos.Last_Name__c = 'Adams';
		hos.Sex__c = 'M';
		hos.School_Dbn__c = 'TESTSCHL1';
		hos.Class_Id__c = 'CLS-1';
				hos.School_Year__c ='123456';
		hos.Disability_Flag__c = 'y';
		hos.Course_Name__c = 'Course';
		hos.Reporting_Period_Id__c=sem.id;
		batch.add(hos);
		
		
		insert batch;
	}
	

}
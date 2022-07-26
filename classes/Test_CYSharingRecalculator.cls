@isTest
private class Test_CYSharingRecalculator {
/*	
	private static Account school;
	private static User user;
	private static Contact c;
	private static Staff__c staff;
	private static List<Student__c> students;
	private static Section__c sec;
	
	static testMethod void testConstructor(){
		Test.startTest();
			CYSharingRecalculator cysr = new CYSharingRecalculator();
			system.assert(!cysr.useLog);
			cysr = new CYSharingRecalculator(true);
			system.assert(cysr.useLog);
		Test.stopTest();
	}
	
	static testMethod void testCorpsMember(){
		TestDataUtil.setupSharingControls();
		TestDataUtil.setupTime();
		setupSchool('Corps Member');
		setupSection(staff);
		Test.startTest();
			User cmUser = [SELECT id, Profile.Name FROM User WHERE id=:user.id];
			CYSharingRecalculator cysr = new CYSharingRecalculator();
			cysr.execute(null,new List<User>{cmUser});
			Map<ID,Map<ID,ID>> shares = SharingUtils.getExistingSharing(new Set<ID>{cmUser.id});
			system.assertEquals(1,shares.size());
			system.assertEquals(4,shares.get(cmUser.Id).size());
			staff.Active__c = false;
			update staff;
			cysr.execute(null,new List<User>{cmUser});
			shares = SharingUtils.getExistingSharing(new Set<ID>{cmUser.id});
			system.assertEquals(0,shares.size());
		Test.stopTest();
	}
	
	static testMethod void testSchoolAdmin(){
		TestDataUtil.setupSharingControls();
		TestDataUtil.setupTime();
		setupSchool('School Admin');
		Contact c2 = TestDataUtil.createContact('ApexText','CM',null);
		insert c2;
		Staff__c cmstaff = TestDataUtil.createStaff(c2,school,2);
		insert cmstaff;
		setupSection(cmstaff);
		Test.startTest();
			User saUser = [SELECT id, Profile.Name FROM User WHERE id=:user.id];
			CYSharingRecalculator cysr = new CYSharingRecalculator();
			cysr.execute(null,new List<User>{saUser});
			Map<ID,Map<ID,ID>> shares = SharingUtils.getExistingSharing(new Set<ID>{saUser.id});
			system.assertEquals(1,shares.size());
			system.assertEquals(4,shares.get(saUser.Id).size());
			staff.Active__c = false;
			update staff;
		Test.stopTest();
		shares = SharingUtils.getExistingSharing(new Set<ID>{saUser.id});
		system.assertEquals(0,shares.size());
	}
	
	static testMethod void testBatch(){
		TestDataUtil.setupSharingControls();
		TestDataUtil.setupTime();
		setupSchool('Corps Member');
		setupSection(staff);
		Test.startTest();
			Data_Load_Log__c dll = SharingUtils.getLog('Pending');
			dll.Messages__c = user.id;
			upsert dll;
			CYSharingRecalculator cysr = new CYSharingRecalculator(true);
			Database.executeBatch(cysr,1);
		Test.stopTest();
		Map<ID,Map<ID,ID>> shares = SharingUtils.getExistingSharing(new Set<ID>{user.id});
		system.assertEquals(1,shares.size());
		system.assertEquals(4,shares.get(user.Id).size());
		
		dll = [SELECT id, Batch_ID__c, Status__c, End_Time__c FROM Data_Load_Log__c WHERE id=:dll.id];
		system.assertEquals('Completed', dll.Status__c);
		system.assertNotEquals(null,  dll.End_Time__c);
	}
	
	static testMethod void testUpdateQuery(){
		Test.startTest();
			CYSharingRecalculator cysr = new CYSharingRecalculator();
			String newString = cysr.updateQuery('start (',',','beg ',' end', new List<String>{'a','b','c'});
			system.assertEquals('start (beg a end,beg b end,beg c end)',newString);
		Test.stopTest();
	}
	
	static testMethod void testSchedule(){
		Test.startTest();
			Schedule_CYSharingRecalculator cys = new Schedule_CYSharingRecalculator(true);
			DateTime sched = system.now().addMinutes(5);
			String sch = sched.second()+' '+sched.minute()+' '+sched.hour()+' '+sched.day()+' '
				+sched.month()+' ? '+sched.year();
			ID jobId = System.schedule('Test Schedule',sch,cys);
			
			CronTrigger ct = [SELECT id, CronExpression, TimesTriggered FROM CronTrigger WHERE id=:jobId];
			system.assertEquals(sch, ct.CronExpression);
			system.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
	
	static void setupSchool(String profile){
		school = TestDataUtil.createSchool('ApexTest School');
		insert school;
		TestDataUtil.schoolList.add(school);
		TestDataUtil.setupSetupRecord();
		
		String profileName = '%'+profile+'%';
		Profile p = [SELECT id FROM Profile WHERE Name LIKE :profileName and UserType = 'Standard' LIMIT 1];
		user = TestDataUtil.createUser('ApexTestUser',p.id);
		insert user;
		c = TestDataUtil.createContact('ApexTest','User',user.id);
		insert c;
		staff = TestDataUtil.createStaff(c,school,1);
		insert staff;
		students = TestDataUtil.createStudents(3, school);
		insert students;
	}
	
	static void setupSection(Staff__c cmstaff){
		List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
		insert ia;
		List<Program__c> programs = TestDataUtil.createPrograms(1,true,ia[0]);
		insert programs;
		Account_Program__c ap = TestDataUtil.createAccountProgram(school,programs[0]);
		insert ap;
		sec = TestDataUtil.createSection(school, ap, students, cmstaff, programs[0]);
	}
	*/
}
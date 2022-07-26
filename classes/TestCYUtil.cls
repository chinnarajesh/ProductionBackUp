@isTest
private class TestCYUtil {
	static testMethod void testCM() {
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
		User cm = SW.cmDirect.userRecord;
		
		test.startTest();
			system.runAs(cm) {
				List <Account> schools = CYUtil.getAllActiveSchools();
				system.assertEquals(1,schools.size());
			}
		test.stopTest();	 
	}

	static testMethod void testNetwork() {
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
		User network = SW.networkAdmin.userRecord;
		
		test.startTest();
		 system.runAs(network) {
			List <Account> schools = CYUtil.getAllActiveSchools();
			system.assertEquals(1,schools.size());
			
		}
		test.stopTest();
	}

	static testMethod void testSchoolAdmin() {
		TestDataUtil.setupData(1);
		 TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
	   
		 User schoolAdmin = SW.schoolAdmin.userRecord;
		
		 test.startTest();
		 system.runAs(schoolAdmin) {
		 	List <Account> schools = CYUtil.getAllActiveSchools();
			system.assertEquals(1,schools.size());
		 }
		 test.stopTest();
	}

	static testMethod void testSystemAdmin() {
		TestDataUtil.setupData(1);
		 TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
		 User sysAdmin = SW.sysAdmin.userRecord;
		 test.startTest();
		 system.runAs(sysAdmin) {
		 	List <Account> schools = CYUtil.getAllActiveSchools();
		 	schools = CYUtil.getStaffSchool();
			system.assertEquals(1,schools.size());
		 	
		 }
		 test.stopTest();
	}

	static testMethod void otherMethodTest() {
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
		User sysAdmin = SW.sysAdmin.userRecord;
		test.startTest();
		system.runAs(sysAdmin) {
			Id recId = CYUtil.getRecordTypeID('School');
			Id yearID = CYUtil.getSchoolYearID(SW.school.Id);
			system.assertEquals(recId,CYUtil.getRecordTypeID('School'));
		}
		test.stopTest();
	}

	static testMethod void testGetInterventionSessionsByDate() {
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];

		Account school = SW.school;
		Staff__c cm = SW.cmDirect.staffRecord;
		List<Student__c> students = SW.students;
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Indicator_Area_Student__c> iaStu =  TestDataUtil.createIAStudents (students,ia.Id);
		insert iaStu;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		Account_Program__c accProg = TestDataUtil.createAccountProgram(school, program);
		insert accProg;
		List<Student__c> enrolledStudents = new List<Student__c>();
		List<Student__c> notEnrolledStudents = new List<Student__c>();
		integer cnt = 0;
		for(Student__c s :students) {
			if(cnt < students.size()/2) {
				enrolledStudents.add(s);
			}
			cnt++;
		}
		List<Section__c> sections = TestDataUtil.createSections(1, school, accProg, new List<List<Student__c>>{enrolledStudents}, cm, program);
		Intervention_Session__c is = TestDataUtil.createInterventionSession(sections[0].Id, null, cm.Id);
		insert is;
		list<Intervention_Session__c> isConfirm;
		test.startTest();
			isConfirm = CYUtil.getInterventionDataForSection(sections[0].Id, is.Date__c, is.Date__c);
			system.assertEquals(1, isConfirm.size());
			system.assertEquals(is.Id, isConfirm[0].Id);
		test.stopTest();
	}

	static testMethod void testGetStudentIndicatorAreaMap() {
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];

		Account school = SW.school;
		Staff__c cm = SW.cmDirect.staffRecord;
		List<Student__c> students = SW.students;
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Indicator_Area_Student__c> iaStu =  TestDataUtil.createIAStudents (students,ia.Id);
		insert iaStu;
		map<ID, list<Indicator_Area_Student__c>> studentIndicatorAreaMap;
		test.startTest();
			studentIndicatorAreaMap = CYUtil.getStudentIndicatorAreaMap(students);
		test.stopTest();
		system.assertEquals(students.size(), studentIndicatorAreaMap.keySet().size());
		for (Student__c s : students) {
			for (Indicator_Area_Student__c iarea : studentIndicatorAreaMap.get(s.Id)) {
				system.assertEquals(s.ID, iarea.Student__c);
			}
		}
	}
}
@isTest
private class TestStudentProgramController {

	static testMethod void TestFilterChanges() {
		TestDataUtil.setupData(2);	
		List<Student__c> students = TestDataUtil.testData[0].students;
		students.addAll(TestDataUtil.testData[1].students);
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c();
		ia.Name = 'IA';
		insert ia;
		List<Indicator_Area_Student__c> iaStuList = new List<Indicator_Area_Student__c>();
		for(Student__c stu :students) {
			Indicator_Area_Student__c iaStu = new Indicator_Area_Student__c();
			iaStu.Student__c = stu.id;
			iaStu.Indicator_Area__c = ia.id;
			iaStu.Active__c = true;
			iaStuList.add(iaStu);
		}
		insert iaStuList;
		List<Program__c> programs = new List<Program__c>();
		programs.add(new Program__c(Name = 'Program', Required_Program__c =true, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		programs.add(new Program__c(Name = 'Not Required Program', Required_Program__c =false, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		
		insert programs;
		List<Account_Program__c> aps = new List<Account_Program__c>();
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_2.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_2.id,Active__c = true));
		insert aps;

		Section__c sec = new Section__c();
		ApexPages.StandardController sc = new ApexPages.standardController(sec);
			
		test.startTest();
		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			StudentProgramController controller = new StudentProgramController(sc);
			system.assertEquals(2, controller.schools.size(),'Expected 2 schools to load.');
			controller.getFreqOptions(); //called from page
			controller.getSchoolList();

			controller.activeSchoolID = controller.schools[0].id;
			controller.changeSchool();
			system.assertEquals(2, controller.programs.size(),'Expected 2 programs to load for this school.');
			controller.selectedProgram = controller.programs[0].getValue();
			controller.changeProgram();

			system.assertEquals(10, controller.availableStudents.size(),'Expected 10 students by default.');
			system.assertEquals(false, controller.indicatorAreas.isEmpty(),'Expected there to be at least one indicator Area to choose from.');
			controller.selectedIndicatorArea = controller.indicatorAreas[0].getValue();
			controller.changeIndicatorArea();
			system.assertEquals(false, controller.availableStudents.isEmpty(),'Expected at least one student to remain.');

			controller.selectedFilterSection = 'null';
			controller.changeSection();
			system.assertEquals('null', controller.selectedIndicatorArea,'Choosing a section should reset the indicator area filter.');

			controller.selectedGrade = '5';
			controller.changeGrade();
			system.assertEquals(false, controller.availableStudents.isEmpty(),'Expected at least one student to remain.');
		}
		test.stopTest();
	}
	
	static testMethod void enrollmentTableTest() {
		TestDataUtil.setupData(2);	
		List<Student__c> students = TestDataUtil.testData[0].students;
		students.addAll(TestDataUtil.testData[1].students);
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c();
		ia.Name = 'IA';
		insert ia;
		List<Indicator_Area_Student__c> iaStuList = new List<Indicator_Area_Student__c>();
		for(Student__c stu :students) {
			Indicator_Area_Student__c iaStu = new Indicator_Area_Student__c();
			iaStu.Student__c = stu.id;
			iaStu.Indicator_Area__c = ia.id;
			iaStu.Active__c = true;
			iaStuList.add(iaStu);
		}
		insert iaStuList;
		List<Program__c> programs = new List<Program__c>();
		programs.add(new Program__c(Name = 'Program', Required_Program__c =true, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		programs.add(new Program__c(Name = 'Not Required Program', Required_Program__c =false, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		
		insert programs;
		List<Account_Program__c> aps = new List<Account_Program__c>();
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_2.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_2.id,Active__c = true));
		insert aps;
			
		
		test.startTest();
		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			Section__c sec = new Section__c();
			ApexPages.StandardController sc = new ApexPages.standardController(sec);
			StudentProgramController cont = new StudentProgramController(sc);
			
			for(studentWrapper s :cont.availableStudents) {
				s.checked = true;
			}
			cont.addStudents();
			system.assertEquals(false, cont.selectedStudents.isEmpty());
			system.assertEquals(true, cont.availableStudents.isEmpty());

			for(studentWrapper s :cont.selectedStudents) {
				s.checked = true;
			}
			cont.removeStudents();


			cont.addStudents();
			cont.removeStudents();

		}
		test.stopTest();
	}
	static testMethod void createSectionErrors() {
		TestDataUtil.setupData(2);	
		List<Student__c> students = TestDataUtil.testData[0].students;
		students.addAll(TestDataUtil.testData[1].students);
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c();
		ia.Name = 'IA';
		insert ia;
		List<Indicator_Area_Student__c> iaStuList = new List<Indicator_Area_Student__c>();
		for(Student__c stu :students) {
			Indicator_Area_Student__c iaStu = new Indicator_Area_Student__c();
			iaStu.Student__c = stu.id;
			iaStu.Indicator_Area__c = ia.id;
			iaStu.Active__c = true;
			iaStuList.add(iaStu);
		}
		insert iaStuList;
		List<Program__c> programs = new List<Program__c>();
		programs.add(new Program__c(Name = 'Program', Required_Program__c =true, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		programs.add(new Program__c(Name = 'Not Required Program', Required_Program__c =false, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		
		insert programs;
		List<Account_Program__c> aps = new List<Account_Program__c>();
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_2.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_2.id,Active__c = true));
		insert aps;
			
		
		test.startTest();
		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			Section__c sec = new Section__c();
			ApexPages.StandardController sc = new ApexPages.standardController(sec);
			StudentProgramController cont = new StudentProgramController(sc);
			
			for(studentWrapper s :cont.availableStudents) {
				s.checked = true;
			}
			cont.addStudents();
			cont.saveSection();
			system.assert(true);
			
		}
		test.stopTest();
	}
	static testMethod void createSection() {
		TestDataUtil.setupData(2);	
		List<Student__c> students = TestDataUtil.testData[0].students;
		students.addAll(TestDataUtil.testData[1].students);
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c();
		ia.Name = 'IA';
		insert ia;
		List<Indicator_Area_Student__c> iaStuList = new List<Indicator_Area_Student__c>();
		for(Student__c stu :students) {
			Indicator_Area_Student__c iaStu = new Indicator_Area_Student__c();
			iaStu.Student__c = stu.id;
			iaStu.Indicator_Area__c = ia.id;
			iaStu.Active__c = true;
			iaStuList.add(iaStu);
		}
		insert iaStuList;
		List<Program__c> programs = new List<Program__c>();
		programs.add(new Program__c(Name = 'Program', Required_Program__c =true, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		programs.add(new Program__c(Name = 'Not Required Program', Required_Program__c =false, Status__c = 'Approved',Indicator_Area__c = ia.Id));
		
		insert programs;
		List<Account_Program__c> aps = new List<Account_Program__c>();
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_1.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[0].id,School__c = school_2.id,Active__c = true));
		aps.add(new Account_Program__c(Program__c = programs[1].id,School__c = school_2.id,Active__c = true));
		insert aps;
			
		
		test.startTest();
		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			Section__c sec = new Section__c();
			ApexPages.StandardController sc = new ApexPages.standardController(sec);
			StudentProgramController cont = new StudentProgramController(sc);
			
			cont.activeSchoolId = TestDataUtil.testData[0].cmDirect.staffRecord.Organization__c;
			cont.changeSchool();
			
			for(studentWrapper s :cont.availableStudents) {
				s.checked = true;
			}

			cont.addStudents();
			cont.selectedStaff = TestDataUtil.testData[0].cmDirect.staffRecord.Id;
			
			cont.sectionHolder.Start_Date__c = Date.Today();
			cont.sectionHolder.End_Date__c = Date.Today().addDays(5);
			cont.freqChecks.add('Monday');
			cont.sectionHolder.In_After_School__c = 'In School';
			cont.sectionHolder.Target_Dosage_Section_Goal__c = 100;
			cont.stuSecHolder.Enrollment_Start_Date__c = Date.Today();
			PageReference pref = cont.saveSection();
			System.assertNotEquals(null, pref);
			
			pref = cont.saveAndNewSection();
			System.assertNotEquals(null, pref);

			cont.getSectionToClone();
			
		}
		test.stopTest();
	}
}
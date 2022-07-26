@isTest
private class Test_StudentDetailComponent {
	
	private static Account school;
	private static Section__c section;
	private static List<Student__c> students;
	private static Skill__c skill;

	static testMethod void Test_Constructor() {
		setupData();
		
		Test.setCurrentPage(Page.IM_StudentDetail);
		ApexPages.currentPage().getParameters().put('StudentId',students[0].id);

		Test.startTest();
			StudentDetailComponent controller = new StudentDetailComponent();
			system.assertEquals(2, controller.sectionList.size());

			controller.selectedSectionId = controller.sectionList[1].getValue();
			controller.changeSection();
		Test.stopTest();
	}

	static testMethod void Test_ErrorConstructor() {
		setupData();

		Test.setCurrentPage(Page.IM_StudentDetail);

		Test.startTest();
			StudentDetailComponent controller = new StudentDetailComponent();
		Test.stopTest();

		system.assertEquals(true, controller != null);

	}

	static testMethod void Test_AddTime(){
		setupData();
		
		Test.setCurrentPage(Page.IM_StudentDetail);
		ApexPages.currentPage().getParameters().put('StudentId',students[0].id);

		Test.startTest();
			StudentDetailComponent controller = new StudentDetailComponent();
			
			controller.sessionHolder.Date__c = Date.today();
			controller.primarySkill = skill.id;
			//controller.sessionHolder.Skills_Covered_for_the_Session__c = 'Test Skills';
			controller.sessionHolder.All_avenues__c = 'In-Person Service';
			controller.selectedFields.add(new SelectOption('Self-Awareness: Identifying strengths and weaknesses','Self-Awareness: Identifying strengths and weaknesses'));
			controller.resultHolder.Amount_of_Time__c = 10;

			controller.saveTime();
			system.assertEquals(10, controller.selectedStudentSection.Dosage_to_Date__c);
		Test.stopTest();
	}

	static testMethod void Test_modalCancel(){
		setupData();

		Test.setCurrentPage(Page.IM_StudentDetail);
		ApexPages.currentPage().getParameters().put('StudentId',students[0].id);

		Test.startTest();
			StudentDetailComponent controller = new StudentDetailComponent();
			controller.modalCancel();
		Test.stopTest();

		system.assertEquals(true, controller.resultHolder != null);
		system.assertEquals(true, controller.sessionHolder != null);
	}



	static testMethod void Test_EditTime(){
		setupData();
		
		Test.setCurrentPage(Page.IM_StudentDetail);
		ApexPages.currentPage().getParameters().put('StudentId',students[0].id);

		Test.startTest();
			StudentDetailComponent setupController = new StudentDetailComponent();
			
			setupController.sessionHolder.Date__c = Date.today();
			setupController.sessionHolder.Skills_Covered_for_the_Session__c = 'Test Skills';
			setupController.primarySkill = skill.id;
			setupController.sessionHolder.Skill_Primary__c = skill.id;
			setupController.sessionHolder.All_avenues__c = 'In-Person Service';
			setupController.resultHolder.Amount_of_Time__c = 10;

			setupController.saveTime();

			StudentDetailComponent controller = new StudentDetailComponent();
			system.assertEquals(1, controller.sessions.size());

			controller.selectedSessionID = controller.sessions[0].session.ID;
			controller.editSession();

			controller.resultHolder.Amount_of_Time__c = 50;
			controller.saveTime();

			system.assertEquals(50, controller.selectedStudentSection.Dosage_to_Date__c);
		Test.stopTest();
	}
	
	static void setupData(){
		skill = new Skill__c();
		skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
		skill.Category__c = 'SEL/Behavior and Attendance Interventions';
		skill.IsPrimary__c = true;
		insert skill;
		TestDataUtil.setupSharingControls();
		TestDataUtil.setupTime();
		school = TestDataUtil.createSchool('ApexTestSchool1');
		school.Site__c = 'Boston';
		insert school;
		TestDataUtil.schoolList.add(school);
		TestDataUtil.setupSetupRecord();
		List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
		insert ia;
		
		List<Program__c> programs = TestDataUtil.createPrograms(1,true,ia[0]);
		programs.addAll(TestDataUtil.createPrograms(1,true,ia[1]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[2]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[3]));
		insert programs;
		Account_Program__c accProg = TestDataUtil.createAccountProgram(school, programs[0]);
		insert accProg;
		//students = TestDataUtil.createStudents(1, school);
		//insert students;
		
		Contact c = TestDataUtil.createContact('ApexTest','User',null);
		insert c;
		Staff__c staff = TestDataUtil.createStaff(c,school,1);
		insert staff;
		
		students = TestDataUtil.createStudents(1, school);
		insert students;
		
		section = TestDataUtil.createSection(school, accProg, students, staff, programs[0]);
		TestDataUtil.createSection(school, accProg, students, staff, programs[0]);
	}
}
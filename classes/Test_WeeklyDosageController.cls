@isTest
private class Test_WeeklyDosageController{
	private static Account school;
	private static Section__c section;
	private static List<Student__c> students;
	private static Skill__c skill;

	static testMethod void myUnitTest(){
		setupData();
		Test.setCurrentPage(Page.IM_Weekly);

		Test.startTest();
			WeeklyDosageController controller = new WeeklyDosageController();
			system.assertEquals(1, controller.schools.size(),'Expected the school list to containt 1 entry only');
			controller.selectedSchool = controller.schools[0].getValue();
			controller.changeSchool();
			System.assertEquals(1, controller.staff.size(),'Expected only one staff to display');
			controller.selectedStaff = controller.staff[0].getValue();
			controller.changeStaff();
			System.assertEquals(1, controller.sections.size(),'Expected only one section to display');
			controller.selectedSection = controller.sections[0].getValue();
			controller.changeSection();

			System.assertEquals(2, controller.resultsData.size());
			System.assertEquals(7, controller.tableHeaders.size());

			System.debug(controller.tableHeaders[0]);
			System.assertEquals(false, controller.tableHeaders[0].isDisabled);
			controller.resultsData[0].dosages[0].isr.Amount_Of_Time__c = 5;
			controller.tableHeaders[0].primarySkill = skill.Id;
			controller.tableHeaders[0].selectedSkills = 'Self-Awareness: Identifying strengths and weaknesses';
			controller.tableHeaders[0].isProceed=true;
			controller.tableHeaders[0].session.All_avenues__c = 'In-Person Service';
			//controller.selectedFields.add(new SelectOption('Self-Awareness: Identifying strengths and weaknesses','Self-Awareness: Identifying strengths and weaknesses'));

			controller.saveNewSessions();
			System.assertEquals(false, ApexPages.hasMessages(ApexPages.Severity.ERROR));

			controller.toggleSortDirection();
			//with only one kid, there's really nothing to assert here.

			controller.weekEndHolder.Date__c = system.today().addDays(-7);
			controller.changeWeek();
			System.assertEquals(system.today().addDays(-7).toStartOfWeek(), controller.currentWeek);
			controller.lastWeek();
			System.assertEquals(system.today().addDays(-14).toStartOfWeek(), controller.currentWeek);
			controller.nextWeek();
			System.assertEquals(system.today().addDays(-7).toStartOfWeek(), controller.currentWeek);

			controller.resetPage();
		Test.stopTest();
	}
	
	static void setupData(){
		skill = new Skill__c();
		skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
		skill.Category__c = 'SEL/Behavior and Attendance Interventions';
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
		students = TestDataUtil.createStudents(2, school);
		insert students;
		
		Contact c = TestDataUtil.createContact('ApexTest','User',null);
		insert c;
		Staff__c staff = TestDataUtil.createStaff(c,school,1);
		insert staff;
		section = TestDataUtil.createSections_WithoutInsert(1,school, accProg, staff, programs[0])[0];
		section.Start_Date__c = Date.today().addDays(-7);
		insert section;

		insert TestDataUtil.createStudentSections_WithoutInsert(new List<Section__c>{section}, new List<List<Student__c>>{students});
	}
}
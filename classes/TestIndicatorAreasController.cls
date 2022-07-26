@isTest
private class TestIndicatorAreasController {
/*
	private static List<Student__c> students;
	private static TestDataUtil.schoolWrapper SW;
	private static IndicatorAreasController iac;
	
	static void setupData(){
		TestDataUtil.setupData(1);
		SW = TestDataUtil.testData[0];
		
		students = SW.students;
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
	}

	static testMethod void testConstructor(){
		setupData();

		Test.startTest();
			IndicatorAreasController controller = new IndicatorAreasController();
			system.assertEquals(1, controller.schools.size(),'Expected there to be a school loaded.');
			system.assertEquals(1, controller.gradeLevels.size(),'Expected a default grade level to load.');
		Test.stopTest();
	}
	
	static testMethod void testSchoolFilter(){
		setupData();

		Test.startTest();
			system.runAs(SW.sysAdmin.userRecord){
				IndicatorAreasController controller = new IndicatorAreasController();
				system.assertEquals(1, controller.schools.size(),'Expected there to be a school loaded.');
				controller.SchoolFilterParam = TestDataUtil.schoolList[0].ID;
				controller.changeSchool();
				System.assertEquals(10, controller.availableStudents.size(), 'Expected 10 students to be loaded.');
			}
		Test.stopTest();
	}
	
	static testMethod void testChangeGrade(){
		setupData();

		Test.startTest();
			system.runAs(SW.sysAdmin.userRecord){
				IndicatorAreasController controller = new IndicatorAreasController();
				system.assertEquals(1, controller.schools.size(),'Expected there to be a school loaded.');
				controller.SchoolFilterParam = TestDataUtil.schoolList[0].ID;
				controller.changeSchool();

				controller.selectedGrade = '5';
				controller.changeGrade();
				System.assertEquals(10, controller.availableStudents.size(),'Expected ten students in grade 5.');
			}
		Test.stopTest();	
	}

	static testMethod void testselectStudents(){
		setupData();
		Test.startTest();
			system.runAs(SW.sysAdmin.userRecord){
				IndicatorAreasController controller = new IndicatorAreasController();
				system.assertEquals(1, controller.schools.size(),'Expected there to be a school loaded.');
				controller.SchoolFilterParam = TestDataUtil.schoolList[0].ID;
				controller.changeSchool();
				System.assertEquals(10, controller.availableStudents.size(), 'Expected 10 students to be loaded.');

				controller.availableStudents[0].checked = true;
				controller.availableStudents[1].checked = true;
				controller.availableStudents[5].checked = true;

				controller.selectStudents();

				system.assertEquals(3, controller.selectedStudents.size());
				system.assertEquals(controller.availableStudents[0].student.id, controller.selectedStudents[0].student.id);
				system.assertEquals(controller.availableStudents[1].student.id, controller.selectedStudents[1].student.id);
				system.assertEquals(controller.availableStudents[5].student.id, controller.selectedStudents[2].student.id);
			}
		Test.stopTest();
	}

	static testMethod void testUpdateStudents(){
		setupData();
		Test.startTest();
			system.runAs(SW.sysAdmin.userRecord){
				IndicatorAreasController controller = new IndicatorAreasController();
				system.assertEquals(1, controller.schools.size(),'Expected there to be a school loaded.');
				controller.SchoolFilterParam = TestDataUtil.schoolList[0].ID;
				controller.changeSchool();
				System.assertEquals(10, controller.availableStudents.size(), 'Expected 10 students to be loaded.');

				controller.availableStudents[0].checked = true;
				controller.availableStudents[1].checked = true;
				controller.availableStudents[5].checked = true;

				controller.selectStudents();

				system.assertEquals(3, controller.selectedStudents.size());
				controller.selectedIndicatorArea = controller.indicatorAreas[0].getValue();
				controller.updateStudents();

				controller.saveChanges();

				controller.resetPage();
			}
		Test.stopTest();
	}
	*/
}
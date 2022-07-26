@isTest
private class TestSectionDetailComponent{

	private static TestDataUtil.schoolWrapper SW;
	private static Section__c section;
	private static List<Student__c> enrolledStudents;
	/* KC: This is old test class from the Interventions package. You can delete it if you want.
	private static void setupTestData(){
		TestDataUtil.setupData(1);
		SW = TestDataUtil.testData[0];
		
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Indicator_Area_Student__c> iaStu =  TestDataUtil.createIAStudents (SW.students,ia.Id);
		insert iaStu;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		Account_Program__c accProg = TestDataUtil.createAccountProgram(SW.school, program);
		insert accProg;
		enrolledStudents = new List<Student__c>();
		List<Student__c> notEnrolledStudents = new List<Student__c>();
		integer cnt = 0;
		for(Student__c s :SW.students) {
			if(cnt < SW.students.size()/2) {
				enrolledStudents.add(s);
			} else notEnrolledStudents.add(s);
			cnt++;
		}

		List<Section__c> sections = TestDataUtil.createSections(2,SW.school, accProg, new List<List<Student__c>>{enrolledStudents,notEnrolledStudents}, SW.cmDirect.staffRecord, program);
		section = sections[0];
	}

	static testMethod void testConstructor(){
		setupTestData();
		Test.setCurrentPage(Page.IM_SectionDetail);
		ApexPages.currentPage().getParameters().put('SectionID', section.ID);

		Test.startTest();
			sectionDetailExtension controller = new sectionDetailExtension();
			system.assertEquals(section.ID, controller.selectedSection.ID,'Expected the provided section to load');
			system.assertEquals(5, controller.enrolledStudents.size(),'Expected there to be 5 students in the section.');
			system.assertEquals(false, ApexPages.hasMessages());
		Test.stopTest();
	}

	static testMethod void testAddStudents(){
		setupTestData();
		Test.setCurrentPage(Page.IM_SectionDetail);
		ApexPages.currentPage().getParameters().put('SectionID', section.ID);

		Test.startTest();
			sectionDetailExtension controller = new sectionDetailExtension();
			system.assertEquals(5, controller.enrolledStudents.size(),'Expected 5 students to be enrolled in the section.');

			controller.startAddStudents();
			system.assertEquals(false, controller.availableStudents.isEmpty(),'Expected there to be at least one available student.');

			controller.availableStudents[0].checked = true;
			controller.addStudents();

			controller.selectedStudents[0].checked = true;
			controller.removeStudents();

			controller.availableStudents[0].checked = true;
			ID reactivatedStudentID = controller.availableStudents[0].studentID;
			controller.addStudents();
			
			system.assertEquals(1, controller.selectedStudents.size());

			controller.studentSectionHolder.Enrollment_Start_Date__c = system.today().addDays(1);

			controller.enrollStudents();
			system.assertEquals(6, controller.enrolledStudents.size(),'Expected there to be 6 students now.');

			for(sectionDetailExtension.studentEnrollmentWrapper sew: controller.enrolledStudents){
				if(sew.stuSecRec.Student__c == reactivatedStudentID){
					system.assertEquals(true, sew.stuSecRec.Active__c, 'Expected the student to be active.');
				}
			}

			system.assertEquals(1, [select id from Student_Section__c where Student__c=: reactivatedStudentID and Section__c =: section.id].size());
		Test.stopTest();
	}

	static testMethod void testAddStudentFilters(){
		setupTestData();
		Test.setCurrentPage(Page.IM_SectionDetail);
		ApexPages.currentPage().getParameters().put('SectionID', section.ID);

		Test.startTest();
			sectionDetailExtension controller = new sectionDetailExtension();
			system.assertEquals(5, controller.enrolledStudents.size(),'Expected 5 students to be enrolled in the section.');

			controller.startAddStudents();
			system.assertEquals(false, controller.availableStudents.isEmpty(),'Expected there to be at least one available student.');

			controller.selectedGrade = controller.grades[0].getValue();
			controller.changeGrade();

			controller.selectedGrade = 'null';
			controller.changeGrade();

			controller.selectedIndicatorArea = controller.indicatorAreas[0].getValue();
			controller.changeIndicatorArea();

			controller.selectedFilterSection = controller.filterSections[0].getValue();
			controller.changeSection();
			system.assertEquals('null', controller.selectedIndicatorArea);

			controller.selectedFilterSection = 'null';
			controller.changeSection();
		Test.stopTest();
	}

	static testMethod void testExitStudents(){
		setupTestData();
		Test.setCurrentPage(Page.IM_SectionDetail);
		ApexPages.currentPage().getParameters().put('SectionID', section.ID);

		Test.startTest();
			sectionDetailExtension controller = new sectionDetailExtension();
			system.assertEquals(5, controller.enrolledStudents.size(),'Expected 5 students to be enrolled in the section.');

			controller.enrolledStudents[0].checked = true;

			controller.startExitStudents();
			controller.studentSectionHolder.Enrollment_End_Date__c = system.today().addDays(3);
			controller.studentSectionHolder.Section_Exit_Reason__c = 'Testing the exit';

			controller.finishExitStudents();
		Test.stopTest();
	}

	static testMethod void addTimetTest() {
		setupTestData();

		Test.setcurrentPage(Page.IM_SectionDetail);
		ApexPages.currentPage().getParameters().put('SectionID',section.id);
		Test.startTest();
			System.runAs(TestDataUtil.testData[0].sysAdmin.userRecord){
				sectionDetailExtension controller = new sectionDetailExtension();
				
				controller.enrolledStudents[0].checked = true;
				controller.enrolledStudents[1].checked = true;
				controller.enrolledStudents[2].checked = true;
				controller.enrolledStudents[3].checked = true;
				controller.enrolledStudents[4].checked = true;
				controller.addStudentstoAddTime();
				system.assertEquals(5, controller.studentsToAddTime.size());

				controller.ISHolder.Date__c = Date.today();
				controller.ISHolder.Skills__c = 'Test Skills';
				controller.ISHolder.Comments__c = 'Test Comments';
				controller.ISRHolder.Amount_of_Time__c = 10;
				controller.addTime();
				for(sectionDetailExtension.studentEnrollmentWrapper sew: controller.enrolledStudents){
					system.assertEquals(10, sew.Dosage);
				}
				
				controller.ISHolder.Date__c = Date.today();
				controller.getSessionDetails();
				controller.ISHolder.Skills__c = 'Test Skills';
				controller.ISHolder.Comments__c = 'Test Comments';
				controller.ISRHolder.Amount_of_Time__c = 15;
				controller.addTime();
				for(sectionDetailExtension.studentEnrollmentWrapper sew: controller.enrolledStudents){
					system.assertEquals(15, sew.Dosage);
				}
			}
		Test.stopTest();
	}
	*/
}
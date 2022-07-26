@isTest
private class Test_Student_GradeCalculations {
	@isTest static void Test_Constructor() {
		Test_Report_Card_Controller.setupData(false);

		pageReference rcPage = Page.Student_GradeCalculations;
		rcPage.getParameters().put('studentId', TestDataSetupUtil_v2.studentsList[0].id);
		Test.setCurrentPage(rcPage);

		Test.startTest();
			Student_GradeCalculations controller = new Student_GradeCalculations();
			system.assertEquals(TestDataSetupUtil_v2.studentsList[0].id,controller.student.id);
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id, controller.setup.id);
			system.assertEquals(8, controller.orderedReportingPeriods.size());
			system.assertEquals(TestDataSetupUtil_v2.sectionsList.size(), controller.gradeTable.sections.size());
		Test.stopTest();
	}

	@isTest static void Test_FinalGradeDrill(){
		Test_Report_Card_Controller.setupData(false);

		pageReference rcPage = Page.Student_GradeCalculations;
		rcPage.getParameters().put('studentId', TestDataSetupUtil_v2.studentsList[0].id);
		Test.setCurrentPage(rcPage);

		Test.startTest();
			Student_GradeCalculations controller = new Student_GradeCalculations();
			controller.selectedCourse = controller.gradeTable.sections[0].sectionInfo.courseID;
			controller.drillFinalGrade();
			system.assertEquals(controller.gradeTable.sections[0].sectionInfo.courseID,controller.detailWrapper.finalGrade.Course__c);
		Test.stopTest();
	}

	@isTest static void Test_SectionGradeDrill(){
		Test_Report_Card_Controller.setupData(false);
		Assignment__c a = new Assignment__c(
			Time__c=TestDataSetupUtil_v2.semester.id,
			Name='Test Assignment',
			Section__c= TestDataSetupUtil_v2.sectionsList[0].id,
			Include_In_Final_Grade__c = true);
		insert a;
		Grade__c g = new Grade__c(
			Time__c=TestDataSetupUtil_v2.semester.id,
			Assignment__c=a.id, 
			Course__c= TestDataSetupUtil_v2.coursesList[0].id,
			Student_Section__c=TestDataSetupUtil_v2.studSectionsList[0].id,
			Student__c = TestDataSetupUtil_v2.studentsList[0].id,
			Entered_Grade__c = '40');
		insert g;

		pageReference rcPage = Page.Student_GradeCalculations;
		rcPage.getParameters().put('studentId', TestDataSetupUtil_v2.studentsList[0].id);
		Test.setCurrentPage(rcPage);

		Test.startTest();
			Student_GradeCalculations controller = new Student_GradeCalculations();
			controller.selectedCourse = TestDataSetupUtil_v2.sectionsList[0].Course__c;
			system.assertEquals(a.Section__c, controller.gradeTable.sections[0].sectionInfo.sectionId);
			system.assertEquals(g.Student_Section__c, controller.gradeTable.sections[0].sectionGrades[0].sg.Student_Section__c);
			controller.selectedRecord = controller.gradeTable.sections[0].sectionGrades[0].sg.id;

			controller.drillSectionGrade();

			System.assertNotEquals(null, controller.gradeDetailWrapper);
			System.assertEquals(1, controller.gradeDetailWrapper.grades.size());
		Test.stopTest();
	}


}
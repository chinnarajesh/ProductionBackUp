/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_Transfer_CourseWizard {

    static testMethod void testTransferCourseWizard() {
    	testDataSetupUtil_v2.isGradebook = true;
        testDataSetupUtil_v2.setUPCoreData(3);
		testDataSetupUtil_v2.setUPStaffData(3);
		testDataSetupUtil_v2.setUPStudentData(3);

		ID subjectArea = core_SoqlUtils.getRecordTypesBySobject('Course__c').get('Subject_Area');
		Course__c subjectAreaCourse = new Course__c(RecordTypeID = subjectArea, Name = 'Test Subject Area Writing');
		insert subjectAreaCourse;		
		
		test.starttest();
			Transfer_CourseWizard TCW1 = new Transfer_CourseWizard();
			TCW1.getTransferCourses();

			//make a new transfer course
			TCW1.openTransferCourses();
			TCW1.openTransferCreateCourses();
			TCW1.newCourse.Name = 'test transfer course';
			TCW1.newCourse.Course_Number__c = 'TTCourse1';
			TCW1.newCourse.Subject_Area_Lookup__c = TCW1.subjectSelections[0].getValue();
			TCW1.newCourse.Credit_Hours__c = 5;
			TCW1.createTransferCourse();

			//search students
			TCW1.searchSTudents();
			TCW1.fromSearchStudent[0].selected = true;
			TCW1.selectStudent();

			//create a new transfer student
			TCW1.page2Transition();
			TCW1.openCreateStudentRecord();
			TCW1.chosenStudent.dummyStudent.Grade__c = '8';
			TCW1.chosenStudent.dummyStudent.School_Year__c = TCW1.yearSelections[0].getValue();
			TCW1.chosenStudent.addStudentRecord();

			//edit a final grade
			TCW1.selectedStudentID = (String)TCW1.chosenStudent.student.ID;	
			TCW1.chosenStudent.selectedStudentID = (String)TCW1.selectedStudentID;
			TCW1.chosenStudent.editFinalGrade();
			TCW1.chosenStudent.selectedStudentID = (String)TCW1.chosenStudent.student.ID;
			TCW1.chosenStudent.currentFinalGradeList = TCW1.chosenStudent.studentToFinalGrades.get(TCW1.selectedStudentID);
			TCW1.openEditFinalGrade();

			//make a new final grade
			TCW1.chosenStudent.selectedStudentID = (String)TCW1.chosenStudent.student.ID;
			TCW1.chosenStudent.addFinalGrade();
			TCW1.chosenStudent.currentFinalGradeList[TCW1.chosenStudent.currentFinalGradeList.size() - 1].Transfer_School__c = 'Fake School';
			TCW1.chosenStudent.currentFinalGradeList[TCW1.chosenStudent.currentFinalGradeList.size() - 1].Final_Grade_Letter_v2__c = 'A';
			TCW1.chosenStudent.currentFinalGradeList[TCW1.chosenStudent.currentFinalGradeList.size() - 1].Final_Grade_Value__c = 97;
			TCW1.chosenStudent.currentFinalGradeList[TCW1.chosenStudent.currentFinalGradeList.size() - 1].Unweighted_GPA__c = 4;
			TCW1.chosenStudent.currentFinalGradeList[TCW1.chosenStudent.currentFinalGradeList.size() - 1].Weighted_GPA__c = 4;
			TCW1.chosenStudent.saveFinalGrade();
			
			//call random methods - BOO
			TCW1.closeTransferCreateCourses();
			TCW1.closeTransferCourses();
			TCW1.closeEditStudentRecord();
			TCW1.openEditSTudentRecord();
			TCW1.closeEditFinalGrade();
			TCW1.closeAddfinalGrade();
			TCW1.openAddFinalGrade();
			TCW1.cancelingCourse();
			TCW1.openEditFinalGrade();
			TCW1.selectedRowID = String.valueOf(0);
			TCW1.deleteRow();
			TCW1.selectedStudentRowID = String.valueOf(1);
			TCW1.deleteStudentRow();
			TCW1.nextStep();
			TCW1.enrollmentWizard();
		test.stopTest();
    }
}
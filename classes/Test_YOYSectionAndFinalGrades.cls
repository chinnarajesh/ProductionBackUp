@isTest
private class Test_YOYSectionAndFinalGrades {
	public static void createTestData(){
        TestDataSetupUtil_v2.setUPCoreData(3);
        TestDataSetupUtil_v2.setUpStaffData(5);
        TestDataSetupUtil_v2.setUpStudentData(5);
        
        Section_Grade__c sg=
            new Section_Grade__c(
                Student_Section__c = TestDataSetupUtil_v2.studSectionsList[0].id,
                Time__c = TestDataSetupUtil_v2.semester.id,
                Grade_Overridden__c = true,
                Grade_Override__c = '98',
                Grade__c = 98,
                Letter_Grade__c = 'A');
        insert sg;
        Final_Grade__c fg=
            new Final_Grade__c (Student__c=TestDataSetupUtil_v2.studentsList[0].id, 
                Course__c=TestDataSetupUtil_v2.coursesList[0].id, 
                Final_Grade_Value__c=98, 
                Final_Grade_Letter_v2__c = 'A', 
                Unweighted_GPA__c =4.0, 
                Weighted_GPA__c=4.0);
        insert fg;

        Test.setCurrentPage(Page.YOY_SectionAndFinalGrades);
    }

    static testMethod void myUnitTest() {
        createTestData();

        Test.startTest();
            Contact c = TestDataSetupUtil_v2.studContactsList[0];
            ApexPages.StandardController con = new ApexPages.StandardController(c);
            YOY_SectionGradesAndFinalGrades yoy = new YOY_SectionGradesAndFinalGrades(con);
            yoy.selectedYear = yoy.yearOptions[0].getValue();
            yoy.retrieveGrades();
        
            System.assertNotEquals(0, yoy.studentWrapperList.size());
        Test.stopTest();
    }
}
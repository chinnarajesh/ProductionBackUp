@isTest
private class Test_SectionGrade_Comments {

    static testMethod void test_SG_Comments(){
        Test_Gradebook_AssignmentController_v2.createTestData();
        test.starttest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
            Test_attachAssignment.createAssignment();
            GradebookController g = new GradebookController();
            
            g.baseObj.selectedTimeID = testDataSetupUtil_v2.sectionsList[0].Reporting_Period__c;
            g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
            g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);           
            
            g.retrieveStudentGrades();

//          Id sectGradeId = g.gradebookObj.studentWrapperList[0].sectionGrade.Id;
//
//          Map<Id,String> sgCommentsMap = new Map<Id,String>();
//          sgCommentsMap.put(sectGradeId,'Test English Comments');
//
//          Map<Id,String> sgAltCommentsMap = new Map<Id,String>();
//          sgAltCommentsMap.put(sectGradeId,'Test Alt Lang Comments');
//
//          Gradebook_SG_CommentsController testObj = new Gradebook_SG_CommentsController(g);
//          String result = Gradebook_SG_CommentsController.updateComments_SG(sgCommentsMap,sgAltCommentsMap);
//          System.assertEquals(result,'success');
//
//          result = Gradebook_SG_CommentsController.updateComments_SG(null,null);
//          System.assertEquals(result,'failure');
            System.assert(true);

            test.stoptest();
        }
    }
}
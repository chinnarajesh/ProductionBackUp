@isTest
public with sharing class Test_PointsMatrix {
	private static void setupData(boolean teacherISAdmin){
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(1);
		testDataSetupUtil_v2.setUpStudentData(3);
		TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = TestDataSetupUtil_v2.term.Date_Start_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = TestDataSetupUtil_v2.term.End_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Monthly';
        TestDataSetupUtil_v2.activeSetUp.Points_Reset_Value__c = 0;
        TestDataSetupUtil_v2.activeSetUp.Days__c = '1';
        update TestDataSetupUtil_v2.activeSetUp;
		testDataSetupUtil_v2.createPointsCats(null);
		testDataSetupUtil_v2.createPointsCats(testDataSetupUtil_v2.activeSetup.id);
		TestDataSetupUtil_v2.createPointsSettings(teacherISAdmin);
	}
	
	private static testmethod void TestConstructorTeacher(){
		setupData(false);
		
		PageReference pr = Page.Points_Matrix;
		Test.setCurrentPage(pr);
		
		Test.startTest();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
				Points_Matrix controller = new Points_Matrix();
				
				system.assertEquals(false, controller.bFatalError);
				system.assertEquals(false, controller.showMatrix);
				system.assertEquals(system.today(), controller.selectedDate);
			}
		
		Test.stopTest();
	}
	
	private static testmethod void TestConstructorAdmin(){
		setupData(true);
		
		PageReference pr = Page.Points_Matrix;
		Test.setCurrentPage(pr);
		
		Test.startTest();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
				Points_Matrix controller = new Points_Matrix();
				
				system.assertEquals(false, controller.bFatalError);
				system.assertEquals(false, controller.showMatrix);
				system.assertEquals(system.today(), controller.selectedDate);
			}
		Test.stopTest();
	}
	
	private static testmethod void TestFilterChangeMethods(){
		setupData(false);
		
		PageReference pr = Page.Points_Matrix;
		Test.setCurrentPage(pr);
		
		Test.startTest();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
				Points_Matrix controller = new Points_Matrix();
				
				controller.selectedSchool = testDataSetupUtil_v2.school.id;
				controller.changeSchool();
				system.assertEquals('--None--',controller.selectedGrade);
				
				controller.selectedGrade = '5';
				controller.changeGrade();
			}
		Test.stopTest();
	}
	
	private static testmethod void TestFilterAndLoadTeacher(){
		setupData(false);
		
		PageReference pr = Page.Points_Matrix;
		Test.setCurrentPage(pr);
		
		Test.startTest();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
				Points_Matrix controller = new Points_Matrix();
				
				controller.selectedSchool = '--None--';
				controller.selectedGrade = '--None--';
				controller.changeGrade();
				
				controller.selectedSchool = testDataSetupUtil_v2.school.id;
				controller.changeSchool();
				system.assertEquals('--None--',controller.selectedGrade);
				
				controller.selectedGrade = '9';
				controller.changeGrade();
				
				controller.selectedGrade = '--None--';
				controller.changeGrade();
				
				controller.selectedGrade = '5';
				controller.selectedSchool = '--None--';
				controller.changeGrade();
				
				controller.selectedSection = testDataSetupUtil_v2.sectionsList[0].id;
				controller.filterAndLoad();
			}
		Test.stopTest();
	}
	
	private static testmethod void TestFilterAndLoadAdmin(){
		setupData(true);
		
		PageReference pr = Page.Points_Matrix;
		Test.setCurrentPage(pr);
		
		Test.startTest();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
				Points_Matrix controller = new Points_Matrix();
				
				controller.selectedSchool = testDataSetupUtil_v2.school.id;
				controller.changeSchool();
				system.assertEquals('--None--',controller.selectedGrade);
				
				controller.selectedGrade = '5';
				controller.changeGrade();
				controller.prettyDate = '6/1/2012';
				controller.changeDate();
				controller.filterAndLoad();
			}
		Test.stopTest();
	}
	
	private static testmethod void TestSave(){
		setupData(true);
		
		PageReference pr = Page.Points_Matrix;
		Test.setCurrentPage(pr);
		
		Test.startTest();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
				Points_Matrix controller = new Points_Matrix();
				
				controller.selectedSchool = testDataSetupUtil_v2.school.id;
				controller.changeSchool();
				system.assertEquals('--None--',controller.selectedGrade);
				
				controller.selectedGrade = '5';
				controller.changeGrade();
				
				controller.filterAndLoad();
				controller.points[0].points[0].Points__c=15;
				controller.redeempoints[0].redeempoint.Points__c = -5;
				controller.RedeemPoints();
				controller.SavePoints();
			}
		Test.stopTest();
	}
}
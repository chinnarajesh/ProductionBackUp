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
public class Test_Gradebook_EditAssignStandards {

	public static Assignment__c createdAssignment;
	
	public static void createAssignment(){
		
		createdAssignment = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
		createdAssignment.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;
		createdAssignment.Picklist_value__c = [select id from Picklist_value__c  where RecordType.DeveloperName = 'Grade_Scale' AND Name = 'Points'  limit 1 ].id;
		createdAssignment.Possible_Points__c = 40;	
		createdAssignment.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		createdAssignment.Name_in_Gradebook__c = 'Test1';
		insert createdAssignment;
		
		Grade__c g = new Grade__c(
			Possible_points__c = createdAssignment.Possible_Points__c, 
			Student__c =testDataSetupUtil_v2.studentsList[0].id, 
			Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , 
			Time__c = testDataSetupUtil_v2.semester.id, 
			Assignment__c = createdAssignment.id,
			Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id, 
			Assignment_Weighting__c = createdAssignment.Weighting_Value__c, 
			Include_In_Standard_Grade__c = false);
		insert g;
		
	    Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = createdAssignment.Standard_Scale__c);
    	update co; 
	}

    static testMethod void myUnitTest() {
        TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();  
		testDataSetupUtil_v2.setupStandards();

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){

			createAssignment();
			test.startTest();
			Gradebook_EditAssignStandardsController EAS = new Gradebook_EditAssignStandardsController(createdAssignment.ID);
			
			Standard__c testStandard2 = new Standard__c();
			Standard__c testStrand2 = new Standard__c();
			testStandard2.name = 'Test Standard 2';
			testStandard2.Level__c = 2;
			testStandard2.Course__c = EAS.course;
			testStandard2.Subject__c = 'test';
			testStandard2.Identifier__c = 'testing';
			system.debug('Anson: test standard 2 course: ' + EAS.course);
			testStrand2.name = 'Test Strand 2';
			testStrand2.Level__c = 1;
			testStrand2.Course__c = EAS.course;
			testStrand2.Subject__c = 'test';
			insert testStrand2;
			testStandard2.Strand__c = testStrand2.ID;
			insert testStandard2;
									
			EAS.standardIdentifierSearch = 'testing*';
			EAS.standardStrandSearch = 'Test Strand 2*';
			EAS.standardParentStandardSearch = '';
			EAS.standardSubjectSearch = 'test';
			EAS.searchStandardMethods();
			
			system.debug('Anson: is there a standard grade scale?: ' + EAS.assignment.Standard_Scale__c);
			system.debug('Anson: what is in teh generalList: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList:' + EAS.searchList);
			
			EAS.standardOnly = true;			
						
			EAS.searchList[0].selected = true;
			EAS.addStandards();
			
			system.debug('Anson: what is in the standardList NOW: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList Now: ' + EAS.searchList);
			
			ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(EAS.assignment);
			Assignment_StandardsListController a_sLC = new Assignment_StandardsListController(sc);			
			
			EAS.standardList[0].selected = true;
			
			EAS.cancel();
			EAS.returnToAssignment();
		}		
		test.stopTest();      
    }
    
   static testMethod void myUnitTest2() {
		testDataSetupUtil_v2.setUPCoreData(2);	
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();  
		testDataSetupUtil_v2.setupStandards();
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			createAssignment();
			test.startTest();
			Gradebook_EditAssignStandardsController EAS = new Gradebook_EditAssignStandardsController(createdAssignment.ID);
			
			Standard__c testStandard2 = new Standard__c();
			Standard__c testStrand2 = new Standard__c();
			testStandard2.name = 'Test Standard 2';
			testStandard2.Level__c = 2;
			testStandard2.Course__c = EAS.course;
			testStandard2.Subject__c = 'test';
			testStandard2.Identifier__c = 'testing';
			system.debug('Anson: test standard 2 course: ' + EAS.course);
			testStrand2.name = 'Test Strand 2';
			testStrand2.Level__c = 1;
			testStrand2.Course__c = EAS.course;
			testStrand2.Subject__c = 'test';
			insert testStrand2;
			testStandard2.Strand__c = testStrand2.ID;
			insert testStandard2;
			
			system.debug('testStandard2: ' + testStandard2);
			
			Standard__c ts = [select id, Subject__c from Standard__c where id = :testStandard2.id AND Subject__c = 'test' limit 1];
			
			system.debug('Anson: what is ts: ' + ts);
			
			EAS.standardIdentifierSearch = 'testing*';
			EAS.standardStrandSearch = 'Test Strand 2*';
			EAS.standardParentStandardSearch = '';
			EAS.standardSubjectSearch = 'test';
			EAS.searchStandardMethods();
			
			system.debug('Anson: is there a standard grade scale?: ' + EAS.assignment.Standard_Scale__c);
			system.debug('Anson: what is in teh generalList: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList:' + EAS.searchList);			
						
			EAS.searchList[0].selected = true;
			EAS.addStandards();
			
			system.debug('Anson: what is in the standardList NOW: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList Now: ' + EAS.searchList);
			EAS.editSaveStandards();
			EAS.standardList[0].selected = true;
			EAS.removeStandards();
			
			EAS.cancel();
			EAS.returnToAssignment();
			
		}		
		test.stopTest();      
    }
}
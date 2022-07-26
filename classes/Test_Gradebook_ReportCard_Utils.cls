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
private class Test_Gradebook_ReportCard_Utils {

	static testMethod void test_populateTimeList() {
		TestDataSetupUtil_v2.setupCoreData(1);
		Test.startTest();
			Map<ID,Time_Element__c> rpMap = new Map<ID,Time_Element__c>([SELECT id, Date_Start_Date__c, End_Date__c FROM Time_Element__c]);
			List<String> timeList = Gradebook_ReportCard_Utils.populateTimeList(rpMap);
			system.assertEquals(rpMap.size(),timeList.size());
			for(String s: timeList){
				List<String> split = s.split(';');
				system.assert(rpMap.containsKey(split[0]));
				system.assertEquals(rpMap.get(split[0]).Date_Start_Date__c.format(),split[1]);
				system.assertEquals(rpMap.get(split[0]).End_Date__c.format(),split[2]);
			}
		Test.stopTest();
	}
	
	static testMethod void test_getDocumentSchools(){
		TestDataSetupUtil_v2.setupCoreData(1);
		Test.startTest();
			List<Setup__c> results = Gradebook_ReportCard_Utils.getDocumentSchools(true);
			system.assertEquals([SELECT count() FROM Setup__c WHERE Active__c=true],results.size());
			results = Gradebook_ReportCard_Utils.getDocumentSchools(false);
			system.assertEquals([SELECT count() FROM Setup__c],results.size());
		Test.stopTest();
	}
	
	static testMethod void test_getReportingPeriods(){
		TestDataSetupUtil_v2.setupCoreData(1);
		Test.startTest();
			List<Time_Element__c> terms = [SELECT id FROM Time_Element__c WHERE Picklist_Value__r.Name='Term'];
			Set<ID> termIds = new Set<ID>();
			for(Time_Element__c te: terms) termIds.add(te.id);
			List<Time_Element__c> rps = Gradebook_ReportCard_Utils.getReportingPeriods(termIds);
			system.assertEquals([SELECT count() FROM Time_Element__c WHERE Parent_Time_Element__c IN :termIds AND Reporting_Period__c=true],rps.size());
		Test.stopTest();
	}
	
	/*static testMethod void test_getStudentReportingPeriods(){
		
	}
	
	static testMethod void test_getStudentReportingPeriodList(){
		
	}*/
	
	static testMethod void test_getStudentInfo(){
		TestDataSetupUtil_v2.setupCoreData(1);
		TestDataSetupUtil_v2.setUpStaffData(1);
		TestDataSetupUtil_v2.setUpStudentData(2);
		Test.startTest();
			Student__c result = Gradebook_ReportCard_Utils.getStudentInfo(TestDataSetupUtil_v2.studentsList[0].id);
			system.assertNotEquals(null,result.id);
			try{
				result = Gradebook_ReportCard_Utils.getStudentInfo(TestDataSetupUtil_v2.activeSetup.id);
			} catch(Gradebook_ReportCard_Utils.DocumentRuntimeException e){
				system.assertEquals('ERROR: The student with the id specified was not found in the system.',e.getMessage());
			}
		Test.stopTest();
	}
	
	static testMethod void test_getStudentClassSize(){
		TestDataSetupUtil_v2.setupCoreData(1);
		TestDataSetupUtil_v2.setUpStaffData(1);
		TestDataSetupUtil_v2.setUpStudentData(2);
		Test.startTest();
			system.assertEquals(2,Gradebook_ReportCard_Utils.getStudentClassSize('5',TestDataSetupUtil_v2.school.id));
		Test.stopTest();
	}
	
	/*static testMethod void test_getStudentReportingPeriod(){
		
	}*/
	
	static testMethod void test_getSetupInfo(){
		TestDataSetupUtil_v2.setupCoreData(1);
		Test.startTest();
			Setup__c result = Gradebook_ReportCard_Utils.getSetupInfo(TestDataSetupUtil_v2.activeSetup.id);
			system.assertNotEquals(null,result.id);
			try{
				result = Gradebook_ReportCard_Utils.getSetupInfo(TestDataSetupUtil_v2.school.id);
			} catch(Gradebook_ReportCard_Utils.DocumentRuntimeException e){
				system.assertEquals('The system was unable to find the setup as listed on the student record. Check to make sure the student is linked to a setup.',e.getMessage());
			}
		Test.stopTest();
	}
	
	static testMethod void test_getSchoolInfo(){
		TestDataSetupUtil_v2.setupCoreData(1);
		Test.startTest();
			Account result = Gradebook_ReportCard_Utils.getSchoolInfo(TestDataSetupUtil_v2.school.id);
			system.assertNotEquals(null,result.id);
			try{
				result = Gradebook_ReportCard_Utils.getSchoolInfo(TestDataSetupUtil_v2.activeSetup.id);
			} catch(Gradebook_ReportCard_Utils.DocumentRuntimeException e){
				system.assertEquals('The system was unable to find the school as listed on the student record. Check to make sure the student is linked to a school.',e.getMessage());
			}
		Test.stopTest();
	}
	/* KC: Commenting these out as they don't need to be run if they do nothing
	static testMethod void test_getReportingPeriodsByID(){
		
	}
	
	static testMethod void test_getSectionGrades(){
		
	}
	
	static testMethod void test_getSemesterGrades(){
		
	}
	
	static testMethod void test_getSectionEnrollment(){
		
	}
	
	static testMethod void test_getFinalGrades(){
		
	}
	
	static testMethod void test_getInstructionalStaff(){
		
	}
	
	static testMethod void test_getStudentHomework(){
		
	}
	
	static testMethod void test_getStudentAttendance(){
		
	}
	
	static testMethod void test_getIncompleteAssignments(){
		
	}
	
	static testMethod void test_getStandardGrades(){
		
	}
	
	static testMethod void test_getStrandGrades(){
		
	}
	
	static testMethod void test_getFinalGradeNoralizations(){
		
	}*/
}
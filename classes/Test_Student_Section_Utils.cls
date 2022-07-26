@isTest
private class Test_Student_Section_Utils {
	private static final Integer COUNT = 5;
	private static final Integer AMOUNT = 30;

	@testSetup
	private static void setupData(){
		testDataSetupUtil_v2.setUPCoreData(COUNT);
		testDataSetupUtil_v2.setUPStaffData(COUNT);
		testDataSetupUtil_v2.setUPStudentData(COUNT);
		testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
		testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);

		List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
		//groups[0] has 3 sections, groups[1] has 2 sections
		List<Scheduled_Section__c> schsec = TestDataSetupUtil_v2.createScheduledSections(groups);		
	}

	static testMethod void testFillStudentProgramField() {
		List<Student_Section__c> listSS = [SELECT Id, Student__c, Program__c, Amount_of_Time__c, Student_Program__c, Active__c FROM Student_Section__c];
		for(Student_Section__c studentSection: listSS){
			studentSection.Student_Program__c = null;
		}

    	Test.startTest();
    		StudentSectionUtils.fillStudentProgramField(listSS, null);
    	Test.stopTest();

		for(Student_Section__c studentSection: listSS){
			System.assertNotEquals(null, studentSection.Student_Program__c);
		}
	}

	static testMethod void testCalculateAmountOfTime() {
		List<Student_Section__c> listSS = [SELECT Id, Student__c, Program__c, Amount_of_Time__c, Student_Program__c, Active__c FROM Student_Section__c];
		StudentSectionUtils.fillStudentProgramField(listSS, null);

    	Test.startTest();
    		StudentSectionUtils.calculateAmountOfTime(listSS, null);
    	Test.stopTest();

    	List<Student_Program__c> studentPrograms = new List<Student_Program__c>([SELECT Id, Student__c, Amount_of_Time__c FROM Student_Program__c]);
    	System.assertEquals(COUNT + 1, studentPrograms.size());
		for(Student_Program__c studentProgram: studentPrograms){
			System.assertEquals(AMOUNT, studentProgram.Amount_of_Time__c);
		}
	}

	static testMethod void testdeleteStudentSection() {
		List<Student_Section__c> listSS = [SELECT Id, Student__c, Section__c, Section__r.Account_Program__c, Program__c, Amount_of_Time__c, Student_Program__c, Active__c,
			(SELECT Id, Intervention_Session__c FROM Intervention_Session_Results__r) FROM Student_Section__c];
		List<Section__c> listS = [SELECT Id FROM Section__c];
		Section__c newSec = listS[COUNT-1];
		newSec.Program__c = listSS[0].Program__c;
		newSec.Account_Program__c = listSS[0].Section__r.Account_Program__c;
		update newSec;
		Student_Section__c uss = new Student_Section__c(Section__c = listSS[COUNT].Section__c, Student__c = listSS[0].Student__c);
		insert uss;
		
		Map<Id, Intervention_Session__c> mapIS = new Map<Id, Intervention_Session__c>(); 
		for(Student_Section__c ss: listSS){
			for(Intervention_Session_Result__c isr: ss.Intervention_Session_Results__r){
				mapIS.put(isr.Intervention_Session__c, new Intervention_Session__c(Id=isr.Intervention_Session__c));
			}
		}

    	Test.startTest();
    		delete mapIS.values();
    		delete listSS;
    	Test.stopTest();

    	List<Student_Program__c> studentPrograms = new List<Student_Program__c>([SELECT Id, Student__c, Amount_of_Time__c FROM Student_Program__c]);
    	System.assertEquals(1, studentPrograms.size());
	}

	static testMethod void testdeleteSection() {
		List<Section__c> listS = [SELECT Id FROM Section__c];		

    	Test.startTest();
    		delete listS;
    	Test.stopTest();

    	List<Student_Program__c> studentPrograms = new List<Student_Program__c>([SELECT Id, Student__c, Amount_of_Time__c FROM Student_Program__c]);
    	System.assertEquals(0, studentPrograms.size());
	}

	static testMethod void testEnrollmentSS() {
		List<Enrollment_Tracking__c> listET;
		List<Student_Section__c> listSS = [SELECT Id, Student__c, Section__c, Section__r.Account_Program__c, Program__c, Amount_of_Time__c, Student_Program__c, Active__c FROM Student_Section__c];

    	Test.startTest();
    		listSS[0].Active__c = false;
    		listSS[0].Section_Exit_Reason__c = core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
    		update listSS[0];
    		listET = [SELECT Id FROM Enrollment_Tracking__c WHERE Student_Section__c = :listSS[0].Id];
    		System.assertEquals(2, listET.size());
    		listSS[0].Active__c = true;
    		listSS[0].Enrollment_start_date__c = Datetime.now().addMinutes(1);
    		update listSS[0];
    		listET = [SELECT Id FROM Enrollment_Tracking__c WHERE Student_Section__c = :listSS[0].Id];
    		System.assertEquals(3, listET.size());    		
    	Test.stopTest();
	}

	static testMethod void testSheduledSS() {
		List<Section__c> groups = [SELECT Id FROM Section__c WHERE RecordType.DeveloperName='Schedule_Group'];
		List<Student__c> listStudent = [SELECT Id FROM Student__c];

		Test.startTest();
			listStudent[0].Primary_Schedule_Group__c = groups[0].id;
			update listStudent[0];
			List<Student_Section__c> listSS = [SELECT Id FROM Student_Section__c WHERE Student__c = :listStudent[0].Id];
			System.assertEquals(2, listSS.size());
		Test.stopTest();
	}

}
@isTest
private class Test_AssessmentTrigger {

    static testMethod void test() {
        testDataSetupUtil_v2.setUPCoreData(0);
        testDataSetupUtil_v2.setUPStaffData(0);
        testDataSetupUtil_v2.setUPStudentData(1);
        
        Test.startTest();
        	Assesment__c sfId = new Assesment__c(Assessment_Results__c = '1', Student__c = testDataSetupUtil_v2.studentsList[0].id);
        	Assesment__c cId = new Assesment__c(Assessment_Results__c = '2', Student__c = testDataSetupUtil_v2.studentsList[0].id, Year_Over_Year__c = true);
        	
        	List<Assesment__c> tempList = new List<Assesment__c>{sfId, cId};
        	insert tempList;
        	
        	tempList.clear();
        	tempList = [select Student_Id__c, Student__c, Contact__c, Year_Over_Year__c from Assesment__c where Student__c =: testDataSetupUtil_v2.studentsList[0].id];
        	//There should be two assessments.
        	system.assertEquals(2, tempList.size());
        	for(Assesment__c a: tempList){
                //CY workflows makes this always invalid as they don't change in the memory after insert.
        		//system.assertEquals(testDataSetupUtil_v2.studentsList[0].Student_ID__c, a.Student_ID__c);
        		if(a.Year_Over_Year__c)
        			system.assertEquals(testDataSetupUtil_v2.studentsList[0].Individual__c, a.Contact__c);
        		else
        			system.assertEquals(null, a.Contact__c);
        	}
        Test.stopTest();
    }
}
@isTest
private class Test_SchedulerWrapper {

	/*
		Since there's only one real method here (constructor), I'll test that
	*/
    static testMethod void testConstructor() {
        testDataSetupUtil_v2.setUpCoreData(5);
        testDataSetupUtil_v2.setUpStaffData(5);
        testDataSetupUtil_v2.setUpStudentData(5);
        
        Test.startTest();
        
        SchedulerWrapper testing = new SchedulerWrapper(testDataSetupUtil_v2.school);
        System.assertEquals(testing.availableStudents.size(),testDataSetupUtil_v2.studentsList.size());
        System.assertEquals(testing.availableStaff.size(),testDataSetupUtil_v2.teachersList.size());
        System.assertEquals(testing.availableRooms.size(),testDataSetupUtil_v2.roomList.size());
        
        Test.stopTest();
    }
    
    /*
    	This class doesn't really do much
    */
    static testMethod void testInnerClass(){
    	testDataSetupUtil_v2.setUpCoreData(2);
    	Room__c room = new Room__c(School__c=testDataSetupUtil_v2.school.id);
    	insert room;
    	
    	Test.startTest();
    	
    	SchedulerWrapper.cSectionWrapper testing = new SchedulerWrapper.cSectionWrapper(room);
    	System.assertEquals(room.id,testing.room.id);
    	
    	Test.stopTest();
    }
}
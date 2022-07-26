@isTest
private class TestNewStudentController {

	static testMethod void myUnitTest() {
		Test.startTest();
			ApexPages.StandardController sc = new ApexPages.StandardController(new Student__c());
			NewStudentController controller = new NewStudentController(sc);
			List<String> testList = controller.addInfo;
			system.assertEquals(3,testList.size());
			testList = controller.sysInfo;
			system.assertEquals(4,testList.size());
			controller.stu.Student_First_Name__c = 'Test';
			controller.stu.Student_Last_Name__c = 'LastTest';
			controller.saveStudent();
			controller.saveAndNewStudent();
		Test.stopTest();
	}
}
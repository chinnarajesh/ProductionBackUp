@isTest
private class Test_PortalAddAttachmentsController {
	static testMethod void testUpload() {
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUPStaffData(5);
		TestDataSetupUtil_v2.setUPStudentData(5);
		TestDataSetupUtil_v2.sessionsList = TestDataSetupUtil_v2.getSessions(5, TestDataSetupUtil_v2.semester,testDataSetupUtil_v2.sectionsList[1].id, null);
		
		
		PageReference pref = Page.Portal_AddAttachments;
		pref.getParameters().put('aID', TestDataSetupUtil_v2.sessionsList[0].id);
		pref.getParameters().put('aName', 'TestName');
		pref.getParameters().put('stud', TestDataSetupUtil_v2.studentsList[0].id);
		pref.getParameters().put('session', TestDataSetupUtil_v2.sessionsList[0].id);
		Test.setCurrentPage(pref);
		
		Test.startTest();
			Portal_AddAttachmentsController controller = new Portal_AddAttachmentsController();
			controller.fileDesc = 'TestAttachment';
			controller.fileBlob = Blob.valueOf('TestBody');
			controller.fileName = 'TestName';
			
			controller.upload();
			
			Attachment a = [select id, Name, Description, ParentId, body from Attachment where ParentID =: TestDataSetupUtil_v2.sessionsList[0].id];
			system.assertEquals('TestName', a.Name);
			system.assertEquals('TestBody', a.Body.toString());
		Test.stopTest();
	}
}
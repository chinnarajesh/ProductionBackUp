@isTest
private class Test_CourseSubjectAreaHelper
{
	private final static String SUB_AREA = 'Citizenship';
	static testMethod void testCreateSubAreas()
	{
		testDataSetupUtil_v2.setupCoreData(2);
		testDataSetupUtil_v2.coursesList[0].subject_area__c = SUB_AREA;
		update testDataSetupUtil_v2.coursesList[0];
		
		Test.startTest(); 
		Course_SubjectAreaHelper.createSubjectAreas();
		Course_SubjectAreaHelper.createSubjectAreas();
		Test.stopTest();
		
		Id subjAreaId = core_SoqlUtils.getRecordTypesBySobject('Course__c').get('Subject_Area');
		System.assert([SELECT Id FROM Course__c WHERE RecordTypeId = :subjAreaId].size() > 0);
	}
}
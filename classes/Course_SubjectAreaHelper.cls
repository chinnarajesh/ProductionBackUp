public with sharing class Course_SubjectAreaHelper
{
	public static void createSubjectAreas()
	{
		Schema.DescribeFieldResult subArea = Course__c.Subject_Area__c.getDescribe();
		List<Schema.PicklistEntry> picklistVals = subArea.getPicklistValues();
		Id subType = core_SoqlUtils.getRecordTypesBySobject('Course__c').get('Subject_Area');
		Set<String> pickVals = new Set<String>();
		for (Schema.PicklistEntry entry: picklistVals)
		{
			pickVals.add(entry.getLabel());
		}
		Set<String> alreadyExists = new Set<String>();
		List<Course__c> existingAreas = [SELECT Name FROM Course__c WHERE Name IN :pickVals AND RecordTypeId = :subType];
		for (Course__c course: existingAreas)
		{
			alreadyExists.add(course.Name);
		}
		
		List<Course__c> subjectAreas = new List<Course__c>();
		for (Schema.PicklistEntry entry: picklistVals)
		{
			if (alreadyExists.contains(entry.getLabel()))
				continue;
			
			Course__c subj = new Course__c(Name = entry.getValue(), RecordTypeId = subType);
			subjectAreas.add(subj);
		}
		insert subjectAreas;
		subjectAreas.addAll(existingAreas);
		Map<String, Id> subPickToSubIdMap = new Map<String, Id>();
		for (Course__c course: subjectAreas)
		{
			subPickToSubIdMap.put(course.Name, course.Id);
		}
		for (List<Course__c> courses: [SELECT Subject_Area__c, Subject_Area_Lookup__c FROM Course__c WHERE Subject_Area_Lookup__c = null AND RecordTypeId != :subType])
		{
			setupChildCourses(subPickToSubIdMap, courses);
		}
	}
	
	private static void setupChildCourses(Map<String, Id> subPickToSubIdMap, List<Course__c> courses)
	{
		List<Course__c> coursesToUpdate = new List<Course__c>();
		for (Course__c course: courses)
		{
			Id subArea = subPickToSubIdMap.get(course.Subject_Area__c);
			if (subArea == null)
				continue;
			course.Subject_Area_Lookup__c = subArea;
			coursesToUpdate.add(course);
		}
		update coursesToUpdate;
	}
}
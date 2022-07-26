public with sharing class Course_Weightings_Utils {


	/***************** Start of Course Weightings Util methods***********************************/
			
	public static void processBeforeInsert(List <Course_Weightings__c> newList){
	}
	public static void processAfterInsert(Map <Id, Course_Weightings__c> newMap){
		createSectionRps(newMap);
	}
	public static void processBeforeUpdate(Map <Id, Course_Weightings__c> newMap, Map<Id, Course_Weightings__c> oldMap){
	}
	public static void processAfterUpdate(Map <Id, Course_Weightings__c> newMap, Map<Id, Course_Weightings__c> oldMap){
		
	}
	public static void processBeforeDelete(Map <Id, Course_Weightings__c> oldMap){
		createSectionRps(oldMap);
	}  
	
	
	
	public static void createSectionRps(Map <Id, Course_Weightings__c> newMap){
		Set <String> courseWeightingConfigKeySet = new Set <String>();
		Set <Id>		courseIds  = new Set <Id>();
		Set <Id> rpPlValueSet = new Set <Id>();
		Set <Id>	sectionIds = new Set <Id>();
		List <Section__c> sectionList = new List <Section__c>();
		Map <Id, Picklist_Value__c> rpPlValueMap = new Map <Id, Picklist_Value__c>();
		for (Course_Weightings__c cw: newMap.values()){
			rpPlValueSet.add(cw.reporting_period_Type__c);
		}
		for (Picklist_Value__c plv: [select id, corresponding_value__c from Picklist_Value__c where id in:rpPlValueSet]){
			rpPlValueMap.put(plv.id, plv);
		}
		system.debug('rpPlValueMap~~~~'+rpPlValueMap);
		for (Course_Weightings__c cw: newMap.values()){
			courseIds.add(cw.course__c);
			system.debug('cw.reporting_period_type__c~~~'+cw.reporting_period_type__c);
			courseWeightingConfigKeySet.add(cw.course__c+'-'+rpPlValueMap.get(cw.reporting_period_type__c).corresponding_value__c);
		}	
		system.debug('courseWeightingConfigKeySet~~~'+courseWeightingConfigKeySet);
		for (Section__c sect : [select id , course__c, School__c, number_of_reporting_periods__c, Reporting_Period__c,Number_of_Periods__c , Reporting_Period__r.Parent_Time_Element__c,  Section__c.RecordTypeId
													from Section__c 
													where Active__c = true 
											and (RecordType.DeveloperName='Published' or RecordType.DeveloperName='Unpublished')
											and course__c in:courseIds]	){
			string sectionCwKey = sect.course__c+'-'+sect.number_of_reporting_periods__c;
			system.debug('sectionCwKey~~~~'+sectionCwKey);
			if (courseWeightingConfigKeySet.contains(sectionCwKey)){
				sectionList.add(sect);
			}
		}
		
		Section_Utils.reportingPeriodIds = new Set <Id>();
		for (Section__c sect: sectionList) Section_Utils.reportingPeriodIds.add(sect.reporting_period__c);
		
		if (!Section_Utils.reportingPeriodIds.isEmpty()){
			if (section_Utils.termRpMap==null){
				Section_Utils.getTeConfig();
			}
		}
		
		if (!sectionList.isEmpty()){
			Scheduler_TriggerUtils.createSectionRPs(sectionList); 
			
		}
			
	
	}
}
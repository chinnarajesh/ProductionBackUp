public with sharing class core_GradeScaleCatalogController {
	public static List <Picklist_Value__c> getAvailableGrade_Scales(){
    	List <Picklist_Value__c> Grade_ScaleList = core_SoqlUtils.getPlValues('Grade Scale', null).values();
    	return Grade_ScaleList;
    }
}
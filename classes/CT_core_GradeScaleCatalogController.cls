public with sharing class CT_core_GradeScaleCatalogController {
	public static List <Picklist_Value__c> getAvailableGrade_Scales(){
    	List <Picklist_Value__c> Grade_ScaleList = CT_core_SoqlUtils.getPlValues('Grade Scale', null).values();
    	return Grade_ScaleList;
    }
}
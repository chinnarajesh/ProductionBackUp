public with sharing class PicklistRedirectController {
	private string assessmentType;
	public PicklistRedirectController(ApexPages.StandardController stdcon){
		assessmentType = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
	}
	
	public PageReference redirect(){
		PageReference pref;
		
		//get all the page params
		string returnURL = ApexPages.currentPage().getParameters().get('retURL');
		string rType = ApexPages.currentPage().getParameters().get('RecordType');
		string ent = ApexPages.currentPage().getParameters().get('ent');
		string cancelURL = ApexPages.currentPage().getParameters().get('cancelURL');
		string confirmationToken = ApexPages.currentPage().getParameters().get('_CONFIRMATIONTOKEN');
		string saveNewURL = ApexPages.currentPage().getParameters().get('save_new_url');
		string recordid = ApexPages.currentPage().getParameters().get('id');
		
		system.debug(rType);
		system.debug(assessmentType);
		if(recordId != null){
			Picklist_Value__c pv = [select RecordTypeID from Picklist_Value__c where id =: recordID];
			rType = pv.RecordTypeId;
		}
		
		if(rType == assessmentType.substring(0,15) || rType == assessmentType){
			pref=new PageReference('/apex/Assessment_TypeWizard');
			pref.getParameters().put('id', recordID);
			pref.setRedirect(true);
		} else {
			string objectKey = Schema.SObjectType.Picklist_Value__c.getKeyPrefix();
			pref = new PageReference('/' + objectKey + '/e');
			pref.getParameters().put('retURL', returnURL);
			pref.getParameters().put('ent', ent);
			pref.getParameters().put('RecordType', rType);
			pref.getParameters().put('cancelURL', cancelURL);
			pref.getParameters().put('_CONFIRMATIONTOKEN', confirmationToken);
			pref.getParameters().put('save_new_url', saveNewURL);
			pref.getParameters().put('nooverride', '1');
			pref.getParameters().put('id', recordID);
		}
		
		system.debug(pref);
		return pref;
	}
	
	private static testmethod void testRedirect(){
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		id assessmentType = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
		id behaviorType = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Behavior_Type');
		
		PageReference pref = Page.BehaviorIncidentEdit;
        pref.getParameters().put('RecordType', assessmentType);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController stdcon = new ApexPAges.StandardController(new Picklist_Value__c());
        PicklistRedirectController controller = new PicklistRedirectController(stdcon);
        pref = controller.redirect();
        system.assert(pref.getURL() == Page.Assessment_TypeWizard.getURL());
        
        pref = Page.BehaviorIncidentEdit;
        pref.getParameters().put('RecordType', behaviorType);
        Test.setCurrentPage(pref);
        
        stdcon = new ApexPAges.StandardController(new Picklist_Value__c());
        controller = new PicklistRedirectController(stdcon);
        pref = controller.redirect();
        system.assert(pref.getURL() != Page.Assessment_TypeWizard.getURL());
	}
}
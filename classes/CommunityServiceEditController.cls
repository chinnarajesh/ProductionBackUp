public with sharing class CommunityServiceEditController {
	public ApexPages.StandardController	standardController	{get; set;}
	public Community_Service__c			communityService	{get; set;}
	public String 						communityServiceId	{get; set;}
	public String						studentId			{get; set;}
	public String						contactId			{get; set;}
	public Student__c					student				{get; set;}
	
	public CommunityServiceEditController(ApexPages.StandardController standardController) {
		try {
			if (System.currentPageReference().getParameters().containsKey('id')) {
				communityServiceId = System.currentPageReference().getParameters().get('id');
				communityService = [SELECT c.Contact_Email__c, c.Contact_Name__c, c.Contact_Phone__c, c.Contact__c, c.Id, c.Name, c.Organization_Name__c, c.Service_End_Date__c, c.Service_Hours_Completed__c, c.Service_Start_Date__c, c.Student__c, c.Location_of_Service__c FROM Community_Service__c c WHERE c.Id = :communityServiceId];
			} else {
				if (System.currentPageReference().getParameters().containsKey('sId')) {
					studentId = System.currentPageReference().getParameters().get('sId');
					student = [SELECT s.Id, s.Individual__c, s.Individual__r.Name, s.Name FROM Student__c s WHERE s.Id = :studentId];
				} else if (System.currentPageReference().getParameters().containsKey('sContactId')) {
					contactId = System.currentPageReference().getParameters().get('sContactId');
					student = [SELECT s.Id, s.Individual__c, s.Individual__r.Name, s.Name FROM Student__c s WHERE s.Active__c = true AND Individual__c = :contactId];
				}
				if (communityService == null) {
					communityService = new Community_Service__c(Student__c = student.Id, Contact__c = student.Individual__c);
				}
			}
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred during initialization.'));
		}
	}

	public pageReference saveCommunityService(){
		upsert communityService;
		return getRedirectPage();
	}

	public pageReference saveNewCommunityService(){
		upsert communityService;
		communityService = communityService.clone(false, false, false, false);
		return System.currentPageReference();
	}

	public pageReference cancelCommunityService(){
		return getRedirectPage();
	}

	public pageReference getRedirectPage(){
		PageReference redirectPage;

		if (communityServiceId != null) {
			redirectPage = new PageReference('/' + communityServiceId);
		} else if (studentId != null) {
			redirectPage = new PageReference('/' + studentId); 
		} else if (contactId != null) {
			redirectPage = new PageReference('/' + contactId);
		}

		redirectPage.setRedirect(true);
		return redirectPage;
	}
}
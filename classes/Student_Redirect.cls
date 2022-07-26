public with sharing class Student_Redirect {
	public ApexPages.StandardController 			controller 				{get; set;}
	public Id																	studentId				{get;set;}
	public Link_Settings__c linkSetting {get;set;}  
	
	public Student_Redirect(ApexPages.StandardController controller){
		if (System.currentPageReference().getParameters().containsKey('id')!=null) studentId = System.currentPageReference().getParameters().get('id');
		if 			(Link_Settings__c.getInstance(UserInfo.getProfileId())!=null)	linkSetting=Link_Settings__c.getInstance(UserInfo.getProfileId());
		else	if	(Link_Settings__c.getOrgDefaults()!=null) 								linkSetting=Link_Settings__c.getOrgDefaults();
		else {
			linkSetting = new Link_Settings__c(); 
		}
	}
	
}
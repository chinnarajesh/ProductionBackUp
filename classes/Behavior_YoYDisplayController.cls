public with sharing class Behavior_YoYDisplayController {
	public List<Student_Behavior__c> sbList	{get;set;}
	public string selectedIncident			{get;set;}
	public string redirectString			{get;set;}
	
	public Behavior_YoYDisplayController(ApexPages.StandardController stdCon){
		Contact student = (Contact) stdCon.getRecord();
		sbList = Behavior_SOQLUtils.getStudentBehaviorListByContact(student.id);
		if(sbList.size()>1000){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The selected student has more then 1000 archived incidents. Some of the incidents cannot be displayed. Please use a report to view all incidents.'));
		}
	}
	
	public void viewSingle(){
		redirectString = Page.BehaviorIncidentDetail.getURL() + '?id='+selectedIncident;
	}
}
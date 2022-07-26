public with sharing class CommunityServiceWizardController {

	public Boolean					showError				{get; set;}
	public Boolean 					showSearchResults 		{get; set;}
	public Boolean					showCommunityService	{get; set;}
	public Community_Service__c		communityService		{get; set;}
	public List<studentWrapper>  	searchResultsList		{get; set;}
	public List<studentWrapper>  	addedStudentList		{get; set;}
	public Set<Id>					addedStudentIdList		{get; set;}
	public Student_SearchStudent   	searchStudent 			{get; set;}

	public CommunityServiceWizardController() {
		initialize();
		clear();
	}
	
	public void initialize() {
		communityService = new Community_Service__c();
		searchResultsList = new List<studentWrapper>();
		addedStudentList = new List<studentWrapper>();
		addedStudentIdList = new Set<Id>();
		searchStudent = new Student_SearchStudent();		
	}
	
	public void clear() {
		searchResultsList.clear();
		addedStudentList.clear();
		showError = false;
		showSearchResults = false;
		showCommunityService = false;
	}
	
	public void searchStudents() {
		
		searchResultsList = new List<studentWrapper>();
		searchStudent.mainQuery += ' AND School__r.RecordType.Name = \'School\'';
		searchStudent.searchStudents();
		
		for (Student__c student : searchStudent.studResults) {
			if (!addedStudentIdList.contains(student.Id)) {
				searchResultsList.add(new studentWrapper(student));
			}
		}
		
		if (searchResultsList.isEmpty() && addedStudentList.isEmpty()) {
			
			showSearchResults = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Sorry! No student in the system matches your search criteria.'));
			clear();
		
		} else {
			showSearchResults = true;
		}
			 
	}
	
	public void addStudents() {
		
		for (studentWrapper wrapper : searchResultsList) {
			
			if (wrapper.add) {
				wrapper.add = false;
				addedStudentList.add(wrapper);
				addedStudentIdList.add(wrapper.student.Id);
			}	
		
		}
		
		searchStudents();
	
	}
	
	public void removeStudents() {
		
		List<studentWrapper> tempStudentWrapperList = new List<studentWrapper>();
		
		addedStudentIdList.clear();
		
		for (studentWrapper wrapper : addedStudentList) {
			
			if (wrapper.add) {
				wrapper.add = false;
				searchResultsList.add(wrapper);
			} else {
				tempStudentWrapperList.add(wrapper);
				addedStudentIdList.add(wrapper.student.Id);
			}
		
		}
		
		addedStudentList = tempStudentWrapperList;
		
	}
	
	public void addCommunityService() {
		showCommunityService = true;
	}
	
	public void saveCommunityService(){
		
		List<Community_Service__c> cloneCommunityServiceList = new List<Community_Service__c>();
		
		for (studentWrapper wrapper : addedStudentList) {
			Community_Service__c cloneCommunityService = communityService.clone();
			cloneCommunityService.Student__c = wrapper.student.Id;
			cloneCommunityService.Contact__c = wrapper.student.Individual__c;
			cloneCommunityServiceList.add(cloneCommunityService);
		}
		
		try {
			upsert cloneCommunityServiceList;
		} catch (Exception e) {
			showError = true;
		}
		
		if (!showError) {
			ApexPages.addMessage(new apexpages.message(apexpages.severity.confirm, 'Community service hours added for ' + cloneCommunityServiceList.size() + ' student(s)!'));
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,  'An error has occurred. Please contact your administrator.'));
		}
		
		clear();
	
	}
	
	public class studentWrapper {
		
		public Boolean 		add			{get; set;}
		public Student__c 	student		{get; set;}
		
		public studentWrapper(Student__c student) {
			this.add = false;
			this.student = student;
		}
	
	}

}
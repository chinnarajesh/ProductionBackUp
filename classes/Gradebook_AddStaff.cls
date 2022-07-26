public with sharing class Gradebook_AddStaff {

	public List<SelectWrapper> options1 	{get;set;}
	public List<SelectWrapper> options2 	{get;set;}

	public Gradebook_AddStaff(){
		options1 = new List<SelectWrapper>();//staff
		options2 = new List<SelectWrapper>();//sections
		for(Staff__c s : [Select ID, Organization__c, Organization__r.name, Name from Staff__c order by Organization__r.Name, Staff_Last_Name__c]){
			SelectWrapper isw = new SelectWrapper();
			isw.name=s.Name;
			isw.selected = false;
			isw.data1 = s.Organization__r.name;
			isw.data2 = s.Organization__c;
			isw.id = s.id;
			options1.add(isw);	
		}
		
		options2 = new List<SelectWrapper>();//staff list
		for(Section__c s : [Select ID, Name, School__c, Course__r.Name, School__r.Name from Section__c where Active__c = true and (RecordType.DeveloperName='Published' or RecordType.DeveloperName='Scheduled_Group') order by School__r.Name, Course__r.Name]){
			SelectWrapper isw = new SelectWrapper();
			string temp;
			if(s.School__c ==null)temp='';
			else temp=s.School__r.Name;
			isw.data1 = s.School__r.Name;				
			isw.name=s.Name;
			isw.selected = false;
			isw.id = s.id;
			options2.add(isw);
		}
	}

	public void addStaff(){
		list<Staff_Section__c> toInsert = new List<Staff_Section__c>();
		set<string> existingStaffSections = new set<String>();
		set<id> sectionsToAdd = new Set<ID>();
		set<ID> staffToAdd	  = new Set<ID>();
		boolean atLeastOneSelected = false;
		for(SelectWrapper sw : options1){
			if(sw.selected){
				staffToAdd.add(sw.id);
				sw.selected = false;
			}
		}
		for(SelectWrapper sw: options2){
			if(sw.selected){
				sectionsToAdd.add(sw.id);
				sw.selected = false;
			}
		}
		//check the existing staff sections
		for(Staff_Section__c ss : [Select ID, Staff__c, Section__c from Staff_Section__c where Staff__c IN : staffToAdd AND Section__c IN: sectionsToAdd]){
			existingStaffSections.add(string.valueOf(ss.Staff__c) + string.valueOf(ss.Section__c));
		}
		for(string staff : staffToAdd){
			for(String section : sectionsToAdd){
				if(!existingStaffSections.contains(staff+section)){
					//no dupes plz
					toInsert.add(new Staff_Section__c(Is_Active__c = true, Staff__c = staff, Section__c=section));
				}
			}
		}
		system.debug(toInsert);
		insert toInsert;
		
	}
		
		public class SelectWrapper{
		public string selectAllClass			{get;set;}//jquery class helper for select all functionality
		public string id						{get;set;}//id for the data
		public boolean selected					{get;set;}//checkbox for selecting
		public boolean flag						{get;set;}
		public string data1						{get;set;}
		public string data2						{get;set;}
		public string data3						{get;set;}
		public string data4						{get;set;}
		public List<List<String>> tableData		{get;set;}//dynamic list of strings for columns
		public string Name						{get;set;}
		
		public SelectWrapper(){
			selected = false;
			tableData = new List<List<String>>();//dynamic list of strings for columns
		}
	}
	
	static testMethod void testAddStaff(){
		 testDataSetupUtil_v2.setUpCoreData(5);
         testDataSetupUtil_v2.setUpStaffData(5);
         testDataSetupUtil_v2.setUpStudentData(5);
        
        Test.startTest();
        Gradebook_AddStaff controller = new Gradebook_AddStaff();
        for(selectWrapper sw : controller.options1){
        	sw.selected = true;
        }
        for(selectWrapper sw : controller.options2){
        	sw.selected = true;
        }
        controller.addStaff();
	}
}
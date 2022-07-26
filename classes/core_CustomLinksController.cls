public with sharing class core_CustomLinksController {

	public Link_Settings__c linkSetting {get;set;}  
	public List <linkListWrapper> linkList {get;set;}

	public static boolean checkAcademics(Link_Settings__c ls){
		return (ls.Overall_Comments__c||ls.Assessment_Wizard__c||ls.Run_Report_Cards__c||ls.complete_sections__c);
	}

	public static boolean checkAdvancedReports(Link_Settings__c ls){
		return (ls.advanced_reports__c);
	}

	public static boolean checkPoints(Link_Settings__c ls){
		return (ls.Points_Matrix__c);
	}

	public static boolean checkFrontOffice(Link_Settings__c ls){
		return	ls.Attendance_Wizard__c||ls.Section_Wizard__c||ls.Cohort_Wizard__c||ls.Transfer_Wizard__c||ls.Community_Service_Wizard__c||ls.Print_Schedule__c||ls.ProActive_Processor__c;
	}


	public static boolean checkSysAdmin(Link_Settings__c ls){
		return (ls.Year_Close_Wizard__c);
	}

	public static boolean checkSchoolForceCommunity(Link_Settings__c ls){
		return ls.Communities_SSO__c&&ls.Communities_SSO_URL__c!=null;
	}

	public core_CustomLinksController(){ 
		if 			(Link_Settings__c.getInstance(UserInfo.getProfileId())!=null)	linkSetting=Link_Settings__c.getInstance(UserInfo.getProfileId());
		else	if	(Link_Settings__c.getOrgDefaults()!=null) 								linkSetting=Link_Settings__c.getOrgDefaults();
		else {
			linkSetting = new Link_Settings__c(); 
		}
		linkList = new List <linkListWrapper>();
		
		if (checkAcademics(linkSetting)){
				linkListWrapper llw = new linkListWrapper('Academics');
				if (linkSetting.Overall_Comments__c) llw.lwList.add(new linkWrapper('overall_comments', 'Overall Comments'));
				if (linkSetting.Assessment_Wizard__c) llw.lwList.add(new linkWrapper('AssessmentWizard', 'Assessment Wizard'));
				if (linkSetting.Run_Report_Cards__c) llw.lwList.add(new linkWrapper('gradebook_runreportCards', 'Generate Documents'));
				if (linkSetting.Complete_sections__c) llw.lwList.add(new linkWrapper('gradebook_completeSections', 'Mark Sections Completed'));
			linkList.add(llw);
		}
		if (checkAdvancedReports(linkSetting)){
			linkListWrapper llw = new linkListWrapper('Gradebook Advanced Reports');
			if (linkSetting.Advanced_Reports__c) llw.lwList.add(new linkWrapper('Advanced_Reports', 'View Gradebook Advanced Reports'));
			linkList.add(llw);
		}
		if (checkPoints(linkSetting)){
			linkListWrapper llw = new linkListWrapper('Points');
			if (linkSetting.Points_Matrix__c) llw.lwList.add(new linkWrapper('Points_Matrix', 'Points Module'));
			linkList.add(llw);
		}
		if (checkFrontOffice(linkSetting)){
			linkListWrapper llw = new linkListWrapper('Front Office');
			if (linkSetting.Attendance_Wizard__c) llw.lwList.add(new linkWrapper('AttendanceWizard_v2', 'Attendance Wizard'));
			if (linkSetting.Section_Wizard__c) llw.lwList.add(new linkWrapper('Scheduler_SectionWizard', 'Section Wizard'));
			if (linkSetting.Cohort_Wizard__c) llw.lwList.add(new linkWrapper('Cohort_SetupWizard', 'Cohort Wizard'));
			if (linkSetting.Transfer_Wizard__c) llw.lwList.add(new linkWrapper('Transfer_CourseWizard', 'Transfer Wizard'));
			if (linkSetting.Community_Service_Wizard__c) llw.lwList.add(new linkWrapper('CommunityServiceWizard', 'Community Service Wizard'));
			if (linkSetting.Print_Schedule__c) llw.lwList.add(new linkWrapper('printSchedule', 'Email/Print Schedule'));
			if (linkSetting.ProActive_Processor__c) llw.lwList.add(new linkWrapper('proActiveVF', 'ProActive Processor'));
			linkList.add(llw);
		}
		if(checkSchoolForceCommunity(linkSetting)){
			linkListWrapper llw = new linkListWrapper('SchoolForce Community');
			if (linkSetting.Communities_SSO__c) llw.lwList.add(new linkWrapper(linkSetting.Communities_SSO_URL__c,'SchoolForce Community',true));
			linkList.add(llw);
		}
		if (checkSysAdmin(linkSetting)){
			linkListWrapper llw = new linkListWrapper('System Admin');
			//if (linkSetting.Year_Close_Wizard__c) llw.lwList.add(new linkWrapper('EOY_SchoolCloseout', 'Year Close Wizard'));
			if (linkSetting.Csv_Loader__c) llw.lwList.add(new linkWrapper('core_LoadCsvData_v2', 'CSV Loader'));
			linkList.add(llw);
		}
		

	}

	public class linkListWrapper{
		public List <linkWrapper> lwList {get;set;}
		public string sLabel {get;set;}
		public linkListWrapper(string sName){
			this.sLabel= sName;
			this.lwList = new List <linkWrapper>();
		}
		
	}

	public class linkWrapper{
		
		public pageReference redirect {get;set;}
		public string				label		{get;set;}
		
		public linkWrapper(string sLink, string sName){
			this.redirect = dummyReturn(sLink);
			this.label 		= sName;
		}
		
		public linkWrapper(string sLink, string sLabelName, boolean staticURL){
			this.redirect = new PageReference(sLink);
			this.label = sLabelName;
		}
	}
	 
	public static pageReference dummyReturn(string pageName){
		boolean isManagedPackage = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
		PageReference pr = new PageReference( '/apex/'+ ((isManagedPackage)?'SchoolForce__':'')+pageName);
			
		pr.setRedirect (true); 
		return pr;
	}
}
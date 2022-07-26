public with sharing class Gradebook_RunReportCardsWrapper {

	public class schoolWrapper{
		public String displayName					{get;set;}
		public Setup__c setup						{get;set;}
		public boolean selected						{get;set;}
		public List<SelectOption> reportingPeriods	{get;set;}
		public string selectedReportingPeriod		{get;set;}
		public string selectedDocument				{get;set;}
		public string selectedTime					{get;set;}
		public string startDate						{get;set;}
		public string endDate						{get;set;}
		public List<SelectOption> allowedDocuments	{get;set;}
		public ID recordID							{get;set;}
		public Student__c searchOptionWrapper		{get;set;}
		public Staff__c staffOptionWrapper			{get;set;}
		public ID SchoolId;
		public boolean bTimeFilter = false;
		//DE3640
		public Boolean bOfficialTranscript			{get;set;}
		
		public List<sectionWrapper> sections		{get;set;}

		public schoolWrapper(Setup__c s, boolean checkDocuments, List<Time_Element__c> rps){
			this.setup = s;
			this.schoolID = s.School__c;
			this.selected = false;
			this.recordID = s.id;
			this.displayName = s.School__r.Name + ' (' + s.Term__r.Name__c + ')';
			//DE3640
			this.bOfficialTranscript = true;
			
			this.searchOptionWrapper = new Student__c(Setup__r = this.setup);
			this.staffOptionWrapper = new Staff__c(Organization__c = this.schoolID);

			selectedReportingPeriod = null;
			this.reportingPeriods = new List<selectOption>();
			for(Time_Element__c rp:rps){
				if(selectedReportingPeriod == null){
					selectedReportingPeriod = rp.id;
					startDate = rp.Date_Start_Date__c.format();
					endDate = rp.End_Date__c.format();
				}
				this.reportingPeriods.add(new selectOption(rp.id,rp.Name__c));
			}
			
			//setup available documents list
			if(checkDocuments){
				this.allowedDocuments = new List<selectOption>();
				for(String docType:s.Evaluation_Documents__c.split(';')){
					this.allowedDocuments.add(new SelectOption(docType,docType));
				}
			}
			//if no documents option, user selected schedule creation
			else {
				this.selectedDocument = 'Schedule';
			}
		}

		public void loadSections(){
			if(sections == null || bTimeFilter){
				sections = new List<sectionWrapper>();
				String query = 'SELECT ID, School__r.Name, Name, Grade_Level__c, All_Grades__c, Section__r.Course__c';
				query += (bTimeFilter)?',(Select id, time__r.name__c, completed__c'+
									' from Section_ReportingPeriod__r'+
									' WHERE Time__c =: selectedReportingPeriod'+
									' and RecordType.DeveloperName = \'Published\' limit 1 )':'';
				query+= ' FROM Section__c'+
						' WHERE Active__c = true'+
						' AND School__c = \''+this.setup.School__c+'\''+
						' AND RecordType.DeveloperName = \'Published\'';

				for(Section__c s:Database.query(query)){
					if(!bTimeFilter || (s.section_reportingPeriod__r!=null && s.section_reportingPeriod__r.size()>0))
						sections.add(new sectionWrapper(s));
				}
			}
		}
	}

	public class sectionWrapper{
		public boolean selected					{get;set;}
		public Section__c section				{get;set;}
		public Section_ReportingPeriod__c srp	{get;set;}

		public sectionWrapper(Section__c s){
			this.section = s;
			this.selected = true;
			if (s.section_reportingPeriod__r!=null && !s.Section_ReportingPeriod__r.isEmpty())
				srp = s.section_reportingPeriod__r[0];
		}
	}

	public class personWrapper{
		public boolean selected		{get;set;}
		public ID attachmentID		{get;set;}
		public Student__c student	{get;set;}
		public Staff__c staff		{get;set;}
		public Document_Log__c log	{get;set;}
		public Student_Reporting_Period__c srp {get;set;}

		public personWrapper(Student__c s){
			this.student = s;
			this.selected = false;
		}
		
		public personWrapper(Staff__c s){
			this.staff = s;
			this.selected = false;
		}
	}

	@isTest static void testWrapper(){
		TestDataSetupUtil_v2.setupCoreData(5);
		TestDataSetupUtil_v2.setupStaffData(5); //sections
		TestDataSetupUtil_v2.setupStudentData(5);

		Test.startTest();
			Gradebook_RunReportCardsWrapper.schoolWrapper school = new Gradebook_RunReportCardsWrapper.schoolWrapper(Gradebook_ReportCard_Utils.getDocumentSchools(false)[0], true,Gradebook_ReportCard_Utils.getReportingPeriods(TestDataSetupUtil_v2.activeSetup.Term__c));
			school.loadSections();
			System.assertEquals(false, school.sections.isEmpty());
			Gradebook_RunReportCardsWrapper.personWrapper student = new Gradebook_RunReportCardsWrapper.personWrapper(TestDataSetupUtil_v2.studentsList[0]);
			System.assertNotEquals(null, student.student);
		Test.stopTest();
	}
}
public with sharing class Student_SectionLocator{
	public ApexPages.StandardController controller				{get;set;}
	public List <cSessionWrapper>	selectedSessions			{get;set;}
	public transient List<Student_Section__c> studentSections	{get;set;}
	public Id studentId			{get;set;}
	public Student__c student	{get;set;}
	public boolean	bInClass	{get;set;}
	
	public Student_SectionLocator(ApexPages.StandardController controller){
		if (System.currentPageReference().getParameters().containsKey('id')!=null)
			studentId = System.currentPageReference().getParameters().get('id');

		student = core_SoqlUtils.getStudentById(studentId)[0]; 
		selectedSessions = new List <cSessionWrapper>();
		Set <Id> sectionIDs = new Set <Id>();
		for (Student_Section__c ss:
				[select section__c, section__r.active__c from Student_Section__c 
				where student__c =:student.id
				and active__c =:true
				and	section__r.active__c=:true]){
			sectionIDs.add(ss.section__c);
		}
		try { 
			for (Session__c sess :
					[select id, name , Start_DateTime__c, end_datetime__c, section__c, section__r.name, section__r.room__r.number__c
					from Session__c 
					where section__c in:sectionIds
					and start_Datetime__c < :system.now()
					and end_datetime__c >: system.now() 
					and section__r.daily_attendance__c = false]){
				selectedSessions.add(new cSessionWrapper(sess));
				bInClass = true;
			}
		}
		catch (exception e){
			bInClass= false;
		}
	}
	
	public class cSessionWrapper{
		public Session__c sess		{get;set;}
		public string sessStartTime	{get;set;}
		public string sessEndTime	{get;set;}
		public cSessionWrapper(Session__c session){
			sess = session;
			sessStartTime = session.Start_DateTime__c.format('h:mm a');
			sessEndTime = session.end_datetime__c.format('h:mm a');
		}
	}
	
	public static testMethod void test_Student_SectionLocator(){
		core_triggerUtils.studentTriggerUpdate(false); 
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);

		test.setCurrentPage(Page.Student_SectionLocator);
		ApexPages.currentPage().getParameters().put('id', testDataSetupUtil_v2.studentsList[1].id);
		
		Test.startTest();
			ApexPages.StandardController con = new ApexPages.StandardController(testDataSetupUtil_v2.studentsList[1]);
			Student_SectionLocator s = new Student_SectionLocator(con);
		test.stopTest();
	}
}
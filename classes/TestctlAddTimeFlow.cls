/**
  Due to the complexity of the data model, it is very difficult to set up all test data within the test itself.
	Therefore, this unit test, hence the deployment of this change set, depends on test data being set up before deployment.
  Test data includes:
	1. Test user, with an Alias 'AdamV'
	2. Test staff, pointing to the user.
	3. Test sections (3), assigned to the test staff
	4. Test students, assigned to the section
	5. Each test section needs to have at least a student assigned.
*/
@isTest
public class TestctlAddTimeFlow {
	public static Account individualsAccount;
	public static User u;
	public static Contact c;

	public static void createCommunityUser(){
		ID indivudalsRTID = CYUtil.getRecordTypeID('Individuals');
		individualsAccount = new Account(Name = 'Individuals', RecordTypeID = indivudalsRTID);
		insert individualsAccount;

		ID corpsCommunityProfileID = [select id from Profile where Name = 'Corps Members Community - Customer License'][0].ID;
		ID staffContactRTID = CYUtil.getRecordTypeID('Staff');

		c = new Contact(
			RecordTypeID = staffContactRTID,
			FirstName = 'Test',
			LastName = 'Staff',
			Reference_ID__c = '12345',
			Active__c = true,
			AccountID = individualsAccount.ID
		);
		insert c;

		u = new User(
			ContactID = c.ID,
			FirstName = 'Test',
			LastName = 'Staff',
			Alias = 'tstaff',
			Username = 'tstaff@test.com',
			Email = 'tstaff@test.com',
			CommunityNickname = 'tstaff',
			TimeZoneSidKey='America/New_York',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8' ,
			ProfileId = corpsCommunityProfileID,
			LanguageLocaleKey='en_US',
			Site__c = 'Washington, DC',
			IsActive = true
		);
		insert u;
	}

	public static testMethod void testPositiveMyController() {
		List<Section__c> mysections;
		PageReference pageRefSection = Page.pageSectionList;
		Test.setCurrentPage(pageRefSection);

		Skill__c skill = new Skill__c();
		skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
		skill.Category__c = 'SEL/Behavior and Attendance Interventions';
		insert skill;

		TestDataUtil.setupSharingControls();
		TestDataUtil.setupData(1);
		List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
		List<Program__c> programs = TestDataUtil.createPrograms(1,true,ia[0]);
		programs.addAll(TestDataUtil.createPrograms(1,true,ia[1]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[2]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[3]));
		insert programs;
		Account_Program__c accProg = TestDataUtil.createAccountProgram(TestDataUtil.schoolList[0], programs[0]);
		insert accProg;
		TestDataUtil.createIAStudents(TestDataUtil.testDataMap.values()[0].students, ia[0].Id);

		createCommunityUser();
		c.User__c = u.ID;
		update c;

		Staff__c staff = TestDataUtil.createStaff(c,TestDataUtil.schoolList[0],1);
		insert staff;
		Section__c section = TestDataUtil.createSection(TestDataUtil.schoolList[0], accProg, TestDataUtil.testDataMap.values()[0].students, staff, programs[0]);

		Test.startTest();
		System.RunAs(u){
			ctlAddTimeFlow controller = new ctlAddTimeFlow();
			mysections = controller.getSecList();
			system.assertEquals(1,mysections.size());
			controller.getPageNumber();
			controller.getTotal_size();
			controller.getTotalPages();
			controller.getprev();
			controller.getnxt();
			controller.Beginning();
			controller.Previous();
			controller.Next();
			controller.End();

			System.debug('Mysection 1:' + mysections[0].Id + mysections[0].Name);
			controller.sectionID=mysections[0].Id;
			PageReference pageRefSectionStudents = controller.doSectionStudents();
			List<ctlAddTimeFlow.StudentWrapper> mystudents = new List<ctlAddTimeFlow.StudentWrapper>();

			PageReference pageRefSectionStudentsCancel = controller.doStudentsCancel();
			System.assertEquals('/apex/pagesectionlist', pageRefSectionStudentsCancel.getURL());

			controller.studentsInSection.get(0).selected = true;
			mystudents = controller.studentsInSection;
			Decimal val = mystudents[0].stuSecRec.Dosage_to_Date__c;
			System.assertEquals('/apex/pagesectionstudents', pageRefSectionStudents.getURL());
			System.debug('Student Name 1:' + mystudents[0].selected + mystudents[0].stuSecRec.Student_Name__c);
			PageReference pageRefAddTime = controller.doStudentsAddTime();
			System.assertEquals('/apex/pageaddtime', pageRefAddTime.getURL());

			controller.currentSession.Date__c = Date.today();
			controller.currentSession.Section__c = mysections[0].Id;
			controller.currentSession.All_avenues__c = 'In-Person Service';
			controller.sessionDosage = 10;

			PageReference pageRefAddStudent = controller.doAddStudentToSession();
			System.assertEquals('/apex/pagesectionstudents', pageRefAddStudent.getURL());

			pageRefAddTime = controller.doStudentsAddTime();
			System.assertEquals('/apex/pageaddtime', pageRefAddTime.getURL());

			controller.selectedFields.addAll(controller.avaliableFields);
			for(Intervention_Session_Result__c isr:controller.studentsInSession){
				isr.Amount_of_Time__c = 10;
			}

			PageReference pageRefSectionStudents1 = controller.doSessionSubmit();
			//System.assertEquals('/apex/pageaddtime', pageRefSectionStudents1.getURL());
		  //  System.assertEquals(val + 10,mystudents[0].stuSecRec.Dosage_to_Date__c);


			PageReference pageRefAddStudentToSession = controller.doAddStudentToSession();
			System.assertEquals('/apex/pagesectionstudents', pageRefAddStudentToSession.getURL());


			PageReference pageSessionList = controller.doShowSessions();
			System.assertEquals('/apex/pagesessionlist', pageSessionList.getURL());

			PageReference pageSessionListCancel = controller.doSessionListCancel();
			System.assertEquals('/apex/pagesectionstudents', pageSessionListCancel.getURL());

			PageReference pageSessionCancel = controller.doSessionCancel();
			System.assertEquals('/apex/pagesectionstudents', pageSessionCancel.getURL());

			controller.getPageNumber();
			controller.getTotal_size();
			controller.getTotalPages();
			controller.getprev();
			controller.getnxt();
			controller.Next();
			controller.End();
			controller.Previous();
			controller.Beginning();
			
			/*
			List<SessionList> mysessions;
			mysessions=controller.getSessionList();
			system.assertEquals(1, mysessions.size());
			controller.updateSessionID=mysessions[0].Id;

			PageReference pageRefAddTime1 = controller.doUpdateSession();
			System.assertEquals('/apex/pageaddtime', pageRefAddTime1.getURL());

			controller.sessionDosage = 20;

			PageReference pageRefSectionStudents2 = controller.doSessionSubmit();
			System.assertEquals('/apex/pagesectionstudents', pageRefSectionStudents2.getURL());
			*/
		}//System.RunAs
		Test.stopTest();
	}

	static testMethod void testNegativeMyController() {
		List<Section__c> mysections;
		PageReference pageRefSection = Page.pageSectionList;
		Test.setCurrentPage(pageRefSection);

		Skill__c skill = new Skill__c();
		skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
		skill.Category__c = 'SEL/Behavior and Attendance Interventions';
		insert skill;

		TestDataUtil.setupSharingControls();
		TestDataUtil.setupData(1);
		List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
		List<Program__c> programs = TestDataUtil.createPrograms(1,true,ia[0]);
		programs.addAll(TestDataUtil.createPrograms(1,true,ia[1]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[2]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[3]));
		insert programs;
		Account_Program__c accProg = TestDataUtil.createAccountProgram(TestDataUtil.schoolList[0], programs[0]);
		insert accProg;
		TestDataUtil.createIAStudents(TestDataUtil.testDataMap.values()[0].students, ia[0].Id);

		createCommunityUser();
		c.User__c = u.ID;
		update c;

		Staff__c staff = TestDataUtil.createStaff(c,TestDataUtil.schoolList[0],1);
		insert staff;
		Section__c section = TestDataUtil.createSection(TestDataUtil.schoolList[0], accProg, TestDataUtil.testDataMap.values()[0].students, staff, programs[0]);

		Test.startTest();

		System.RunAs(u){
		ctlAddTimeFlow controller = new ctlAddTimeFlow();
		mysections = controller.getSecList();
		controller.getPageNumber();
		controller.getTotal_size();
		controller.getTotalPages();
		controller.getprev();
		controller.getnxt();
		controller.Beginning();
		controller.Previous();
		controller.Next();
		controller.End();

		System.debug('Mysection 1:' + mysections[0].Id + mysections[0].Name);
		controller.sectionID=mysections[0].Id;
		PageReference pageRefSectionStudents = controller.doSectionStudents();
		List<ctlAddTimeFlow.StudentWrapper> mystudents = new List<ctlAddTimeFlow.StudentWrapper>();

		PageReference pageRefSectionStudentsCancel = controller.doStudentsCancel();
		System.assertEquals('/apex/pagesectionlist', pageRefSectionStudentsCancel.getURL());

		//Negative Test Case
		controller.studentsInSection.get(0).selected = true;
		mystudents = controller.studentsInSection;

		PageReference pageRefAddTime = controller.doStudentsAddTime();
		controller.currentSession.Date__c = Date.Today().addDays(1);
		controller.currentSession.Section__c = mysections[0].Id ;
		controller.sessionDosage = 10;
		try{
		  PageReference pageRefSectionStudents1 = controller.doSessionSubmit();
		}catch (DmlException e) {
		  System.assert( e.getMessage().contains('Date should be within current Fiscal Year'),e.getMessage());

		}
	 }
	 Test.stopTest();
	}

	public static testMethod void testIDConversion(){
		String shortID = '005c0000001ASda';
		String longID= '005c0000001ASdaAAG';

		System.assertEquals(shortID, ctlAddTimeFlow.convert18To15ID(longID));
		System.assertEquals(longID, ctlAddTimeFlow.convert15To18ID(shortID));
	}
}
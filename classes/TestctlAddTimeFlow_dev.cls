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
public class TestctlAddTimeFlow_dev {
	public static User u;
	public static Contact c;
	private static Skill__c skill;

	@testSetup
	public static void setupData(){
		UserRole portalRole = [
                SELECT Id
                FROM UserRole
                WHERE PortalType = 'None'
                LIMIT 1];		
  		User su = new User(Id = UserInfo.getUserId(), UserRoleId = portalRole.Id);
  		update su;

  		System.runAs(su){
			List<Skill__c> skills = new List<Skill__c>{
				new Skill__c(Name = 'Self-Awareness: Identifying strengths and weaknesses', Category__c = 'SEL/Behavior and Attendance Interventions'),
				new Skill__c(Name = 'Decisiom Making', Category__c = 'SEL/Behavior and Attendance Interventions', IsPrimary__c = true)
			};
			insert skills;
  
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

		    // Inserting test school account.
		    List<Account> theSchoolAccount = TestDataUtil.createSchools(1);

		    // Inserting test student records.
		    List<Student__c> theTestStudents = TestDataUtil.createStudents(5, theSchoolAccount.get(0));
		    insert theTestStudents;

  		}    
	}

	public static void createCommunityUser(){
		ID indivudalsRTID = CYUtil.getRecordTypeID('Individuals');
		Account individualsAccount = new Account(Name = 'Individuals', RecordTypeID = indivudalsRTID);
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
		Test.setCurrentPage(Page.CY_AddWeeklyTime);

		Test.startTest();

		Section__c section = [SELECT Id, Intervention_Primary_Staff__c FROM Section__c];

	    // Inserting test student records.
	    List<Student__c> theTestStudents = [SELECT Id FROM Student__c];

		List<Student_Section__c> theTestStudentSections = [SELECT Id FROM Student_Section__c];    

		// Inserting test intervention session records.
		List<Intervention_Session__c> theTestInterventionSessions = new List<Intervention_Session__c>();
		for(Integer index = 0;index < 5;index++) {
		  theTestInterventionSessions.add(TestDataUtil.createInterventionSession(
		    section.Id,
		    null,
		    section.Intervention_Primary_Staff__c
		  ));
		}
		insert theTestInterventionSessions;

		// Inserting test intervention session result records.
		List<Intervention_Session_Result__c> theTestInterventionSessionResults = new List<Intervention_Session_Result__c>();
		for(Integer index = 0;index < 5;index++) {
		  theTestInterventionSessionResults.add(new Intervention_Session_Result__c(
		    Intervention_Session__c = theTestInterventionSessions.get(index).Id,
		    Student_Section__c = theTestStudentSections.get(index).Id,
		    Amount_of_Time__c = 10,
		    Individual_Student_Comment__c = 'Testing'
		  ));
		}
		insert theTestInterventionSessionResults;

		u = [SELECT Id FROM User WHERE Username = 'tstaff@test.com'];

		System.RunAs(u) {
			ctlAddTimeFlow_dev controller = new ctlAddTimeFlow_dev();

			controller.reportID = null;
			mysections = controller.getSecList();
			system.assertEquals(1, mysections.size());

			controller.getPageNumber();
			controller.getTotal_size();
			controller.getTotalPages();
			controller.getprev();
			controller.getnxt();
			controller.Beginning();
			controller.Previous();
			controller.Next();
			controller.End();
			controller.getCurrentStaff();
			controller.dogetstdata();

			System.debug('Mysection 1: ' + mysections[0].Id + mysections[0].Name);
			controller.sectionID = mysections[0].Id;
			controller.getSessionList();
			////////
			controller.changeSection();
			controller.resultsData[0].dosages[0].isr.Amount_Of_Time__c = 5;
			//controller.tableHeaders[0].primarySkill = skill.Id;
			//controller.tableHeaders[0].selectedSkills = 'Self-Awareness: Identifying strengths and weaknesses';
			controller.tableHeaders[0].isProceed=true;
			controller.tableHeaders[0].session.All_avenues__c = 'In-Person Service';
			//controller.selectedFields.add(new SelectOption('Self-Awareness: Identifying strengths and weaknesses','Self-Awareness: Identifying strengths and weaknesses'));

			controller.saveNewSessions();
			//controller.toggleSortDirection();
			controller.weekEndHolder.Date__c = system.today().addDays(-7);
			controller.changeWeek();
			System.assertEquals(system.today().addDays(-7).toStartOfWeek(), controller.currentWeek);
			controller.lastWeek();
			System.assertEquals(system.today().addDays(-14).toStartOfWeek(), controller.currentWeek);
			controller.nextWeek();
			System.assertEquals(system.today().addDays(-7).toStartOfWeek(), controller.currentWeek);
			////////

			PageReference pageRefSectionStudents = controller.doSectionStudents();
			List<ctlAddTimeFlow_dev.StudentWrapper> mystudents = new List<ctlAddTimeFlow_dev.StudentWrapper>();

			PageReference pageRefSectionStudentsCancel = controller.doStudentsCancel();
			System.assertEquals('/apex/cy_sections', pageRefSectionStudentsCancel.getURL());
			/////
            Pagereference pagecancelReport = controller.gototheReportchart();

			controller.studentsInSection.get(0).selected = true;
			mystudents = controller.studentsInSection;
			Decimal val = mystudents[0].stuSecRec.Dosage_to_Date__c;
			System.assertEquals('/apex/cy_students', pageRefSectionStudents.getURL());
			System.debug('Student Name 1:' + mystudents[0].selected + mystudents[0].stuSecRec.Student_Name__c);

			controller.slctdStdId = String.valueOf(theTestStudents.get(0).Id) + ',' + String.valueOf(theTestStudents.get(1).Id);
			PageReference pageRefAddTime = controller.doStudentsAddTime();
			System.assertEquals('/apex/cy_addtime', pageRefAddTime.getURL());
			///////
            Pagereference pageRefCystudent = controller.StudentReportChart();
			controller.showPopwindow=false;	
			Pagereference newpageReference = controller.cancelPopUp();
			Pagereference secindpagerference =controller.ContactNamepassing();
			//System.assertEquals('/apex/cy_students', pageRefCystudent.getURL());

			controller.currentSession = new Intervention_Session__c();
            controller.currentSession.Date__c = Date.today();
			controller.currentSession.Section__c = mysections[0].Id;
			controller.currentSession.Comments__c = 'Test Session Comment.';
			controller.sessionDosage = 10;

			PageReference pageRefAddStudent = controller.doAddStudentToSession();
			System.assertEquals('/apex/cy_students', pageRefAddStudent.getURL());

			pageRefAddTime = controller.doStudentsAddTime();
			System.assertEquals('/apex/cy_addtime', pageRefAddTime.getURL());
			///////////
            pageRefCystudent = controller.StudentReportChart();
			controller.getReportWrapper();
			controller.getStudentReport();
			//System.assertEquals('/apex/cy_students', pageRefCystudent.getURL());

			controller.primaryField = controller.avaliableFields[0].getValue();
			controller.selectedFields = new List<SelectOption>();
      		controller.avaliableFields = new List<SelectOption> {
      			new SelectOption('Test1', 'Test1'),
      			new SelectOption('Test2', 'Test2'),
      			new SelectOption('Test3', 'Test3')
      		};
      		controller.selectedFields.addAll(controller.avaliableFields);

	    List<Intervention_Session_Result__c> theInterventionSessionResults = new List<Intervention_Session_Result__c>();
	    for(Integer index = 0;index < 5;index++) {
	      theInterventionSessionResults.add(new Intervention_Session_Result__c(
	        Intervention_Session__c = theTestInterventionSessions.get(index).Id,
	        Student_Section__c = theTestStudentSections.get(index).Id,
	        Amount_of_Time__c = 10,
	        Individual_Student_Comment__c = 'Testing'
	      ));
	    }
      controller.studentsInSession = theInterventionSessionResults;
			for(Intervention_Session_Result__c isr : controller.studentsInSession) {
				isr.Amount_of_Time__c = 10;
			}

			controller.selectedFieldsitem = 'Test1,Test2,Test3';
			PageReference pageRefSectionStudents1 = controller.doSessionSubmit();

			PageReference pageRefAddStudentToSession = controller.doAddStudentToSession();
			System.assertEquals('/apex/cy_students', pageRefAddStudentToSession.getURL());

			PageReference pageSessionList = controller.doShowSessions();
			System.assertEquals('/apex/cy_session', pageSessionList.getURL());

			PageReference pageSessionListCancel = controller.doSessionListCancel();
			System.assertEquals('/apex/cy_students', pageSessionListCancel.getURL());

			PageReference pageSessionCancel = controller.doSessionCancel();
			System.assertEquals('/apex/cy_students', pageSessionCancel.getURL());

			controller.getPageNumber();
			controller.getTotal_size();
			controller.getTotalPages();
			controller.getprev();
			controller.getnxt();
			controller.Next();
			controller.End();
			controller.Previous();
			controller.Beginning();
			controller.initializePicklist();

			controller.searchResults = controller.getSessionList();
			system.assertEquals(5, controller.searchResults.size());
      	controller.updateSessionID = controller.searchResults[0].intervSection.Id;
			PageReference pageRefAddTime1 = controller.doUpdateSession();
			System.assertEquals('/apex/cy_addtime', pageRefAddTime1.getURL());

			controller.sessionDosage = 20;
			controller.primaryField = controller.allPrimaryFields[0].getValue();
			PageReference pageRefSectionStudents2 = controller.doSessionSubmit();
			System.assertEquals('/apex/cy_students', pageRefSectionStudents2.getURL());

			controller.doDeleteStudentFromSession();
			controller.search();
		}//System.RunAs
		Test.stopTest();
	}

	static testMethod void testNegativeMyController() {
		List<Section__c> mysections;
		PageReference pageRefSection = Page.pageSectionList;
		Test.setCurrentPage(pageRefSection);

		Section__c section = [SELECT Id FROM Section__c];

	    // Inserting test school account.
	    List<Account> theSchoolAccount = [SELECT Id, Legacy_ID__c FROM Account WHERE Legacy_ID__c = 'school'];

	    // Inserting test student records.
	    List<Student__c> theTestStudents = [SELECT Id FROM Student__c];

		Test.startTest();

		u = [SELECT Id FROM User WHERE Username = 'tstaff@test.com'];
		System.RunAs(u){
		ctlAddTimeFlow_dev controller = new ctlAddTimeFlow_dev();
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
		List<ctlAddTimeFlow_dev.StudentWrapper> mystudents = new List<ctlAddTimeFlow_dev.StudentWrapper>();

		PageReference pageRefSectionStudentsCancel = controller.doStudentsCancel();
		System.assertEquals('/apex/cy_sections', pageRefSectionStudentsCancel.getURL());

		//Negative Test Case
		controller.studentsInSection.get(0).selected = true;
		mystudents = controller.studentsInSection;

        PageReference pageRefAddTime = controller.doStudentsAddTime();
		controller.currentSession = new Intervention_Session__c();
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

		System.assertEquals(shortID, ctlAddTimeFlow_dev.convert18To15ID(longID));
		System.assertEquals(longID, ctlAddTimeFlow_dev.convert15To18ID(shortID));
	}

   //Added by Harsh Singh on 13th May 2016 for T-502641
	static testMethod void testSearchFunctionality() {
		List<Section__c> mysections;
		PageReference pageRefSection = Page.pageSectionList;
		Test.setCurrentPage(pageRefSection);
       
		Section__c section = [SELECT Id, Intervention_Primary_Staff__c FROM Section__c];

	    // Inserting test school account.
	    List<Account> theSchoolAccount = [SELECT Id, Legacy_ID__c FROM Account WHERE Legacy_ID__c = 'school'];

	    // Inserting test student records.
	    List<Student__c> theTestStudents = [SELECT Id FROM Student__c];

	    List<Student_Section__c> theTestStudentSections = [SELECT Id FROM Student_Section__c];
	    System.debug('>>>>> theTestStudentSections'+ theTestStudentSections);

		ctlAddTimeFlow_dev controller = new ctlAddTimeFlow_dev();
		controller.sectionID = section.ID;

	    // Inserting test intervention session records.
	    List<Intervention_Session__c> theTestInterventionSessions = new List<Intervention_Session__c>();
	    for(Integer index = 0;index < 5;index++) {
	      theTestInterventionSessions.add(TestDataUtil.createInterventionSession(
	        section.Id,
	        null,
	        section.Intervention_Primary_Staff__c
	      ));
	    }
	    insert theTestInterventionSessions;

	    // Inserting test intervention session result records.
	    List<Intervention_Session_Result__c> theTestInterventionSessionResults = new List<Intervention_Session_Result__c>();
	    for(Integer index = 0;index < 5;index++) {
	      theTestInterventionSessionResults.add(new Intervention_Session_Result__c(
	        Intervention_Session__c = theTestInterventionSessions.get(index).Id,
	        Student_Section__c = theTestStudentSections.get(index).Id,
	        Amount_of_Time__c = 10,
	        Individual_Student_Comment__c = 'Testing'
	      ));
	    }
	    insert theTestInterventionSessionResults;

		Test.startTest();

			controller.sect = new Section__c(
				Start_Date__c = Date.today(),
				End_Date__c = Date.today().addDays(10)
			);
			controller.searchSession();

			controller.sect = new Section__c(
				Start_Date__c = Date.today().addDays(10),
				End_Date__c = Date.today()
			);
			controller.searchSession();

			controller.sect = new Section__c(
				Start_Date__c = null,
				End_Date__c = Date.today().addDays(10)
			);
			controller.searchSession();

			controller.sect = new Section__c(
				Start_Date__c = Date.today(),
				End_Date__c = null
			);
			controller.searchSession();
			controller.searchstudentName ='rajesh juturi';
			controller.sect = new Section__c(
				Start_Date__c = Date.today(),
				End_Date__c = null
			);
            controller.searchSession();
			controller.searchstudentName ='rajesh juturi';
			controller.sect = new Section__c(
				Start_Date__c = null,
				End_Date__c = Date.today().addDays(10)
			);
			controller.searchSession();
		Test.stopTest();
  	}
   
    static testMethod void testNewFunctionality(){
		Test.startTest();
			ctlAddTimeFlow_dev controller = new ctlAddTimeFlow_dev();
			controller.sessionDate=System.today(); 
			controller.sessionSkills ='Maths';
			controller.sessionComment='Demo Session';
			controller.sectionName='Libby Awesome Section'; 
			controller.sectionNickName='L A S'; 
			controller.sectionELT='eslt';
			List<Section__c> mysections;
			PageReference pageRefSection = Page.pageSectionList;
			Test.setCurrentPage(pageRefSection);
        Test.stopTest();
    }

    static testMethod void testCurriculumFunctionality(){
		List<String> lstCurrNames = CT_core_SoqlUtils.getPicklistValuesBySobject('Curriculum__c', 'Curriculum_Name__c');
		List<String> lstCurrModules = CT_core_SoqlUtils.getPicklistValuesBySobject('Curriculum__c', 'Module_Name__c');
		List<String> lstCurrAssignments = CT_core_SoqlUtils.getPicklistValuesBySobject('Curriculum__c', 'Module_Assignments__c');
		PageReference pageRefSection = Page.pageSectionList;
		Test.setCurrentPage(pageRefSection);
		Section__c sec = [SELECT Id, Name, In_After_School__c FROM Section__c LIMIT 1];
		sec.In_After_School__c = 'Curriculum';
		update sec;

		Test.startTest();
		u = [SELECT Id FROM User WHERE Username = 'tstaff@test.com'];
		System.RunAs(u) {
			ctlAddTimeFlow_dev controller = new ctlAddTimeFlow_dev();

			//init section
			controller.reportID = null;
			List<Section__c> mysections = controller.getSecList();
			system.assertEquals(1, mysections.size());
			System.debug('Mysection 1: ' + mysections[0].Id + mysections[0].Name);
			controller.sectionID = mysections[0].Id;

			//get students
			PageReference pageRef = controller.doSectionStudents();
			System.assertEquals('/apex/cy_studentcurriculums', pageRef.getURL());

			//test error if student not checked
			pageRef = controller.doStudentsAddCurriculum();
			System.assertEquals('/apex/cy_studentcurriculums', pageRef.getURL());

			//init page cy_addcurriculum with selected students
			String selStudent1 = controller.studentsInSection.get(0).stuSecRec.Student__c;
			String selStudent2 = controller.studentsInSection.get(1).stuSecRec.Student__c;
			controller.slctdStdId = selStudent1;
			controller.studentsInSection.get(0).selected = true;
			pageRef = controller.doStudentsAddCurriculum();
			System.assertEquals('/apex/cy_addcurriculum', pageRef.getURL());
			
			//select Curriculum values and submit new Curriculums
			controller.currenCurriculum.Date_of_Module__c = Date.today();
			controller.currenCurriculum.Curriculum_Name__c = lstCurrNames[0];
			controller.currenCurriculum.Module_Name__c = lstCurrModules[0];
			controller.currenCurriculum.Module_Assignments__c = lstCurrAssignments[0];
			for(Curriculum__c curr: controller.studentsInCurriculum){
				curr.Module_Score__c = 5;
			}
			pageRef = controller.doCurriculumSubmit();
			System.assertEquals('/apex/cy_studentcurriculums', pageRef.getURL());

			//refresh student list with Curriculums
			controller.slctdStdId = selStudent1+','+selStudent2;
			controller.doStudentsAddCurriculum();

			//romove selected Curriculum from list new Curriculums
			pageRefSection.getParameters().put('sID', selStudent1);
			controller.doDeleteStudentFromCurriculum();
			System.assertEquals(1, controller.studentsInCurriculumDeleted.size());
			
			//check selected Curriculums to add
			controller.doAddStudentToCurriculum();
			System.assertEquals(1, controller.studentsInCurriculum.size());

			//refresh Curriculums
			controller.slctdStdId = selStudent1;
			controller.doStudentsAddCurriculum();

			//cancel page cy_addcurriculum
			pageRef = controller.doCurriculumCancel();
			System.assertEquals('/apex/cy_studentcurriculums', pageRef.getURL());
		}
        Test.stopTest();
    }

}
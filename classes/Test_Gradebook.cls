@isTest
public class Test_Gradebook {
	
	public static Assignment__c testAssign;
	public static Grade__c standardGrade;
	public static Grade__c fakeGrade;
	public static void setupData(){
		
		TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		TestDataSetupUtil_v2.activeSetUp.Standards_ONLY_Gradebook__c=true;
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
	}
	
	static void createGrade_Standard(Assignment__c a, Strand_Grade__c strandGrade, Standard__c standard,  Student_Section__c ss){
		Grade__c g= new Grade__c(
		Standards_Only_Grading__c = true,
		Strand_Grade__c = strandGrade.Id,
		exclude_From_Section_Grade__c = false,
		Student__c = ss.Student__c,
		Course__c = ss.Section__r.Course__c,
		Time__c = a.Time__c,
		Assignment__c = a.id,
		Student_Section__c = ss.id,
		Assignment_Weighting__c = a.Weighting_Value__c,
		Standard__c = standard.id,
		Standard_Weighting__c = 1,
		Include_In_Standard_Grade__c = true
		);
		fakeGrade = g.clone(false);
		fakeGrade.Strand_Grade__c = strandGrade.Id;
		fakeGrade.Standard__c = standard.Id;
		fakeGrade.Standard_Weighting__c=1;	
		fakeGrade.Include_In_Standard_Grade__c = true;
		fakeGrade.Standard_Times_Assignment__c = g.Standard_Weighting__c*a.Weighting_Value__c;
			SchoolForce_Settings__c sf = SchoolForce_Settings__c.getOrgDefaults();
			sf.triggers_disabled__c = true;
			update sf;
			insert fakeGrade;
			insert g;
			sf.triggers_disabled__c = false;
			update sf;
		standardGrade = g;
	}
	
	public static void createAssignment(){
		Assignment_Lib__c al    = new Assignment_Lib__c();
		al.Picklist_Value__c = [select picklist_value__c from Default_Assignment_Weighting__c where course__c = :testDataSetupUtil_v2.sectionsList[0].course__c limit 1].picklist_value__c;
		insert al;
		Assignment__c a = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
		a.Assignment_Library__r = al;
		a.Assignment_Library__c = al.id;
		a.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;
		a.Picklist_value__c =a.standard_scale__c;
		a.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		a.Name_in_Gradebook__c = 'Test1';
		insert a;
		testAssign = a;
		
		Grade__c g = new Grade__c( Student__c =testDataSetupUtil_v2.studentsList[0].id, Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , Time__c = testDataSetupUtil_v2.semester.id, Assignment__c = a.id,  Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id, Assignment_Weighting__c = a.Weighting_Value__c, Include_In_Standard_Grade__c = false);
		insert g;
	}
	
	
	static testMethod void test_Gradebook(){
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			
		createAssignment();
			
			test.starttest();
			GradebookController g = new GradebookController();
			g.section = g.baseObj.sectionList[0].id;
			system.debug('g.section~~~~'+g.section);
			system.assert(g.section!=null);

			g.baseObj.selectedTimeID = testDataSetupUtil_v2.semester.id;
			g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
			g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);
			
			g.standardDisplayString = 'true';
			g.standardDisplay = true;
			g.retrieveStudentGrades();
			system.assertEquals(g.gradebookObj.studentWrapperList.size(), 1, 'Students Not Retrieved');
			for(Grade__c gr:g.gradeList){
				gr.Entered_Grade__c='20';
				gr.Comment__c = 'COMMENT1';
			}	
			Student__c stu = g.gradebookObj.studentWrapperList[0].student;
			g.selectedStudentID = stu.Id;
			
			g.redirectInitialPage();

			GradebookController.updategradelist2(string.valueof(g.gradeList[0].Id)+';N,');
			GradebookController.fetchcomment(string.valueof(g.gradeList[0].Id));
			//US2681 updating
			GradebookController.updatecomment_v3(string.valueof(g.gradeList[0].Id),'test comment', 'true', 'N', false, true);
			GradebookController.lockgrades(string.valueof(g.gradeList[0].Id)+',');
		
			test.stoptest();
		}
	}
	
	static testMethod void testAttendance() {
				setupData();
		testDataSetupUtil_v2.setupSessiondata();
		List<Session__c> sessionsList = testDataSetupUtil_v2.sessionsList; //getSessions(1, semester, sectionsList[0].Id, 1);
		List<Attendance__c> newAttends = new List<Attendance__c>();
		Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
		Picklist_Value__c val = new Picklist_Value__c(RecordTypeId = rtMap.get('Attendance'), Category__c = 'Present');
	
		insert val;
		
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			
			createAssignment();
			test.starttest();		
	
			

			GradebookController g = new GradebookController();
			g.reloadSchool();
			g.section = g.baseObj.sectionList[0].id;
			
			Section__c sec = [SELECT Daily_Attendance__c FROM Section__c WHERE Id = :g.section];
			sec.Daily_Attendance__c = true;
			update sec;
			
			sessionsList = testDataSetupUtil_v2.getSessions(1, testDataSetupUtil_v2.semester, g.section, 1);
			
			Session__c sess = [SELECT Id FROM Session__c WHERE Section__c = :g.section LIMIT 1];
			
			for (Student__c stud: testDataSetupUtil_V2.studentsList)
			{
				for(integer i = 0; i < 10; i++)
				{
					Attendance__c att = new Attendance__c(); 
					att.Student__c = stud.Id;
					att.Arrival_Time__c = datetime.now();
					att.Arrival_Time_Text__c = 'test' + i;
					att.Daily__c = true;
					att.Departure_Time__c = datetime.now().addHours(1);
					att.Session__c = sess.Id;
					att.Picklist_Value__c = val.Id;
					newAttends.add(att);
				}
			}
			insert newAttends;
			
			system.assert(g.section!=null);

			g.baseObj.selectedTimeID = testDataSetupUtil_v2.sectionsList[0].Reporting_Period__c;
			g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
			g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);
			
			g.retrieveStudentGrades();

			test.stoptest();
		}		
	}
	
	
	static testMethod void testUpdateGrades() {
		setupData();

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			
			createAssignment();
			
			test.starttest();				
			

			GradebookController g = new GradebookController();
			g.section = g.baseObj.sectionList[0].id;
			
			g.baseObj.selectedTimeID = testDataSetupUtil_v2.sectionsList[0].Reporting_Period__c;
			g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
			g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);
			
			g.retrieveStudentGrades();
			g.standardDisplayString = 'true';
			g.standardDisplay = true;
			g.retrieveStudentGrades();
			system.assertEquals(g.gradebookObj.studentWrapperList.size(), 1, 'Students Not Retrieved');
			for(Grade__c gr:g.gradeList){
				gr.Entered_Grade__c='20';
				gr.Comment__c = 'COMMENT1';
			}	
			Student__c stu = g.gradebookObj.studentWrapperList[0].student;
			g.selectedStudentID = stu.Id;
			
			g.redirectInitialPage();
			
			GradebookController.updategradelist2(string.valueof(g.gradeList[0].Id)+';N,');
			g.newAssignmentPage();
			system.assertEquals(g.selectedAssignmentID, 'All', 'selectedAssignmentID Not Reset');
			system.assertEquals(g.selectedstandardID, 'All', 'selectedstandardID Not Locked');

			test.stoptest();
		}		
	}
	
	static testMethod void testGradebookBatch()
	{
		setupData();
		

		system.runAs(testDataSetupUtil_v2.staffUsersList[0])
		{
			
			createAssignment();
			test.starttest();
			GradebookController g = new GradebookController();
			g.section = g.baseObj.sectionList[0].id;
			system.assert(g.section != null);
		
			//g.retrieveStudentGrades();
			
			g.standardDisplayString = 'true';
			g.standardDisplay = true;

			g.baseObj.selectedTimeID = testDataSetupUtil_v2.sectionsList[0].Reporting_Period__c;
			g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
			g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);			
	
			
			g.retrieveStudentGrades();
			system.assertEquals(g.gradebookObj.studentWrapperList.size(), 1, 'Students Not Retrieved');
			for(Grade__c gr: g.gradeList)
			{
				gr.Entered_Grade__c = '20';
				gr.Comment__c = 'COMMENT1';
			}
			Student__c stu = g.gradebookObj.studentWrapperList[0].student;
			g.selectedStudentID = stu.Id;
			
			g.redirectInitialPage();
		
			g.xls();
			
			GradebookController.updategradelist2(string.valueof(g.gradeList[0].Id)+';N,');

			
			Batch_GradeRecalc bg = new Batch_GradeRecalc();
			bg.query = 'select Id, Grade_Update__c from Grade__c LIMIT 1';
			Database.executeBatch(bg,1);
		}
		test.stoptest();
	}
	
	static testmethod void testGradebookEverythingElse() {
		setupData();
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			createAssignment();
			test.startTest();
			
			Assignment__c aID = [SELECT ID FROM Assignment__c WHERE Name_in_Gradebook__c = 'Test1' LIMIT 1];
			PageReference pageRef = new PageReference('/apex/Gradebook');
			pageRef.getParameters().put('fromAssignment', '1');	
			pageRef.getParameters().put('timeid', testDataSetupUtil_v2.sectionsList[0].Reporting_Period__c);
			pageRef.getParameters().put('assignmentID', aID.ID);
			pageRef.getParameters().put('studentID', 'All');		
			Test.setCurrentPageReference(pageRef);
			GradebookController g = new GradebookController();
			g.section = g.baseObj.sectionList[0].id;			

			g.baseObj.selectedTimeID = testDataSetupUtil_v2.sectionsList[0].Reporting_Period__c;
			g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
			g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);
			
			g.retrieveStudentGrades();
			g.standardDisplayString = 'true';
			g.standardDisplay = true;
			g.retrieveStudentGrades();	
			
			g.gradelist[0].Entered_Grade__c = '20';
			g.gradelist[0].Comment__c = 'COMMENT1';
			g.gradelist[0].Exclude_From_Section_Grade__c = true;
			
			String gID = g.gradelist[0].ID;
			
			GradebookController.updateGradeListcheck(gID + ';commenting;checked;true');
			GradebookController.excludeErrorMethod(gID, 'commenting', 'checked', 'true', 'true', 'false');	
			test.stopTest();		
		}		
	}
	
	static testMethod void test_Gradebook_quickCreate(){
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			
			createAssignment();
			
			Test.startTest();
			GradebookController g = new GradebookController();
			g.section = g.baseObj.sectionList[0].id;
			system.debug('g.section~~~~'+g.section);
			system.assert(g.section!=null);

			g.baseObj.selectedTimeID = testDataSetupUtil_v2.semester.id;
			g.timeFilter.Date_Start_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(-1);
			g.timeFilter.End_Date__c=testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1);
			
			g.standardDisplayString = 'true';
			g.standardDisplay = true;
			g.retrieveStudentGrades();
			system.assertEquals( 1, g.gradebookObj.studentWrapperList.size(), 'Students Not Retrieved');

			//quick create assignment process
			g.initializeQuickCreateAssignment();
			g.assignmentWrapper.assignmentName = 'quick Test';
			g.populateGradebookName();
			g.dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
			g.assignmentWrapper.assignmentType = g.assignmentTypeOptions[0].getValue();
			g.searchFeature.SOSLsearch = 'Test';
			g.searchFeature.SOSlsearchMethod();
			g.assignmentWrapper.attachAssignment = true;
			//g.searchFeature.searchStandardResults[0].selected = true;
			g.submit();
			test.stoptest();
		}	
	}
}
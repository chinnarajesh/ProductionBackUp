@isTest
public class Test_Report_Card_Controller {
	public static List<Time_Element__c> rps;
	public static Student_Reporting_Period__c srp;
	public static List<Section_Grade__c> sectionGrades;
	public static List<Final_Grade__c> finalGrades;
	public static List<Standard__c> strands;
	public static List<Standard__c> standards;
	public static List<Standard_Grade__c> standardGrades;
	public static List<Strand_Grade__c> strandGrades;
	public static void setupData(boolean generateSOrecords){
		TestDataSetupUtil_v2.is4rp = true;
		TestDataSetupUtil_v2.setUPCoreData(10);
		TestDataSetupUtil_v2.setupStaffData(10);
		TestDataSetupUtil_v2.createScalesNormalizations();

		rps = new List<Time_Element__c>{TestDataSetupUtil_v2.semester,TestDataSetupUtil_v2.semester2,TestDataSetupUtil_v2.semester3,TestDataSetupUtil_v2.semester4};

		//going to have to use some manual setup here, because test data generates under populated data sets
		TestDataSetupUtil_v2.studContactsList = TestDataSetupUtil_v2.getContacts(1, 'Student' , null);
		TestDataSetupUtil_v2.studentsList = TestDataSetupUtil_v2.getStudents(1, 'Student', TestDataSetupUtil_v2.studContactsList);
		generateStudentSections();
		srp = new Student_Reporting_Period__c(
				Time__c =testdatasetuputil_v2.semester4.id,
				Student__c =testdatasetuputil_v2.studentsList[0].id,
				GPA__c = 3.75);
		insert srp;

		generateSectionGrades();
		generateFinalGrades();

		if(generateSOrecords){
			getStandards();
			generateStandardGrades();
			generateStrandGrades();
		}
	}

	public static void generateHomework(){
		List<Picklist_Value__c> hwStatus = testDataSetupUtil_v2.createHomeworkPicklistValues();
        Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1);
        List<HW_Tracker__c> hwList = new List<HW_Tracker__c>();
	    for(Picklist_Value__c pv:hwStatus){
	    	hwList.add(new HW_Tracker__c(Student__c = testDataSetupUtil_v2.studentsList[0].id, 
	    		Picklist_value__c=pv.id, 
	    		Student_Section__c=testDataSetupUtil_v2.studSectionsList[0].id,
	    		Due_Date__c = testDate
	    	));
	    }
	    insert hwList;
	}

	public static void generateAttendance(){
		List<Picklist_Value__c> attStatus = testDataSetupUtil_v2.createDefaultAttendanceTypes(TestDataSetupUtil_v2.activeSetup);
		TestDataSetupUtil_v2.createSessions(20,rps[0],TestDataSetupUtil_v2.sectionsList[0].id);
		List<Attendance__c> attendance = new List<Attendance__c>();
		for(Integer i=0;i< attStatus.size();i++){
			system.debug(testDataSetupUtil_v2.studentsList[0].id);
			system.debug(TestDataSetupUtil_v2.sessionsList[i].id);
			attendance.add(new Attendance__c(
				Picklist_Value__c = attStatus[i].id,
				Student__c = testDataSetupUtil_v2.studentsList[0].id,
				Session__c = TestDataSetupUtil_v2.sessionsList[i].id,
				Daily__c = true
			));
		}
		insert attendance;
	}

	public static void updateSetupOptions(boolean showStandards, boolean showStrands){
		TestDataSetupUtil_v2.activeSetup.Display_GPA_on_Report_Cards__c = true;
		TestDataSetupUtil_v2.activeSetup.Include_Section_Grades__c = true;
		TestDataSetupUtil_v2.activeSetup.Show_Semester_Grades_On_Report_Cards__c = true;
		TestDataSetupUtil_v2.activeSetup.Show_Homework_Percentage__c = true;
		TestDataSetupUtil_v2.activeSetup.Show_Section_Comments__c = true;
		TestDataSetupUtil_v2.activeSetup.Show_Standard_Grades__c = showStandards || showStrands;
		TestDataSetupUtil_v2.activeSetup.Progress_Report_Standard_Display__c = (showStrands)?'Strands':'Standards';
		TestDataSetupUtil_v2.activeSetup.Report_Card_Standard_Display__c = (showStrands)?'Strands':'Standards';
		TestDataSetupUtil_v2.activeSetup.Show_Sectional_Attendance_on_Report_Card__c = true;
		TestDataSetupUtil_v2.activeSetup.Calculation_Type__c = 'Mean';
		update TestDataSetupUtil_v2.activeSetup;
	}

	public static void generateStudentSections(){
		List<Student_Section__c> studSections = new List<Student_Section__c>();
		for(Section__c s:TestDataSetupUtil_v2.sectionsList){
			studSections.add(new Student_Section__c(
					Student__c = TestDataSetupUtil_v2.studentsList[0].id,
					Section__c = s.id,
					Reference_ID__c = TestDataSetupUtil_v2.studentsList[0].Student_ID__c+'_'+s.Name+'_'+TestDataSetupUtil_v2.school.Name + '_' + TestDataSetupUtil_v2.masterYear.Name__c,
					Active__c = true,
					Section__r = s
			));
		}

		insert studSections;
		TestDataSetupUtil_v2.studSectionsList = studSections;
	}

	public static void generateSectionGrades(){
		Map<ID, ID> courseWeightingMap = new Map<ID,ID>();
		for(Course_Weightings__c cw: [select id, Course__c from Course_Weightings__c where Course__c IN: TestDataSetupUtil_v2.coursesList]){
			courseWeightingMap.put(cw.Course__c, cw.id);
		}

		//Test data why you no make list of reporting periods?
		sectionGrades = new List<Section_Grade__c>();
		for(Student_Section__c ss:TestDataSetupUtil_v2.studSectionsList){
			for(Time_Element__c rp:rps){
				sectionGrades.add(new Section_Grade__c(
					Student_Section__c = ss.id,
					Time__c = rp.id,
					Letter_Grade__c = 'B- (83-80)',
					Grade__c = 81.65,
					Course_Weighting__c = courseWeightingMap.get(ss.Section__r.Course__c)));
			}
		}
		insert sectionGrades;
	}

	public static void generateFinalGrades(){
		finalGrades = new List<Final_Grade__c>();
		for(Course__c c:TestDataSetupUtil_v2.coursesList){
			finalGrades.add(new Final_Grade__c(
				Course__c = c.id,
				Student__C = TestDataSetupUtil_v2.studentsList[0].id,
				Key__c = (String)TestDataSetupUtil_v2.studentsList[0].id + (String)c.id,
				Final_Grade_Letter_v2__c = 'B- (83-80)',
				Final_Grade_Value__c = 81.65,
				Unweighted_GPA__c = 2.34,
				Course_Credits__c = 1.0,
				Weighted_GPA__c = 2.34,
				Final_GPA_Value__c = 2.34
			));
		}
		insert finalGrades;
	}

	public static void getStandards(){
		strands = new List<Standard__c>();
		standards = new list<Standard__c>();
		for(Integer i=0;i<5;i++){
			strands.add(new Standard__c(
				Name='TestStrand'+i,
				Subject__c = 'Subject'+Math.mod(i,2)
			));
		}
		insert strands;

		for(integer i=0;i<15;i++){
			standards.add(new Standard__c(
				Name='TestStandard'+i,
				Subject__c = 'Subject'+Math.mod(i,3),
				Strand__c  = strands[Math.mod(i,5)].id
			));
		}
		insert standards;
	}

	public static void generateStandardGrades(){
		standardGrades = new List<Standard_Grade__c>();
		for(Standard__c s:standards){
			standardGrades.add(new Standard_Grade__c(
				Grade__c = 2.5,
				Student__c = TestDataSetupUtil_v2.studentsList[0].id,
				Standard__c = s.id,
				Mean_Grade__c = 2.5,
				Key__c = ''+TestDataSetupUtil_v2.studentsList[0].id + s.id + TestDataSetupUtil_v2.semester.ID,
				Reporting_Period__c = TestDataSetupUtil_v2.semester.ID
			));
		}

		insert standardGrades;
	}

	public static void generateStrandGrades(){
		strandGrades = new List<Strand_Grade__c>();
		for(Standard__c s:strands){
			for(Time_Element__c rp:rps){
				strandGrades.add(new Strand_Grade__c(
					Student__c = TestDataSetupUtil_v2.studentsList[0].id,
					Strand__c = s.id,
					Reporting_Period__c = rp.id,
					Grade__c = 3.45
				));
			}
		}

		insert strandGrades;
	}

	@isTest static void Test_Traditonal_Load() {
		setupData(false);
		updateSetupOptions(false, false);
		generateHomework();
		generateAttendance();

		pageReference rcPage = Page.Report_Card;
		rcPage.getParameters().put('studentId', TestDataSetupUtil_v2.studentsList[0].id);
		rcPage.getParameters().put('rpId', TestDataSetupUtil_v2.semester4.id);
		rcPage.getParameters().put('incInactiveSS', 'true');
		rcPage.getParameters().put('incInactiveS','true');
		rcPage.getParameters().put('dispRank','true');

		Test.setCurrentPage(rcPage);
		Test.startTest();
			Report_Card_Controller controller = new Report_Card_Controller();
			//first did all the sections end up on the list?
			system.assertEquals(TestDataSetupUtil_v2.sectionsList.size(),controller.card.sectionWrappers.size());
			//gpa should have come out alright
			system.assertEquals(String.valueOf(srp.Gpa__c), controller.card.studentInfo.overallGPA);
			//school and setup loaded?
			system.assertNotEquals(null, controller.card.school,'School didn\'t load.');
			system.assertNotEquals(null, controller.card.setup,'Setup didn\'t load.');

			//language settings
			system.assertNotEquals(null, controller.ldw);
			system.assertEquals(null,TestDataSetupUtil_v2.studentsList[0].Home_Language__c,'Expecting the language to be null');
			system.assertEquals(false, controller.displaySpanish);
			//just checking it loaded in english
			system.assertEquals('Course',controller.ldw.get('course'));
		Test.stopTest();
	}

	@istest static void Test_StandardsBased_Load_Standards(){
		setupData(true);
		updateSetupOptions(true, false);

		pageReference rcPage = Page.Report_Card;
		rcPage.getParameters().put('studentId', TestDataSetupUtil_v2.studentsList[0].id);
		rcPage.getParameters().put('rpId', TestDataSetupUtil_v2.semester4.id);
		rcPage.getParameters().put('incInactiveSS', 'true');
		rcPage.getParameters().put('incInactiveS','true');
		rcPage.getParameters().put('dispRank','true');

		Test.setCurrentPage(rcPage);
		Test.startTest();
			Report_Card_Controller controller = new Report_Card_Controller();
			//standard grouping looks to the strand subject, so there are only two strand subjects.
			system.assertEquals(2, controller.card.subjectWrappers.size());
		Test.stopTest();
	}

	@isTest static void Test_StandardsBased_Load_Strands(){
		setupData(true);
		updateSetupOptions(true, true);

		pageReference rcPage = Page.Report_Card;
		rcPage.getParameters().put('studentId', TestDataSetupUtil_v2.studentsList[0].id);
		rcPage.getParameters().put('rpId', TestDataSetupUtil_v2.semester4.id);
		rcPage.getParameters().put('incInactiveSS', 'true');
		rcPage.getParameters().put('incInactiveS','true');
		rcPage.getParameters().put('dispRank','true');

		Test.setCurrentPage(rcPage);
		Test.startTest();
			Report_Card_Controller controller = new Report_Card_Controller();
		Test.stopTest();
	}
}
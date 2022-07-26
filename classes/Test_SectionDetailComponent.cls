@isTest
private class Test_SectionDetailComponent {

    private static Account school;
    private static Section__c section;
    private static Section__c section1;
    private static List<Student__c> students;
    private static Staff__c staff;
    private static Skill__c skill;
    private static final Integer UNENROLLED_STUDENT_COUNT = 5;
    private static final Integer ALL_STUDENT_COUNT = 10;

    private static void setupTestData() {
        skill = new Skill__c();
        skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
        skill.Category__c = 'SEL/Behavior and Attendance Interventions';
        insert skill;
        TestDataUtil.setupSharingControls();
        TestDataUtil.setupTime();
        school = TestDataUtil.createSchool('ApexTestSchool1');
        school.Site__c = 'Boston';
        insert school;
        TestDataUtil.schoolList.add(school);
        TestDataUtil.setupSetupRecord();
        List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
        insert ia;
        List<Program__c> programs = TestDataUtil.createPrograms(1, true, ia[0]);
        programs.addAll(TestDataUtil.createPrograms(1, true, ia[1]));
        programs.addAll(TestDataUtil.createPrograms(1, false, ia[2]));
        programs.addAll(TestDataUtil.createPrograms(1, false, ia[3]));
        insert programs;
        Account_Program__c accProg = TestDataUtil.createAccountProgram(school, programs[0]);
        Account_Program__c accProg1 = TestDataUtil.createAccountProgram(school, programs[1]);
        insert new List<Account_Program__c>{
                accProg, accProg1
        };
        students = TestDataUtil.createStudents(ALL_STUDENT_COUNT, school);
        insert students;
        List<Indicator_Area_Student__c> ias = TestDataUtil.createIAStudents(students, ia[0].Id);
        insert ias;

        Contact c = TestDataUtil.createContact('ApexTest', 'User', null);
        insert c;
        staff = TestDataUtil.createStaff(c, school, 1);
        insert staff;
        section = TestDataUtil.createSections_WithoutInsert(1, school, accProg, staff, programs[0])[0];
        section.Start_Date__c = Date.today().addDays(-7);
        section1 = TestDataUtil.createSections_WithoutInsert(1, school, accProg1, staff, programs[1])[0];
        section1.Name = 'SectionNewTest';
        section1.Start_Date__c = Date.today().addDays(-7);
        insert new List<Section__c>{
                section, section1
        };

        insert TestDataUtil.createStudentSections_WithoutInsert(new List<Section__c>{
                section, section1
        }, new List<List<Student__c>>{
                students, students
        });

        List<Student__c> notEnrolled = TestDataUtil.createStudents(UNENROLLED_STUDENT_COUNT, school);
        insert notEnrolled;

        Test.setCurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', section.id);
    }

    private static Id setupExistingSessions() {
        Intervention_Session__c session = new Intervention_Session__c(
                Section__c = section.ID,
                Session_Time_Completed_For__c = staff.ID,
                All_avenues__c = 'In-Person Service',
                Date__c = Date.today()
        );
        insert session;

        List<Intervention_Session_Result__c> results = new List<Intervention_Session_Result__c>();
        for (Student_Section__c s : [select id from Student_Section__c where Section__c = :section.ID]) {
            results.add(new Intervention_Session_Result__c(
                    Intervention_Session__c = session.ID,
                    Amount_of_Time__c = 30,
                    Student_Section__c = s.ID
            ));
        }
        insert results;
        return session.Id;
    }

    static testMethod void testConstructor_NoSectionID() {
        setupTestData();
        Test.setCurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().remove('SectionID');
        Test.startTest();
        SectionDetailExtension controller = new SectionDetailExtension();
        System.assertEquals('The system was unable to locate the id of the section you wish to view. Please return to the section detail page and try again.', ApexPages.getMessages()[0].getSummary());
        Test.stopTest();
    }

    static testMethod void testConstructor() {
        setupTestData();
        Test.startTest();
        SectionDetailExtension controller = new SectionDetailExtension();
        System.assertEquals(section.ID, controller.section.ID, 'Expected the section IDs to match.');
        System.assertEquals(students.size(), controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testWithdrawStudents() {
        setupTestData();
        Test.startTest();
        sectionDetailExtension controller = new sectionDetailExtension();

        controller.studentSections[0].selected = true;
        controller.startWithdrawStudents();
        System.assertEquals(1, controller.studentsToWithdraw.size(), 'Expected only one student to withdraw.');

        controller.studentSectionHolder.Enrollment_End_Date__c = system.today();
        controller.studentSectionHolder.Section_Exit_Reason__c = 'Testing withdrawl system';

        controller.withdrawStudents();
        System.assertEquals(students.size(), controller.studentSections.size(), 'Withdrawn student should still display in the list');
        System.assertEquals(false, controller.studentSections[0].studentSection.Active__c, 'The student should have been deactivated.');
        Test.stopTest();
    }


    static testMethod void testEditTime() {
        setupTestData();
        setupExistingSessions();
        Test.startTest();
        sectionDetailExtension controller = new sectionDetailExtension();
        controller.startEditTime();
        system.assertEquals(1, controller.sessions.size());
//			controller.selectedSessionID = controller.sessions[0].session.ID;
        controller.filterSessions();
        Test.stopTest();
    }


    static testMethod void enrollTest() {
        setupTestData();

        Test.setCurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', section.id);
        Test.startTest();
        sectionDetailExtension controller = new sectionDetailExtension();

        system.assertEquals(students.size(), controller.studentSections.size());
        controller.studentSectionHolder = new Student_Section__c();
        controller.studentSectionHolder.Enrollment_Start_Date__c = system.today();
        controller.selectedStudents = new List<StudentInfoWrapper>();
        controller.enrollStudents();
//			system.assertEquals(startingAvaible+students.size(), controller.studentSections.size());
        test.stopTest();
    }

    static testMethod void exitTest() {
        setupTestData();

        Test.setcurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', section.id);
        Test.startTest();
        sectionDetailExtension controller = new sectionDetailExtension();

        for (StudentInfoWrapper s : controller.studentSections) {
            s.selected = true;
        }

        system.assertEquals(students.size(), controller.studentSections.size());
        controller.startWithdrawStudents();
        controller.studentSectionHolder.Enrollment_End_Date__c = Date.today().addDays(5);
        controller.withdrawStudents();

        //past students are still displayed, their records are just disabled
        for (StudentInfoWrapper sew : controller.studentSections) {
            system.assertEquals(false, sew.studentSection.Active__c);
        }
        test.stopTest();
    }
    static testMethod void testGetRecordPage() {
        setupTestData();

        Test.setcurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', section.id);
        Test.startTest();
        sectionDetailExtension controller = new sectionDetailExtension();
        controller.GetRecordPage();
        test.stopTest();
    }

    static testMethod void testGetRecordPageForSession() {
        setupTestData();

        Test.setcurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', section.id);
        Test.startTest();
        sectionDetailExtension controller = new sectionDetailExtension();
        controller.getSectionRecordPage();
        test.stopTest();
    }


}
@isTest
private class ModalEnrollStudentController_Test {

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

//    static testMethod void testConstructor_NoSectionID() {
//        setupTestData();
//        Test.setCurrentPage(Page.IM_SectionDetail);
//        ApexPages.currentPage().getParameters().remove('SectionID');
//        Test.startTest();
//        ModalEnrollStudentController controller = new ModalEnrollStudentController();
//        System.assertEquals('The system was unable to locate the id of the section you wish to view. Please return to the section detail page and try again.', ApexPages.getMessages()[0].getSummary());
//        Test.stopTest();
//    }

    static testMethod void testConstructor() {
        setupTestData();
        Test.startTest();

        ModalEnrollStudentController controller = new ModalEnrollStudentController();
        System.assertEquals(section.ID, controller.sectionID, 'Expected the section IDs to match.');
        Test.stopTest();
    }

    static testMethod void testEnrollStudents() {
        setupTestData();
        Test.startTest();

        ModalEnrollStudentController controller = new ModalEnrollStudentController();
        controller.section = section;
        controller.startEnrollStudents();
        System.assertEquals(15, controller.availableStudents.size(), 'Expected the availableStudents size to match the unenrolled students in the school.');
        System.assertEquals(2, controller.gradeFilters.size());
        System.assertEquals(2, controller.indicatorAreaFilters.size());

        for (StudentInfoWrapper s : controller.availableStudents) {
            s.selected = true;
        }

        controller.addToSelected();
        System.assertEquals(15, controller.selectedStudents.size(), 'Expected all student to be moved to selectedStudents.');

        controller.selectedStudents[0].selected = true;
        controller.removeFromSelected();
        System.assertEquals(1, controller.availableStudents.size(), 'Expected only one student to be removed');
        System.assertEquals(15 - 1, controller.selectedStudents.size(), 'Expected only one student to be removed.');

        controller.enrollStudents();
        Test.stopTest();
    }

//    static testMethod void testDisplayStudent() {
//        setupTestData();
//        Test.startTest();
//        ModalEnrollStudentController controller = new ModalEnrollStudentController();
//
//        controller.displayStudent();
//        Test.stopTest();
//    }


    static testMethod void enrollTest() {
        setupTestData();

        Test.setCurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', section.id);
        Test.startTest();
        ModalEnrollStudentController controller = new ModalEnrollStudentController();
        controller.section = section;

        controller.startEnrollStudents();
        system.assert(controller.availableStudents.size() > 0);

        Integer startingAvaible = controller.availableStudents.size();
        string stuIds = '';
        for (StudentInfoWrapper s : controller.availableStudents) {
            s.selected = true;
        }
        controller.addToSelected();
        system.assertEquals(startingAvaible, controller.selectedStudents.size());
        system.assertEquals(0, controller.availableStudents.size());

        for (StudentInfoWrapper s : controller.selectedStudents) {
            s.selected = true;
        }
        controller.removeFromSelected();
        system.assertEquals(0, controller.selectedStudents.size());
        system.assertEquals(startingAvaible, controller.availableStudents.size());

        for (StudentInfoWrapper s : controller.availableStudents) {
            s.selected = true;
        }
        controller.addToSelected();
        system.assertEquals(startingAvaible, controller.selectedStudents.size());
        system.assertEquals(0, controller.availableStudents.size());

        controller.studentSectionHolder.Enrollment_Start_Date__c = system.today();
        controller.enrollStudents();
        test.stopTest();
    }
}
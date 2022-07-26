@isTest
private class Test_ModalAddSessionCtrl {

    private static Skill__c skill;
    public static Student_Section__c studentSections;
    private static final Integer COUNT = 5;
    private static final Integer AMOUNT = 30;

    private static void setupData(){
        testDataSetupUtil_v2.setUPCoreData(COUNT);
        testDataSetupUtil_v2.setUPStaffData(COUNT);
        testDataSetupUtil_v2.setUPStudentData(COUNT);
        testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
        testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);

        List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
        List<Scheduled_Section__c> schsec = TestDataSetupUtil_v2.createScheduledSections(groups);
    }

    static testMethod void testConstructor() {
        setupData();
        Test.startTest();
        ModalAddSessionCtrl controller = new ModalAddSessionCtrl();
        controller.selectedSessionID = testDataSetupUtil_v2.interventionSessionsList[0].Id;
        StudentInfoWrapper siw = new StudentInfoWrapper(testDataSetupUtil_v2.studSectionsList[0]);
        controller.studentSections = new List<StudentInfoWrapper>{siw};
        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testAddTime() {
        setupData();
        skill = new Skill__c();
        skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
        skill.Category__c = 'SEL/Behavior and Attendance Interventions';
        insert skill;

        Section__c sectionwithRelatedList =
        [SELECT Id, Name, Start_Date__c, Program__c, Intervention_Primary_Staff__c, End_Date__c,
                School__c, Active__c, School__r.Name, Time__r.Name__c, Program__r.Indicator_Area__r.Id,
                Program__r.Indicator_Area__r.Name, RecordTypeID, RecordType.Name, Account_Program__r.Name,
                In_After_School__c, Auto_Name__c,
        (SELECT Active__c, Student__c, Student__r.Id, Student__r.Name, Student_Name__c, Student_Grade__c,
                Section__c, Dosage_to_Date__c, Intervention_Enrollment_Start_Date__c,
                Enrollment_Start_Date__c, Enrollment_End_Date__c
        FROM Student_Section__r
        ORDER BY Student__r.Student_First_Name__c ASC LIMIT 1000),
        (SELECT Is_Active__c, Staff__r.Name, Intervention_Primary_Staff__c
        FROM Staff_Section__r)
        FROM Section__c
        WHERE Id =:testDataSetupUtil_v2.sectionsList[0].Id];
        Test.startTest();
        ModalAddSessionCtrl controller = new ModalAddSessionCtrl();

        controller.selectedSessionID = testDataSetupUtil_v2.interventionSessionsList[0].Id;
        controller.section = sectionwithRelatedList /*testDataSetupUtil_v2.sectionsList[0]*/;
        controller.selectedStaff = testDataSetupUtil_v2.staffContactsList[0].Id;
        controller.selectedSession.studentResults = testDataSetupUtil_v2.interventionSessionResultsList;
        controller.loadSession();
        StudentInfoWrapper siw = new StudentInfoWrapper(testDataSetupUtil_v2.studSectionsList[0]);
        controller.studentSections = new List<StudentInfoWrapper>{siw};
        controller.studentSections[0].selected = true;
        controller.startAddTime();
        System.assertEquals(1, controller.studentSections.size(), 'Students should not be removed from the enrollment list when adding time.');
        controller.selectedSession.session.Date__c = system.today();
        controller.selectedFields.add(new SelectOption('Self-Awareness: Identifying strengths and weaknesses', 'Self-Awareness: Identifying strengths and weaknesses'));
        controller.selectedSession.session.Skill_Primary__c = testDataSetupUtil_v2.interventionSessionsList[0].Skill_Primary__c;
        controller.primarySkill = skill.Id;
        controller.selectedSession.session.Comments__c = 'Bob refused to do his reading';
        controller.selectedSession.session.All_avenues__c = 'In-Person Service';
        controller.selectedSession.studentResults[0].Amount_of_Time__c = 30.0;
        controller.saveTime();
        Test.stopTest();
    }


    static testMethod void testloadSession() {
        setupData();
        Test.startTest();
        ModalAddSessionCtrl controller = new ModalAddSessionCtrl();
        controller.selectedSessionID = testDataSetupUtil_v2.interventionSessionsList[0].Id;
        controller.section = testDataSetupUtil_v2.sectionsList[0];
        controller.loadSession();
        System.assertEquals(testDataSetupUtil_v2.interventionSessionsList[0].Id, controller.selectedSession.session.Id);
        controller.getRecordPage();
        StudentInfoWrapper siw = new StudentInfoWrapper(testDataSetupUtil_v2.studSectionsList[0]);
        controller.studentSections = new List<StudentInfoWrapper>{siw};
        controller.startAddStudents();
        StudentInfoWrapper sew = controller.studentSections[0];
        sew.selected = true;
        controller.addableStudents.add(sew);
        controller.addStudentsToSession();
        controller.removeStudentFromSession();
        Test.stopTest();
    }

    static testMethod void testGetRecordPage() {
        setupData();
        Test.setcurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', testDataSetupUtil_v2.sectionsList[0].Id);
        Test.startTest();
        ModalAddSessionCtrl controller = new ModalAddSessionCtrl();
        controller.GetRecordPage();
        test.stopTest();
    }

    static testMethod void addTimetTest() {
        setupData();
        Test.setcurrentPage(Page.IM_SectionDetail);
        ApexPages.currentPage().getParameters().put('SectionID', testDataSetupUtil_v2.sectionsList[0].Id);
        Test.startTest();
        ModalAddSessionCtrl controller = new ModalAddSessionCtrl();
        StudentInfoWrapper siw = new StudentInfoWrapper(testDataSetupUtil_v2.studSectionsList[0]);
        controller.studentSections = new List<StudentInfoWrapper>{siw};
        for (StudentInfoWrapper s : controller.studentSections) {
            s.selected = true;
        }

        controller.startAddTime();
        controller.selectedStaff = testDataSetupUtil_v2.sectionsList[0].Intervention_Primary_Staff__c;
        controller.selectedSession.session.Date__c = Date.today()-1;
        controller.primarySkill = testDataSetupUtil_v2.interventionSessionsList[0].Skill_Primary__c;
        controller.selectedSession.session.Skills__c = 'Test Skills';
        controller.selectedSession.session.Comments__c = 'Test Comments';
        controller.selectedSession.session.All_avenues__c = 'In-Person Service';

        for (Intervention_Session_Result__c isr : controller.selectedSession.studentResults) {
            isr.Amount_of_Time__c = 10;
        }
        controller.saveTime();
        test.stopTest();
    }
}
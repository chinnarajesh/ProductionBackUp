@isTest
public with sharing class SessionInterventionBulkUploadContrTest {
    private static Account school;
    private static Section__c section;
    private static List<Student__c> students;
    private static Skill__c skill;

    private static testmethod void testConstructor(){
        test.startTest();
        SessionInterventionBulkUploadController controller = new SessionInterventionBulkUploadController();
        system.assertEquals(false, controller.showDownloadTemplate);
        test.stopTest();
    }

    static testMethod void myUnitTest(){
        setupData();
        Test.setCurrentPage(Page.SessionInterventionBulkUpload);
        Test.startTest();
            SessionInterventionBulkUploadController controller = new SessionInterventionBulkUploadController();
            system.assertEquals(1, controller.schools.size(),'Expected the school list to contain 1 entry only');
            controller.selectedSchool = controller.schools[0].getValue();
            controller.changeSchool();
            System.assertEquals(1, controller.staff.size(),'Expected only one staff to display');
            controller.selectedStaff = controller.staff[0].getValue();
            controller.changeStaff();
            System.assertEquals(1, controller.sections.size(),'Expected only one section to display');
            controller.selectedSection = controller.sections[0].getValue();
            controller.changeSection();
            System.assertEquals(2, controller.resultsData.size());
            controller.toggleSortDirection();
            controller.resultsData[0].isChecked = true;
            controller.confirmSelectedStudents();
            System.assertEquals(2, controller.resultsData.size());
            System.assertEquals(true, controller.showDownloadTemplate);
            controller.prepareStudentsTemplate();
            System.assertEquals(1, controller.newISRs.size());
            controller.resetPage();
            System.assertEquals(true, controller.showImportSection);
        Test.stopTest();
    }

    static testMethod void saveForExportTest(){
        setupData();
        Test.setCurrentPage(Page.SessionInterventionBulkUpload);
        Test.startTest();
        SessionInterventionBulkUploadController controller = new SessionInterventionBulkUploadController();
        controller.resultsData[0].isChecked = true;
        controller.resultsData[1].isChecked = true;
        controller.confirmSelectedStudents();
        PageReference pref = controller.saveForExport();
        system.assertEquals(pref.getURL(), Page.SessionInterventionBulkUploadExport.getURL());
        PageReference pref2 = controller.startSessionImport();
        system.assertEquals(pref.getURL(), Page.SessionInterventionBulkUploadExport.getURL());
        Test.stopTest();
    }

    static testMethod void importStudentsTest(){
        setupData();
        SessionInterventionBulkUploadController controller = new SessionInterventionBulkUploadController();
        controller.csvData = '';
        String importData = 'Intervention Session Results,Generated 6-11-2021,,,,,\n' +
                'Student Internal Id, Student USID, Student Id, Student Name, *REQ* Date, *REQ* Amount of Time (in minutes) (Amount_of_Time__c), Exit Ticket (Exit_Ticket__c)\n' +
                + students[0].Id + ',082402M909,CY-736701,"Delcastillo, Rudy",06/21/2021,34,yes\n' +
                + students[1].Id + ',082402M922,CY-736714,"Flemings, Tena",06/22/2021,36,no';

        test.startTest();
            PageReference pref = controller.startImport();
            system.assertEquals(pref.getURL(), Page.SessionInterventionBulkUploadImport.getURL());
            controller.fileBlob = Blob.valueOf(importData);
            importData = '';
            controller.fileName = 'testData.csv';
            controller.fileContentType = 'text/csv';
            controller.processInput();
            System.assertEquals(2, controller.createdSessions.size());
            controller.saveSessionsForExport();
            System.assertEquals(true, controller.showImportSessionsButton);
            PageReference pref1 = controller.exportSessionTemplate();
            system.assertEquals(pref1.getURL(), Page.SessionInterventionBulkUploadExport.getURL());
            controller.csvData = '';
            importData = 'Intervention Sessions,Generated 6-16-2021,,,,,,,,\n' +
                    'Session Internal ID, Session ID, Date, Add\'l Comments for Session (Comments__c), All avenues (All_avenues__c), Primary Skill (Skill_Primary__c), Other Skills (Skills_Covered_for_the_Session__c), Site Details (Site_Details__c), Session Type (Session_Type__c), Session Format (Session_Format__c)\n' +
                    + controller.createdSessions[0].Id + ',IS-1507330,2021-06-09 00:00:00,test comment 1,In-Person Service,Critical Thinking,,Option 1,Small Group,Push In\n' +
                    + controller.createdSessions[1].Id + ',IS-1507329,2021-06-10 00:00:00,test comment 2,Virtual Service,Decision Making,,Option 2,Small Group,Pull Out';
            controller.fileBlob = Blob.valueOf(importData);
            importData = '';
            controller.fileName = 'testData.csv';
            controller.fileContentType = 'text/csv';
            controller.processSessionsInput();
            System.assertEquals(2, controller.createdSessions.size());
            System.assertEquals(true, controller.showUpdatedSessions);
        test.stopTest();
    }

    static void setupData(){
        String category1 = 'SEL/Behavior and Attendance Interventions';
        skill = new Skill__c();
        skill.Name = 'Self-Awareness: Identifying strengths and weaknesses';
        skill.Category__c = category1;
        Skill__c skill1 = new Skill__c(
                Name = 'Critical Thinking',
                Category__c = category1
        );
        Skill__c skill2 = new Skill__c(
                Name = 'Decision Making',
                Category__c = category1
        );
        List<Skill__c> skills = new List<Skill__c>{skill, skill1, skill2};
        insert skills;
        TestDataUtil.setupSharingControls();
        TestDataUtil.setupTime();
        school = TestDataUtil.createSchool('ApexTestSchool1');
        school.Site__c = 'Boston';
        insert school;

        TestDataUtil.schoolList.add(school);
        TestDataUtil.setupSetupRecord();

        List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
        insert ia;

        List<Program__c> programs = TestDataUtil.createPrograms(1,true,ia[0]);
        programs.addAll(TestDataUtil.createPrograms(1,true,ia[1]));
        programs.addAll(TestDataUtil.createPrograms(1,false,ia[2]));
        programs.addAll(TestDataUtil.createPrograms(1,false,ia[3]));
        insert programs;
        Account_Program__c accProg = TestDataUtil.createAccountProgram(school, programs[0]);
        insert accProg;
        students = TestDataUtil.createStudents(2, school);
        insert students;

        Contact c = TestDataUtil.createContact('ApexTest','User',null);
        insert c;
        Staff__c staff = TestDataUtil.createStaff(c,school,1);
        insert staff;
        section = TestDataUtil.createSections_WithoutInsert(1,school, accProg, staff, programs[0])[0];
        section.Start_Date__c = Date.newInstance(2021, 6, 15);
        insert section;

        insert TestDataUtil.createStudentSections_WithoutInsert(new List<Section__c>{section}, new List<List<Student__c>>{students});
    }

}
/**
 * Created by YuriyRudenko on 9/25/2020.
 */
@IsTest
public with sharing class CT_core_SoqlUtilsTest {
    private static final Integer COUNT = 5;
    private static final Integer AMOUNT = 30;
    private static final String TEST_ERROR = 'Test';
    private static Setup__c setup;

    private static void setupData(){
        testDataSetupUtil_v2.setUPCoreData(COUNT);
        testDataSetupUtil_v2.setUPStaffData(COUNT);
        testDataSetupUtil_v2.setUPStudentData(COUNT);
        testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
        testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);

        List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
        List<Scheduled_Section__c> schsec = TestDataSetupUtil_v2.createScheduledSections(groups);
    }

    static testMethod void testGetTimeElementsByTerm() {
        setupData();
        Test.startTest();
        List <Time_Element__c> listTermIds = CT_core_SoqlUtils.getTimeElementsByTerm(testDataSetupUtil_v2.term.Id, true);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetTimeElementsByTermWithData() {
        setupData();
        Test.startTest();
        List <Time_Element__c> listTermIds = CT_core_SoqlUtils.getTimeElementsByTerm(testDataSetupUtil_v2.term.Id, true, Date.today());
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetTimeElementsByTermGB() {
        setupData();
        Test.startTest();
        List <Time_Element__c> listTermIds = CT_core_SoqlUtils.getTimeElementsByTermGB(testDataSetupUtil_v2.term.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetTimeElementById() {
        setupData();
        Test.startTest();
        Time_Element__c termId = CT_core_SoqlUtils.getTimeElementById(testDataSetupUtil_v2.term.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetRecentThreeYears() {
        setupData();
        Test.startTest();
        List<String> listRecrnts = CT_core_SoqlUtils.getRecentThreeYears();
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetTermSetupsBySchool() {
        setupData();

        Test.startTest();

        Map <String,Setup__c> mapTermSetupsBySchool = CT_core_SoqlUtils.getTermSetupsBySchool(testDataSetupUtil_v2.school.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetRecentSchoolSetups() {
        setupData();

        Test.startTest();

        Map<String,Map<String,Setup__c>> mapRecentSchoolSetups = CT_core_SoqlUtils.getRecentSchoolSetups(CT_core_SoqlUtils.getRecentThreeYears(), new Set<Id>{testDataSetupUtil_v2.school.Id});
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetUsersByIds() {
        setupData();
        User user = [SELECT Id, firstname, lastname, email, Extension, Title, ManagerId, Phone, Street, City, State, PostalCode, Country , Department,School__c
        FROM User LIMIT 1];
        Test.startTest();
        List<User> getUsersByIds = CT_core_SoqlUtils.getUsersByIds(new Set<Id>{user.Id});
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetSectionById() {
        setupData();
        Section__c sect = [select id, name,name_spanish__c, grade_level__c, all_grades__c, description__c, school__c, time__c from Section__c where RecordType.Name='Schedule Group' LIMIT 1];
        Test.startTest();
        Section__c sectionById = CT_core_SoqlUtils.getSectionById(sect.Id );
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetGroupsBySetupId() {
        setupData();
        setup = [SELECT id, Active__c
        FROM Setup__c
        LIMIT 1];

        Test.startTest();

        List<Schedule_Group__c> listGroupsBySetupId = CT_core_SoqlUtils.getGroupsBySetupId(setup.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetSetupById() {
        setupData();
        setup = [SELECT id, Active__c
        FROM Setup__c
        LIMIT 1];

        Test.startTest();

        Setup__c setupById = CT_core_SoqlUtils.getSetupById(setup.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetPlValuesListID() {
        setupData();
        setup = [SELECT id, Active__c
        FROM Setup__c
        LIMIT 1];

        Test.startTest();

        List<Picklist_Value__c> listPlValuesListID = CT_core_SoqlUtils.getPlValuesListID('Time', setup.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetPlValues() {
        setupData();
        setup = [SELECT id, Active__c
        FROM Setup__c
        LIMIT 1];

        Test.startTest();

        Map<Id,Picklist_Value__c> mapPlValues = CT_core_SoqlUtils.getPlValues('Time', setup.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetTeMap() {
        setupData();
        Test.startTest();

        Map<Id, Time_Element__c> mapTeMap = CT_core_SoqlUtils.getTeMap('Time');
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetPlValuesListByRecordType() {
        setupData();
        setup = [SELECT id, Active__c
        FROM Setup__c
        LIMIT 1];

        Test.startTest();

        List<Picklist_Value__c> listPlValuesListByRecordType = CT_core_SoqlUtils.getPlValuesListByRecordType('Time', setup.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetStudentById() {
        setupData();

        Test.startTest();

        List<Student__c> listStudentById = CT_core_SoqlUtils.getStudentById(testDataSetupUtil_v2.studentsList[0].Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetStudents() {
        setupData();

        Test.startTest();

        List<Student__c> listStudents = CT_core_SoqlUtils.getStudents(new Set<String>{testDataSetupUtil_v2.studentsList[0].Id});
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetSearchName() {
        setupData();

        Test.startTest();

        String searchName = CT_core_SoqlUtils.getSearchName(testDataSetupUtil_v2.studentsList[0].Name);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetSectionsbyStaffMap() {
        setupData();

        Test.startTest();

        Map <Id, List <Section__c>> mapSectionsbyStaffMap = CT_core_SoqlUtils.getSectionsbyStaffMap(new Set <Id>{testDataSetupUtil_v2.staffUsersList[0].Id});
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetSetupBySchoolYear() {
        setupData();

        Test.startTest();

        Setup__c getSetupBySchoolYear = CT_core_SoqlUtils.getSetupBySchoolYear(testDataSetupUtil_v2.school.Id, testDataSetupUtil_v2.masterYear.Id);
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetErrorMessageByName() {
        setupData();
        ErrorMessages__c error = new ErrorMessages__c(Message__c = 'Test Error', Name = TEST_ERROR);
        insert error;

        Test.startTest();
        String getErrorMessageByName = CT_core_SoqlUtils.getErrorMessageByName(TEST_ERROR);
        Test.stopTest();

        System.assertEquals(getErrorMessageByName, 'Test Error');
    }

    static testMethod void testgetContactsByExternalId() {
        setupData();
        Contact cont = [SELECT Id, Reference_Id__c FROM Contact LIMIT 1];

        Test.startTest();
        Map<String, Contact> getContactsByExternalId = CT_core_SoqlUtils.getContactsByExternalId(new List<String>{cont.Reference_Id__c});
        Test.stopTest();

        System.assertEquals(1, getContactsByExternalId.size());
    }

    static testMethod void testgetStudentsInGroup() {
        setupData();

        Test.startTest();
        List<Student__c> getStudentsInGroup = CT_core_SoqlUtils.getStudentsInGroup('5', testDataSetupUtil_v2.school.Id );
        Test.stopTest();

        System.assertEquals(false, getStudentsInGroup.isEmpty());
    }

    static testMethod void testgetnotifymap() {
        setupData();
        Value__c value = new Value__c(Name = 'Test Value', Type__c = 'Homework Alerts', Communication_Type__c = 'Email');
        insert value;

        Test.startTest();
        Map<String, Map<String, String>> getnotifymap = CT_core_SoqlUtils.getnotifymap(value.Type__c );
        Test.stopTest();

        System.assertEquals(1, getnotifymap.size());
    }

    static testMethod void testgetStaffDetails() {
        setupData();
        Staff__c staff = new Staff__c(Name = 'Test Staff');


        Test.startTest();
        Staff__c getStaffDetails = CT_core_SoqlUtils.getStaffDetails(staff.Id);
        Test.stopTest();

        System.assertEquals(null, getStaffDetails);
    }

    static testMethod void testGetSectionsbyYear() {
        setupData();

        Test.startTest();

        Map<String,Map<String,List<Section__c>>> mapSectionsbyStaffMap = CT_core_SoqlUtils.getSectionsbyYear(new Set <Id>{testDataSetupUtil_v2.school.Id},
        new List<Id>{testDataSetupUtil_v2.staffUsersList[0].Id}, CT_core_SoqlUtils.getRecentThreeYears());
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetLoggedInContact() {
        setupData();

        Test.startTest();

        Contact loggedInContact = CT_core_SoqlUtils.getLoggedInContact();
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetOrgActiveSetups() {
        setupData();

        Test.startTest();

        List<Setup__c> listOrgActiveSetups = CT_core_SoqlUtils.getOrgActiveSetups();
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetDummyOrganization() {
        setupData();

        Test.startTest();

        Account accountDummyOrganization = CT_core_SoqlUtils.getDummyOrganization();
//        System.assertEquals(1, controller.size(), 'Expected all enrolled time elements to be loaded.');
        Test.stopTest();
    }

    static testMethod void testProcessStaticResourceMap() {
        setupData();
        Test.startTest();
        CT_core_SoqlUtils.processStaticResourceMap();
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testProcessCSVFile() {
        setupData();
        Test.startTest();
        String[] stringProcessCSVFile = CT_core_SoqlUtils.processCSVFile('samp_staffRoster');
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetLoggedInUser() {
        setupData();
        Test.startTest();
        User loggedInUser = CT_core_SoqlUtils.getLoggedInUser();
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testParentalNotifyAbsentOne() {
        setupData();
        Test.startTest();
        String parentalNotifyAbsentOne = CT_core_SoqlUtils.ParentalNotifyAbsentOne();
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetMainTardyQuery() {
        setupData();
        Test.startTest();
        String stringMainTardyQuery = CT_core_SoqlUtils.getMainTardyQuery(Date.today(), true);
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetActiveStaffForContact() {
        setupData();
        Contact contact = [select id, name from Contact  limit 1];
        Test.startTest();
        List<Staff__c> listActiveStaffForContact = CT_core_SoqlUtils.getActiveStaffForContact(contact.Id);
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetSectionListforContact() {
        setupData();
        Contact contact = [select id, name from Contact  limit 1];
        Test.startTest();
        List<Section__c> listSectionListforContact = CT_core_SoqlUtils.getSectionListforContact(contact.Id);
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetContactStaffList() {
        setupData();
        Contact contact = [select id, name from Contact  limit 1];
        Test.startTest();
        List<Staff__c> listContactStaffList = CT_core_SoqlUtils.getContactStaffList(contact.Id);
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testgetStaffForContactBySchool() {
        setupData();
        Contact contact = [select id, name from Contact  limit 1];
        Test.startTest();
        List<Staff__c> listStaffForContactBySchool = CT_core_SoqlUtils.getStaffForContactBySchool(contact.Id,testDataSetupUtil_v2.school.Id );
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetMasterPlValues() {
        setupData();
        Test.startTest();
        Map <Id, Map<String, List <Picklist_Value__c>>> mapMasterPlValues = CT_core_SoqlUtils.getMasterPlValues();
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testSectOptionsList() {
        setupData();
        Test.startTest();
        List<SelectOption> sectOptionsList = CT_core_SoqlUtils.SectOptionsList(testDataSetupUtil_v2.sectionsList);
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }

    static testMethod void testGetMainAbsentQuery() {
        setupData();
        Test.startTest();
        String stringMainTardyQuery = CT_core_SoqlUtils.getMainAbsentQuery(Date.today(), true);
        String stringMainPGQuery = CT_core_SoqlUtils.getMainPGQuery();
//        System.assertEquals(1, controller.studentSections.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }
}
/**
 * Created by TarasTorubka on 22.09.2020.
 */
@IsTest
public class CT_core_TermSetup_v2Test {
    private static final String TEST_ERROR = 'Test';

    static testMethod void test_core_TermSetup_v2() {
        string termId;
        testDataSetupUtil_v2.setUPCoreData(2);
        PageReference p = Page.CT_core_TermSetup_v2;
        testDataSetupUtil_v2.activeSetUp.Year__c = testDataSetupUtil_v2.term.Parent_Time_Element__c;
        Test.setCurrentPage(p);
        ApexPages.currentPage().getParameters().put('setupId', testDataSetupUtil_v2.activeSetUp.id);

        Test.startTest();
        CT_core_TermSetup_v2 c = new CT_core_TermSetup_v2();
        c.configureNewTerm();
        c.selectedTermWrapper.term.name__c = 'Test for Apex';
        c.selectedTermWrapper.term.date_start_Date__c = TestDataSetupUtil_v2.masterYear.Date_Start_Date__c;
        c.selectedTermWrapper.term.end_Date__c = TestDataSetupUtil_v2.masterYear.End_Date__c;
        c.selectedTermWrapper.term.Reporting_Period_Value__c = TestDataSetupUtil_v2.term.Reporting_Period_Value__c;
        c.selectedTermWrapper.term.Days_of_Week__c = TestDataSetupUtil_v2.semester2.Days_of_Week__c;
        c.saveTermConfig();

        termId = c.selectedTermWrapper.term.id;
        PageReference p2 = Page.CT_core_TermSetup_v2;
        Test.setCurrentPage(p2);
        ApexPages.currentPage().getParameters().put('setupId', testDataSetupUtil_v2.activeSetUp.id);
        ApexPages.currentPage().getParameters().put('selectedTermId', termId);
        CT_core_TermSetup_v2 c2 = new CT_core_TermSetup_v2();
        c2.selectedTermId = termId;
        c2.viewReportingPeriods();
        system.assertEquals(c2.selectedTermWrapper.timeElementList.size(), 0); // Check that there are no reporting periods for the new term
        system.assert(c2.selectedTermWrapper.cQasw.days.hasMon()); // Verify it has monday enabled - default for the wrapper
        c2.initReportingPeriod(); //Add a new Rp
        c2.cancelAddReportingPeriod(); //Verify cancel
        c2.initReportingPeriod(); //Add a new Rp
        c2.addReportingPeriod();// Save a new one..
        c2.editTermDetails();
        c2.populateTermDetailTable();
        c2.checkReportingPeriod();
        c2.editReportingPeriod();
        c2.saveReportingPeriodAfterEdit();
        c2.goHome();
        c2.goHomeModified();
        c2.next();
        c2.cancelViewReportingPeriods();
        c2.checkTermSelectionChanges();

        CT_TestException e = new CT_TestException('ERROR');
        c.insertLogsException(e, 'An error occurred while setting the term.', testDataSetupUtil_v2.activeSetUp.id, c2.selectedTermWrapper.term.id, 'error setting term');
//        c.insertLogsExceptionInSaveReportingPeriodAfterEdit(e);
        system.assertEquals(c2.selectedTermWrapper.timeElementList.size(), 0); //verify it throws an error

        c2.addReportingPeriod();    //Save and add new
        system.assertEquals(c2.selectedTermWrapper.timeElementList.size(), 0); //verify it still throws an error for overlap
        c2.addReportingPeriod();     //Save, should actually work this time
        system.assertEquals(c2.selectedTermWrapper.timeElementList.size(), 0); //Yup, got one
        ApexPages.currentPage().getParameters().put('selectedTermIdForSetup', c2.selectedTermWrapper.term.id);
        c2.setTerm();  //Select the term from the radio
        c2.saveSetup(); //Save it
        system.assertEquals(c2.cSetup.setup.term__c, c2.selectedTermIdForSetup);
        system.assertEquals(null, c2.schoolSetup);
        system.assertEquals(null, c2.stepNo);
        system.assertEquals(1, c2.TERMS);
        system.assertEquals(2, c2.SELECTIONS);
        system.assertEquals(3, c2.TEMPLATES);
        system.assertEquals(4, c2.CALENDAR);
        system.assertEquals(5, c2.COURSE_CATALOG);
        system.assertEquals(6, c2.ROOMS);
        system.assertEquals(7, c2.STAFF);
        system.assertEquals(10, c2.GROUP_CONFIG);
        system.assertEquals(11, c2.SCHEDULE);
        system.assertEquals(13, c2.STUDENT_SECTIONS);
        system.assertEquals(14, c2.PUBLISH);
        system.assertEquals(16, c2.ACTIVATION);
        Test.stopTest();
    }

    static testMethod void Test_ErrorMessages() {
//        ErrorMessages__c error = new ErrorMessages__c(Message__c = 'Test Error', Name = TEST_ERROR);
//        insert error;

        Test.startTest();
        CT_core_TermSetup_v2 c = new CT_core_TermSetup_v2();
        c.processErrorMessages();
        Test.stopTest();

//        system.assertEquals(true, controller != null);

    }

    public with sharing class CT_TestException extends Exception{

    }
}
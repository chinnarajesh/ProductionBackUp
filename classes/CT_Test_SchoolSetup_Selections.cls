/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CT_Test_SchoolSetup_Selections {

    static testMethod void testConstructor() {
        PageReference pr = Page.CT_SchoolSetup_Selections;
        Test.setCurrentPage(pr);
        Test.startTest();
            CT_SchoolSetup_Selections sss = new CT_SchoolSetup_Selections();
            system.assertEquals(null,sss.schoolSetup);
            system.assertEquals(CT_SetupWizard_Utils.NO_SETUP_MESSAGE,ApexPages.getMessages()[0].getSummary());
            
            pr.getParameters().put('setupId',null);
            Test.setCurrentPage(pr);
            sss = new CT_SchoolSetup_Selections();
            system.assertEquals(null,sss.schoolSetup);
            system.assertEquals(CT_SetupWizard_Utils.NO_SETUP_MESSAGE,ApexPages.getMessages()[0].getSummary());
            
            TestDataSetupUtil_v2.setUPCoreData(1);
            pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
            Test.setCurrentPage(pr);
            sss = new CT_SchoolSetup_Selections();
            system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,sss.schoolSetup.id);
            system.assert(!sss.settingsSaved);
            system.assertEquals('School preferences must be saved before moving on to the next step.',ApexPages.getMessages()[1].getSummary());
            EOY_Progress__c testProgress = new EOY_Progress__c(Setup__c=TestDataSetupUtil_v2.activeSetup.id,
                                                            Year__c=TestDataSetupUtil_v2.activeSetup.Year__c,
                                                            School__c=TestDataSetupUtil_v2.activeSetup.School__c,
                                                            RecordTypeId=CT_SetupWizard_Utils.SW_RECORD_TYPE,
                                                            School_Selections_Completed__c=true);
            insert testProgress;
            sss = new CT_SchoolSetup_Selections();
            system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,sss.schoolSetup.id);
            system.assert(sss.settingsSaved);
            system.assertEquals('School selections have been saved.  No action required.',ApexPages.getMessages()[2].getSummary());
        Test.stopTest();
    }
    
    static testMethod void testSaveSetup(){
        CT_SchoolSetup_Selections sss = createTestData();
        Test.startTest();
            sss.saveSetup();
            system.assert(sss.settingsSaved);
            system.assertEquals('Selections saved successfully!',ApexPages.getMessages()[1].getSummary());
            EOY_Progress__c testProgress = CT_SetupWizard_Utils.getEOYProgressRecord(TestDataSetupUtil_v2.activeSetup);
            system.assert(testProgress.School_Selections_Completed__c);
            testProgress.School_Selections_Completed__c=false;
            update testProgress;
            
            //create error
            sss = new CT_SchoolSetup_Selections();
            sss.schoolSetup=null;
            List<Global_Error__c> ge = [SELECT id FROM Global_Error__c];
            sss.saveSetup();
            system.assertEquals('There was an error while saving your selections.  Please have your system administrator verify any global errors.',ApexPages.getMessages()[2].getSummary());
            system.assertEquals(ge.size()+1,[SELECT count() FROM Global_Error__c]);
        Test.stopTest();
    }
    
    static testMethod void testPrev(){
        CT_SchoolSetup_Selections sss = createTestData();
        Test.startTest();
            PageReference pr = sss.prev();
            system.assert(pr.getURL().toLowerCase().contains('ct_core_termsetup_v2'));
            system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,pr.getParameters().get('setupId'));
        Test.stopTest();
    }
    
    static testMethod void testNext(){
        CT_SchoolSetup_Selections sss = createTestData();
        Test.startTest();
            PageReference pr = sss.next();
            system.assertEquals(null,pr);
            system.assertEquals('School preferences must be saved before moving on to the next step.',ApexPages.getMessages()[0].getSummary());
            
            EOY_Progress__c testProgress = CT_SetupWizard_Utils.getEOYProgressRecord(sss.schoolSetup);
            testProgress.School_Selections_Completed__c=true;
            insert testProgress;
            pr = sss.next();
            system.assert(pr.getURL().toLowerCase().contains('ct_core_scheduletemplate'));
            system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,pr.getParameters().get('setupId'));
    }
    
    static CT_SchoolSetup_Selections createTestData(){
        TestDataSetupUtil_v2.setUPCoreData(1);
        PageReference pr = Page.CT_SchoolSetup_Selections;
        pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(pr);
        return new CT_SchoolSetup_Selections();
    }
}
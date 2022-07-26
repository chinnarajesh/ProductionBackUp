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
private class CT_Test_SetupWizard_Home {

    static testMethod void testConstructor() {
        Test.startTest();
            CT_SetupWizard_Home swh = new CT_SetupWizard_Home();
            system.assert(swh.needSchools);
            system.assert(!swh.needYears);
            system.assert(!swh.orgWideComplete);
            
            Account a = new Account(Name='Test School', RecordTypeId=CT_core_SoqlUtils.getRecordTypesBySobject('Account').get('School'));
            insert a;
            swh = new CT_SetupWizard_Home();
            system.assert(!swh.needSchools);
            system.assert(swh.needYears);
            system.assert(!swh.orgWideComplete);
            
            Picklist_Value__c yearPV = new Picklist_Value__c(Name='Year',Type__c='Time',RecordTypeId=CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Time'));
            insert yearPV;
            Time_Element__c year = new Time_Element__c(Name__c='Test Year',Picklist_Value__c=yearPV.id);
            insert year;
            swh = new CT_SetupWizard_Home();
            system.assert(!swh.needSchools);
            system.assert(!swh.needYears);
            system.assert(swh.orgWideComplete);
            system.assertEquals(1,swh.schools.size());
            system.assertEquals(1,swh.years.size());
        Test.stopTest();
    }
    
    static testMethod void testGoToSchoolSetup(){
        Account a = new Account(Name='Test School', RecordTypeId=CT_core_SoqlUtils.getRecordTypesBySobject('Account').get('School'));
        insert a;
        Picklist_Value__c yearPV = new Picklist_Value__c(Name='Year',Type__c='Time',RecordTypeId=CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Time'));
        insert yearPV;
        Time_Element__c year = new Time_Element__c(Name__c='Test Year',Picklist_Value__c=yearPV.id);
        insert year;
        Test.startTest();
            CT_SetupWizard_Home swh = new CT_SetupWizard_Home();
            PageReference pr = swh.goToSchoolSetup();
            system.assertEquals(null,pr);
            system.assertEquals('Please select a school to set up.',ApexPages.getMessages()[0].getSummary());
            system.assertEquals('Please select a year for which the setup will be valid.',ApexPages.getMessages()[1].getSummary());
            
            Setup__c setup = [SELECT id FROM Setup__c WHERE School__c=:a.id AND Year__c=:year.id];
            swh.selectedSchool = a.id;
            swh.selectedYear = year.id;
            pr = swh.goToSchoolSetup();
            system.assert(pr.getURL().toLowerCase().contains('ct_core_termsetup_v2'));
            system.assertEquals(setup.id,pr.getParameters().get('setupId'));
        Test.stopTest();
    }
}
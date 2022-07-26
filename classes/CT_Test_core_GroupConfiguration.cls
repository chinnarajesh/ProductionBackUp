@isTest
private class CT_Test_core_GroupConfiguration {
    @isTest static void test_core_GroupConfiguration(){
        testDataSetupUtil_v2.setUPCoreData(1);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUpStudentData(5);
    //  List <Section__c> sgroupList = testDataSetupUtil_v2.getScheduleGroups_Section();
        testDataSetupUtil_v2.activeSetUp.Group_Based__c=true;
        update testDataSetupUtil_v2.activeSetUp;
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            PageReference  p = Page.CT_core_GroupConfiguration;
            Test.setCurrentPage(p);
            ApexPages.currentPage().getParameters().put('setupId', testDataSetupUtil_v2.activeSetUp.id);
            CT_core_GroupConfiguration c = new CT_core_GroupConfiguration();
            
            PageReference pr = c.next();
            system.assertEquals(CT_core_GroupConfiguration.NO_GROUPS_MSG,ApexPages.getMessages()[0].getSummary());
            system.assertEquals(c.availableGroups.size(),0);
            c.addGroup();
            c.selectedGroup.Name='5A';
            c.selectedGroup.All_Grades__c='5';
            c.selectedGroup.Description__c='Nothing special';
            c.saveGroup();
            system.assertEquals(c.availableGroups.size(),1);
            System.currentPageReference().getParameters().put('selectedGroupId', c.selectedGroup.id);
            c.selectedGroupId = c.selectedGroup.id;
            
            c.editGroup();
            system.debug(c.availableStudents);
            system.assertEquals(c.availableStudents[0].size(),5);
            system.assertEquals(c.studentsInGroup.size(),0);
            c.availableStudents[0][0].bSelected = true;
            c.saveStudentList();
            system.assertEquals(c.availableStudents[0].size(),4);
            system.assertEquals(c.studentsInGroup[0].size(),1);
            c.studentsInGroup[0][0].bSelected = true;
            c.removeStudentsFromGroup();
            system.assertEquals(c.availableStudents[0].size(),5);
            system.assertEquals(c.studentsInGroup.size(),0);
            pr = c.prev();
            system.assert(pr.getURL().toLowerCase().contains('ct_schoolsetup_staff'));
            pr = c.next();
            if(TestDataSetupUtil_v2.activeSetup.Group_Based__c)
                system.assert(pr.getURL().toLowerCase().contains('ct_groupagendaview'));
            else
                system.assert(pr.getURL().toLowerCase().contains('ct_scheduler_grid'));
        }
        Test.stopTest();
    }
        
    @isTest static void testDeleteScheduleGroup(){

        testDataSetupUtil_v2.setUPCoreData(1);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUpStudentData(5);
        List <Section__c> sgroupList = testDataSetupUtil_v2.getScheduleGroups_Section();
        testDataSetupUtil_v2.activeSetUp.Group_Based__c=true;
        update testDataSetupUtil_v2.activeSetUp;
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            PageReference  p = Page.CT_core_GroupConfiguration;
            Test.setCurrentPage(p);
            ApexPages.currentPage().getParameters().put('setupId', testDataSetupUtil_v2.activeSetUp.id);
            CT_core_GroupConfiguration c = new CT_core_GroupConfiguration();
            /* test Delete US1719*/
            system.debug(c.availableGroups[0]);
            System.currentPageReference().getParameters().put('selectedGroupId', c.availableGroups[0].id);
            c.selectedGroupId = c.availableGroups[0].id;
            c.editGroupInfo();
            c.selectedGroup.Description__c='Nothing specialasdf';
            c.saveGroup();
            c.selectedGroupId = c.availableGroups[0].id;
            c.deleteGroup();
        }
        Test.stopTest();
    } //end test method 
}
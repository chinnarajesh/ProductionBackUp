@isTest
private class Test_Behavior_YOYDisplayController {
	@isTest static void testDisplayController(){
		testDataSetupUtil_v2.isBehavior=true;
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
		
		Behavior_Incident__c bi = new Behavior_Incident__c(Incident_Type__c = 'Negative'
                                                            ,Incident_Date__c = system.today()
                                                            ,Incident_Description__c = 'This is a test incident'
                                                            ,Incident_Title__c = 'Test Incident'
                                                            ,Incident_Time__c = '0730'
                                                            ,Context_Time__c = 'EDP-BeforeSchool'
                                                            ,Context_Location__c = 'Sidewalk/Street'
                                                            ,Weapon_Type__c = 'Bomb'
                                                            ,Other__c = true
                                                            ,Incident_Status__c = 'Draft'
                                                            ,Other_Notes__c = 'Test'
                                                            ,Selected_Behavior_Incident_Type__c = plList[2].id
                                                            ,Selected_Behavior_Category__c = 'Disruptive / Disrespectful'
                                                            ,Preserve__c = true
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[0].id,
        													Contact__c = testDataSetupUtil_v2.studContactsList[0].id,
                                                           Incident_Role__c = 'Instigator',
                                                           Behavior_Incident__c = bi.Id);
        insert sb;
        
        List<Consequence__c> consequences = new List<Consequence__c>();
        Map<String,Picklist_Value__c> pvString1 = core_SoqlUtils.getPlStringValues('Behavior Consequence', testDataSetupUtil_v2.activeSetUp.id);
        
        Consequence__c consequence1 = new Consequence__c(Student__c = sb.Id
                                                        ,Picklist_Value__c = pvString1.get('Other').id
                                                        ,Final_Consequence__c = false
                                                        ,Student_Consequence__c = sb.Student__c
                                                        );
        consequences.add(consequence1);
        
        Consequence__c consequence2 = new Consequence__c(Student__c = sb.Id
                                                        ,Picklist_Value__c = pvString1.get('Suspension').id
                                                        ,Final_Consequence__c = true
                                                        ,Student_Consequence__c = sb.Student__c
                                                      );
        consequences.add(consequence2);
        
        insert consequences;
        ApexPages.StandardController con = new ApexPages.StandardController(testDataSetupUtil_v2.studContactsList[0]);
        Behavior_YoyDisplayController controller = new Behavior_YoyDisplayController(con);
        
        system.assertEquals(1, controller.sbList.size());
        controller.selectedIncident = bi.id;
        controller.viewSingle();
        system.assertEquals(controller.redirectString, Page.BehaviorIncidentDetail.getURL() + '?id='+bi.id);
	}
	
}
@isTest
private class Test_BehaviorIncidentController {
	
	public static void setupData(){
		testDataSetupUtil_v2.isBehavior=true;
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
	}
	
    private static testmethod void TestNewConstructor() {
    	setupData();
    	
    	List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            Test.startTest();
                //set up the controller for a new record
                ApexPages.StandardController con = new ApexPages.StandardController(new Behavior_Incident__c());
                BehaviorIncidentController controller = new BehaviorIncidentController(con);
                
                //Expect the incident type to be negative
                system.assertEquals('Negative', controller.incident.Incident_Type__c);
                //Expect the AoD to be the current user
                system.assertEquals(testDataSetupUtil_v2.staffUsersList[1].ContactId, controller.incident.Adult_on_Duty__r.Individual__c);
                //Expect the system to be in search mode
                system.assertEquals(true, controller.showSearch);
            Test.stopTest();
        }
    }
    
    private static testmethod void TestExistingConstructor() {
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
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
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[0].id,
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
        
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            Test.startTest();
               ApexPages.StandardController con = new ApexPages.StandardController(bi);
               BehaviorIncidentController controller = new BehaviorIncidentController(con);
               
               system.assertEquals(bi.Id, controller.incident.id);
               system.assertEquals(controller.incident.Incident_Type__c, 'Negative');
               system.assertEquals(controller.stuWrapperList.size(), 1);
               system.assertEquals(controller.stuWrapperList[0].sb.Id, sb.Id);
               system.assertEquals(controller.stuWrapperList[0].conList.size(), 2);
               
               //Make sure the consequence id's are different.
               system.assert(controller.stuWrapperList[0].conList[0].id != controller.stuWrapperList[0].conList[1].id);
               
            Test.stopTest();
        }
    }
    
    private static testmethod void testAddStudent() {
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
      
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
           ApexPages.StandardController con = new ApexPages.StandardController(new Behavior_Incident__c());
           BehaviorIncidentController controller = new BehaviorIncidentController(con);
           
               
            Test.startTest();
               
               //can add a new student (on top of the one added by default)
               
               controller.startSearch();
               system.assertEquals(true, controller.showSearch);
               controller.searchInfo.Student_First_Name__c = testDataSetupUtil_v2.studentsList[0].Student_First_Name__c;
               controller.searchInfo.Student_Last_Name__c = testDataSetupUtil_v2.studentsList[0].Student_Last_Name__c;
               controller.searchStudents();
               
               //should have only got one student back
               system.assertEquals(1, controller.results.size());
               controller.results[0].selected = true;
               
               //add the student
               controller.searchAdd();
               system.assertEquals(1, controller.stuWrapperList.size());
            Test.stopTest();
        }
    }
    
    private static testmethod void testSaveFunctions() {
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
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
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[1].id
                                                           ,Incident_Role__c = 'Instigator'
                                                           ,Behavior_Incident__c = bi.Id
        );
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
        
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            ApexPages.StandardController con = new ApexPages.StandardController(bi);
            BehaviorIncidentController controller = new BehaviorIncidentController(con);
           
            Test.startTest();
                system.assertEquals(false, controller.bHasBeenSavedAsDraft);
                controller.incident.Other_Notes__c = 'Changed';
                controller.incident.Weapon_Type__c = 'Other Weapon';
                
                controller.saveDraft();
                
                Behavior_Incident__c incident = [select id, Other_Notes__c, Incident_Status__c, Weapon_Type__c from Behavior_Incident__c where id =: controller.incident.id];
                
                system.assertEquals('Draft', incident.Incident_Status__c);
                system.assertEquals('Other Weapon', incident.Weapon_Type__c);
                system.assertEquals('Changed', incident.Other_Notes__c);
                
           Test.stopTest();
        }
    }
    
    private static testmethod void testCancelFunctions() {
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
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
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[1].id
                                                           ,Incident_Role__c = 'Instigator'
                                                           ,Behavior_Incident__c = bi.Id
        );
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
        
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            ApexPages.StandardController con = new ApexPages.StandardController(bi);
            BehaviorIncidentController controller = new BehaviorIncidentController(con);
            
            Test.startTest();
                controller.studentInvolvedId = controller.stuWrapperList[0].id;
                controller.deleteStudent();
                system.assert(controller.stuWrapperList.size() == 0);
                
                //Quit without saving
                String behaviorTabURL = '/' + Schema.SObjectType.Behavior_Incident__c.getKeyPrefix() + '/o';
                system.assert(controller.escapeToBehaviorTab().getURL() == behaviorTabURL);
                
                List<Consequence__c> cons = [select id, Student__c from Consequence__c where Student__c =: sb.id];
                //Makes sure the conseuence wasn't deleted if there was no save.
                system.assert(cons.size() == 2);
                //Makes sure the student wasn't deleted if there was no save.
                system.assert([select id, Behavior_Incident__c from Student_Behavior__c where Behavior_Incident__c =: bi.id].size() == 1);
                
                delete sb;
                delete bi;
            Test.stopTest();
        }
    }
    
    private static testmethod void testNotifyFunctions() {
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
        Behavior_Incident__c bi;
        
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {
        
            bi = new Behavior_Incident__c(Incident_Type__c = 'Negative'
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
	                                      );
            insert bi;
            
            Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[1].id
                                                           ,Incident_Role__c = 'Instigator'
                                                           ,Behavior_Incident__c = bi.Id
        												);
			insert sb;
        }
        
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            ApexPages.StandardController con = new ApexPages.StandardController(bi);
            BehaviorIncidentController controller = new BehaviorIncidentController(con);

            Test.startTest();
                controller.canUserNotify = true;
                
                controller.notifyIncidentOwner();
                
                Behavior_Incident__c incident = [select id, Notify_Incident_Owner__c, Incident_Status__c from Behavior_Incident__c where id =: bi.id];
                //This is very hard to test. I may need to build this from the ground up without using the Test utilities.
                //system.assert(incident.Notify_Incident_Owner__c);
                system.assertEquals('Closed', incident.Incident_Status__c);
           Test.stopTest();
        } 
    }
    
    private static testmethod void testActionMethods() {
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
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
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[1].id
                                                           ,Incident_Role__c = 'Instigator'
                                                           ,Behavior_Incident__c = bi.Id
        );
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
        
        //Run the tests as a staff memeber, not as the current user.
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            ApexPages.StandardController con = new ApexPages.StandardController(bi);
            BehaviorIncidentController controller = new BehaviorIncidentController(con);
            
            Test.startTest();
                controller.fillBehaviorType();
                system.assertEquals(1, controller.behaviorTypeValues.size());
                
                controller.selBehType = plList[3].id;
                controller.displayWeaponType();
                system.assert(controller.hasWeapon);
                
                controller.incident.Selected_Behavior_Category__c = '--Please Select--';
                controller.fillBehaviorType();
                system.assertEquals(1, controller.behaviorTypeValues.size());
                system.assertEquals('--Please Select Category--', controller.behaviorTypeValues[0].getLabel());
                
                controller.displayWeaponType();
                system.assert(!controller.hasWeapon);
                system.assert(controller.incident.Weapon_Type__c == null);
            Test.stopTest();
        }
    }
    
    private static testmethod void testConsequenceFunctions(){
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
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
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[1].id
                                                           ,Incident_Role__c = 'Instigator'
                                                           ,Behavior_Incident__c = bi.Id
        );
        insert sb;
        
        List<Consequence__c> consequences = new List<Consequence__c>();
        Map<String,Picklist_Value__c> pvString1 = core_SoqlUtils.getPlStringValues('Behavior Consequence', testDataSetupUtil_v2.activeSetUp.id);
        
        Consequence__c consequence1 = new Consequence__c(Student__c = sb.Id
                                                        ,Picklist_Value__c = plList[0].id
                                                        ,Final_Consequence__c = true
                                                        ,Student_Consequence__c = sb.Student__c
                                                        );
        consequences.add(consequence1);
        
        insert consequences;
        
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            ApexPages.StandardController con = new ApexPages.StandardController(bi);
            BehaviorIncidentController controller = new BehaviorIncidentController(con);
            
            Test.startTest();
                
               //Assert this because testDataSetupUtil_v2 sometimes inserts two students.
               system.assertEquals(1, controller.stuWrapperList.size());
               
               //adding a consequence
               controller.studentInvolvedId = controller.stuWrapperList[0].id;
               controller.addConsequence();
               
               system.assertEquals(2, controller.stuWrapperList[0].conList.size());
               system.assertEquals(false, controller.stuWrapperList[0].hasSuspension);
               
               //change it's value
               pref.getParameters().put('selectedCon', plList[1].id);
               controller.activeConsequence = controller.stuWrapperList[0].conList[1].id;
               
               controller.storeCon();
               
               system.assertEquals(plList[1].id, controller.stuWrapperList[0].conList[1].con.Picklist_Value__c);
               system.assertEquals(true, controller.stuWrapperList[0].hasSuspension);
               
               //remove the consequence
               controller.removeCon();
               system.assertEquals(1, controller.stuWrapperList[0].conList.size());
               system.assertEquals(false, controller.stuWrapperList[0].hasSuspension);
               
               controller.activeConsequence = controller.stuWrapperList[0].conList[0].id;
               controller.removeCon();
               system.assertEquals(0, controller.stuWrapperList[0].conList.size());
               system.assertEquals(false, controller.stuWrapperList[0].hasSuspension);
               
               //trigger coverage
               controller.saveIncident();
               //the save shouldn't have errored out
               system.assertEquals(false, apexPages.hasMessages());
            Test.stopTest();   
        }
    }
        
	private static testmethod void testAttendanceUpdates(){
        setupData();
        List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
        
        PageReference pref = Page.BehaviorIncidentEdit;
        Test.setCurrentPage(pref);
        
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
                                                          );
        insert bi;
        
        Student_Behavior__c sb = new Student_Behavior__c(Student__c = testDataSetupUtil_v2.studentsList[1].id
                                                           ,Incident_Role__c = 'Instigator'
                                                           ,Behavior_Incident__c = bi.Id
        );
        insert sb;
        
        List<Consequence__c> consequences = new List<Consequence__c>();
        Map<String,Picklist_Value__c> pvString1 = core_SoqlUtils.getPlStringValues('Behavior Consequence', testDataSetupUtil_v2.activeSetUp.id);
        
        Consequence__c consequence1 = new Consequence__c(Student__c = sb.Id
                                                        ,Picklist_Value__c = plList[1].id
                                                        ,Final_Consequence__c = true
                                                        ,Student_Consequence__c = sb.Student__c
                                                        ,Show_Suspension_In_Attendance__c = true
                                                        ,Suspension_Start_Date__c = system.today()
                                                        ,Suspension_End_Date__c = system.today().addDays(7)
                                                        ,Days_Suspended__c = 7
                                                        ,Date_of_Re_entry__c = system.today().addDays(7)
                                                        ,Re_entry_Mtg_Time__c = '7:30'
                                                        ,Re_entry_Mtg_Date__c = system.today().addDays(7)
                                                        );
        consequences.add(consequence1);
        
        insert consequences;
        
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
            ApexPages.StandardController con = new ApexPages.StandardController(bi);
            BehaviorIncidentController controller = new BehaviorIncidentController(con);
            
            Test.startTest();
            	controller.saveIncident();
            	List<Attendance__c> att = [select Picklist_Value__c, Session_Date__c from Attendance__c where Student__c =: testDataSetupUtil_v2.studentsList[1].id];
            	
            	for(Attendance__c a:att){
            		system.assertEquals(plList[5].id, a.Picklist_Value__c);
            		system.assert(a.Session_Date__c >= system.today());
            		system.assert(a.Session_Date__c <= system.today().addDays(7));
            	}
            Test.stopTest();
        }
    }
}
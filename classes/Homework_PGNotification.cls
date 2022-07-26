global class Homework_PGNotification implements Database.Batchable<sObject>,Database.Stateful{
    public String query;
    public String email;
    global Set<Id> ustudents = new Set<Id>();
    global Map<String, Map<String, String>> mNotificationText;

    global Homework_PGNotification (String alerttype) {
        mNotificationText = core_SoqlUtils.getnotifymap(alerttype);
    }

    global database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for(sObject s : scope) {
            HW_Tracker__c hwTracker = (HW_Tracker__c ) s;
            for (Student_PG__c pg: Homework_SoqlUtils.getParentalInfo(hwTracker.Student__c)) {
                if ((pg.Parent_Guardian_c__r.Notify_via_Email__c && pg.Parent_Guardian_c__r.Email != null) 
                		||(pg.Parent_Guardian_c__r.Notify_via_SMS__c && pg.Parent_Guardian_c__r.Email_to_SMS_Address__c != null)){
                	
                	NotificationUtils.sendnotification sn;		
                    if (mNotificationText.containsKey(pg.Parent_Guardian_c__r.Preferred_Language__c + pg.Student__r.School__c)){
                		sn = new NotificationUtils.sendnotification(pg, mNotificationText.get(pg.Parent_Guardian_c__r.Preferred_Language__c + pg.Student__r.School__c));
                    } else {
                    	sn = new NotificationUtils.sendnotification(pg, mNotificationText.get('English' + pg.Student__r.School__c));
                    }
                    
                    ustudents.add(hwTracker.Student__c);
                }
            }
        }
    }// end execute   

    global void finish(Database.BatchableContext BC){
        List<HW_Tracker__c> updatehw = new List<HW_Tracker__c>();
        //Mark all HW Notifications as sent since even though First Notify only goes to missing, we don't want to send again on same day

        for (HW_Tracker__c hw : [Select Id, Student__c From HW_Tracker__c WHERE Student__c IN : ustudents]) {
            hw.Received_First_Alert__c = true;
            updatehw.add(hw);
        }
    
        try {
        	Database.update(updatehw, false); 
        } catch (Exception Ex) {
        }
    } // end finish

    @isTest static void testBatch(){
        TestDataSetupUtil_v2.setupCoreData(5);
        TestDataSetupUtil_v2.setupStaffData(5);
        TestDataSetupUtil_v2.setupStudentData(5);
        Test_Report_Card_Controller.generateHomework();
        Value__c hwNotification = new Value__c(Type__c='Homework Alerts', Communication_Type__c='Email', Language__c='English',Setup__c=TestDataSetupUtil_v2.activeSetup.id, Text_Alert__c='Test');
        insert hwNotification;
        Notification_Settings__c ns = new Notification_Settings__c(reply_to__c='test@test.com',display_name__c='Tester',Subject__c='Homework test');
        insert ns;

        Test.startTest();
            Homework_PGNotification batch = new Homework_PGNotification('Homework Alerts');
            batch.query='select id, Student__c from HW_Tracker__c';
            Database.executeBatch(batch);
        Test.stopTest();
    }
}
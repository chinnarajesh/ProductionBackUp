public with sharing class EOYWiz_OrgPurgeSettings {

    //EOY Progress
    public EOY_Progress__c orgWideProgress {get; set;}  
    public String EOYID {get; set;}
    public ID EOYrecordType {get; set;}
    
    //the containers for possible pcs states
    private Map<String, Purged_Object__c> initialPurgeCustomSettings {get; set;}
    private Map<String, Purged_Object__c> upsertPurgeCustomSettings {get; set;}
    private Map<String, Purged_Object__c> deletePurgeCustomSettings {get; set;}
    private Map<String, Purged_Object__c> suggestedPurgeCustomSettings {get; set;}

    //description and displayName Map
    private Map<String, String> pcDescription {get; set;}
    private Map<String, String> pcDisplayName {get; set;}

    //only two display lists for page
    public List<pcsWrapper> dPurgeCustomSettings {get; set;}
    public List<pcsWrapper> dSuggestedPurgeCustomSettings {get; set;}
    
    //page controls
    public String selectedRowName {get; set;}
    public Boolean unsaved {get; set;}
    
    //saving Naming convention
    private Integer N {get; set;}
    
    //static string error messages
    public static String warning1 = 'There are no Purge Custom Settings.';
    public static String warning2 = 'Purge Custom Settings have been edit.  Please save when you are done.';
    public static String warning3 = 'Purge Custom Settings are not finalized for this year yet.';
    public static String error1 = 'Error! Failed to upsert Purge Custom Settings.';
    public static String error2 = 'Error! Failed to query for Purge Custom Settings.';
    public static String error3 = 'Error! Failed to delete Purge Custom Settings.';
    public static String success1 = 'Success!  Purge Custom Settings have been saved.';
    public static String success2 = 'Success!  Purge Custom Settings have been finalized.';
    
    public EOYWiz_OrgPurgeSettings() {
        orgWideProgress = new EOY_Progress__c();
                
        initialPurgeCustomSettings = new Map<String, Purged_Object__c>();
        upsertPurgeCustomSettings = new Map<String, Purged_Object__c>();
        deletePurgeCustomSettings = new Map<String, Purged_Object__c>();
        suggestedPurgeCustomSettings = new Map<String, Purged_Object__c>();

        dPurgeCustomSettings = new List<pcsWrapper>();
        dSuggestedPurgeCustomSettings = new List<pcsWrapper>();
        
        selectedRowName = '';
        unsaved = false;
        N = 0;
        
        EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
        
        initialize();       
    }
    
    private void initialize() { 
        EOYID = apexPages.currentPage().getParameters().get('EOY_Progress');
        populateDescriptionDisplayName();
        getOrgPurgeSettingsProgress(EOYID);
        getInitialPurgeCustomSettings();
        
        selectAllSuggestedPurgeSettings();
        
        //no longer valid argument, by default have the display list contain all of the settings!
        /*
        if(initialPurgeCustomSettings.size() == 0) {
            apexPages.addMessage(new apexpages.message(apexpages.severity.WARNING, warning1));
        }
        */
        if(!orgWideProgress.EOY_Purge_Settings_Completed__c) {
            apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning3));
        }
    }
    
    public Boolean saveFunction() {
        Database.upsertResult[] results;
        Database.deleteResult[] deleteResults;
        //check the results
        Boolean successFlag = true;     
        
        //populate the name field
        for(Integer j = 0; j < upsertPurgeCustomSettings.Values().size(); j++) {
            if(upsertPurgeCustomSettings.Values()[j].Name == null || upsertPurgeCustomSettings.Values()[j].Name == '') {
                upsertPurgeCustomSettings.Values()[j].Name = String.valueOf(N += 1);
            }
        }

        try {
            if(upsertPurgeCustomSettings.Values().size() > 0) {
                system.debug('before Upserting: ' + upsertPurgeCustomSettings.Values());
                results = Database.upsert(upsertPurgeCustomSettings.Values());
            }

            if(results != null) {
                for(Database.upsertResult result : results) {
                    if(!result.isSuccess()) {
                        if(successFlag) {
                            successFlag = false;
                        }
                        Database.Error[] errs = result.getErrors();
                        for(Database.Error err : errs) {
                            system.debug(err.getStatusCode() + ' - ' + err.getMessage());               
                        }
                    }
                }
            }           
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, error1));
            successFlag = false;
        }
        
        try {
            if(deletePurgeCustomSettings.Values().size() > 0) {
                system.debug('before Deleting: ' + deletePurgeCustomSettings.Values());
                deleteResults = Database.delete(deletePurgeCustomSettings.Values());
            }
            
            if(deleteResults != null) {
                for(Database.deleteResult result : deleteResults) {
                    if(!result.isSuccess()) {
                        if(successFlag) {
                            successFlag = false;
                        }
                        Database.Error[] errs = result.getErrors();
                        for(Database.Error err : errs) {
                            system.debug(err.getStatusCode() + ' - ' + err.getMessage());               
                        }
                    }           
                }
            }                   
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, error3));
            successFlag = false;
        }   
        return successFlag; 	
    }
    
    public void savePCS() {
        if(saveFunction()) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success1));     
        }
        
        setLastModified();
        checkChanges();
                
        //clear all of the containers
        upsertPurgeCustomSettings.clear();
        deletePurgeCustomSettings.clear();
        initialPurgeCustomSettings.clear();
        dPurgeCustomSettings.clear();
        getInitialPurgeCustomSettings();
    }
    
    public void finalizePCS() {
    	if(saveFunction()) {
    		apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success2));
    	}
    	
        orgWideProgress.EOY_Purge_Settings_Completed__c = true;
        setLastModified();
        checkChanges();
                
        //clear all of the containers
        upsertPurgeCustomSettings.clear();
        deletePurgeCustomSettings.clear();
        initialPurgeCustomSettings.clear();
        dPurgeCustomSettings.clear();
        getInitialPurgeCustomSettings();        
    }

    //from suggested purge custom settings table
    /*
    public void addSelected() {
        for(pcsWrapper p : dSuggestedPurgeCustomSettings) {
            if(p.Selected) {
                upsertPurgeCustomSettings.put(p.pcs.Name__c, p.pcs);
                dPurgeCustomSettings.add(p);
            }
        }       
        setErrorMessage();
    }
    */
    
    //on main purge table
    public void editSelected() {
        selectedRowName = apexPages.currentPage().getParameters().get('selectedRowName');
        system.debug('selectedRowName: ' + selectedRowName);
        //updating a previously saved setting
        if(initialPurgeCustomSettings.containsKey(selectedRowName) && !upsertPurgeCustomSettings.containsKey(selectedRowName)) {
            Purged_Object__c edit = initialPurgeCustomSettings.get(selectedRowName);
            system.debug('*~*~* edit: ' + edit);
            upsertPurgeCustomSettings.put(selectedRowName, edit);
        }
        //updating a value that was just added to the display settings (from addAllsuggestedSettings) 
        //or in general, want to update based off the record in the upsert PurgeCustomSettings.
        else if(upsertPurgeCustomSettings.containsKey(selectedRowName)) {
            Purged_Object__c edit = upsertPurgeCustomSettings.get(selectedRowName);
            upsertPurgeCustomSettings.put(selectedRowName, edit);
        }

        //validate here
        validationDependency(selectedRowName);

        /*
        no longer a valid case
        //removing that change
        else if(initialPurgeCustomSettings.containsKey(selectedRowName) && upsertPurgeCustomSettings.containsKey(selectedRowName)) {
            if(initialPurgeCustomSettings.get(selectedRowName).Purged_EOY__c != upsertPurgeCustomSettings.get(selectedRowName).Purged_EOY__c) {
                upsertPurgeCustomSettings.remove(selectedRowName);
            }
        }
        */
        setErrorMessage();
    }
    
    //on main purge table
    /*
    //no longer used, requirement change such that display all suggested settings.
    public void removeSelected() {
        selectedRowName = apexPages.currentPage().getParameters().get('selectedRowName');
        system.debug('selectedRowName: ' + selectedRowName);
        if(upsertPurgeCustomSettings.containsKey(selectedRowName)) {
            upsertPurgeCustomSettings.remove(selectedRowName);
        }
        if(initialPurgeCustomSettings.containsKey(selectedRowName)) {
            deletePurgeCustomSettings.put(selectedRowName, initialPurgeCustomSettings.remove(selectedRowName));
        }
        
        //a little inefficient
        for(Integer i = 0; i < dPurgeCustomSettings.size(); i++) {
            if(dPurgeCustomSettings[i].pcs.Name__c == selectedRowName) {
                dPurgeCustomSettings.remove(i);
            }
        }
        
        setErrorMessage();
    }
    */
    
    public pageReference gotoEOYLandingPage() {
        pageReference p = new pageReference('/apex/EOYWiz_Landing');
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoOrgNextYear() {
        pageReference p = new pageReference('/apex/EOYWiz_OrgNextYear');
        p.getParameters().put('EOY_Progress', EOYID);
        p.setRedirect(true);
        return p;
    }
    
    public void checkChanges() {
        if(upsertPurgeCustomSettings.size() > 0 || deletePurgeCustomSettings.size() > 0) {
            unsaved = true;
        }
        else {
            unsaved = false;
        }
    }
    
    public void setLastModified() {
        //update the EOY Progress
        user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
        String timeZone = UserInfo.getTimeZone().getID();
        orgWideProgress.EOY_Purge_Settings_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
        upsert orgWideProgress;
        getOrgPurgeSettingsProgress(EOYID);     
    }       
    
    public void setErrorMessage() {
        //no longer valid argument
        if(upsertPurgeCustomSettings.size() > 0 || deletePurgeCustomSettings.size() > 0) {
            apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning2));
        }
        //no longer valid argument
        else if(upsertPurgecustomSettings.size() == 0) {    
            apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning3));
        }
        checkChanges();
    }
    
    public void getOrgPurgeSettingsProgress(String eID) {
        if(eID != null || eID != '') {
            system.debug('eoyID: ' + eID);
            orgWideProgress = [SELECT ID, EOY_Purge_Settings_Completed__c, EOY_Next_School_Year_Completed__c, EOY_Purge_Settings_Last_Modified__c, EOY_Next_School_Year_Last_Modified__c FROM EOY_Progress__c WHERE ID =: eID AND RecordTypeID =: EOYrecordType];
        }
        else {
            //should display error message here
            //but the first landing page would fail and not get to this point if eoyID was null
        }
    }
    
    public void getInitialPurgeCustomSettings() {
        try {
            for(Purged_Object__c po : [SELECT ID, Name, Name__c, Purged_EOY__c FROM Purged_Object__c ORDER BY Name ASC]) {
                initialPurgeCustomSettings.put(po.Name__c, po);
                //add to the display table for user
                pcsWrapper temp = new pcsWrapper(false, po);
                if(pcDisplayName.containsKey(po.Name__c)) {
                    temp.displayName = pcDisplayName.get(po.Name__c);
                }
                if(pcDescription.containsKey(po.Name__c)) {
                    temp.description = pcDescription.get(po.Name__c);
                }
                dPurgeCustomSettings.add(temp);
                if(Integer.valueOf(po.Name) > N) {
                    N = Integer.valueOf(po.Name);
                }
            }
        }
        catch(Exception e) {
            //apexPages.addMessage(new apexpages.message(apexpages.severity.FATAL, error2));
            system.debug('errorMessage: ' + e.getMessage());
        }
    }   
    
    public void getSuggestedPurgeCustomSettings() {
        //manually create these values for now always clear  
        suggestedPurgeCustomSettings.clear();
        dSuggestedPurgeCustomSettings.clear();
        
        //must manually check for specific objects: 24/25 counted
        if(!initialPurgeCustomSettings.containsKey('Alert__c') && !upsertPurgeCustomSettings.containsKey('Alert__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Alert__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Alert for Portal';
            //temp.description = 'Alerts for the Student/Parent Portal are crated on the Student, Section and School Records.  We recommend purging these every year since they will not display on the portal year over year.';
            suggestedPurgeCustomSettings.put('Alert__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Assessment added!
        //Assessment removed!  US1171, it was said Assessments are never purged! So we are removing this purge setting.  
        //Assessment added DE 3314
        if(!initialPurgecustomSettings.containsKey('Assesment__c') && !upsertPurgeCustomSettings.containsKey('Assesment__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Assesment__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Assessment';
            //temp.description = 'Assessment records are created from the Assessment Module and associated with the Student Record.  They are not related to the Gradebook.  Assessment records that are marked as \"Year over year?\" will be stored permanently.  We recommend purging all other assessment records every year.';
            suggestedPurgeCustomSettings.put('Assesment__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        
        if(!initialPurgeCustomSettings.containsKey('Assignment__c') && !upsertPurgeCustomSettings.containsKey('Assignment__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Assignment__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Assignment';
            //temp.description = 'Gradebook Assignments are stored with grade data and are available for teachers to view in the Gradebook for up to two years.  We recommend purging these every two years with grades.  SchoolForce will always keep high level GPA data for each student.';
            suggestedPurgeCustomSettings.put('Assignment__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Attendance__c') && !upsertPurgeCustomSettings.containsKey('Attendance__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Attendance__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Attendance';
            //temp.description = 'An Attendance record is the attendance status of a student for either a daily or sectional session.  We recommend purging these every two years with Session records.';
            suggestedPurgeCustomSettings.put('Attendance__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //question on spreadsheet: says validation on Notifications, but Notifications never gets deleted... need confirmation
        if(!initialPurgeCustomSettings.containsKey('Attendance_Tracking__c') && !upsertPurgeCustomSettings.containsKey('Attendance_Tracking__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Attendance_Tracking__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Attendance Tracking';
            //temp.description = 'Attendance Tracking records are used for Attendance notifications.  These records are not used in any reports so we recommend purging them every year.';
            suggestedPurgeCustomSettings.put('Attendance_Tracking__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Awards added!
        if(!initialPurgeCustomSettings.containsKey('Awards__c') && !upsertPurgeCustomSettings.containsKey('Awards__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Awards__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Award';
            //temp.description = 'Awards are created on the Student Record and may optionally display on the Student/Parent Portal.  Awards are not summarized or reported on so we recommend purging them every year.';
            suggestedPurgeCustomSettings.put('Awards__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Behavior_Incident__c') && !upsertPurgeCustomSettings.containsKey('Behavior_Incident__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Behavior_Incident__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Behavior';
            //temp.description = 'Behavior Incident that are marked \"Keep Permanently?\" are saved permanently.  All other Behavior Incidents will be purged.  We recommend purging every two years to have historical incident data.';
            suggestedPurgeCustomSettings.put('Behavior_Incident__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Consequence__c') && !upsertPurgeCustomSettings.containsKey('Consequence__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Consequence__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Consequence';
            //temp.description = 'Consequences are related to Behavior Incidents.  Any Consequence that is related to a Behavior Incident that is marked \"Keep Permanently?\" will be saved permanently.  All others will be purged.  We recommend purging every two years to have historical data.';
            suggestedPurgeCustomSettings.put('Consequence__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }       
        if(!initialPurgeCustomSettings.containsKey('Daily_Meal_Summary__c') && !upsertPurgeCustomSettings.containsKey('Daily_Meal_Summary__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Daily_Meal_Summary__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Daily Meal Summary';
            //temp.description = 'A Daily Meal Summary is created for those schools using the Meals Module.  Each Meal Summary is created daily as an overview of all meal transactions.  We recommend purging these yearly.';
            suggestedPurgeCustomSettings.put('Daily_Meal_Summary__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }       
        //External Resource added!
        if(!initialPurgeCustomSettings.containsKey('External_Resources__c') && !upsertPurgeCustomSettings.containsKey('External_Resources__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'External_Resources__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'External Resource';
            //temp.description = 'External Resources are associated with Gradebook Assignments that display on the Student Portal.  We recommend purging these every two years with Assignments.';
            suggestedPurgeCustomSettings.put('External_Resources__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        /*
        //Don't display to admins we will put this in the function that calls this
        if(!initialPurgeCustomSettings.containsKey('Global_Error__c') && !upsertPurgeCustomSettings.containsKey('Global_Error__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Global_Error__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            suggestedPurgeCustomSettings.put('Global_Error__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
        if(!initialPurgeCustomSettings.containsKey('Grade__c') && !upsertPurgeCustomSettings.containsKey('Grade__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Grade__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Grade';
            //temp.description = 'A Grade record is an individual grade given to one student on one assignment.  These records are related to Assignments.  We recommend purging them every two years and they must be purged with Assignments.';
            suggestedPurgeCustomSettings.put('Grade__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //HW_Tracker__c added!
        if(!initialPurgeCustomSettings.containsKey('HW_Tracker__c') && !upsertPurgeCustomSettings.containsKey('HW_Tracker__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'HW_Tracker__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Homework';
            //temp.description = 'Homework records are created if your school is using the Homework Module.  Each record indicates the status for each student on a Homework Assignment.  These records are not included in any summary snapshots or reports so we recomment purging them every year.';
            suggestedPurgeCustomSettings.put('HW_Tracker__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //marked this as a dead object?
        if(!initialPurgeCustomSettings.containsKey('HW_Assignment__c') && !upsertPurgeCustomSettings.containsKey('HW_Assignment__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'HW_Assignment__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'HW Assignment';
            //temp.description = 'Homework Assignments are used in the Homework Module.  We recommend purging these every year along with the Homework records.';
            suggestedPurgeCustomSettings.put('HW_Assignment__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Meal_Transaction__c') && !upsertPurgeCustomSettings.containsKey('Meal_Transaction__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Meal_Transaction__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Meal Transaction';
            //temp.description = 'A Meal Transaction is a specific transaction for a student per meal.  These transactions are summarized daily in the Daily Meal Summaries, and are summarized yearly in the Student Snapshot.  We recommend purging these transactions yearly.';
            suggestedPurgeCustomSettings.put('Meal_Transaction__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }       
        //Media__c added!
        if(!initialPurgeCustomSettings.containsKey('Media__c') && !upsertPurgeCustomSettings.containsKey('Media__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Media__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Media';
            //temp.description = 'Media records are created and associated to Gradebook Assignments.  These are populated on the Student/Parent Portal.  We recomment purging these every two years along with Gradebook Assignments.';
            suggestedPurgeCustomSettings.put('Media__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Period__c added!
        //removed 6/3/2013
        /*
        if(!initialPurgeCustomSettings.containsKey('Period__c') && !upsertPurgeCustomSettings.containsKey('Period__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Period__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Period';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Period__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
        if(!initialPurgeCustomSettings.containsKey('Points__c') && !upsertPurgeCustomSettings.containsKey('Points__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Points__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Points';
            //temp.description = 'Points record are created from the Points Module.  They are a record of a student\'s total Points per category.  We recommend purging them every year.';
            suggestedPurgeCustomSettings.put('Points__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Proactive_Attendance__c added!
        if(!initialPurgeCustomSettings.containsKey('Proactive_Attendance__c') && !upsertPurgeCustomSettings.containsKey('Proactive_Attendance__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Proactive_Attendance__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Proactive Attendance';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Proactive_Attendance__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Proactive_Demographics__c? added!
        if(!initialPurgeCustomSettings.containsKey('Proactive_Demographics__c') && !upsertPurgeCustomSettings.containsKey('Proactive_Demographics__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Proactive_Demographics__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false,po);
            //temp.displayName = 'Proactive Demographics';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Proactive_Demographics__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //used to be false, now is true?
        //removed 6/3/2013
        /*
        if(!initialPurgeCustomSettings.containsKey('Schedule_Day__c') && !upsertPurgeCustomSettings.containsKey('Schedule_Day__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Schedule_Day__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Schedule Day';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Schedule_Day__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
        //Schedule_Group__c added!
        //removed
        /*
        if(!initialPurgeCustomSettings.containsKey('Schedule_Group__c') && !upsertPurgeCustomSettings.containsKey('Schedule_Group__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Schedule_Group__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Schedule Group';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Schedule_Group__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
        //changed to true...
        //changed back to faluse
        /*
        if(!initialPurgeCustomSettings.containsKey('Schedule_Template__c') && !upsertPurgeCustomSettings.containsKey('Schedule_Template__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Schedule_Template__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Schedule Template';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Schedule_Template__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
        /*
        if(!initialPurgeCustomSettings.containsKey('Scheduled_Section__c') && !upsertPurgeCustomSettings.containsKey('Scheduled_Section__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Scheduled_Section__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Scheduled Section';
            //temp.description = 'TBD';
            suggestedPurgeCustomSettings.put('Scheduled_Section__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }       
        */
        if(!initialPurgeCustomSettings.containsKey('Session__c') && !upsertPurgeCustomSettings.containsKey('Session__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Session__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Session';
            //temp.description = 'A Session is related to Attendance and is the record for when a section meets on a specific day.  We recommend purging these every two years.';
            suggestedPurgeCustomSettings.put('Session__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Standard_Grade__c') && !upsertPurgeCustomSettings.containsKey('Standard_Grade__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Standard_Grade__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Standard Grade';
            //temp.description = 'A Standard Grade is calculated based on all assignments given on a specific standard for standards-based schools.  We recomment purging these every two years.';
            suggestedPurgeCustomSettings.put('Standard_Grade__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Strand Grade added!
        if(!initialPurgeCustomSettings.containsKey('Strand_Grade__c') && !upsertPurgeCustomSettings.containsKey('Strand_Grade__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Strand_Grade__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Strand Grade';
            //temp.description = 'A Strand Grade is the average grade of all the standards related to that Strand.  If your school is a standards-only school, Strands are calculated and may be displayed on Report Cards.  We recommend purging these every two years.';
            suggestedPurgeCustomSettings.put('Strand_Grade__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        //Student Document Logs/Document_Log__c
        //pretty sure document logs should be done in the background similarly like data load logs
        if(!initialPurgeCustomSettings.containsKey('Student_Behavior__c') && !upsertPurgeCustomSettings.containsKey('Student_Behavior__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Student_Behavior__c');
            po.Purged_EOY__c = false;
            pcsWrapper temp = new pcsWrapper(false, po);
            //temp.displayName = 'Student/Behavior';
            //temp.description = 'Student/Behavior is the backend intersection object between a Student and a Behavior Incident.  We recomment purging this object every two years with Behavior Incidents (Bheaviors marked \"Keep Permanently?\" will not be deleted).';
            suggestedPurgeCustomSettings.put('Student_Behavior__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }

        /*
        //should not purge at all?
        if(!initialPurgeCustomSettings.containsKey('Staff_Section__c') && !upsertPurgeCustomSettings.containsKey('Staff_Section__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Staff_Section__c');
            pcsWrapper temp = new pcsWrapper(false, po);
            suggestedPurgeCustomSettings.put('Staff_Section__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Notifications__c') && !upsertPurgeCustomSettings.containsKey('Notifications__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Notifications__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po); 
            suggestedPurgeCustomSettings.put('Notifications__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Student_Reporting_Period__c') && !upsertPurgeCustomSettings.containsKey('Student_Reporting_Period__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Student_Reporting_Period__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            suggestedPurgeCustomSettings.put('Student_Reporting_Period__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        if(!initialPurgeCustomSettings.containsKey('Section_ReportingPeriod__c') && !upsertPurgeCustomSettings.containsKey('Section_ReportingPeriod__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Section_ReportingPeriod__c');
            pcsWrapper temp = new pcsWrapper(false, po);
            suggestedPurgeCustomSettings.put('Section_ReportingPeriod__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }       
        */
        
        //keep previous functionality?
        /*
        //hide from admins
        if(!initialPurgeCustomSettings.containsKey('Snapshot_Log__c') && !upsertPurgeCustomSettings.containsKey('Snapshot_Log__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Snapshot_Log__c');
            po.Purged_EOY__c = true;
            pcsWrapper temp = new pcsWrapper(false, po);
            suggestedPurgeCustomSettings.put('Snapshot_Log__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
        
        /*
        Dead object
        if(!initialPurgeCustomSettings.containsKey('Schedule__c') && !upsertPurgeCustomSettings.containsKey('Schedule__c')) {
            Purged_Object__c po = new Purged_Object__c(Name__c = 'Schedule__c');
            pcsWrapper temp = new pcsWrapper(false, po);
            suggestedPurgeCustomSettings.put('Schedule__c', po);
            dSuggestedPurgeCustomSettings.add(temp);
        }
        */
    }       
    
    //internal wrapper class, used for display table
    public class pcsWrapper {
        public Boolean Selected {get; set;}
        public Purged_Object__c pcs {get; set;}
        public String description {get; set;}
        public String displayName {get; set;}
        
        public pcsWrapper(Boolean s, Purged_Object__c purgeCustomSetting) {
            Selected = s;
            pcs = purgeCustomSetting;
            description = '';
        }
    }
    
    private void selectAllSuggestedPurgeSettings() {
        getSuggestedPurgeCustomSettings();
        
        for(pcsWrapper p : dSuggestedPurgeCustomSettings) {
            p.Selected = true;
            if(pcDisplayName.containsKey(p.pcs.Name__c)) {
                p.displayName = pcDisplayName.get(p.pcs.Name__c);
            }
            if(pcDescription.containsKey(p.pcs.Name__c)) {
                p.description = pcDescription.get(p.pcs.Name__c);
            }
            upsertPurgeCustomSettings.put(p.pcs.Name__c, p.pcs);
            dPurgeCustomSettings.add(p);            
        }       
    }
    
    private void populateDescriptionDisplayName() {
        //literally 27 puts into a map!
        pcDescription = new Map<String, String>();
        pcDisplayName = new Map<String, String>();
        
        pcDisplayName.put('Alert__c', 'Alert for Portal');
        pcDescription.put('Alert__c', 'Alerts for the Student/Parent Portal are created on the Student, Section and School Records.  We recommend purging these every year since they will not display on the portal year over year.');
        
        pcDisplayName.put('Assesment__c', 'Assessment');
        pcDescription.put('Assesment__c', 'Assessment records are created from the Assessment Module and associated with the Student Record.  They are not related to the Gradebook.  Assessment records that are marked as \"Year over year?\" will be stored permanently.  We recommend purging all other assessment records every year.');
        
        pcDisplayName.put('Assignment__c', 'Assignment');
        pcDescription.put('Assignment__c', 'Gradebook Assignments are stored with grade data and are available for teachers to view in the Gradebook for up to two years.  We recommend purging these every two years with grades.  SchoolForce will always keep high level GPA data for each student.');
    
        pcDisplayName.put('Attendance__c', 'Attendance');
        pcDescription.put('Attendance__c', 'An Attendance record is the attendance status of a student for either a daily or sectional session.  We recommend purging these every two years with Session records.');

        pcDisplayName.put('Attendance_Tracking__c', 'Attendance Tracking');
        pcDescription.put('Attendance_Tracking__c', 'Attendance Tracking records are used for Attendance notifications.  These records are not used in any reports so we recommend purging them every year.');              
    
        pcDisplayName.put('Awards__c', 'Award');
        pcDescription.put('Awards__c', 'Awards are created on the Student Record and may optionally display on the Student/Parent Portal.  Awards are not summarized or reported on so we recommend purging them every year.');
        
        pcDisplayName.put('Behavior_Incident__c', 'Behavior');
        pcDescription.put('Behavior_Incident__c', 'Behavior Incident that are marked \"Keep Permanently?\" are saved permanently.  All other Behavior Incidents will be purged.  We recommend purging every two years to have historical incident data.');
        
        pcDisplayName.put('Consequence__c', 'Consequence');
        pcDescription.put('Consequence__c', 'Consequences are related to Behavior Incidents.  Any Consequence that is related to a Behavior Incident that is marked \"Keep Permanently?\" will be saved permanently.  All others will be purged.  We recommend purging every two years to have historical data.');
        
        pcDisplayName.put('Daily_Meal_Summary__c', 'Daily Meal Summary');
        pcDescription.put('Daily_Meal_Summary__c', 'A Daily Meal Summary is created for those schools using the Meals Module.  Each Meal Summary is created daily as an overview of all meal transactions.  We recommend purging these yearly.');
        
        pcDisplayName.put('External_Resources__c', 'External Resource');
        pcDescription.put('External_Resources__c', 'External Resources are associated with Gradebook Assignments that display on the Student Portal.  We recommend purging these every two years with Assignments.');
        
        pcDisplayName.put('Grade__c', 'Grade');
        pcDescription.put('Grade__c', 'A Grade record is an individual grade given to one student on one assignment.  These records are related to Assignments.  We recommend purging them every two years and they must be purged with Assignments.');
        
        pcDisplayName.put('HW_Tracker__c', 'Homework');
        pcDescription.put('HW_Tracker__c', 'Homework records are created if your school is using the Homework Module.  Each record indicates the status for each student on a Homework Assignment.  These records are not included in any summary snapshots or reports so we recommend purging them every year.');
        
        pcDisplayName.put('HW_Assignment__c', 'HW Assignment');
        pcDescription.put('HW_Assignment__c', 'Homework Assignments are used in the Homework Module.  We recommend purging these every year along with the Homework records.');
        
        pcDisplayName.put('Meal_Transaction__c', 'Meal Transaction');
        pcDescription.put('Meal_Transaction__c', 'A Meal Transaction is a specific transaction for a student per meal.  These transactions are summarized daily in the Daily Meal Summaries, and are summarized yearly in the Student Snapshot.  We recommend purging these transactions yearly.');
        
        pcDisplayName.put('Media__c', 'Media');
        pcDescription.put('Media__c', 'Media records are created and associated to Gradebook Assignments.  These are populated on the Student/Parent Portal.  We recommend purging these every two years along with Gradebook Assignments.');
        
        //pcDisplayName.put('Period__c', 'Period');
        //pcDescription.put('Period__c', 'Period is the time that a section meets in a period based school. We recommend purging this object every year.');
        
        pcDisplayName.put('Points__c', 'Points');
        pcDescription.put('Points__c', 'Points record are created from the Points Module.  They are a record of a student\'s total Points per category.  We recommend purging them every year.');
        
        pcDisplayName.put('Proactive_Attendance__c', 'Proactive Attendance');
        pcDescription.put('Proactive_Attendance__c', 'Proactive Attendance returns the count of your school\'s active students\' homeroom attendance status for a specified period of time. The attendance count translates and returns each SchoolForce attendance status in a format that is accepted by OSSE. We recommend purging this object every year.');
        
        pcDisplayName.put('Proactive_Demographics__c', 'Proactive Demographics');
        pcDescription.put('Proactive_Demographics__c', 'Proactive Demographics returns the demographic data required by OSSE for each of your school\'s active students. The data extracted is translated into a format that is OSSE acceptable. We recommend purging this object every year.');
        
        //pcDisplayName.put('Schedule_Day__c', 'Schedule Day');
        //pcDescription.put('Schedule_Day__c', 'Schedule Day represents a day on the calendar (date and schedule template). We recommend Schedule Day be purged every year.');
        
        //pcDisplayName.put('Schedule_Group__c', 'Schedule Group');
        //pcDescription.put('Schedule_Group__c', 'Schedule Group represents groups of students that attend the same classes at the same time. We recommend purging this object every year.');
        
        //pcDisplayName.put('Schedule_Template__c', 'Schedule Template');
        //pcDescription.put('Schedule_Template__c', 'Schedule Template is the shell for the start and end time of each school day. In period based schools, schedule templates also have the start and end time for each period. We recommend purging this object every year.');
        
        //pcDisplayName.put('Scheduled_Section__c', 'Scheduled Section');
        //pcDescription.put('Scheduled_Section__c', 'Scheduled Sections represent sections that have been scheduled on either the grid or the agenda view.');
        
        pcDisplayName.put('Session__c', 'Session');
        pcDescription.put('Session__c', 'A Session is related to Attendance and is the record for when a section meets on a specific day.  We recommend purging these every two years.');
        
        pcDisplayName.put('Standard_Grade__c', 'Standard Grade');
        pcDescription.put('Standard_Grade__c', 'A Standard Grade is calculated based on all assignments given on a specific standard for standards-based schools.  We recommend purging these every two years.');

        pcDisplayName.put('Strand_Grade__c', 'Strand Grade');
        pcDescription.put('Strand_Grade__c', 'A Strand Grade is the average grade of all the standards related to that Strand.  If your school is a standards-only school, Strands are calculated and may be displayed on Report Cards.  We recommend purging these every two years.');
        
        pcDisplayName.put('Student_Behavior__c', 'Student/Behavior');
        pcDescription.put('Student_Behavior__c', 'Student/Behavior is the backend intersection object between a Student and a Behavior Incident.  We recommend purging this object every two years with Behavior Incidents (Behaviors marked \"Keep Permanently?\" will not be deleted).');                                                                                                                                                                         
    }
    
    public void validationDependency(String pcsName) {
        if(upsertPurgeCustomSettings.containsKey(pcsName)) {
            
            //update Map
            //Map<String, Purged_Object__c> updatePurgeCustomSettings = initialPurgeCustomSettings;
            
            Purged_Object__c pcs = upsertPurgeCustomSettings.get(pcsName);
            if(pcs.Name__c == 'Assignment__c') {
                //set the Grades, External Resources, Media
                setDependency(pcs, 'Grade__c');
                setDependency(pcs, 'External_Resources__c');
                setDependency(pcs, 'Media__c');
            }
            
            else if(pcs.Name__c == 'Attendance__c') {
                //set the Session
                setDependency(pcs, 'Session__c');
            }
            
            else if(pcs.Name__c == 'Behavior_Incident__c') {
                //set the consequences, student_behavior
                setDependency(pcs, 'Consequence__c');
                setDependency(pcs, 'Student_Behavior__c');                          
            }
            
            else if(pcs.Name__c == 'Consequence__c') {
                setDependency(pcs, 'Behavior_Incident__c');
                setDependency(pcs, 'Student_Behavior__c');          
            }
            
            else if(pcs.Name__c == 'External_Resources__c') {
                setDependency(pcs, 'Grade__c');
                setDependency(pcs, 'Media__c');
                setDependency(pcs, 'Assignment__c');
            }
            
            else if(pcs.Name__c == 'Grade__c') {
                setDependency(pcs, 'External_Resources__c');
                setDependency(pcs, 'Assignment__c');
                setDependency(pcs, 'Media__c');
            }
            
            //7/30/2013: added '__c' on Daily_Meal_Summary...
            else if(pcs.Name__c == 'Meal_Transaction__c') {
                setDependency(pcs, 'Daily_Meal_Summary__c');           
            }
            
            else if(pcs.Name__c == 'Media__c') {
                setDependency(pcs, 'External_Resources__c');
                setDependency(pcs, 'Assignment__c');
                setDependency(pcs, 'Grade__c');     
            }
            
            /*
            else if(pcs.Name__c == 'Schedule_Day__c') {
                setDependency(pcs, 'Schedule_Template__c');
                setDependency(pcs, 'Scheduled_Section__c');
                setDependency(pcs, 'Period__c');            
            }
            */
            
            /*
            else if(pcs.Name__c == 'Schedule_Group__c') {
                setDependency(pcs, 'Scheduled_Section__c');            
            }
            */
            /*
            else if(pcs.Name__c == 'Schedule_Template__c') {
                setDependency(pcs, 'Schedule_Day__c');
                setDependency(pcs, 'Scheduled_Section__c');
                setDependency(pcs, 'Period__c');                                        
            }
            */
            /*
            else if(pcs.Name__c == 'Scheduled_Section__c') {
                //setDependency(pcs, 'Schedule_Group__c');            
            }
            */
            else if(pcs.Name__c == 'Session__c') {
                setDependency(pcs, 'Attendance__c');            
            }
            
            else if(pcs.Name__c == 'Student_Behavior__c') {
                setDependency(pcs, 'Consequence__c');
                setDependency(pcs, 'Behavior_Incident__c');                 
            }
            
            else {
                
            }
            
            //in the end, putAll of the upsert changes in: initial + upsert, and take the value list and display that.
            //updatePurgeCustomSettings.putAll(upsertPurgeCustomSettings);
            //clear the dPurgeCustomSettings and rebuild it?
            //dPurgeCustomSettings.clear();
            for(pcsWrapper p : dPurgeCustomSettings) {
                if(upsertPurgeCustomSettings.containsKey(p.pcs.Name__c)) {
                    p.pcs.Purged_EOY__c = upsertPurgeCustomSettings.get(p.pcs.Name__c).Purged_EOY__c;
                }
            }
        }
    }
    
    public void setDependency(Purged_Object__c pcs, String keyName) {
        Purged_Object__c validate;
        if(initialPurgeCustomSettings.containsKey(keyName)) {
            validate = initialPurgeCustomSettings.get(keyName);
        }
        else if(upsertPurgeCustomSettings.containsKey(keyName)) {
            validate = upsertPurgeCustomSettings.get(keyName);
        }               
        validate.Purged_EOY__c = pcs.Purged_EOY__c;
        upsertPurgeCustomSettings.put(keyName, validate);       
    }
}
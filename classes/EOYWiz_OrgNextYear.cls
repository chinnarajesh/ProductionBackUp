public with sharing class EOYWiz_OrgNextYear {

    //EOY Progress
    public EOY_Progress__c orgWideProgress {get; set;}
    public String EOYID {get; set;}
    
    //time element container
    public Time_Element__c activeYear {get; set;}
    public Time_Element__c nextYear {get; set;}
    
    //used to check for changes
    public Boolean unsaved {get; set;}
    public Boolean InitializationError {get; set;}
    public ID EOYrecordType {get; set;}
    
    //static string error messages
    public static String warning1 = 'The next school year has been updated. Please save when you are done editing.';
    public static String warning2 = 'The next school year is not finalized for the following year yet.';
    public static String error1 = 'Error! Failed to upsert the next school year.';
    public static String error2 = 'Error! Completed this step but does not have a next school year!';
    public static String success1 = 'Success! The next school year is currently saved as it appears.';
    public static String success2 = 'Success! The next school year is currently finalized as it appears.';
    
    public EOYWiz_OrgNextYear() {
        orgWideProgress = new EOY_Progress__c();
        
        activeYear = new Time_Element__c();
        activeYear.Date_Start_Date__c = null;
        activeYear.End_Date__c = null;
        nextYear = new Time_Element__c(New_School_Year__c=true);
        nextYear.Date_Start_Date__c = null;
        nextYear.End_Date__c = null;
        
        unsaved = false;
        initializationError = false;
        EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
                
        initialize();
    }
    
    private void initialize() {
        EOYID = apexPages.currentPage().getParameters().get('EOY_Progress');
        getOrgNextYearProgress(EOYID);
        //populateYearInformation();
    }
    
    public pageReference gotoEOYExport() {
        pageReference p = new pageReference('/apex/EOYWiz_OrgExport');
        p.getParameters().put('EOY_Progress', EOYID);
        p.setRedirect(true);
        return p;
    }   
    
    public pageReference gotoOrgPurgeSettings() {
        pageReference p = new pageReference('/apex/EOYWiz_OrgPurgeSettings');
        p.getParameters().put('EOY_Progress', EOYID);
        p.setRedirect(true);
        return p;
    }   
    
    public void fieldEditedMessage() {
        apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning1));
    }
    
    public void fieldUnEditedMessage() {
        apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning2));
    }   
    
    public Boolean saveFunction() {
        Database.upsertResult results;
        //check the results
        Boolean successFlag = true;     
    
        try {
            system.debug('before Upserting: ' + nextYear);
            results = Database.upsert(nextYear);    

            if(results != null) {
                if(!results.isSuccess()) {
                    if(successFlag) {
                        successFlag = false;
                    }
                    Database.Error[] errs = results.getErrors();
                    for(Database.Error err : errs) {
                        system.debug(err.getStatusCode() + ' - ' + err.getMessage());               
                    }
                }
            }
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.severity.FATAL, error1));
            successFlag = false;
        }
        return successFlag;    	
    }
    
    public void saveNextYear() {
        if(saveFunction()) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success1));     
        }       
        
        //populateYearInformation();
        setLastModified();
        unsaved = false;
    }
    
    public void finalizeNextYear() {
        if(nextYear.Date_Start_Date__c != null && nextYear.End_Date__c != null && (nextYear.Name__c != null && nextYear.Name__c != '')) {
            try {
            	upsert nextYear;
	            orgWideProgress.EOY_Next_School_Year_Completed__c = true;
	            //saveNextYear();
	            if(saveFunction()) {
	            	apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success2));
	            }
	            setLastModified();
	            unsaved = false;            	
            }
            catch(Exception e) {
            	//apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, e.getMessage()));
            }

            
        }
        else {
            if(nextYear.Name__c == null || nextYear.Name__c == '') {
                apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'Error! The name is empty.'));
            }
            if(nextYear.Date_Start_Date__c == null) {
                apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'Error! The Start date is empty.'));
            }
            if(nextYear.End_Date__c == null) {
                apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'Error! The End date is empty.'));
            }
        }
    }
    
    public void setLastModified() {
        //update the EOY Progress
        user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
        String timeZone = UserInfo.getTimeZone().getID();
        orgWideProgress.EOY_Next_School_Year_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
        upsert orgWideProgress;
        getOrgNextYearProgress(EOYID);      
    }       
    
    public void getOrgNextYearProgress(String eID) {
        if(eID != null || eID != '') {
            system.debug('eoyID: ' + eID);
            orgWideProgress = [SELECT ID, EOY_Next_School_Year_Completed__c, EOY_Next_School_Year_Last_Modified__c FROM EOY_Progress__c WHERE ID =: eID AND EOY_Purge_Settings_Completed__c = true AND RecordTypeID =: EOYrecordType];
        }
        else {
            //should display error message here
            //but the first landing page would fail and not get to this point if eoyID was null
        }       
    }
    
    public void populateYearInformation() {
        //DE3150
        //updated validation logic even more.
        List<Time_Element__c> activeYears = new List<Time_Element__c>();
        List<Time_Element__c> nextYears = new List<Time_Element__c>();
        
        ID rtID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Time');
        Picklist_Value__c yearPLV = [SELECT ID FROM Picklist_Value__c WHERE Type__c = 'Time' AND Name='Year' AND RecordTypeID =: rtID LIMIT 1];
        system.debug('yearPLV: ' + yearPLV);
            for(Time_Element__c year : [SELECT ID, Name__c, Date_Start_Date__c, End_Date__c, Current__c, New_School_Year__c FROM Time_Element__c WHERE Picklist_Value__c =: yearPLV.ID AND ((Current__c = true AND New_School_Year__c = false) OR (New_School_Year__c = true AND Current__c = false) OR (New_School_Year__c = true AND Current__c = true)) ORDER BY Current__c DESC]) {
                if(year.Current__c && year.New_School_Year__c && !initializationError) {
                    activeYears.add(year);
                    nextYears.add(year);
                    apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'There is a year marked \'Current\' and \'Next School Year\'.  Please verify the time elements'));
                    initializationError = true;
                    break;
                }
                
                if(year.Current__c && !initializationError) {
                    activeYears.add(year);
                    if(activeYears.size() > 1) {
                        apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'There are multiple years that are marked \'Current\'. Please verify the year time elements'));
                        initializationError = true;
                        break;
                    }
                }   
                
                if(year.New_School_Year__c && !initializationError) {
                    nextYears.add(year);
                    if(nextYears.size() > 1) {
                        apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'There are multiple years that are marked \'New School Year\'.  Please verify the year time elements.'));                  
                        initializationError = true;
                        break;
                    }
                }
            }
            
            if(!initializationError) {
                if(activeYears.size() == 1) {
                    activeYear = activeYears[0];
                }
                else if(activeYears.size() == 0) {
                    apexPages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'There are no years that are marked \'Current\'. Please verify the current year.'));
                    initializationError = true;
                }
                
                if(nextYears.size() == 1) {
                    nextYear = nextYears[0];
                }
                else if(nextYears.size() == 0) {
                    //should warn users to create a net next year! that is part of the process.
                    //Apexpages.addMessage(new apexPages.message(apexPages.severity.WARNING, 'There are no years that are marked \'New School Year\'.  Please create a New School Year.'));
                    //createYearMessage();
                    nextYear = new Time_Element__c(Picklist_Value__c = yearPLV.ID, New_School_Year__c = true, Date_Start_Date__c = activeYear.End_Date__c.addDays(1), End_Date__c = activeYear.End_Date__c.addYears(1));
                    system.debug('*~*~* nextYear: ' + nextYear);
                    nextYear.Name__c = 'Enter Year Name';
                    //insert nextYear;
                }
                
                if(!orgWideProgress.EOY_Next_School_Year_Completed__c && nextYear.ID != null && activeYear.ID != null && !initializationError) {
                    apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning2));
                }
            }
        
    }
}
public with sharing class EOYWiz_SchoolGradeSpan {
    
    //School Progress
    public EOY_Progress__c schoolProgress {get; set;}
    public String EOYID {get; set;}
    public ID EOYrecordType {get; set;}
    
    //specifically for School Step 1
    public Time_Element__c activeYear {get; set;}
    public Time_Element__c nextYear {get; set;}
    
    public Setup__c activeSetup {get; set;}
    public Setup__c nextSetup {get; set;}
    
    //used to check for changes in grade span
    public Boolean unsaved {get; set;}
    public String currentNextGradeSpan {get; set;}
    
    public static String warning1 = 'The grade span has been edited. Please save when you are done.';
    public static String warning2 = 'The grade span is not finalized for the next school year.';
    public static String error1 = 'Error! Failed to update the grade span for the next school year.';
    public static String success1 = 'Success! The grade span for the next school year is updated.';
    public static String success2 = 'Success! The grade span for the next school year is finalized.';
    
    public EOYWiz_SchoolGradeSpan() {
        schoolProgress = new EOY_Progress__c();
        EOYID = '';
        
        activeYear = new Time_Element__c();
        nextYear = new Time_Element__c();
        
        activeSetup = new Setup__c();
        nextSetup = new Setup__c();
        
        unsaved = false;
        currentNextGradeSpan = '';
        EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
        initialize();
    }
    
    private void initialize() {
        populateYearInformation();
        getSchoolProgress();
        getSchoolSetups();
        
        if(!schoolProgress.School_Grade_Span_Completed__c) {
            apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning2));
        }       
    }
    
    public pageReference gotoEOYLandingPage() {
        pageReference p = new pageReference('/apex/EOYWiz_Landing');
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolStudentPromotional() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolStudentPromotional');
        p.getParameters().put('selectedProgress', EOYID);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);
        p.setRedirect(true);
        return p;
    }   
    
    public void editNextGradeSpan() {
        if(currentNextGradeSpan != nextSetup.grade_span__c) {
            apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning1));
            unsaved = true;
        }
        else {
            apexPages.addMessage(new apexPages.message(apexPages.severity.WARNING, warning2));
            unsaved = false;
        }
    }
    
    public Boolean saveFunction() {
        Database.upsertResult results;
        
        try {
            system.debug('before Upserting: ' + nextSetup);
            results = Database.upsert(nextSetup);   
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.severity.FATAL, error1));
        }
        
        Boolean successFlag = true;
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
        return successFlag;    	
    }
    
    public void saveNextSetup() {
        if(saveFunction()) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success1));
        }
        
        setLastModified();
        unsaved = false;
    }   
    
    public void finalizeNextSetup() {
        if(nextSetup.grade_span__c != null) {
            schoolProgress.School_Grade_Span_Completed__c = true;
            //saveNextSetup();
        	if(saveFunction()) {
        		apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success2));
        	}
        	setLastModified();
        	unsaved = false;
        }
        else {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'Error! The grade span is not acceptable.'));
        }
    }
    
    public void setLastModified() {
        user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
        String timeZone = UserInfo.getTimeZone().getID();
        schoolProgress.School_Grade_Span_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
        upsert schoolProgress;
        getSchoolProgress();
        getSchoolSetups();
    }
    
    public void getSchoolProgress() {
        EOYID = apexPages.currentPage().getParameters().get('selectedProgress');        
        if(EOYID != null || EOYID != '') {
            system.debug('eoyID: ' + EOYID);
            schoolProgress = [SELECT ID, School_Grade_Span_Completed__c, School_Grade_Span_Last_Modified__c, School__c, School__r.Name, Setup__c FROM EOY_Progress__c WHERE ID =: EOYID AND Year__c =: activeYear.ID AND RecordTypeID =: EOYrecordType];
        }
        else {
            //should display an error message here
        }
    }
    
    private void populateYearInformation() {
        String activeYearID = apexPages.currentPage().getParameters().get('activeYear');
        String nextYEarID = apexPages.currentPage().getParameters().get('nextYear');
        
        for(Time_Element__c y : [SELECT ID, Name__c, Date_Start_Date__c, End_Date__c, Current__c, New_School_Year__c FROM Time_Element__c WHERE ID =: activeYearID OR ID =: nextYearID]) {
            if(y.Current__c) {
                activeYear = y;
            }
            else if(y.New_School_Year__c) {
                nextYear = y;
            }
        }
    }   
    
    private void getSchoolSetups() {
        try {
            activeSetup = [SELECT ID, Grade_Span__c, Year__c, Year__r.Name__c, School__c, School__r.Name FROM Setup__c WHERE ID =: schoolProgress.Setup__c];
            nextSetup = [SELECT ID, Grade_Span__c, Year__c, Year__r.Name__c, School__c, School__r.Name FROM Setup__c WHERE Year__c =: nextYear.ID AND School__c =: schoolProgress.School__c];
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'Error! Failed to get school setups.'));
        }
        
        /*
        for(String g : nextSetup.Grade_Span__c.split(',')) {
            currentNextGradeSpan.add(g);
            system.debug('currentNextGradeSpan: ' + currentNextGradeSpan);
        }
        */
        currentNextGradeSpan = nextSetup.Grade_Span__c;
    }
}
public with sharing class EOYWiz_OrgExport {

    //EOY Progress
    public EOY_Progress__c orgWideProgress {get; set;}
    public String EOYID {get; set;}
    public Folder EOYFolder {get; set;}
    public Boolean initializationError {get; set;}
    public ID EOYrecordType {get; set;}
    
    //static string error messages
    public static String error1 = 'Error! Organization Setup has not been completed!';
    public static String error2 = 'Error! Please create a folder to store EOY Reports.';
    
    public EOYWiz_OrgExport() {
        orgWideProgress = new EOY_Progress__c();
        initializationError = false;
        EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
        initialize();
    }
    
    private void initialize() {
        EOYID = apexPages.currentPage().getParameters().get('EOY_Progress');
        getOrgWideProgress();
        getReportFolder();
    }
    
    public pageReference gotoEOYLanding() {
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
    
    public void getOrgWideProgress() {
        if(EOYID != null || EOYID != '') {
            system.debug('eoyID: ' + EOYID);
            orgWideProgress = [SELECT ID, EOY_Purge_Settings_Completed__c, EOY_Next_School_Year_Completed__c FROM EOY_Progress__c WHERE ID =: EOYID AND RecordTypeID =: EOYrecordType];
        }
        else {
            //should display error message here
            //but the first landing page would fail and not get this point if eoyID was null
        }
        if(!orgWideProgress.EOY_Purge_Settings_Completed__c || !orgWideProgress.EOY_Next_School_Year_Completed__c) {
            if(!initializationError) {
                initializationError = true;
            }
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, error1));
        }
    }
    
    public void getReportFolder() {
        if(!initializationError) {
            try{
                EOYFolder = [SELECT Id FROM Folder WHERE Type = 'Report' AND Name ='EOY Process Folder'];
            }
            catch(Exception e){
                if(!initializationError) {
                    initializationError = true;
                }
                ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, error2));
            }
        }
    }
}
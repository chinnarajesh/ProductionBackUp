public with sharing class CT_SchoolSetup_Finish {
    public Setup__c schoolSetup			{get;set;}

    public CT_SchoolSetup_Finish() {
        if(System.currentPageReference().getParameters().containsKey('setupid')) {
            Id setupId = System.currentPageReference().getParameters().get('setupid');
            if (setupId != null) {
                schoolSetup = CT_SetupWizard_Utils.getSetupById(setupId);
            }
        }
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'All data has been successfully published and activated!');
    }

    public PageReference prev(){
        return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.SCHEDULE,false,schoolSetup);
    }
}
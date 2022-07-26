public with sharing class CT_SchoolSetup_StudentSections {
    public Id setupId       {get;set;}
    public CT_core_LoadCsvData csvLoader    {get;set;}

    public CT_core_SetupWrapper	cSetup {get;set;} // setup wrapper for the setup with id setupId
    public List<Id> termIds {get;set;}
    public List<Term__c> selectedTermObjectsInSetup {get;set;}
    public Boolean bOccupancyError {get;set;}
    public List<String> termsToPublish {get;set;}

    public CT_SchoolSetup_StudentSections(){
        bOccupancyError = false;
        termsToPublish = new List<String>();
        if(System.currentPageReference().getParameters().containsKey('setupid')){
            setupId = System.currentPageReference().getParameters().get('setupid');
            if(setupId!=null){
                csvLoader = new CT_core_LoadCsvData();
                csvLoader.selectedLoadType = 'Student/Section';
                csvLoader.changeLink();
                csvLoader.bNeedsType=false;
                cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'Create Student/Sections');
                termIds = getSetupTermsFromTermObject();
                checkTermsOccupancy();
            }
            else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
        }
        else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
    }

    public PageReference prev(){
        System.debug('\n\n previos \n');
        return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.SCHEDULE,false,CT_SetupWizard_Utils.getSetupById(setupId));
    }

    public PageReference next(){
        csvLoader.cSetup.setup.Verification_Status__c = 'Verification';
        update csvLoader.cSetup.setup;
        return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.FINISH,false,CT_SetupWizard_Utils.getSetupById(setupId));
    }


    /* ========================================================= */
    /*     Additional code by Sergey Prishchepa
    /* ========================================================= */
    private List<Id> getSetupTermsFromTermObject() {
        List<Id> termIds = new List<Id>();
        System.debug('\n\n cSetup.setup.Id => ' + cSetup.setup.Id + '\n');

        selectedTermObjectsInSetup = [SELECT Id, Time_Element__r.Id, Time_Element__r.Name__c FROM Term__c WHERE Setup__c =: cSetup.setup.Id];
        for (Term__c selectedTerm : selectedTermObjectsInSetup) {
            termIds.add(selectedTerm.Time_Element__r.Id);
            termsToPublish.add(selectedTerm.Time_Element__r.Name__c);
        }
        return termIds;
    }

    private void checkTermsOccupancy() {
        Boolean sectionsChecked;
        List<Time_Element__c> reportingPeriodsWithChildren = [SELECT Id, Name__c, parent_time_element__c, parent_time_element__r.Name__c,
            (SELECT Id, Name FROM Sections1__r),
            (SELECT Id, Name FROM Scheduled_Sections__r),
            (SELECT Name FROM Schedule_Templates__r)
            FROM Time_Element__c
            WHERE parent_time_element__c IN : termIds
        ];

        for (Term__c term : selectedTermObjectsInSetup) {
            Integer countReportingPeriods = 0;
            sectionsChecked = false;
            for (Time_Element__c repPeriod : reportingPeriodsWithChildren) {
                if (term.Time_Element__r.Id == repPeriod.parent_time_element__c) {
                    System.debug('\n\n repPeriod.parent_time_element__r.Name__c => ' + repPeriod.parent_time_element__r.Name__c + '\n');
                    System.debug('\n\n repPeriod.Scheduled_Sections__r => ' + repPeriod.Scheduled_Sections__r + '\n');

                    if(repPeriod.Schedule_Templates__r.isEmpty() || repPeriod.Schedule_Templates__r == null) {
                        ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Scheduled Templates in  ' + repPeriod.parent_time_element__r.Name__c + ' term. Please fill them in to proceed. ' + repPeriod.Name__c));
                        bOccupancyError = true;
                    }
                    if(!sectionsChecked) {
                        if(repPeriod.Sections1__r.isEmpty() || repPeriod.Sections1__r == null) {
//							ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Sections in  ' + repPeriod.parent_time_element__r.Name__c + ' term. Please fill them in to proceed. ' + repPeriod.Name__c));
                            bOccupancyError = true;
                        }
                        sectionsChecked = true;
                    }

                    if(repPeriod.Scheduled_Sections__r.isEmpty() || repPeriod.Scheduled_Sections__r == null) {
                        ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Scheduled Sections in  ' + repPeriod.parent_time_element__r.Name__c + ' term. Please fill them in to proceed. ' + repPeriod.Name__c));
                        bOccupancyError = true;
                        System.debug('\n\n schedule sections \n');
                    }
                    countReportingPeriods++;
                }
            }
            if (countReportingPeriods == 0) {
                ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Reporting Periods in  ' + term.Time_Element__r.Name__c + ' term. Please fill them in to proceed.'));
                bOccupancyError = true;
            }
        }
    }

}
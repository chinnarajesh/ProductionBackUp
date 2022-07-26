public with sharing  class CT_core_TermSetup_v2 {
    public List <cTimeWrapper>          availableTerms {get;set;}
    public List <cTimeWrapper>          oldTerms {get;set;}//neeeeew
    public Map <Id, Time_Element__c>    timeElementMap {get;set;}
    public string                       selectedTermIdForSetup {get;set;}
    public string                       selectedTermId {get;set;}
    public string                       selectedRpId {get;set;}
    public Time_Element__c              selectedYear                {get;set;}
    public Time_Element__c              selectedTermTimeElement {get;set;}
    public cReportingPeriod             reportingPeriodElement {get;set;}
    public cReportingPeriodEdit         reportingPeriodElementEdit {get;set;}
    public cTermWrapper                 selectedTermWrapper {get;set;}
    public boolean                      bShowTerms      {get;set;}
    public boolean                      bShowTermDetails        {get;set;}
    public boolean                      bConfigureTerm {get;set;} //Boolean to hide show the terms available
    public boolean                      bReadOnlyYear       {get;set;}
    public boolean                      bConfigureRp            {get;set;}
    public boolean                      bReportingPeriods       {get;set;}
    public boolean                      bEdit  {get;set;}  //neeeeeew checks if Reporting Period Type has changed
    public boolean                      bChildrenDeleted  {get;set;}  //neeeeeew checks if Time Element children is null
    public boolean                      needToSave  {get;set;}
    public id                           setupId                         {get;set;}
    public CT_core_SetupWrapper         cSetup                          {get;set;}
    public string[]                     sErrorMessages{get;set;}

    public Setup__c schoolSetup     {get;set;}
    public integer stepNo           {get;set;}
    public integer TERMS            {get{ return CT_SetupWizard_Utils.TERMS; } set;}
    public integer SELECTIONS       {get{ return CT_SetupWizard_Utils.SELECTIONS; } set;}
    public integer TEMPLATES        {get{ return CT_SetupWizard_Utils.TEMPLATES; } set;}
    public integer CALENDAR         {get{ return CT_SetupWizard_Utils.CALENDAR; } set;}
    public integer COURSE_CATALOG   {get{ return CT_SetupWizard_Utils.COURSE_CATALOG; } set;}
    public integer ROOMS            {get{ return CT_SetupWizard_Utils.ROOMS; } set;}
    public integer STAFF            {get{ return CT_SetupWizard_Utils.STAFF; } set;}
    public integer GROUP_CONFIG     {get{ return CT_SetupWizard_Utils.GROUP_CONFIG; } set;}
    public integer SCHEDULE         {get{ return CT_SetupWizard_Utils.SCHEDULE; } set;}
    public integer STUDENT_SECTIONS {get{ return CT_SetupWizard_Utils.STUDENT_SECTIONS; } set;}
    public integer PUBLISH          {get{ return CT_SetupWizard_Utils.PUBLISH; } set;}
    public integer ACTIVATION       {get{ return CT_SetupWizard_Utils.ACTIVATION; } set;}

    public Set<String> TERRITORYPROFIELS = new Set<String>{'Site Administrator'};
    public String USERPROFILENAME       {
        get{
            if(USERPROFILENAME==null){
                USERPROFILENAME = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
            }
            return USERPROFILENAME;
        }
        private set;
    }

    /* Initialize the page variables*/
    public CT_core_TermSetup_v2(){
        try{
            sErrorMessages = new String[]{};
             if ( ApexPages.currentPage().getParameters().get('setupId')!=null){
                SetupId = ApexPages.currentPage().getParameters().get('setupId');
                cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'term');
                selectedTermId = cSetup.setup.Term__c;
                bConfigureTerm = false;
                bReportingPeriods = false;
                bShowTerms = true;
                bEdit = false;
                bChildrenDeleted = false;
                returnAvailableTimeElements();
                if(availableTerms.size()==0){
                    CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There are no terms created for this school year.  Please create a term.');
                }
                else verifyData();
            }
        }
        catch(Exception e){
            CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred during initialization.');
        } 
    }
    
    public  void setTerm(){
        try{
            if (System.currentPageReference().getParameters().get('selectedTermIdForSetup')!=null){
                 selectedTermIdForSetup = System.currentPageReference().getParameters().get('selectedTermIdForSetup');
                }
        }
        catch(Exception e){
            insertLogsException(e, 'An error occurred while setting the term.', cSetup.setup.id, selectedTermIdForSetup, 'error setting term');
        }
    }

//    public void insertLogsExceptionInSetTerm(Exception e){
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while setting the term.');
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermIdForSetup, 'Core (Term)', 'error setting term', e);
//        insert ge;
//    }

    public void saveSetup(){
        System.debug('\n\n saveSetup in \n');
        List<Term__c> termsList = new List<Term__c>();
        List<Term__c> termsListToInsert = new List<Term__c>();
        Set<Id> noSelectedTimeElements = new Set<Id>();
        List<Term__c> unselectedTerms = new List<Term__c>();
        try{
            if (selectedTermIdForSetup!=null){  
                cSetup.setup.Term__c=selectedTermIdForSetup;
                update  cSetup.setup;
                cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'term');
                selectedTermId = selectedTermIdForSetup;
                bShowTerms=true;
            }
        
            for (cTimeWrapper termWrapper : availableTerms) {
                if(termWrapper.bIsSelected) {
                    termsList.add(new Term__c(Setup__c = cSetup.setup.Id, Time_Element__c = termWrapper.timeElement.Id));
                } else {
                    noSelectedTimeElements.add(termWrapper.timeElement.Id);
                }

                if(termWrapper.timeElement.Id == cSetup.setup.Term__c && !termWrapper.bIsSelected){
                    termWrapper.bIsSelected = true;
                    termsList.add(new Term__c(Setup__c = cSetup.setup.Id, Time_Element__c = termWrapper.timeElement.Id));
                }
            }

            Map<Id, Term__c> mapexistingTerms = new Map<Id, Term__c>([SELECT Id, Setup__c, Time_Element__c 
                                                                FROM Term__c WHERE Setup__c =: cSetup.setup.Id]);
            for(Term__c term: mapexistingTerms.values()){
                if(noSelectedTimeElements.contains(term.Time_Element__c)){
                    unselectedTerms.add(term);
                    mapexistingTerms.remove(term.Id);
                }
            }
            if(!unselectedTerms.isEmpty()){
                delete unselectedTerms;
            }

            //update account if term>2
            if(termsList.size()>1){
                update new Account(Id=cSetup.setup.School__c, Split_School__c=true);
            }

            for (Term__c existingTerm: mapexistingTerms.values()){
                for (Integer i = 0; i < termsList.size(); i++) {
                    if (termsList[i].Time_Element__c == existingTerm.Time_Element__c){
                        termsList.remove(i);
                        break;
                    }
                }                
            }

            System.debug('@@@ termsListToInsert => ' + termsList + '\n');
            if(!termsList.isEmpty()){
                upsert termsList;
            }

            //if (noSelectedTimeElements != null) {
            //    unselectedTerms = [SELECT Id, Setup__c, Time_Element__c FROM Term__c WHERE Setup__c =: cSetup.setup.Id AND Time_Element__c IN : noSelectedTimeElements];
            //}
            //if (unselectedTerms != null) {
            //    delete unselectedTerms;
            //}

            //for (Term__c existingTerm : [SELECT Id, Setup__c, Time_Element__c FROM Term__c WHERE Setup__c =: cSetup.setup.Id]) {
            //    for (Integer i = 0; i < termsList.size(); i++) {
            //        if (termsList[i] != null && termsList[i].Time_Element__c == existingTerm.Time_Element__c){
            //            termsList[i] = null;
            //            break;
            //        }
            //    }
            //}
            //System.debug('@@@ termsList: '+termsList.size());
            //for (Term__c term : termsList) {
            //    if(term != null){
            //        termsListToInsert.add(term);
            //    }
            //}
            //System.debug('\n\n termsListToInsert => ' + termsListToInsert + '\n');
            //upsert termsListToInsert;
        }
        catch(Exception e){
            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
            System.debug('\n\n e.getLineNumber() => ' + e.getLineNumber() + '\n');
            insertLogsException(e, 'An error occurred while saving the setup.', cSetup.setup.id, selectedTermIdForSetup, 'error saving term to setup');
        } 
    }

//    public void insertLogsExceptionInSaveSetup(Exception e){
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while saving the setup.');
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermIdForSetup, 'Core (Term)', 'error saving term to setup', e);
//        insert ge;
//    }

    public void processErrorMessages(){
        for (String s: sErrorMessages){
            CT_SetupWizard_Utils.addMessage(apexpages.severity.fatal, s);
        }
    }
    
    public void viewReportingPeriods(){
        returnTermDetails();
        bShowTerms = false;
        bConfigureTerm = false;
        bReportingPeriods = true;
    }
    
    public void cancelViewReportingPeriods(){
        bShowTerms = true;
        bReportingPeriods = false;
    }

    /*Gets all available time elements in system, should not be over 1000 ever, but may need to scale this
        Sets up the map to reference throughout class later; also sets up available term list */

        
    public void returnAvailableTimeElements(){
        availableTerms = new List<cTimeWrapper>();//Initialize a new list of TimeWrappers
        oldTerms = new List<cTimeWrapper>();
        Map<Id, Term__c> mapTerms = new Map<Id, Term__c>();
        cTimeWrapper ctw;

        Set<String> setLocations = new Set<String>();
        for(UserTerritory2Association ut2a: [SELECT Id, Territory2.Name, Territory2.Territory2Model.Name
                FROM UserTerritory2Association WHERE UserId = :Userinfo.getUserId()]){
            setLocations.add(ut2a.Territory2.Name);
        }

        timeElementMap = new Map<Id, Time_Element__c>();
        if (cSetup.setup.Year__c!=null){  //Ensure that the user selecteed a Year in order to display the appropriate data
            selectedYear = CT_core_SoqlUtils.getTimeElementById(cSetup.setup.Year__c);
            for(Term__c t: [SELECT Id, Time_Element__c FROM Term__c WHERE Setup__c =: cSetup.setup.Id]){
                mapTerms.put(t.Time_Element__c, t);
            }

            for(Time_Element__c te: CT_core_SoqlUtils.getTimeElementsByTerm(selectedYear.Id, false)) {
                Boolean isAddedTime = (TERRITORYPROFIELS.contains(USERPROFILENAME)? false: true) /*|| te.Terms__r.isEmpty() */|| te.CreatedById == UserInfo.getUserId();
                if(TERRITORYPROFIELS.contains(USERPROFILENAME)){
                    for(Term__c t: te.Terms__r){
                        isAddedTime = isAddedTime || setLocations.contains(t.Setup__r.School__r.Site__c) /*|| t.Setup__c == null*/;
                    }
                }
                if(isAddedTime == true){
                    ctw = new cTimeWrapper(te, mapTerms.containsKey(te.Id) ? true : false);
                    if(cSetup.setup.published__c && (mapTerms.isEmpty() || mapTerms.containsKey(te.Id))) ctw.bEdit = false;
                    availableTerms.add(ctw);
                }

                timeElementMap.put(te.id, te);
            }
        }
        oldTerms.addAll(availableTerms);
        System.debug('\n\n availableTerms.size() => ' + availableTerms.size() + '\n');
        System.debug('\n\n oldTerms.size() => ' + oldTerms.size() + '\n');
        bShowTerms = true;
    }

    public void checkTermSelectionChanges() {
        needToSave = true;

        for (cTimeWrapper newTerm : availableTerms) {
            for (cTimeWrapper oldTerm : oldTerms) {
                if(newTerm.timeElement.Id == oldTerm.timeElement.Id && newTerm.bIsSelected != oldTerm.bIsSelected) {
                    needToSave = false;
                    break;
                }
            }
        }
    }

    /* Makes map from list of Time_Element__c objects */
//    private Map<Id, Time_Element__c> makeMapFromTEList(List<Time_Element__c> timeElementsList) {
//        Map<Id, Time_Element__c> timeElementMap = new Map<Id, Time_Element__c>();
//        for (Time_Element__c te : timeElementsList) {
//            timeElementMap.put(te.id, te);
//        }
//        return timeElementMap;
//    }
    
    /*Sets up the selectedTermWrapper for the term user clicks 'View' next to the list of available terms*/
    public void returnTermDetails(){
        if (selectedTermId!=null){
            bConfigureTerm = true;
            bShowTerms = false; 
            selectedTermTimeElement = timeElementMap.get(selectedTermId);
            selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
        }
    }
    
    /*Sets up a new sTermWrapper for selectedTermWrapper the term user clicks 'New Term  */
    public void configureNewTerm(){
        try{
            bConfigureTerm = true;
            bShowTerms = false;
            selectedTermWrapper = new cTermWrapper(null, selectedYear);
            system.debug('~~~~~ selectedTermWrapper.term '+selectedTermWrapper.term);
        }
        catch(Exception e){
            insertLogsException(e, 'An error occurred while configuring a new term.', cSetup.setup.id, selectedYear.id, 'error configuring term for year');
        }
    }

//    public void insertLogsExceptionInConfigureNewTerm(Exception e){
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while configuring a new term.');
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Year, '+selectedYear.id, 'Core (Term)', 'error configuring term for year', e);
//        insert ge;
//    }

    public void cancelTermDetails(){
        bShowTerms = true;
        bConfigureTerm = false;
        returnAvailableTimeElements();
    }
    
    public void editTermDetails(){
        bShowTerms = false;
        bConfigureTerm = true;
        if (System.currentPageReference().getParameters().get('selectedTermId')!=null){
            selectedTermTimeElement = timeElementMap.get(selectedTermId);
            selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
            selectedTermWrapper.cQasw = new cQuickAddSchedWrapper(selectedTermTimeElement);
            selectedTermWrapper.reportingPeriod = new cReportingPeriod(selectedTermTimeElement, null);
        }
    }
    
    /*Toggles the view for the detail/Edit term information*/
    
    public void populateTermDetailTable(){
            bConfigureTerm = true;
    }

    public void checkReportingPeriod() {
        List<Time_Element__c> childrenTimeElements = new List<Time_Element__c>();
                System.debug('selectedTermWrapper.term.id ' + selectedTermWrapper.term.id);
                if(selectedTermWrapper.term.id != null) {
                    Time_Element__c te =  CT_core_SoqlUtils.getTimeElementById(selectedTermWrapper.term.id);
                    System.debug('te ' + te);
                    if (te.Reporting_Period_Value__c != selectedTermWrapper.term.Reporting_Period_Value__c && !selectedTermWrapper.timeElementList.isEmpty()) {
                        System.debug('CT_core_SoqlUtils.getTimeElementsByTerm(selectedYear.Id, true) ' + CT_core_SoqlUtils.getTimeElementsByTerm(selectedYear.Id, true));
                        System.debug('selectedTermWrapper.timeElementList; ' + selectedTermWrapper.timeElementList);
                        try {
                            delete selectedTermWrapper.timeElementList;
                        } catch (Exception e) {
                            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
                        }
                        bEdit = true;
                        bChildrenDeleted = true;
                        System.debug('bChildrenDeleted ' + bChildrenDeleted);
                        System.debug('te.Reporting_Period_Value__c ' + te.Reporting_Period_Value__c);
                        System.debug('selectedTermWrapper.term.Reporting_Period_Value__c ' + selectedTermWrapper.term.Reporting_Period_Value__c);
                    } else {
                        bEdit = false;
                    }
                }
    }
    /*Saves information entered for the Term Config*/
    public void saveTermConfig(){
        try{
            selectedTermWrapper.term.Parent_Time_Element__c = selectedYear.Id;
            selectedTermWrapper.term.Picklist_Value__c = CT_core_SoqlUtils.getPlStringValues('Time', null).get('Term').id;
            selectedTermWrapper.term.Days_of_Week__c = selectedTermWrapper.cQasw.days.DaystoString();
            selectedTermWrapper.term = CT_core_TimeUtils.translateTimeText(selectedTermWrapper.term);
            System.debug('====================================> before upsert1 ! ');
            upsert selectedTermWrapper.term; //Insert the term first to set it as the parent of the child terms
            System.debug('====================================> before upsert2 ! ');
            System.debug('====================================> selectedTermWrapper.timeElementList! ' + selectedTermWrapper.term);
            System.debug('bChildrenDeleted ' + bChildrenDeleted);

//          if(bChildrenDeleted) {
//              System.debug('inside if ');
//
//              upsert selectedTermWrapper.timeElementList; //Upsert the necessary time elements
//          }
            System.debug('====================================> before returnAvai ! ');

            returnAvailableTimeElements(); //requery the database to setup the map for all
            System.debug('====================================> before selectedTermTime ! ');
            selectedTermTimeElement = selectedTermWrapper.term;
            cancelTermDetails(); //resets boolean variables on screen so that user is returned to all terms view
        }
        catch(Exception e){
            insertLogsException(e, 'An error occurred while saving the term details.', cSetup.setup.id, selectedTermWrapper.term.id, 'error saving term');
        } 
    }

//    public void insertLogsExceptionInSaveTermConfig(Exception e){
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while saving the term details.');
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermWrapper.term.id, 'Core (Term)', 'error saving term', e);
//        insert ge;
//    }
    /*End Save Term Config*/

    /*Start wrapper class construction and instantiation*/
    public void initReportingPeriod(){
        try{
            reportingPeriodElement = new cReportingPeriod(selectedTermWrapper.term, null);
            bConfigureRp = true;
        }
        catch(Exception e){
            insertLogsException(e, 'An error occurred while initializing the reporting periods', cSetup.setup.id, selectedTermWrapper.term.id, 'error init reporting period');
        } 
    }
//    public void insertLogsExceptionInInitReportingPeriod(Exception e){
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while initializing the reporting periods');
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermWrapper.term.id, 'Core (Term)', 'error init reporting period', e);
//        insert ge;
//    }
//    private void checkReportingPeriodOverlap(List <Time_Element__c> teList){
//        Map <Id, List <Time_Element__c>> rpMap = new Map <Id, List <Time_Element__c>>();//Map to store parent -> rp relationship & data
//        for (Time_Element__c te: teList){
//            System.debug('\n\n te.parent_time_element__c => ' + te.parent_time_element__c + '\n');
//            System.debug('\n\n tett => ' + te + '\n');
//            if (te.Parent_Time_Element__c!=null && te.reporting_period__c){
//                rpMap.put(te.parent_time_element__c, new List <Time_Element__c>());
//            }
//        }
//        if (!rpMap.keySet().isEmpty()){
//            for (Time_Element__c te: [select Parent_Time_Element__c, id, date_start_date__c, end_date__c from Time_Element__c where parent_Time_Element__c in :rpMap.keySet() ORDER by Date_Start_Date__c ASC]){
//                rpMap.get(te.parent_time_element__c).add(te);
//                System.debug('\n\n te => ' + te + '\n');
//            }
//            for (Time_Element__c te: teList){
//                if (te.Parent_Time_Element__c!=null && te.reporting_period__c){
//                    for (Time_Element__c rpTe: rpMap.get(te.parent_time_element__c) ){
//                        if (rpTe.id != te.id){
//                            if(te.date_start_date__c < rpTe.date_start_date__c){
//                                if(te.end_date__c >= rpTe.date_start_date__c) {
//                                    sErrorMessages.add('Reporting period end date cannot be later than next reporting period start date: '+rpTe.Date_Start_Date__c.format());
//                                    break;
//                                }
//                            }
//                            if(te.end_date__c > rpTe.end_date__c){
//                                if(te.date_start_date__c <= rpTe.end_date__c) {
//                                    sErrorMessages.add('Reporting period start date cannot be earlier than prior reporting period end date: '+rpTe.End_Date__c.format());
//                                    break;
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    public void validateReportingPeriod (List<Time_Element__c> timeElementsList){
        System.debug('\n\n selectedTermTimeElement.Date_Start_Date__c => ' + selectedTermTimeElement.Date_Start_Date__c + '\n');
        System.debug('\n\n selectedTermTimeElement.End_Date__c => ' + selectedTermTimeElement.End_Date__c + '\n');
        for (Integer i = 1; i < timeElementsList.size(); i++) {
            if (selectedTermTimeElement.Date_Start_Date__c != null && selectedTermTimeElement.End_Date__c != null
                    && timeElementsList[i].Date_Start_Date__c != null && timeElementsList[i].End_Date__c != null) {

                if (timeElementsList[i].Date_Start_Date__c <= timeElementsList[i - 1].End_Date__c) {
                    sErrorMessages.add('Reporting period start date cannot be earlier or the same than prior reporting period end date: '
                            + timeElementsList[i].Date_Start_Date__c.format() + ' - '
                            + timeElementsList[i - 1].End_Date__c.format());
                }
                if (timeElementsList[i].Date_Start_Date__c >= timeElementsList[i].End_Date__c) {
                    sErrorMessages.add('Reporting period start date must be earlier than End Date:' + timeElementsList[i].Date_Start_Date__c.format() + ' < ' + timeElementsList[i].End_Date__c.format());
                }

            }
        }
        for (Integer i = 0; i < timeElementsList.size(); i++) {
            if (selectedTermTimeElement.Date_Start_Date__c != null && selectedTermTimeElement.End_Date__c != null
                    && timeElementsList[i].Date_Start_Date__c != null && timeElementsList[i].End_Date__c != null) {

                if (selectedTermTimeElement.Date_Start_Date__c > timeElementsList[i].Date_Start_Date__c) {
                    sErrorMessages.add('Child Time Element cannot have a start date earlier than parent: ' + timeElementsList[i].Name__c);
                }
                if (selectedTermTimeElement.Date_Start_Date__c > timeElementsList[i].End_Date__c) {
                    sErrorMessages.add('Child Time Element cannot have an end date earlier than parent: ' + selectedTermTimeElement.Date_Start_Date__c.format());
                }
                if (selectedTermTimeElement.End_Date__c < timeElementsList[i].Date_Start_Date__c) {
                    sErrorMessages.add('Child Time Element cannot have a start date later than parent: ' + selectedTermTimeElement.Date_Start_Date__c.format());
                }
                if (selectedTermTimeElement.End_Date__c < timeElementsList[i].End_Date__c) {
                    sErrorMessages.add('Child Time Element cannot have an end date later than parent: ' + timeElementsList[i].Name__c);
                }
            }
        }
    }



    
    public void addReportingPeriod(){
        try{
            //Save & Add reporting period
            saveReportingPeriod();
            initReportingPeriod();
        }
        catch(Exception e){
            insertLogsException(e, 'An error occurred while adding the reporting period.', cSetup.setup.id, selectedTermWrapper.term.id, 'error adding reporting period');
//            CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while adding the reporting period.');
//            Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermWrapper.term.id, 'Core (Term)', 'error adding reporting period', e);
//            insert ge;
            } 
    }
    
    public void cancelAddReportingPeriod(){
        bConfigureRp = false;
        bReportingPeriods = true;
    }

    public void editReportingPeriod(){

        System.debug('selectedTermWrapper.timeElementList ' + selectedTermWrapper.timeElementList);
        try{
            reportingPeriodElementEdit = new cReportingPeriodEdit(selectedTermWrapper.term, selectedTermWrapper.timeElementList);
            bConfigureRp = true;
            reportingPeriodElementEdit.selectedReportingPeriodType = selectedTermWrapper.term.Reporting_Period_Value__c;
        }
        catch(Exception e){
            insertLogsException(e, 'An error occurred while retrieving reporting period details.', cSetup.setup.id, selectedRpId, 'error getting reporting period');

        }
    }

//    public void insertLogsExceptionInEditReportingPeriod(Exception e){
//        CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while retrieving reporting period details.');
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting period, '+selectedRpId, 'Core (Term)', 'error getting reporting period', e);
//        insert ge;
//    }
    /* Deprecated Chesapeake, should not have this ability until we verify that the term is truly able to be deleted
    public void deleteReportingPeriod(){
        try{
            if (System.currentPageReference().getParameters().get('selectedRpId')!=null){
                selectedRpId = System.currentPageReference().getParameters().get('selectedRpId');
                delete core_SoqlUtils.getTimeElementById(selectedRpId);
                 
                  
                //PU: 08/04/2011 - On rerender the refreshing the selectedTermWrapper List after delete
                selectedTermId = System.currentPageReference().getParameters().get('selectedTermId');
                selectedTermTimeElement = timeElementMap.get(selectedTermId);
                selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while deleting the reporting period.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting period, '+selectedRpId, 'Core (Term)', 'error deleting reporting period', e);
            insert ge;
        } 
    }*/
    
    public void saveReportingPeriod (){
        try{
            sErrorMessages.clear();
            System.debug('reportingPeriodElement.timeElementList ' + reportingPeriodElement.timeElementList);
            validateReportingPeriod(reportingPeriodElement.timeElementList);

            System.debug('\n\n sErrorMessages.size() => ' + sErrorMessages.size() + '\n');
            System.debug('\n\n sErrorMessages => ' + sErrorMessages + '\n');
            if (sErrorMessages.isEmpty()){
                for (Time_Element__c te : reportingPeriodElement.timeElementList) {
                    reportingPeriodElement.selectedReportingPeriodType = selectedTermWrapper.term.Reporting_Period_Value__c;
                    te.picklist_Value__c = reportingPeriodElement.selectedReportingPeriodType;
                    te.parent_time_Element__c = selectedTermWrapper.term.id;
                }
                upsert reportingPeriodElement.timeElementList;
                bConfigureRp = false;
                selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
                viewReportingPeriods();
            }
            else processErrorMessages();
        }
        catch(Exception e){
            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
            System.debug('\n\n  e.getLineNumber()  => ' + e.getLineNumber()  + '\n');
            if(reportingPeriodElement==null || reportingPeriodElement.timeElementList==null){
                ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'The reporting period should exists.'));
                return;
            }
            for (Time_Element__c te : reportingPeriodElement.timeElementList) {
                ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the reporting period.'));
                Global_Error__c ge = CT_Error_Handling.handleError('Setup, ' + cSetup.setup.id + '; Reporting period, ' + reportingPeriodElement.te.id, 'Core (Term)', 'error saving reporting period', e);
                insert ge;
            }
        } 
    }

    public void saveReportingPeriodAfterEdit (){
        try{
            sErrorMessages.clear();
            validateReportingPeriod(reportingPeriodElementEdit.timeElementList);
            if (sErrorMessages.isEmpty()){
                for (Time_Element__c te : reportingPeriodElementEdit.timeElementList) {
                    reportingPeriodElementEdit.selectedReportingPeriodType = selectedTermWrapper.term.Reporting_Period_Value__c;
                    te.picklist_Value__c = reportingPeriodElementEdit.selectedReportingPeriodType;
                    te.parent_time_Element__c = selectedTermWrapper.term.id;
                }
                upsert reportingPeriodElementEdit.timeElementList;
                bConfigureRp = false;
                selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
                viewReportingPeriods();
            }
            else processErrorMessages();
        }
        catch(Exception e){
            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
            System.debug('\n\n  e.getLineNumber()  => ' + e.getLineNumber()  + '\n');
            insertLogsException(e, 'An error occurred while saving the reporting period.',cSetup.setup.id, reportingPeriodElement.te.id, 'error saving reporting period');
        }
    }
    public void insertLogsException(Exception e, String apexPagesMessage,Id SetupId, Id reportingPeriodId, String errorInfo){
        ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, apexPagesMessage));
        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+SetupId+'; Reporting period, '+ reportingPeriodId, 'Core (Term)', errorInfo, e);
        insert ge;
    }
//    public void insertLogsExceptionInSaveReportingPeriodAfterEdit(Exception e){
//        ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the reporting period.'));
//        Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting period, '+reportingPeriodElement.te.id, 'Core (Term)', 'error saving reporting period', e);
//        insert ge;
//    }

    public PageReference goHome(){
        return CT_SetupWizard_Utils.goToSchoolHome(setupId);
    }

    public PageReference goHomeModified(){
        return CT_SetupWizard_Utils.goToSchoolHomeModified(setupId);
    }

    public PageReference next(){
//      if(verifyData()) return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.SELECTIONS,true,cSetup.setup);
//      else return null;
        if(verifyData()) {
            EOY_Progress__c progress = CT_SetupWizard_Utils.getEOYProgressRecord(cSetup.setup);
            progress.School_Selections_Completed__c=true;
            upsert progress;
            return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.TEMPLATES,true,cSetup.setup);
        }
        else{
            CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'School preferences must be saved before moving on to the next step.');
            return null;
        }
    }
    
    public boolean verifyData(){
        try {
            System.debug('\n\n cSetup => ' + cSetup + '\n');
            System.debug('\n\n cSetup.setup.Term__c => ' + cSetup.setup.Term__c + '\n');
            if(String.isBlank(cSetup.setup.School__r.Reference_Id__c)){
                CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Field Reference Id on Setup->School must be selected before moving on to the next step.');
            }
            if(String.isBlank(cSetup.setup.Grade_Span__c)){
                CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Field Grade Span on Setup must be selected before moving on to the next step.');                
            }
            if(CT_SetupWizard_Utils.checkTerm(cSetup.setup)){
                if(cSetup.setup.Term__c==null) CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'A term must be selected before moving on to the next step.');
                else verifyReportingPeriods();
                return false;
            }
            else if(verifyReportingPeriods()) return false;
            else return true;
        } catch (Exception e) {
            System.debug('\n\n e.getLineNumber() => ' + e.getLineNumber() + '\n');
            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
            return null;
        }
        
    }
    
    public boolean verifyReportingPeriods(){
        ID termId = cSetup.setup.Term__c;
        Time_Element__c term = [SELECT id, Name__c, Reporting_Period_Value__c FROM Time_Element__c WHERE id=:termId];
        List<Time_Element__c> rps = [SELECT id FROM Time_Element__c WHERE Reporting_Period__c=true AND Parent_Time_Element__c=:termId];
        Picklist_Value__c termType = [SELECT id, Name, Corresponding_Value__c FROM Picklist_Value__c WHERE id=:term.Reporting_Period_Value__c];
        boolean bError = false;
        //number of reporting periods term has should match the corresponding value on the picklist value
        if(termType.Corresponding_Value__c!=rps.size()){
            CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The term '+term.Name__c+' does not have the correct number of reporting periods for the '
                +termType.Name+' reporting period value.  Expected '+termType.Corresponding_Value__c+' reporting periods, found '
                +rps.size()+' reporting periods.');
            bError=true;
        }
        return bError;
    }
    
    public class cTermWrapper{

        public Time_Element__c                  term            {get;set;}
        public cReportingPeriod                 reportingPeriod {get;set;}
        public List <Time_Element__c>           timeElementList {get;set;}
        public cQuickAddSchedWrapper            cQasw                   {get;set;}
        public List <SelectOption>              reportingPeriodOptionList   {get;set;}
        
        public cTermWrapper(Time_Element__c parentTerm, Time_Element__c year){
            timeElementList = new List <Time_Element__c> ();
            reportingPeriodOptionList = new List <SelectOption>();
            Set <String> timeTypes = new Set <String>();
            for (Picklist_Value__c pl: [select id, name from Picklist_Value__c where category__c='Reporting Period'
                                        and RecordType.Name ='Time']){
                if (!timeTypes.contains(pl.name)){
                    reportingPeriodOptionList.add(new SelectOption(pl.id, pl.name));
                    timeTypes.add(pl.name);
                }
            }
            if (parentTerm ==null){
                this.term = new Time_Element__c(Picklist_Value__r=  CT_core_SoqlUtils.getPlStringValues('Time', null).get('Term') );
                this.cQasw = new cQuickAddSchedWrapper(null); 
                this.term.Date_Start_Date__c= year.Date_Start_Date__c;
                this.term.End_Date__c = year.End_Date__c;

            }
            else {
                this.cQasw = new cQuickAddSchedWrapper(parentTerm); 
                this.term = parentTerm;
                for (Time_element__c te: CT_core_SoqlUtils.getTimeElementsByTerm(parentTerm.id, true)){
                    this.timeElementList.add(te);
                }
                this.reportingPeriod = new cReportingPeriod(this.term, null);
            }
        }
    }


    public class cReportingPeriod {
        public final String FIRST_PERIOD = 'Prior Year';
        public String                           selectedReportingPeriodType {get;set;}
        public Time_Element__c                  te  {get;set;}
        public List <Time_Element__c>           timeElementList{get;set;}
        public List <SelectOption>              reportingPeriodOptionList {get;set;}
        public List <String>                    periodNames {get;set;}
        public Map<String, Integer> termWithPeriodsQuantityMap = new Map<String, Integer> {
                'Semester' => 2,
                'Trimester' => 3,
                'Quarter' => 4,
                'Fifth' => 5,
                'Sixth' => 6,
                'Seventh' => 7,
                'Eighth' => 8,
                'Ninth' => 9
        };
        public Map<String, String>  termWithPeriodsNameMap = new Map<String, String> {
                'Semester' => 'Semester',
                'Trimester' => 'Semester',
                'Quarter' => 'Trimester',
                'Fifth' => 'Quarter',
                'Sixth' => 'Marking Period',
                'Seventh' => 'Marking Period',
                'Eighth' => 'Marking Period',
                'Ninth' => 'Marking Period'
        };

        public Map<String, String> abbreviatedMap = new Map<String, String> {
                'Prior Year' => 'PrYr',
                'Semester' => 'SEM',
                'Trimester' => 'TR',
                'Quarter' => 'QTR',
                'Marking Period' => 'MrPr',
                'Marking Period' => 'MrPr'
        };

        public cReportingPeriod(Time_Element__c ParentTe, Time_Element__c rpTe){
            periodNames = new List <String>();
            reportingPeriodOptionList = new List <SelectOption>();
            timeElementList = new List<Time_Element__c>();

            periodNames.add(FIRST_PERIOD);
            for(Integer i = 1; i < termWithPeriodsQuantityMap.get(ParentTe.Reporting_Period_Value__r.Name); i++) {
                periodNames.add(termWithPeriodsNameMap.get(ParentTe.Reporting_Period_Value__r.Name));
            }
            if (rpTe == null) {
                for (Integer i = 0; i < periodNames.size(); i++) {
                    if(i == 0) {
                        timeElementList.add(new Time_Element__c(parent_time_element__c = ParentTe.id,
                                Reporting_Period__c = true,
                                Days_of_week__c = ParentTe.days_of_week__c,
                                Name__c = periodNames[i],
                                Date_Start_Date__c = ParentTe.Date_Start_Date__c,
                                Name_On_Report_Card__c = abbreviatedMap.get(periodNames[i])));
                    }
                    if((i > 0) && (i < periodNames.size() - 1)) {
                        timeElementList.add(new Time_Element__c(parent_time_element__c = ParentTe.id,
                                Reporting_Period__c = true,
                                Days_of_week__c = ParentTe.days_of_week__c,
                                Name__c = periodNames[i] + ' ' + i,
                                Name_On_Report_Card__c = abbreviatedMap.get(periodNames[i]) + i));
                    }
                    if((periodNames.size() - i) == 1) {
                        timeElementList.add(new Time_Element__c(parent_time_element__c = ParentTe.id,
                                Reporting_Period__c = true,
                                Days_of_week__c = ParentTe.days_of_week__c,
                                Name__c = periodNames[i] + ' ' + i,
                                End_Date__c = ParentTe.End_Date__c,
                                Name_On_Report_Card__c = abbreviatedMap.get(periodNames[i]) + i));
                    }
                }
            } else {
                this.te = rpTe;
                timeElementList.add(rpte);
            }
            for (Picklist_Value__c pl: core_SoqlUtils.getPlValuesList('Time', null)) {
                reportingPeriodOptionList.add(new SelectOption(pl.id, pl.name));
            }
            if (ParentTe.reporting_period_value__c != null) {
                parentTe = core_SoqlUtils.getTimeElementById(ParentTe.id);
                reportingPeriodOptionList.add(new SelectOption(ParentTe.reporting_period_value__c, ParentTe.reporting_period_value__r.name));
            }
            if(timeElementList.size() == 2) {
                timeElementList[1].Name__c = timeElementList[1].Name__c.substring(0,8);
                timeElementList[1].Name_On_Report_Card__c = timeElementList[1].Name_On_Report_Card__c.substring(0,3);
            }
        }
    }



    public class cReportingPeriodEdit {
        public final String FIRST_PERIOD = 'Prior Year';
        public String                           selectedReportingPeriodType {get;set;}
        public List <Time_Element__c>           timeElementList{get;set;}
        public List <SelectOption>              reportingPeriodOptionList {get;set;}

        public cReportingPeriodEdit(Time_Element__c ParentTe, List<Time_Element__c> rpTe){
            reportingPeriodOptionList = new List <SelectOption>();
            timeElementList = new List<Time_Element__c>();

            timeElementList.addAll(rpte);
            for (Picklist_Value__c pl: core_SoqlUtils.getPlValuesList('Time', null)) {
                reportingPeriodOptionList.add(new SelectOption(pl.id, pl.name));
            }
            if (ParentTe.reporting_period_value__c != null) {
                parentTe = core_SoqlUtils.getTimeElementById(ParentTe.id);
                reportingPeriodOptionList.add(new SelectOption(ParentTe.reporting_period_value__c, ParentTe.reporting_period_value__r.name));
            }
        }
    }
    
    public class cQuickAddSchedWrapper {
            public Time_Element__c inputTimeElement {get;set;}  
            public CT_core_UtilDays     days    {get;set;}
            public integer  iDuration   {get;set;}
            public integer  iBreak      {get;set;}
            public cQuickAddSchedWrapper(Time_Element__c inputTimeElement){

            if (inputTimeElement==null){
                this.iDuration = 60;
                this.iBreak = 5;
                this.inputTimeElement = new Time_Element__c( );
                //this.inputTimeElement.StartTime__c = '08:00 AM'; Not needed Chesapeake PN
                //this.inputTimeElement.EndTime__c = '05:00 PM'; Not needed Chesapeake PN
                    this.days = new CT_core_UtilDays();
            }
            else {
                    if (inputTimeElement.days_of_week__c!=null) this.days = new CT_core_UtilDays(inputTimeElement.days_of_week__c);
                    else this.days = new CT_core_UtilDays();
            }
        }
        public cQuickAddSchedWrapper(){
            this.days = new CT_core_UtilDays(); // Use the days class if user is entering details; day of week still applies
        }
    }

    public class cTimeWrapper {
        public Time_Element__c timeElement  {get;set;}
        public boolean   bEdit                      {get;set;}
        public boolean bDisplay                 {get;set;}
        public Boolean bIsSelected          {get;set;}
        public cTimeWrapper(Time_Element__c te, boolean isSelected){ //
            this.timeElement = te;
            this.bEdit = true;
            this.bDisplay = true;
            this.bIsSelected = isSelected;
        }
    }
    /*End wrapper class construction and instantiation*/

}
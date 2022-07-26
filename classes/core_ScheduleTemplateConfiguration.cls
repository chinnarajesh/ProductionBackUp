public with sharing class core_ScheduleTemplateConfiguration {
    public ApexPages.StandardController         controller              {get; set;}
    public List <Period__c>                     periodList              {get;set;}
    public Schedule_Template__c                 schedTemplate           {get;set;} 
    public Period__c                            period                  {get;set;}
    public core_SetupWrapper                    cSetup                  {get;set;}
    public List <Schedule_Template__c>          scheduleTemplateList    {Get;set;} 
    public String                               rpId                    {get;set;}
    public string                               templateId              {get;set;}
    public string                               cloneTemplateId         {get;set;}
    public string                               cloneGrpSchedId         {get;set;}
    public string                               selectedRowNumber       {get;set;}
    public string[]                             sErrorMessages          {get;set;}
    public boolean                              bErrors                 {get;set;}
    public boolean                              bIsClone                {get;set;}
    public boolean                              bIsNew                  {get;set;}
    public boolean                              bConfigureTemplate      {get;set;}
    public boolean                              bPeriod                 {get;set;}
    public List <SelectOption>                  reportingPeriodOptionList {get;set;}
    public String                               selectedReportingPeriod {get;set;}

    public Boolean isViewOnly                                           {get;set;}
    
    public core_ScheduleTemplateConfiguration(){
        if(ApexPages.currentPage().getParameters().containsKey('setupid')){
            Id setupId = ApexPages.currentPage().getParameters().get('setupId');
            init(core_SoqlUtils.getSetupById(setupId));
            reportingPeriodOptionList = SetupWizard_Utils.getReportingPeriodOptions(cSetup.reportingPeriodList);
            if(SetupWizard_Utils.checkTemplates(cSetup.setup)){
                SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The master template must be created for '+cSetup.reportingPeriodList[0].Name__c+' before moving on to the next step.');
            }
        }
        else{
            SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
        }
        isViewOnly = false;
    }
    
    public void init(Setup__c setup){
        bConfigureTemplate = false;
        bIsNew = false;
        bIsClone = false;
        bPeriod = false;
        cloneTemplateId=null;
        templateId=null;
        sErrorMessages = new string[] {};
        periodList = new List <Period__c>{};
        cSetup = new core_SetupWrapper(setup,'Setup Wizard Step 3');
    }
    
    public void getReportingPeriodOptions(Id termId){
        reportingPeriodOptionList = new List<SelectOption>();
        for (Time_Element__c rp: core_SoqlUtils.getTimeElementsByTerm(termId, true)){
            reportingPeriodOptionList.add(new SelectOption(rp.id, rp.Name__c)); //Populates list of possible reporting periods
        }
    }
    
    public void initTemplate(){
        bConfigureTemplate=true;
        if (templateId!=null && templateId!=''){
            system.debug('~~~~ templateId: '+templateId);
            schedTemplate =core_SoqlUtils.getTemplateById(templateId);
            //add validation that schedule templates related to attendance can't be edited
            List<Schedule_Day__c> days = [SELECT Day__c FROM Schedule_Day__c WHERE Schedule_Template__c=:templateId];
            Set<Date> dates = new Set<Date>();
            for(Schedule_Day__c sd: days) dates.add(sd.Day__c);
            List<Attendance__c> att = [SELECT id FROM Attendance__c 
                WHERE Session_Date__c IN :dates
                AND Session__r.Section__r.School__c=:cSetup.school.id
                AND Session__r.Section__r.Time__c=:cSetup.setup.Year__c];
            if(att.size()==0 || isViewOnly){
                if(!cSetup.setup.Group_Based__c) retrievePeriods(false, TemplateId);
                rpId = schedTemplate.reporting_period__c;
            }
            else if(!isViewOnly){
                SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This schedule template has attendance records submitted.  Once attendance records are submitted, you cannot edit the schedule template.  You can add new schedule templates at any time.');
                bConfigureTemplate=false;
            }
        }
        else {
            scheduleTemplateList = cSetup.rpScheduleTemplateMap.get(rpId);
            if (scheduleTemplateList==null) scheduleTemplateList = new List <Schedule_Template__c>();
            if (scheduleTemplateList.isEmpty()){
                system.debug('~~~~~ no existing templates, create new');
                schedTemplate = new Schedule_Template__c(Reporting_Period__c = rpId, Name='Master', setup__c=cSetup.setup.id, is_master__c = true, has_class__c = true);
                bIsNew = true;
            }
            else{
                if (cloneTemplateId!=null){ 
                    bIsClone = true;
                    system.debug('~~~~~ cloneTemplateId: '+cloneTemplateId);
                    schedTemplate = core_SoqlUtils.getTemplateById(cloneTemplateId).clone(false);
                    schedTemplate.name = 'Copy - '+schedTemplate.name;
                    if(!cSetup.setup.Group_Based__c)
                        retrievePeriods(true, cloneTemplateId);
                }
                else {
                    system.debug('~~~~~ net new template');
                    schedTemplate = new Schedule_Template__c(Reporting_Period__c = rpId, Name='New', setup__c=cSetup.setup.id, is_master__c = false, has_class__c = true);
                    bIsNew = true;
                }
            }   
        }
    }
   
    public void retrievePeriods(boolean cloneMaster, string ptId){
        periodList.clear();
        integer i = 1;
        for (Period__c p: [Select Start_Time__c, Start_Time_Text__c, End_Time__c, End_Time_Text__c, Key__c, p.Type__c, p.Time__c, p.SystemModstamp, p.Schedule_Template__c, p.Passing_Time__c, p.Order__c, p.Name, p.LastModifiedDate, p.LastModifiedById, p.IsDeleted, p.Id, p.Description__c, p.CreatedDate, p.CreatedById, p.Class_Minutes__c, p.Abbreviation__c 
                        From Period__c p 
                        Where Schedule_Template__c =:ptId
                        and isDeleted = false
                        order by order__c asc]){
            p.order__c = i; 
            if (cloneMaster) periodList.add(p.clone(false)); //If user is creating a new Period template, they want to clone the master as a base
            else periodList.add(p); //Since record actually has a period templateId bring back the acutal records and use those
            i++;
        }
    }
    
    public void addPeriodRow(){
        try{
            sErrorMessages.clear();
            if (!periodList.isEmpty()){
                Period__c p = periodList[periodList.size()-1];
                validateMandatoryFields(p); //Check that the original row passes validation
                System.debug('After Validation');
                if (!bErrors) { //If it passes validation 
                    p.Start_Time__c=core_TimeUtils.processTimeText(p.Start_Time_Text__c);
                    p.End_Time__c=core_TimeUtils.processTimeText(p.End_Time_Text__c);
                System.debug('Before Clone');
                    period = p.clone(false);
                    if (p.End_Time__c!=null&&p.Start_Time__c!=null) {
                        if (p.Passing_Time__c ==null) p.Passing_Time__c = '0';
                        period.Start_Time__c = p.End_Time__c.addMinutes(Integer.valueOf(p.Passing_Time__c));
                        period.start_Time_Text__c = period.start_time__c.format('hh:mm a');
                        integer endTimeMins = core_TimeUtils.getMinutes(p.End_Time__c);
                        integer startTimeMins = core_TimeUtils.getMinutes(p.Start_Time__c);
                        integer duration = Integer.valueOf(p.Passing_Time__c)+ (endTimeMins-startTimeMins);
                        period.end_Time__c = p.End_Time__c.addMinutes(duration);
                        period.end_Time_Text__c = period.end_Time__c.format('hh:mm a');
                    }
                    period.order__c = p.order__c+1;
                    period.Key__c  = string.valueOf(period.order__c);
                    bPeriod = true;
                }
                else processErrorMessages();
            }
            else {
                period = new Period__c(key__c='1', Order__c=1);
                bPeriod = true;
            }
            System.debug(period);
            System.debug(periodList);
            System.debug(period);
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while creating a new period.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+templateId, 'Core (Template)', 'error adding period', e);
            insert ge;
        } 
    }
    
    public void deleteRow(){
        Period__c deleteP;
        try{
            upsertPeriodList(periodList);
            if (System.currentPageReference().getParameters().get('periodId')!=null){
                Id periodId = System.currentPageReference().getParameters().get('periodId');
                List <Period__c> pList = new List <Period__c>();
                for(Period__c p: periodList){
                    if(p.id==periodId) deleteP = p;
                    else pList.add(p);
                }
                if (deleteP != null)
                    delete deleteP;
                upsertperiodList(pList);
            }
            retrievePeriods(false, schedTemplate.id);
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while updating the period configuration.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error updating periods', e);
            insert ge;
        } 
    }
    
    public void editRow(){
        if(ApexPages.currentPage().getParameters().containsKey('periodId')){
            Id periodId = ApexPages.currentPage().getParameters().get('periodId');
            for(Period__c p : periodList){
                if(p.id==periodId) period = p;
            }
            bPeriod = true;
        }
    }
    
    public void savePeriod(){
        if(period.id==null) periodList.add(period);
        upsertPeriodList(periodList);
    }
    
    public void validateMandatoryFields(Period__c p){
        bErrors=false;
        if (p.key__c==null || p.key__c=='') {
            sErrorMessages.add('Identifier must be populated');
            bErrors = true;
            System.Debug(bErrors);
        }
        else if(p.key__c.contains(',')||p.key__c.contains(';')){
            sErrorMessages.add('Period identifiers cannot contain the "," or ";" special characters.  Please revise your period identifier.');
            bErrors=true;
            System.Debug(bErrors);
        }
        System.Debug(bErrors);
        if (p.start_time_text__c==null||p.start_time_text__c==''){
            sErrorMessages.add('Start time must be populated');
            bErrors = true;
        }
        System.Debug(bErrors);
        if (p.end_time_text__c == null||p.end_time_text__c==''){
            sErrorMessages.add('End time must be populated');
            bErrors = true;
        }
        System.Debug(bErrors);
        if (core_TimeUtils.processTimeText(p.start_time_text__c ) > core_TimeUtils.processTimeText(p.end_time_text__c)){
            sErrorMessages.add('End time must be greater than the start time');
            bErrors=true;
        }
        System.Debug(bErrors);
    }
    
    public void validateTemplateMandatoryFields(Schedule_Template__c st){
        bErrors=false;
        
        if (st.Start_Time_Text__c == null || st.Start_Time_Text__c == ''){
            sErrorMessages.add('Start time must be populated when Has Class? is checked');
            bErrors = true;
        }
        
        if (st.end_time_text__c == null||st.end_time_text__c==''){
            sErrorMessages.add('End time must be populated when Has Class? is checked');
            bErrors = true;
        }
        if (!bErrors){
            if(st.Start_Time_Text__c != '' && st.end_time_text__c != '' && core_TimeUtils.processTimeText(st.Start_Time_Text__c) > core_TimeUtils.processTimeText(st.end_time_text__c)){
                sErrorMessages.add('End time must be greater than the start time');
                bErrors=true;
            }
        }
    }
    
    public void upsertPeriodList(List <Period__c> thisPeriodList){//Method to call when upserting Periods for validation purposes
        List <Period__c> rollBackList = thisPeriodList;
        Set <String> periodKeys = new Set<String>{};
        sErrorMessages = new String[]{};
        DateTime validationTime ;
        for (integer i= 0; i< thisPeriodList.size(); i++){
            Period__c p= thisPeriodList[i];
            if (schedTemplate.id==null) upsert schedTemplate;
            if (p.id==null) p.Schedule_Template__c=schedTemplate.id;
            p.order__c = i+1;
            validateMandatoryFields(p);
            if (!bErrors){
                if(cSetup.setup.Chronological_Periods__c){
                    if (i ==0) validationTime = core_TimeUtils.processTimeText(p.end_time_text__c);
                    else {
                            //   Commented out PTN 10/6 ELH deployment
                            //PU 956
                            if (validationTime>core_TimeUtils.processTimeText(p.start_time_text__c)){
                                sErrorMessages.add('Period times must be chronological');
                                bErrors=true;
                            }
                            else validationTime =  core_TimeUtils.processTimeText(p.end_time_text__c);
                    }
                }   
                if (periodKeys.contains(p.key__c)) {
                    sErrorMessages.add('Period Identifiers must be unique for scheduling purposes');
                    bErrors=true;
                }
                else periodKeys.add(p.key__c);
            }
            if (!bErrors){
                p.Start_Time__c=core_TimeUtils.processTimeText(p.Start_Time_Text__c);
                p.End_Time__c=core_TimeUtils.processTimeText(p.End_Time_Text__c);
            }
        }
            
        if (sErrorMessages.isEmpty()){
            upsert thisPeriodList;
            bPeriod = false;
        }
        else {
            processErrorMessages();
        }
        retrievePeriods(false,schedTemplate.id);
    }
    
    public void processErrorMessages(){
        for (String s: sErrorMessages){
            Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, s));
            if (!bErrors) bErrors = true;
        }
    }
    
    public void cancelschedTemplate(){
        try{
            if(schedTemplate.id!=null&&bIsNew){
                templateId = schedTemplate.id;
                deleteTemplate();
            }
            bConfigureTemplate=false;
            init(cSetup.setup);
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while redirecting the page.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error redirecting to setup page', e);
            insert ge;
        } 
    }
    
    public void deleteTemplate(){
        try{
            schedTemplate = core_SoqlUtils.getTemplateById(templateId);
            delete schedTemplate;
        }
        catch(Exception e){
        }
        init(cSetup.setup);
    }
    
    public void checkMastersOnTemplates(){
        scheduleTemplateList = cSetup.rpScheduleTemplateMap.get(schedTemplate.reporting_period__c);
        if(scheduleTemplateList!= null && scheduleTemplateList.size() > 0){
            for (Schedule_Template__c st: scheduleTemplateList){
                st.Is_Master__c=false; 
            }
            upsert scheduleTemplateList;
        }
    }  
     
    public void saveSchedTemplate(){  
        try{
            if (schedTemplate.Is_Master__c) checkMastersOnTemplates();
            upsert schedTemplate;
            if (!periodList.isEmpty()){
                upsertPeriodList(periodList);
                system.debug('~~~~~ periodList: '+periodList);
                schedTemplate.Start_Time__c = periodList[0].Start_Time__c ;
                system.debug('~~~~~ start time: '+periodList[0].Start_Time__c );
                schedTemplate.End_Time__c = periodList[periodList.size()-1].End_Time__c;
                system.debug('~~~~~ end time: '+periodList[periodList.size()-1].End_Time__c);
                upsert schedTemplate;
            }
            if (sErrorMessages.isEmpty()) init(cSetup.setup);
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the schedule template.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving schedule template', e);
            insert ge;
        } 
    }
    
    public void saveAndNew(){
        try{
            saveSchedTemplate();
            if(!bConfigureTemplate) initTemplate();
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the schedule template.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving template', e);
            insert ge;
        }
    }
    
    public void saveSchedGrp(){
        try{
            sErrorMessages.clear();
            List<Scheduled_Section__c> insertSSecList = new List<Scheduled_Section__c>();
            if(schedTemplate != null ){
                if(schedTemplate.Has_Class__c == true) validateTemplateMandatoryFields(schedTemplate);
                if (sErrorMessages.isEmpty()){
                    if(schedTemplate.Has_Class__c == true){
                        schedTemplate.Start_Time__c=core_TimeUtils.processTimeText(schedTemplate.start_Time_Text__c);
                        schedTemplate.End_Time__c=core_TimeUtils.processTimeText(schedTemplate.End_Time_Text__c);
                    }
                    if (schedTemplate.Is_Master__c) checkMastersOnTemplates();//DE843
                    upsert schedTemplate;
                }
                else{
                    processErrorMessages();
                    return;
                }
            }
            
            if(bIsClone && schedTemplate.Has_Class__c){
                if (cSetup.setup.Group_Based__c) core_TriggerUtils.bGroupAgenda=true;
                insertSSecList = scheduler_SoqlUtils.getClonedScheduledSections(cloneTemplateId, schedTemplate.Id, schedTemplate.Reporting_Period__c);
                if(insertSSecList.size() > 0)
                    upsert  insertSSecList Reference_Id__c;
            }
            init(cSetup.setup);
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while updating the schedule.'));
            Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving schedule group', e);
            insert ge;
        } 
    }
    
    public PageReference prev(){
        return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.SELECTIONS,false,cSetup.setup);
    }
    
    public PageReference next(){
        if(!SetupWizard_Utils.checkTemplates(cSetup.setup)) return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.CALENDAR,true,cSetup.setup);
        else{
            SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The master template must be created for '+cSetup.reportingPeriodList[0].Name__c+' before moving on to the next step.');
            return null;
        }
    }
    
    static testMethod void test_core_schedTemplateConfiguration(){
        TestDataSetupUtil_v2.setUPCoreData(5);
        PageReference pr  = Page.core_scheduleTemplate;
        pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
        test.setCurrentPage(pr);
        Test.startTest();
            core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
            controller.rpID = TestDataSetupUtil_v2.semester.id;
            controller.initTemplate();

            controller.schedTemplate.name = 'Test';
            controller.schedTemplate.Is_Master__c = true;
            controller.addPeriodRow();
            controller.period.key__c= 'A';
            controller.period.start_Time_text__c='08:00 AM';
            controller.period.end_time_text__c='09:00 AM';
            controller.period.Passing_Time__c = '5';
            controller.savePeriod();

            controller.addPeriodRow();
            system.assertEquals(controller.period.start_Time_text__c,'09:05 AM');
            system.assertEquals(controller.period.end_time_text__c,'10:05 AM');
            system.assertEquals(controller.period.order__c,2);
            system.assertEquals(controller.PeriodList[0].key__c,'A');   
            system.assertEquals(controller.period.key__c,'2');
            controller.savePeriod();

            controller.saveschedTemplate();
            Schedule_Template__c pt = controller.schedTemplate;
            controller.TemplateID = pt.id;
            controller.initTemplate();
            controller.periodList[1].key__c = null;
            controller.saveschedTemplate(); 
            controller.periodList[1].key__c = 'B';
            ApexPages.currentPage().getParameters().put('periodId',controller.periodList[1].id);
            controller.saveschedTemplate(); 
            Schedule_Template__c pt2 =[select id, number_of_periods__c from Schedule_Template__c where id=:pt.id];
            system.assertEquals(pt2.Number_of_Periods__c,2);
            controller.TemplateID = pt2.id;
            controller.initTemplate();
            controller.editRow();
            controller.deleteRow();
            system.assertEquals(1,controller.periodList.size());
            PageReference pr2 = Page.core_scheduleTemplate;
            pr2.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
            test.setCurrentPage(pr2);
            core_scheduleTemplateConfiguration controller2 = new core_scheduleTemplateConfiguration();
            controller2.TemplateID = pt2.id;
            controller2.initTemplate();
            controller2.cancelschedTemplate();
        Test.stopTest(); 
    }
}
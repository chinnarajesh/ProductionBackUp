public with sharing class CT_Section_Utils {
/* **************   Start of Method Directly Called from Section Trigger ****************/
    public static Map<Id, List <Time_Element__c>> termRpMap;
    public static Map<Id, Id> parentTeMap;
    public static Map<Id, Id> finalRpMap;
    public static Map<Id, Time_Element__c> teMap;
    public static Map<Id, String> sectRtMap;
    public static Boolean     isForceCreateSectionRPs;
    public static Set<String> nonSectionRtSet = new Set<String>{
                                    'Schedule_Group',
                                    'Gradebook_Group',
                                    'Intervention_Section',
                                    'Curriculum'
                                };

    public static void getTeConfig(Set<Id> rppIds){
        if (termRpMap==null){
            finalRpMap = new Map <Id, Id>();
            parentTeMap = new Map <Id, Id>();
            termRpMap = new Map <Id, List <Time_Element__c>>();
            teMap = new Map <Id, Time_Element__c>();
            for(Id idx: rppIds){
                termRpMap.put(idx, new List <Time_Element__c>());
            }
            for (Time_Element__c te: [select name__c, id, date_start_date__c, parent_time_element__c , (select id from time__r)
                                                            from Time_Element__c 
                                                            where parent_time_element__c in: rppIds
                                                            order by parent_time_element__c, date_start_date__c]){
                parentTeMap.put(te.id, te.parent_time_element__c);
                termRpMap.get(te.parent_time_element__c).add(te);
                teMap.put(te.id, te);
                for (Time_Element__c finalTe: te.time__r){
                    finalRpMap.put(te.id, finalTe.id);
                }
            }
        }
    }    
    
    public static void processBeforeInsert(List <Section__c> newList){
        populateActiveField(newList);
        cascadeCompletedFlagFromSectionReportingPeriod(newList, null);
        translateSectionName(newList);
        mapTimeConfig(newList);
        verifyTimeConfig(newList, null);
        verifyWeightingConfig(newList, null);
    }

    public static void processAfterInsert(Map <Id, Section__c> newMap){
        cascadeSectionTimeChanges(newMap, null);
        //cascadeNumberOfPeriodsUpdate(newMap, null);
    }

    public static void processBeforeUpdate(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        cascadeCompletedFlagFromSectionReportingPeriod(newMap.values(), oldMap);
        updReferenceId(newMap, oldMap);
        verifyTimeConfig(newMap.values(), oldMap);
        verifyWeightingConfig(newMap.values(), oldMap);
        checkDeactivation1(newMap, oldMap);
    }

    public static void processAfterUpdate(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        cascadeSectionTimeChanges(newMap, oldMap);
        //cascadeNumberOfPeriodsUpdate(newMap, oldMap);
        cascadeStaffSectionRefIdUpdate(newMap, oldMap);//merge this functions
        checkDeactivation(newMap, oldMap);
    }

    public static void processBeforeDelete(List<Section__c> old){
        try{
            CT_core_TriggerUtils.cascadeDeletefromSections(old);  //Delete related objects that are not in masater-detail relationships
            Set<Id> sectionIds = new Set<Id>();
            for(Section__c s: old){
                sectionIds.add(s.id);
            }
            delete [select id from Section_Standard__c where Section__c IN: sectionIds];
        } catch(Exception e) {
            List<String> lstLinks = new List<String>();
            for(Section__c s: old){
                if(s.id != null){
                    lstLinks.add(s.name + ',' + s.id);
                }
            }
            insert CT_Error_Handling.handleError(String.join(lstLinks, ';'), 'Scheduler', 'updateSectionRefIds failed', e);
        }
    }
    
        /* **************   End of Method Directly Called from Section Trigger ****************/


    /****************** Start of Utility Methods ************************************/
    public static String generateSectionReference(String secName, String schoolRef, String timeName){
        if(String.isBlank(secName) || string.isBlank(schoolRef) || String.isBlank(timeName)){
            return null;
        }
        return secName + schoolRef + timeName;
    }

    //public static String generateSectionReference(Section__c sec){
    //    return sec.Name + sec.School_Reference__c + sec.Time_Name__c;
    //}

    public static void populateActiveField(List<Section__c> listSection){
        for(Section__c sec: listSection){
            if(sec.isNeedActivate__c){
                sec.Active__c = true;
            }
        }
    }

    public static void updReferenceId (Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        Set <Id> updSectionIDs = new Set <Id>();
        SchoolForce_Settings__c settings = SchoolForce_Settings__c.getOrgDefaults();
        //Set<ID> orgIDs = new Set<ID>{'00Dc00000001OMs','00DL00000009w6e','00DE0000000YCnU','00Dc00000001qrT','00Dc000000020td'};
        for (Section__c sect: newMap.values()){

            if (CT_core_TriggerUtils.scheduler){

                if (oldMap.get(sect.id).Reporting_Period__c!=null){

                    Id oldRpId = oldMap.get(sect.id).Reporting_Period__c;   // obtain the "original" reporting period ID value
                    if (sect.Reporting_Period__c!=oldRpId){ // trigger records don't contain the "original" reporting period ID value

                        sect.Reporting_Period__c=oldRpId;       // reset the reporting period ID to the "original" ID value

                    }
                }
                if (sect.Name!=oldMap.get(sect.id).name){   // trigger records name is not the same as the original or the one the auto generated name was changed to
                    sect.Name=oldMap.get(sect.id).name;     // reset the name to the original
                }
                //DE3193 scheduler should not update number of reporting periods on sections
                if (sect.Number_of_Reporting_Periods__c!=oldMap.get(sect.id).Number_of_Reporting_Periods__c){
                    sect.Number_of_Reporting_Periods__c = oldMap.get(sect.id).Number_of_Reporting_Periods__c;
                }
            }
            if (oldMap.get(sect.id).Time__c!=sect.time__c){
                sect.addError('Not allowed to update the year for Section record, please create new section');
            }
            if (oldMap.get(sect.id).School__c!=sect.School__c){
                sect.addError('Not allowed to update the school for Section record, please create new section');
            }
            if (sect.Name!=oldMap.get(sect.id).name && !settings.Static_Reference_IDs__c){
            //if (sect.Name!=oldMap.get(sect.id).name && !orgIDs.contains(UserInfo.getOrganizationId())){
                //add check to make sure the section Ref Id actually contains the sec name.
                if(!sect.Reference_Id__c.contains(sect.Name)){
                    sect.Reference_Id__c=sect.Reference_Id__c.replace(oldMap.get(sect.id).Name, sect.Name);
                }
                
            }
        }
    }
    
    public static void cascadeCompletedFlagFromSectionReportingPeriod(List<Section__c> listSection, Map<Id, Section__c> oldMap){
        for (Section__c sec: listSection){
            if(oldMap==null || sec.Reporting_Periods_NotCompleted__c != oldMap.get(sec.Id).Reporting_Periods_NotCompleted__c){
                sec.Completed__c = sec.Reporting_Periods_NotCompleted__c == 0? true: false;
            }
        }
    }
    
    public static void prefillFlagFromSectionReportingPeriod(List<Section_ReportingPeriod__c> listSRP, Map<Id, Section_ReportingPeriod__c> oldMap){    
        List<Section_ReportingPeriod__c> updateSrps = new List<Section_ReportingPeriod__c>();
        for(Section_ReportingPeriod__c srp: listSRP){
            if(oldMap == null || srp.Time__c != oldMap.get(srp.Id).Time__c){
                updateSrps.add(srp);
            }
        }

        for(Section_ReportingPeriod__c srp: updateSrps){
            srp.Is_Time_Parent_Term__c = srp.Time_Parent_Picklist_Name__c == 'Term';
        }
    }

    public static void mapTimeConfig(List<Section__c> sectList){
        Map <String, Time_Element__c> yearTeMap = new Map <String, Time_Element__c>();
        Map <String, Time_Element__c> rpTeMap = new Map <String, Time_Element__c>();
        Set <String> rpNameSet = new Set <String>();

        for (Section__c sect: sectList){
            if (!nonSectionRtSet.contains(sect.Section_RT__c)){
                if (sect.year_name__c==null&&sect.time__c==null){
                    sect.addError('Year Name or Time must be entered');
                }   
                else {
                    if (sect.time__c==null){
                        yearTeMap.put(sect.year_name__c, null); 
                    }
                }
                if (sect.reporting_period_Name__c==null&&sect.reporting_period__c==null){
                    sect.addError('Reporting Period Name or Reporting Period must be entered');
                }   
                else {
                    if (sect.reporting_period__c==null){
                        rpNameSet.add(sect.reporting_period_name__c);
                    }
                }
            }
        }
        
        if (!yearTeMap.keySet().isEmpty() || !rpNameSet.isEmpty()){
            for (Time_Element__c te: [Select id, name__c, parent_time_element__r.parent_time_element__c from Time_Element__c where (Name__c in :yearTeMap.keySet() and Picklist_Value__r.Name='Year') OR Name__c in :rpNameSet]){
                yearTeMap.put(te.name__c, te);
                if(te.Parent_time_element__r.Parent_time_element__c != null){
                    rpTeMap.put(te.name__c+'-'+te.parent_time_element__r.parent_time_element__c, te);
                }
            }
        }
        
        for (Section__c sect: sectList){
            if (sect.year_name__c!=null){
                if (yearTeMap.keySet().contains(sect.year_name__c)){
                    sect.time__c = yearTeMap.get(sect.year_name__c).id;
                }
            }
            if (sect.reporting_period_name__c!=null){
                if (rpTeMap.keySet().contains(sect.reporting_period_name__c+'-'+sect.time__c)){
                    sect.reporting_period__c = rpTeMap.get(sect.reporting_period_name__c+'-'+sect.time__c).id;
                }
            }
        }
    }
    
    public static void verifyTimeConfig(List<Section__c> sectList, Map<Id, Section__c> oldMap){
        //Check that the time element & rp 
        Set<Id>         reportingPeriodParentIds = new Set <Id>();
        for (Section__c sect: sectList){
            if (!nonSectionRtSet.contains(sect.Section_RT__c) && (oldMap==null ||
                    sect.number_of_Reporting_periods__c!=oldMap.get(sect.id).number_of_reporting_periods__c||
                    sect.reporting_period__c!=oldMap.get(sect.id).reporting_period__c)){
                if (sect.Reporting_Period__c==null) {
                    sect.addError('Reporting Period must be populated');
                }else {
                    reportingPeriodParentIds.add(sect.Reporting_Period_Parent__c);
                    if(oldMap!=null){
                        reportingPeriodParentIds.add(oldMap.get(sect.id).Reporting_Period_Parent__c);
                    }
                }
            }
        }
        
        if (!reportingPeriodParentIds.isEmpty()){
            getTeConfig(reportingPeriodParentIds);
            for (Section__c sec: sectList){
                if (oldMap!=null){
                    if (sec.reporting_period__c!=oldMap.get(sec.id).reporting_period__c){
                        if (!teMap.keySet().contains(sec.reporting_period__c)){
                            sec.reporting_period__c.addError('Only time elements that are base reporting periods are allowed');
                        }
                        else {
                            if(sec.name.contains(teMap.get(oldMap.get(sec.id).reporting_period__c).name__c)){
                                sec.name=sec.name.replace(teMap.get(oldMap.get(sec.id).reporting_period__c).name__c, teMap.get(sec.reporting_period__c).name__c);//Replace the time element portion of the name to match the new reporting period
                            }
                        }
                    }
                }
                //Integer i=0;
                //system.debug('termRpMap.get(parentTeMap.get(sec.reporting_period__c))~~'+termRpMap.get(parentTeMap.get(sec.reporting_period__c)));
                //system.debug('integer.valueOf(sec.number_of_reporting_periods__c)~~'+integer.valueOf(sec.number_of_reporting_periods__c));
                //system.debug('termRpMap~~'+termRpMap);
                //system.debug('parentTeMap~~'+parentTeMap);
                //for (Time_Element__c te: termRpMap.get(parentTeMap.get(sec.reporting_period__c))){
                //    if (te.id == sec.Reporting_Period__c&&i==0||i!=0){
                //        i++;
                //    }
                //}
                //system.debug('i~~'+i);
                //if (i > integer.valueOf(sec.number_of_reporting_periods__c)){
                    //sec.Number_of_Reporting_Periods__c.addError('Invalid starting reporting period & number of reporting periods combination');
                //}
            }
        }
    }
    
    public static void verifyWeightingConfig(List<Section__c> sectList, Map<Id, Section__c> oldMap){
        Set<Id>              courseIds  = new Set<Id>();
        Map<Id, Set<String>> courseWeightingConfigMap = new Map<Id, Set<String>>();
        for (Section__c sect: sectList){
            if (!nonSectionRtSet.contains(sect.Section_RT__c) && (oldMap==null ||
                    sect.number_of_Reporting_periods__c!=oldMap.get(sect.id).number_of_reporting_periods__c)){
                courseIds.add(sect.course__c);
                courseWeightingConfigMap.put(sect.course__c, new Set<String>{});
            }
        }

        if (!courseIds.isEmpty()){
            for (Course_Weightings__c cw: [select id, key__c, course__c, reporting_period_type__r.corresponding_value__c from Course_Weightings__c where course__c in :courseIds]){
                String weightingConfigKey = cw.course__c+'-'+cw.reporting_period_type__r.corresponding_value__c;
                if (!courseWeightingConfigMap.get(cw.course__c).contains(weightingConfigKey)){
                    courseWeightingConfigMap.get(cw.course__c).add(weightingConfigKey);
                }
            }
            for (Section__c sect: sectList){
                if (sect.course__c!=null){
                    if (courseWeightingConfigMap.get(sect.course__c)!=null){
                        String weightingConfigKey = sect.course__c+'-'+sect.number_of_reporting_periods__c;
                        Set <String> validConfigComboSet = courseWeightingConfigMap.get(sect.course__c);                    
                        if(!validConfigComboSet.contains(weightingConfigKey)){
                            sect.addError('No course weightings for selected course & number of reporting periods combination; please create course weightings.');  
                        }
                    }
                }
            }
        }
    }
    
    public static void checkDeactivation(Map<Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        Map<Id, Section__c> mapSections = new Map<Id, Section__c>();
        for(Section__c sec: newMap.values()){
            //if section was deactivated
            if( sec.Active__c != oldMap.get(sec.id).Active__c ) {
                if(!sec.Active__c && String.isBlank(sec.Section_Exit_Reason__c)){
                    sec.Section_Exit_Reason__c.addError('Please choose Exit Reason');
                    continue;
                }
                mapSections.put(sec.id, sec);
            }
        }
        
        if(!mapSections.isEmpty() && CT_core_TriggerUtils.disabledProceedSS==false){
            CT_core_triggerUtils.populateDeactivateActivateSS(mapSections, oldMap, CT_core_triggerUtils.SOBJTYPE.SECTION, CT_core_triggerUtils.SOBJMODE.All);
            //CT_core_triggerUtils.activateDeactivateStaffAndStudentSections(mapSections, oldMap);    
        }
    }

    public static void checkDeactivation1(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        for(Section__c sec: newMap.values()){
            //if section was deactivated
            if(sec.Active__c && sec.Student_Section_Active_Count__c != oldMap.get(sec.id).Student_Section_Active_Count__c){
                sec.Active__c = sec.Student_Section_Active_Count__c==0? false: true;
            }
            if(!sec.Active__c && oldMap.get(sec.id).Active__c) {
                sec.Deactivated__c = true;     
                if(CT_core_TriggerUtils.disabledProceedSS && String.isBlank(sec.Section_Exit_Reason__c)){
                    sec.Section_Exit_Reason__c = CT_core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
                }
                if(CT_core_TriggerUtils.disabledProceedSS && sec.Section_Exit_Date__c==null){
                    sec.Section_Exit_Date__c = DateTime.now();
                }
            }
            if(sec.Active__c && !oldMap.get(sec.id).Active__c) {
                sec.Section_Exit_Reason__c = '';
                sec.Section_Exit_Date__c = null;
            }
        }
    }

    public static void cascadeSectionTimeChanges(Map<Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        List<Section__c> sectionList = new List<Section__c>();
        Set<Id> reportingPeriodParentIds = new Set<Id>();
        for (Section__c sect: newMap.values()){
            if (!nonSectionRtSet.contains(sect.Section_RT__c) && (oldMap==null || 
                    sect.number_of_Reporting_periods__c!=oldMap.get(sect.id).number_of_reporting_periods__c ||
                    sect.reporting_period__c!=oldMap.get(sect.id).reporting_period__c ||
                    isForceCreateSectionRPs == true)){
                sectionList.add(sect);
                reportingPeriodParentIds.add(sect.Reporting_Period_Parent__c);
            }
        }
        if (!sectionList.isEmpty()){
            getTeConfig(reportingPeriodParentIds);
            CT_Scheduler_TriggerUtils.createSectionRPs(sectionList);
        }
    }
    
    public static void cascadeStaffSectionRefIdUpdate(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
        Map<Id, Section__c> changeRpSectionMap = new Map<Id, Section__c>();
        Set<Id> updSectionIDs = new Set <Id>();
        for (Section__c sect: newMap.values()){
            if (sect.Name!=oldMap.get(sect.id).name){
                updSectionIDs.add(sect.id);
            }
        }
        if(!updSectionIDs.isEmpty()){
            CT_core_triggerUtils.updateStaffSectionRefIdsFromSection(updSectionIDs);
        }
    }
    
    //new formula field Section_Number_Of_Periods__c over Number_of_Periods__c on Section_ReportingPeriod__c
    //public static void cascadeNumberOfPeriodsUpdate(Map<ID, Section__c> newMap, Map<ID, Section__c> oldMap){
    //    Set<ID> sectionIDs = new Set<ID>();
    //    for(Section__c section: newMap.values()){
    //        if(oldMap==null || newMap.get(section.id).Number_of_Periods__c!=oldMap.get(section.id).Number_of_Periods__c){
    //            sectionIDs.add(section.id);
    //        } 
    //    }
    //    if(sectionIDs.size()>0){
    //        List<Section_ReportingPeriod__c> srps = [SELECT id, Section__c FROM Section_ReportingPeriod__c WHERE Section__c IN :sectionIDs];
    //        for(Section_ReportingPeriod__c srp: srps){
    //            srp.Number_of_Periods__c = newMap.get(srp.Section__c).Number_of_Periods__c;
    //        }
    //        update srps;
    //    }
    //}
    
    public static void translateSectionName(List <Section__c> newList){
        for (Section__c sect: newList){
            /*Autopop Section Name in Spanish - US1310*/
            if (sect.Schedule_Group__c!=null && sect.Course__c !=null){
                String spanishCourseName = sect.Course_Name_Spanish__c !=null ? sect.Course_Name_Spanish__c : null;
                String  spanishGroupName = sect.Schedule_Group_Name_Spanish__c !=null? sect.Schedule_Group_Name_Spanish__c : sect.Schedule_Group_Name__c;
                if (spanishCourseName!=null) sect.Name_Spanish__c = spanishGroupName + ' - ' + spanishCourseName;
            }
        }
    }
    
    public static void checkSectionReportingPeriodDeletion(Map <Id, Section_ReportingPeriod__c> oldMap){
        Map <String, Boolean> srpValidationMap = new Map <String, Boolean>();
        Set <Id> sectionIds = new Set <Id>();
        Set <Id> timeIds = new Set <Id>();
        //DE2987 changing Map<ID,String> to Map<String,String> since scheduler reference id will be string, NOT id
        Map <String, String> schedulerRefIdToSrpMap  = new Map <String, String>();
        Map <String, List <Scheduled_Section__c>> srpKeySsDelMap= new Map <String, List <Scheduled_Section__c>>();
        List <Session__c> sessionList = new List <Session__c>();
        List <Scheduled_Section__c> ssDelList = new List <Scheduled_Section__c>();
        for (Section_ReportingPeriod__c srp:oldMap.values()){
            sectionIds.add(srp.section__c);
            timeIds.add(srp.time__c);
            srpValidationMap.put(srp.section__c+'-'+srp.time__c, false);
            if (srp.Scheduler_ReferenceId__c!=null){
                schedulerRefIdToSrpMap.put(srp.Scheduler_ReferenceId__c, srp.section__c+'-'+srp.time__c);
            }
        }

        for(Section__c sect :[SELECT Id, 
                    (SELECT Id, Section__c, Time__c FROM Assignments__r WHERE Time__c in :timeIds), 
                    (SELECT Id, Section__c, Section_reference_id__c, Reporting_period__c FROM Scheduled_Sections__r), 
                    (SELECT Id, Section__c, Time__c, Attendance_Count__c FROM Sessions__r WHERE Time__c in :timeIds) 
                FROM Section__c WHERE Id = :sectionIds]){

            for (Assignment__c ja :sect.Assignments__r){                
                String srpKey = ja.Section__c+'-'+ja.Time__c;
                if (srpValidationMap.containsKey(srpKey)){
                    srpValidationMap.put(srpKey, true);
                }  
            }
            for (Scheduled_Section__c ss :sect.Scheduled_Sections__r){
                String srpKey = ss.Section_reference_id__c!=null? schedulerRefIdToSrpMap.get(ss.Section_reference_id__c): ss.Section__c+'-'+ss.Reporting_period__c;
                if (srpValidationMap.containsKey(srpKey)){
                    if(!srpKeySsDelMap.containsKey(srpKey)){
                        srpKeySsDelMap.put(srpKey, new List<Scheduled_Section__c>());
                    }
                    srpKeySsDelMap.get(srpKey).add(ss);
                }
            }
            //Delete Sessions; will prevent if has attendance
            for (Session__c sess :sect.Sessions__r){
                String srpKey = sess.Section__c+'-'+sess.Time__c;
                if (srpValidationMap.containsKey(srpKey)){
                    if (!srpValidationMap.get(srpKey)){
                        if (sess.Attendance_Count__c>0){
                            srpValidationMap.put(srpKey, true);
                        }
                        else {
                            sessionList.add(sess);
                            if (srpKeySsDelMap.get(srpKey)!=null){
                                ssDelList.addAll(srpKeySsDelMap.get(srpKey));
                            }
                        }
                    }
                }
            }
        }

        //PTN - need a way to restore any sessions that shouldnt be deleted.  
        for (Section_ReportingPeriod__c srp:oldMap.values()){
            String srpKey = srp.section__c+'-'+srp.time__c;
            if (srpValidationMap.get(srpKey)){
                srp.addError('Deletion of Section Reporting Period not allowed. Please delete all assignments & attendance related to the reporting period and section being purged');
            }
        }
        if (!sessionList.isEmpty()){
            delete sessionList;
        }
        if (!ssDelList.isEmpty()){
            delete ssDelList;
        }
    }
    
    /****************** End of Utility Methods ************************************/
}
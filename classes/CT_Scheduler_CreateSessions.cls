public class CT_Scheduler_CreateSessions {
    public List<Schedule_Day__c>           scheduleDaysList;
    public List<HoldingObj__c>             holdingSource;
    public List<Period__c>                 pList;                      
    public Set<Id>                         schedTempIds;                       
    public Set<Id>                         reportingPeriodIds; 
    public Set<Id>                         school; 
    public Set<String>                     periodKeys;
    public Set<String>                     schedSecKeys;
    public Map<String, Session__c>         sessionList;
    public Set<Date>                       schedDays;  
    public Map<Id, List<Period__c>>        schedTempToPeriodMap;
    public Map<String, List<Period__c>>    periodKeyToPeriodMap;
    public Map<String, List<Section_ReportingPeriod__c>>   periodKeyToSectionMap;
    public Map<String, List<Section_ReportingPeriod__c>>   schedSecToSectionMap;
    public Map<Id, List<Scheduled_Section__c>>             schedTempToSchedSecMap;
    public Map<String,List<Scheduled_Section__c>>          schedSecKeyToSchedSecMap;
    public Map<Id, Schedule_Template__c>                   schedTempIdToScheduleTemplate;
    public Map<Id,Section_ReportingPeriod__c>              sectionIdToSection;
    
 
        public CT_Scheduler_CreateSessions(List<Schedule_Day__c> scheduleDayList, List<HoldingObj__c> source){
            schedTempIds = new Set<Id>();
            schedDays = new Set<Date>();
            school = new Set<Id>();
            reportingPeriodIds = new Set<Id>();
            holdingSource = source;

            /*Create a set Of Schduletemplate ids by looping through the schedule Days*/
            for(Schedule_Day__c sd : scheduleDayList){
                schedTempIds.add(sd.Schedule_Template__c);
                schedDays.add(sd.day__c);
                school.add(sd.Schedule_Template__r.Setup__r.School__c);
                reportingPeriodIds.add(sd.Reporting_Period__c);
            }
            System.debug('\n\n scheduleDayList => ' + scheduleDayList + '\n');
            System.debug('\n\n reportingPeriodIds => ' + reportingPeriodIds + '\n');
            
            /* Retrieve all the periods whose schedule Template is in the list of schedTempIds */
            pList = getPeriods();
            createMapOfSchedTempIdScheduleTemplate(schedTempIds);
            
            /* If ther are any existing period records then create Maps to create sessions for Period based scheduling*/
            if(pList.size() > 0){
                createMapOfSchedTempToPeriod(pList);
                createMapOfPeriodToSection();
            }
            else{/* if there are no period records then create Maps to create sessions for Group based scheduling*/
                createMapOfSchedTempToSchedSec();
                createMapOfSchedSecToSection();
            }
        }
        
        /* Retrieve all the periods whose schedule Template is in the list of schedTempIds */
        public List<Period__c> getPeriods(){
            return [SELECT Id
                            ,Schedule_Template__c
                            ,Key__c
                            ,Start_Time__c
                            ,End_Time__c
                    FROM Period__c
                    WHERE Schedule_Template__c in : schedTempIds
                    order by Schedule_Template__c,Start_Time__c];
        }
        
        public void createMapOfSchedTempIdScheduleTemplate(Set<Id> schedTempIds){
            schedTempIdToScheduleTemplate = new Map<Id, Schedule_Template__c>();            
            for(Schedule_Template__c st : [SELECT Start_Time__c,End_Time__c,Id,Has_Class__c FROM Schedule_Template__c WHERE Id in : schedTempIds]){
                schedTempIdToScheduleTemplate.put(st.Id,st);
            }            
        } 
        
        /* If period Based scheduling iterate over the list of periods and create the following maps:
            1) schedTempToPeriodMap - ScheduleTemplate Id , List Of Periods
            2) periodKeyToPeriodMap - Period Key, Period
           periodKeys- Create a list of period Keys  to retrieve all the Sections related to the periodKeys
        */
        public void createMapOfSchedTempToPeriod(List<Period__c> prdList){
            schedTempToPeriodMap = new Map<Id, List<Period__c>>();
            periodKeyToPeriodMap = new Map<String,List<Period__c>>();
            //periodKeys = new Set<String>();
            
            for(Period__c p : prdList){   
                if(!schedTempToPeriodMap.containskey(p.Schedule_Template__c)){
                    schedTempToPeriodMap.put(p.Schedule_Template__c, new List<Period__c>());
                }
                schedTempToPeriodMap.get(p.Schedule_Template__c).add(p);
            }
        } 
        
        /* Retrieve all the sections related to the periods and create a map of  periodKey and its corresponding Section.*/
        public void createMapOfPeriodToSection(){
            periodKeyToSectionMap = new Map<String,List<Section_ReportingPeriod__c>>();
            sectionIdToSection = new Map<Id,Section_ReportingPeriod__c>();
            List<Section_ReportingPeriod__c> sectionsToPublish = new List<Section_ReportingPeriod__c>();

            Set<Id> holdingIds = new Map<Id, HoldingObj__c>(new List<HoldingObj__c>(holdingSource)).keySet();
            String querySectionsToPublish = 'SELECT Period__c,Section__c,Section__r.Name,Section__r.Record_Attendance__c,Section__r.No_Meeting__c'
                +',Section__r.Daily_Attendance__c,Time__c,Section__r.School__r.reference_Id__c,ReferenceId__c'
                +' FROM Section_ReportingPeriod__c WHERE Time__c IN (\''+ String.join(new List<Id>(reportingPeriodIds), '\',\'')+'\')'
                +' AND Section__r.School__c IN (\''+String.join(new List<Id>(school), '\',\'')+'\')'
                +' AND recordTypeId = \'' +CT_core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('Published')+'\''
                +' AND Section__r.No_Meeting__c = false';
            if(!holdingIds.isEmpty()){
                querySectionsToPublish += ' AND Section__r.Holding_Source__c IN (\''+String.join(new List<Id>(holdingIds), '\',\'')+'\')';
            }
            System.debug('@@@ querySectionsToPublish: '+querySectionsToPublish);
            System.debug('\n\n reportingPeriodIds => ' + reportingPeriodIds + '\n');
            System.debug('\n\n school => ' + school + '\n');
            System.debug('\n\n sectionsToPublish => ' + sectionsToPublish + '\n');
            sectionsToPublish = Database.query(querySectionsToPublish);

            for(Section_ReportingPeriod__c s : sectionsToPublish){
                if(s.Section__r.Daily_Attendance__c){
                    sectionIdToSection.put(s.Id,s);
                }else if(s.Period__c != null){
                    String[] prdKeys = s.Period__c.split(',');
                    for(String st: prdKeys){
                        if(!periodKeyToSectionMap.containskey(st)){
                            periodKeyToSectionMap.put(st, new List<Section_ReportingPeriod__c>());
                        }
                        periodKeyToSectionMap.get(st).add(s);
                    }
                }
            }
        }
        
        /* Create Sessions for all the schedule days:
            1) loop through the list of Schedule Days and retrieve all the corresponding sections.
            2) Create sessions for each retrieved Section.
        
         */
        public Database.UpsertResult[] createSessionsForPeriods(List<Schedule_Day__c> scheduleDaysList){
            sessionList = new Map<String, Session__c>();
            //Set<String> referenceIdSet = new Set<String>();
            for(Schedule_Day__c sd : scheduleDaysList){
                System.debug('Checking schedule day '+sd);
                System.debug('Does schedule template have class? '+schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).Has_Class__c);
                if(schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).Has_Class__c){
                    System.debug('Does schedule template have periods? '+schedTempToPeriodMap.containskey(sd.Schedule_Template__c));
                    if(schedTempToPeriodMap.containskey(sd.Schedule_Template__c)){
                        System.debug('Check periods');
                        for(Period__c p : schedTempToPeriodMap.get(sd.Schedule_Template__c)){
                            System.debug('Checking period '+p);
                            System.debug('Does the period have sections? '+periodKeyToSectionMap.containskey(p.Key__c));
                            if(periodKeyToSectionMap.containskey(p.Key__c)){
                                for(Section_ReportingPeriod__c sec : periodKeyToSectionMap.get(p.Key__c)){
                                    System.debug('Adding session for '+sec);
                                    Session__c sess = new Session__c();
                                    String sectionName = (sec.Section__r.Name.length()>60)? sec.Section__r.Name.substring(0,60): sec.Section__r.Name;
                                    sess.Name = sectionName+'-'+dateTime.newInstance(sd.Day__c, p.End_Time__c.time()).format();  
                                    sess.Section__c = sec.Section__c;
                                    sess.Start_DateTime__c = dateTime.newInstance(sd.Day__c, p.Start_Time__c.time());
                                    sess.End_DateTime__c = dateTime.newInstance(sd.Day__c, p.End_Time__c.time());
                                    sess.Record_Attendance__c = sec.Section__r.Daily_Attendance__c ==true? true: sec.Section__r.Record_Attendance__c;
                                    sess.Time__c = sec.Time__c;
                                    sess.Reference_Id__c = sec.Section__c+'-'+sec.Time__c+'-'+p.Key__c+ '-'+ sd.Day__c;
                                    if (!sessionList.containsKey(sess.Reference_Id__c)){
                                        sessionList.put(sess.Reference_Id__c, sess);
                                    }
                                }
                            }
                        }
                    }
                }
                System.debug('Size of Homeroom classes'+sectionIdToSection.values().size());
                if(sectionIdToSection.values().size() > 0){
                    if((schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).Has_Class__c) && (schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).End_Time__c != null) && (schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).Start_Time__c != null)){    
                        for(Section_ReportingPeriod__c sec: sectionIdToSection.values()){
                            Session__c sess = new Session__c();
                            String sectionName = (sec.Section__r.Name.length()>60)? sec.Section__r.Name.substring(0,60): sec.Section__r.Name;
                            sess.Name = sectionName+'-'+dateTime.newInstance(sd.Day__c, schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).End_Time__c.time()).format();
                            sess.Section__c = sec.Section__c;
                            sess.Start_DateTime__c = dateTime.newInstance(sd.Day__c, schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).Start_Time__c.time());
                            sess.End_DateTime__c = dateTime.newInstance(sd.Day__c, schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).End_Time__c.time());
                            sess.Record_Attendance__c = sec.Section__r.Daily_Attendance__c ==true? true: sec.Section__r.Record_Attendance__c;
                            sess.Time__c = sec.Time__c;
                            sess.Reference_Id__c = sec.Section__c +'-'+sec.Time__c+ '-'+ sd.Day__c;
                            if (!sessionList.containsKey(sess.Reference_Id__c)){
                                sessionList.put(sess.Reference_Id__c, sess);
                            }
                        }
                    }
                }
            }
            try{
                Database.UpsertResult[] results = Database.upsert(sessionList.values(), Session__c.Reference_Id__c, false);
                return results;
            }
            catch(Exception e){
                System.debug('Insert Failed:'+e);
                return null;
            }
        }

        /* Retrieve all the sessions for the list of schedule days:
            1) loop through the list of Schedule Days and retrieve all the corresponding sections.
            2) Retrieve all the sessions related to the sections.
        
         */
  
        public void retrieveSessionsForPeriods(List<Schedule_Day__c> scheduleDaysList){
            sessionList = new Map<String, Session__c>();
            Set<Id> sectList = new Set<Id> ();
            Set<Date> schedDayList = new Set<Date> ();
            for(Schedule_Day__c sd : scheduleDaysList){
                System.debug('$$$$SD$$$'+sd);
                if(schedTempToPeriodMap != null && schedTempToPeriodMap.containskey(sd.Schedule_Template__c)){
                    for(Period__c p : schedTempToPeriodMap.get(sd.Schedule_Template__c)){
                        if(periodKeyToSectionMap.containsKey(p.Key__c) != null){
                            if(periodKeyToSectionMap.get(p.Key__c) != null){
                            for(Section_ReportingPeriod__c sec : periodKeyToSectionMap.get(p.Key__c)){
                                sectList.add(sec.Section__c);
                            }
                            }
                        }
                    }
                }
                schedDayList.add(sd.day__c);
            }
            if(sectionIdToSection !=null && sectionIdToSection.keyset().size() > 0){
                sectList.addAll(sectionIdToSection.keySet());
            }
            if( sectList.size() > 0 && schedDayList.size() > 0){
                sessionList = getSessions(sectList,schedDayList);
            }
            
        }
  
  
        public void createMapOfSchedTempToSchedSec(){
            schedTempToSchedSecMap = new Map<Id, List<Scheduled_Section__c>>();
            schedSecKeyToSchedSecMap = new Map<String,List<Scheduled_Section__c>>();
            schedSecKeys = new Set<String>();
            for(Scheduled_Section__c ss : [SELECT Id
                                      ,Schedule_Template__c
                                      ,Reference_Id__c
                                      ,Daily_Attendance__c
                                      ,Record_Attendance__c
                                      ,Start_Time__c
                                      ,End_Time__c
                                      ,Reporting_Period__c
                                      ,Section_Reference_Id__c
                                      FROM Scheduled_Section__c WHERE Schedule_Template__c in : schedTempIds
                                      AND No_Meeting__c = false]){
                
                if(!schedTempToSchedSecMap.containskey(ss.Schedule_Template__c)){
                    schedTempToSchedSecMap.put(ss.Schedule_Template__c, new List<Scheduled_Section__c>());
                }
                schedTempToSchedSecMap.get(ss.Schedule_Template__c).add(ss);
                if (ss.Section_reference_Id__c!=null){
                        if(!schedSecKeyToSchedSecMap.containskey(ss.Section_Reference_Id__c)){
                            schedSecKeyToSchedSecMap.put(ss.Section_Reference_Id__c, new List<Scheduled_Section__c>());
                        }
                        schedSecKeyToSchedSecMap.get(ss.Section_Reference_Id__c).add(ss);
                        schedSecKeys.add(ss.Section_Reference_Id__c);
                    }
                }
        }
        
        public void createMapOfSchedSecToSection(){
            schedSecToSectionMap = new Map<String,List<Section_ReportingPeriod__c>>();
            List<Section_ReportingPeriod__c> sectionsToPublish = new List<Section_ReportingPeriod__c>();
            Set<Id> holdingIds = new Map<Id, HoldingObj__c>(new List<HoldingObj__c>(holdingSource)).keySet();

            String querySectionsTopublish = 'SELECT Id,Section__r.Name,Period__c,Section__r.Record_Attendance__c,Section__r.Daily_Attendance__c,'
                +'Time__c,Section__r.School__r.reference_Id__c,ReferenceId__c,Scheduler_ReferenceId__c'
                +' FROM Section_ReportingPeriod__c '
                +' WHERE Scheduler_ReferenceId__c IN (\''+String.join(new List<String>(schedSecKeys), '\',\'')+'\')';
            if(!holdingIds.isEmpty()){
                querySectionsTopublish += ' AND Section__r.Holding_Source__c IN (\''+String.join(new List<Id>(holdingIds), '\',\'')+'\')';
            }
            System.debug('@@@ querySectionsTopublish: '+querySectionsTopublish);
            sectionsTopublish = Database.query(querySectionsTopublish);

            for(Section_ReportingPeriod__c s : sectionsToPublish){
                if(!schedSecToSectionMap.containskey(s.Scheduler_ReferenceId__c)){
                    schedSecToSectionMap.put(s.Scheduler_ReferenceId__c, new List<Section_ReportingPeriod__c>());
                }
                schedSecToSectionMap.get(s.Scheduler_ReferenceId__c).add(s);
            }        
        }
        
        
        public Database.UpsertResult[] createSessionsForScheduledSects(List<Schedule_Day__c> scheduleDaysList){
            sessionList = new Map<String, Session__c>();
            for(Schedule_Day__c sd : scheduleDaysList){
              if((schedTempIdToScheduleTemplate.get(sd.Schedule_Template__c).Has_Class__c)){        
                if(schedTempToSchedSecMap.containskey(sd.Schedule_Template__c)){
                    for(Scheduled_Section__c ss : schedTempToSchedSecMap.get(sd.Schedule_Template__c)){
                        if(schedSecToSectionMap.containskey(ss.Section_Reference_Id__c)){
                            if(schedSecToSectionMap.get(ss.Section_Reference_Id__c) != null){
                            for(Section_ReportingPeriod__c sec : schedSecToSectionMap.get(ss.Section_Reference_Id__c)){
                                Session__c sess = new Session__c();
                                String sectionName = (sec.Section__r.Name.length()>60)? sec.Section__r.Name.substring(0,60): sec.Section__r.Name;
                                sess.Name = sectionName +'-'+dateTime.newInstance(sd.Day__c, ss.Start_Time__c.time()).format();
                                sess.Section__c = sec.Section__c;
                                sess.Start_DateTime__c = dateTime.newInstance(sd.Day__c, ss.Start_Time__c.time());
                                sess.End_DateTime__c = dateTime.newInstance(sd.Day__c, ss.End_Time__c.time());
                                sess.Record_Attendance__c = sec.Section__r.Daily_Attendance__c ==true? true: sec.Section__r.Record_Attendance__c;
                                sess.Time__c = sec.Time__c;
                                sess.Reference_Id__c = sec.Section__c +'-'+ sec.Time__c+'-'+ sd.Day__c;
                                if (!sessionList.containsKey(sess.Reference_Id__c)){
                                    sessionList.put(sess.Reference_Id__c, sess);
                                }
                            }
                        }
                        }
                    }
                }
              }
            }
            try{
                Database.UpsertResult[] results = Database.upsert(sessionList.values(), Session__c.Reference_Id__c, false);
                return results;
            }
            catch(Exception e){
                System.debug('Insert Failed:'+e);
                return null;
            }
        
        }
              
        public void retrieveSessionsForScheduledSects(List<Schedule_Day__c> scheduleDaysList){
            sessionList = new Map<String, Session__c>();
            Set<Id> sectList = new Set<Id> ();
            Set<Date> schedDayList = new Set<Date> ();
            
            for(Schedule_Day__c sd : scheduleDaysList){
                if(schedTempToSchedSecMap != null && schedTempToSchedSecMap.containskey(sd.Schedule_Template__c)){
                    for(Scheduled_Section__c ss : schedTempToSchedSecMap.get(sd.Schedule_Template__c)){
                            if(schedSecToSectionMap.containskey(ss.Section_Reference_Id__c)){
                                if(schedSecToSectionMap.get(ss.Section_Reference_Id__c) !=null){
                                    for(Section_ReportingPeriod__c sec : schedSecToSectionMap.get(ss.Section_Reference_Id__c)){
                                        sectList.add(sec.Section__c);
                                        system.debug('sect~~~'+sec);
                                    }
                                }
                            }

                    }
                }       
                schedDayList.add(sd.day__c);
            
            }
            sessionList = getSessions(sectList,schedDayList);
        }
  
        public Map<String, Session__c> getSessions(Set<Id> sectList,Set<Date> schedDayList){
            Map<String, Session__c> mapSessions = new Map<String, Session__c>();
            for(Session__c s: [SELECT Id, Reference_Id__c FROM Session__c WHERE Section__c in : sectList AND Session_Date__c in : schedDayList]){
                mapSessions.put(s.Reference_Id__c, s);
            }
            return mapSessions;
        
        }
  
        public void publishScheduleDays(List<Schedule_Day__c> scheduleDaysList){       
            for(Schedule_Day__c sd : scheduleDaysList){
                 sd.Published__c = true;
            }   
            try{
                update scheduleDaysList;
            }
            catch(Exception e){
                System.debug('Update Failed:'+e);
            }
        
        }

}
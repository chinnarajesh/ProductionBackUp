global with sharing class mock_setupUtil {
    
    global static string sYear = 'Year 0,8/1/2099-7/31/2100'; 
    global static boolean bGroupBased = false;
    global static boolean useLegacyScale = false;
    global static date startYear = date.newInstance(2099,8,1); //Deprecated for Chicago
    global static date endYear = date.newInstance(2100,7,31); //Deprecated for Chicago
    
    global static void runBaseSetup(){
        createIndividualAccount();
        loadStaticResources();
        String[] strings = sYear.split(',');
        String[] years = strings[1].split('-');
        startYear = date.parse(years[0]);
        endYear = date.parse(years[1]);
        createYearRecord(strings[0], startYear, endYear);
    }
    
    global static void runStaff(){
        insertSampStaff();
        executeRosterLoad('Staff'); 
    } 
    
    global static void runStudents(){
        insertSampStudent();        
        executeRosterLoad('Student');
    }
    
    global static void runCourses(){ 
        setupDefaultPlValues();
        setupCourses();  
    }
    
    global static void runSetup(){
        setupCatalogs();
        setupDefaultTerms(); 
        setupTermSetup(); 
    }
    
    global static void createSchools(){
        
        List <Account> schoolList = new List <Account>();
        List<HoldingObj__c> staffList = new List<HoldingObj__c>();
        String[] defaultStaff = core_SoqlUtils.processCSVFile('samp_staffRoster');
        Set <String> dbnSet = new Set <String>();
        for (Integer i=0;i<defaultStaff.size();i++){
            Account school = new Account (RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Account').get('School'));
            String[] inputvalues = defaultStaff[i].split(',');
            school.name = inputvalues[1];
             school.reference_id__c = inputvalues[1];
             if (test.isRunningTest()){
                 school.reference_id__c = school.reference_id__c+'**';
                  school.name = school.name+'**';
             }
             if (!dbnSet.contains(school.reference_id__c)){
                schoolList.add(school);
                dbnSet.add(school.reference_id__c);
             }
         
        }
        insert schoolList;
        
        List<Setup__c> setups = [SELECT id FROM Setup__c WHERE School__c IN :schoolList];
        if(setups.size()==0){
            Time_Element__c year = [select id from Time_Element__c where Name__c =:sYear.split(',')[0] limit 1];
            for(integer i = 0; i < schoolList.size(); i++){
                Setup__c newSetup = new Setup__c();
                newSetup.School__c = schoolList[i].id;
                newSetup.Year__c = year.id;
                newSetup.Active__c = true;
                setups.add(newSetup);
            }
            insert setups;
        }
    }
    
    global static void runRandomizeSetup(){
        //Deprecated for Chicago
    }
    global static void runRandomizeSetup(string inputYear){
        List<Setup__c> sList = new List<Setup__c>();
        Set <boolean> booleanCheckSet = new Set <Boolean>();
        for (Setup__c s : [select id, school__r.Reference_Id__c, school__r.Name, Course_Catalog__c, room_dependent__c, term__c, term__r.parent_time_element__c, group_based__c, school__c from Setup__c
        where year__r.name__c =:inputYear]){
           if(test.isRunningTest()){
            if (s.Group_Based__c==bGroupBased){
            Account a =[select name, reference_id__c from account where id=:s.school__c];
                    if (s.school__r.Reference_Id__c.contains('**')){ sList.add(s);
                    break;
                    }
                }
           }
           else sList.add(s);
        }
        randomizeSetup(sList);
    }
    
    
    global static void randomizeSetup(List<Setup__c> sList){ 
        Set<ID> setupIDs = new Set<ID>();
        List<String> calcTypes = new List<String>();
        for(Schema.PicklistEntry plv: Schema.Setup__c.Calculation_Type__c.getDescribe().getPicklistValues()){
            calcTypes.add(plv.getLabel());
        }
        for (Setup__c s : sList){
            s.Room_Dependent__c = (math.random().round()==0?false:true);
            s.Behavior_Referal_Details__c =  (math.random().round()==0?false:true);
            s.Passing_Grade_Threshold__c =  ((math.random()*100).round());
            do {
                s.Passing_Grade_Threshold__c =  ((math.random()*100).round());
                s.On_Track_Threshold__c = s.Passing_Grade_Threshold__c+10;
            } while (80 < s.Passing_Grade_Threshold__c || s.Passing_Grade_Threshold__c < 40);
            //s.Standards_Based_Grading__c  =(math.random().round()==0?false:true);
            if(s.Standards_Based_Grading__c){
                //s.Standards_ONLY_Gradebook__c = math.random().round()==0;
                s.Calculation_Type__c = calcTypes[integer.valueOf(math.floor(math.random()*calcTypes.size()))];
            }
            //s.Group_Based__c = bGroupBased;
            //bGroupBased=!bGroupBased;
            setupIDs.add(s.id);
        } 
        update sList; 
        
        for (Setup__c s : [select id, school__r.Reference_Id__c, Course_Catalog__c, room_dependent__c, term__c, term__r.parent_time_element__c, group_based__c, school__c from Setup__c where id IN :setupIDs]){
           setupCalendaring(s.id);
        }
    }
    
    @future 
    global static void setupCalendaring(ID setupId){
         for (Setup__c s : [select id, school__r.Reference_Id__c, Course_Catalog__c, room_dependent__c, term__c, term__r.parent_time_element__c, group_based__c, school__c from Setup__c where id =:setupID]){
           setupScheduleTemplates(s);
            setupCalendar(s);
        }
    }
    
    global static void createSchedule(String inputYear){
        for (Setup__c s : [select year__c, id, school__r.Reference_Id__c, Course_Catalog__c, room_dependent__c, term__c, term__r.parent_time_element__c, group_based__c, school__c from Setup__c where year__r.name__c =:inputYear]){
            if (s.Room_Dependent__c){
                setupRooms(s);
            }
            if (s.Group_Based__c){
                setupScheduleGroups(s);
                randomizeScheduledSections_Group(s.id);
                
            }
            else {
                loadSections(s);
                randomizeScheduledSections(s.id);
            }
            Section_Utils.termRpMap=null;
            Section_Utils.parentTeMap=null;
            Section_Utils.reportingPeriodIds=null;
            Section_Utils.finalRpMap=null;
        }
    }
    
    
    global static void setupScheduleTemplates(Setup__c setup){
        //Setup 2 templates; various lengths; various breaks; various number; 
        //Differentiate start time & end times vs group based ;
        //Randomize Colors
        List <Integer> startHourList = new List <Integer>{8,9,10,11};
        List <Integer> endHourList = new List <Integer>{13,14,15,16};
        List <Integer> classDuration = new List <Integer>{10, 20, 30, 40, 50, 60};
        List <Integer> classBreak = new List <Integer>{1,2,3,4,5,6};
        List <Schedule_Template__c> stList = new List <Schedule_Template__c>();
        Map <String, List <Period__c>> periodMap = new Map <String, List <Period__c>>();
        List <Period__c> periodList = new List <Period__c>();
                
        List<Time_Element__c> rpList = core_SoqlUtils.getTimeElementsByTerm(setup.term__c, true);
                
            Boolean bMaster = false;
            for (Integer k = 1 ; k<=2; k++){
                    Schedule_Template__c st = new Schedule_Template__c (Name=k+' Template', setup__c = setup.id);
                    st.Has_Class__c = true;
                    st.Color__c = core_ColoringUtils.RGBToHex(math.floor(math.random()*256), math.floor(math.random()*256),math.floor(math.random()*256));
                    if (st.Has_Class__c){
                        if (!bMaster) {
                            st.Is_Master__c = true;
                            bMaster = true;
                        }
                        Time startTime = time.newInstance(startHourList[Integer.valueOf(math.floor(startHourList.size()*math.random()))], Integer.valueOf(math.floor(60*math.random())), 0, 0);
                        Time endTime = time.newInstance(endHourList[Integer.valueOf(math.floor(endHourList.size()*math.random()))], Integer.valueOf(math.floor(60*math.random())), 0, 0);
                        st.Start_Time__c = dateTime.newInstance(system.today(), startTime);
                        st.Start_Time_Text__c = st.Start_Time__c.format('hh:mm a');
                        st.End_Time__c = dateTime.newInstance(system.today(), endTime);
                        st.End_Time_Text__c = st.End_Time__c.format('hh:mm a');
                        if (!setup.Group_Based__c){
                            Time iTime = startTime;
                            integer iKey = 1;
                            integer iBreak = classBreak[Integer.valueOf(math.floor(classBreak.size()*math.random()))];
                            List <Period__c> tempperiodList = new List <Period__c>();
                            while (iTime < endTime){
                                Period__c p = new Period__c();
                                p.Start_Time__c = dateTime.newInstance(system.today(), iTime);
                                p.Passing_Time__c = string.valueOf(iBreak);
                                p.End_Time__c = p.Start_Time__c.addMinutes(Integer.valueOf(classDuration[Integer.valueOf(math.floor(classDuration.size()*math.random()))]));
                                p.Start_Time_Text__c = p.Start_Time__c.format('hh:mm a');
                                p.End_Time_Text__c = p.End_Time__c.format('hh:mm a');
                                p.Key__c = string.valueOf(iKey);
                                iTime = p.End_Time__c.time().addMinutes(iBreak);
                                tempperiodList.add(p);
                                iKey++;
                            }
                            periodMap.put(setup.id+'-'+st.name, tempperiodList);
                        }
                    }
                    for (Time_Element__c te: rpList){
                        st.Reporting_Period__c = te.id;
                        stList.add(st.clone(false));
                    }
            }
        
        insert stList;
        
        for (Schedule_Template__c st: [select id, has_class__c, setup__r.group_based__c, setup__c, name from Schedule_Template__c where setup__c=:setup.id]){
            if (!st.setup__r.group_based__c&&st.Has_Class__c){
                if (periodMap.get(st.setup__c+'-'+st.name)!=null){
                    for (Period__c p: periodMap.get(st.setup__c+'-'+st.name)){
                        p.Schedule_Template__c = st.id;
                        periodList.add(p.clone(false));
                    } 
                }
            }
            if (test.isRunningTest()){
                break;
            }
        }
        insert periodList;
        
    }
    
    global static void setupCalendar(setup__c runningSetup){
        for (Time_Element__c te: core_SoqlUtils.getTimeElementsByTerm(runningSetup.term__c, true)){
            ReportingPeriodCalendarWrapper wrap = new ReportingPeriodCalendarWrapper(runningSetup.id);
            wrap.getScheduleTemps();
            wrap.buildCalendar(te.id);
            saveCalendar(wrap, te.id);
            if (test.isRunningTest()){
                break;
            }
        }
    }
    
    public static void saveCalendar(ReportingPeriodCalendarWrapper repPeriodCal, Id rpId){
        List<Schedule_Day__c>   scheduleDaysList = new List<Schedule_Day__c>();
            for(ReportingPeriodCalendarWrapper.FormatMonthsWrapper f : repPeriodCal.rpIdToFormatWrapperList.get(rpId)){
                for(ReportingPeriodCalendarWrapper.MonthWrapper m : f.monthsList){
                    for(ReportingPeriodCalendarWrapper.WeekWrapper w : m.weeksList){ 
                        for(ReportingPeriodCalendarWrapper.DayWrapper d : w.dayWrapperList){
                            system.debug(LoggingLevel.info, 'in day wrapper~~~'+d);
                            if(d.schedDayId.length() > 0){
                                if(d.schedDay.ReferenceId__c == null){
                                    List <ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper> stlist = repPeriodCal.rpIdToScheduleClassesList.get(rpid);
                                    Schedule_Template__c st = stlist[integer.valueOf(math.floor(math.random()*stlist.size()))].schedTemp;
                                    d.schedDay.Schedule_Template__c = st.id;
                                    d.schedDay.Day__c = d.day;
                                    d.schedDay.ReferenceId__c = repPeriodCal.cSetup.setup.id+'-'+ String.valueOf(d.day);
                                    d.schedDay.Reporting_Period__c = rpid;
                                    scheduleDaysList.add(d.schedDay);
                                }
                                else {
                                    if(d.schedDay.Schedule_Template__c == d.schedDayId){
                                        List <ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper> stlist = repPeriodCal.rpIdToScheduleClassesList.get(rpid);
                                        Schedule_Template__c st = stlist[integer.valueOf(math.floor(math.random()*stlist.size()))].schedTemp;
                                        d.schedDay.Schedule_Template__c = st.id;
                                        d.schedDay.Day__c = d.day;
                                        d.schedDay.Reporting_Period__c = rpid;
                                        d.schedDay.ReferenceId__c = repPeriodCal.cSetup.setup.id+'-'+ String.valueOf(d.day);
                                        scheduleDaysList.add(d.schedDay);
                                    }
                                }
                            }
                        }
                    }
                }
            }
                upsert scheduleDaysList ReferenceId__c;
    }
     
    global static String roundTime(String t){
            Integer roundedval;
            Integer tempHour = core_timeUtils.returnTimeHour(t);
            Integer temp = core_TimeUtils.returnTimeMinute(t);
            if(core_TimeUtils.returnTimeMinute(t) < 8) roundedval = 0;
            else
            if(core_TimeUtils.returnTimeMinute(t) < 16) roundedval = 15;
            else
            if(core_TimeUtils.returnTimeMinute(t) < 24) roundedval = 15;
            else
            if(core_TimeUtils.returnTimeMinute(t) < 32) roundedval = 30;
            else
            if(core_TimeUtils.returnTimeMinute(t) < 40) roundedval = 30;
            else
            if(core_TimeUtils.returnTimeMinute(t) < 48) roundedval = 45;
            else
            if(core_TimeUtils.returnTimeMinute(t) < 53) roundedval = 45;
            else
            roundedval = 60;
            
            Time tempTime = Time.newInstance(tempHour, roundedval,0,0);      
            dateTime dTemp = dateTime.newInstance(system.today(), tempTime);
            return dTemp.format('hh:mm a');
        }
        
        
    global static void setupScheduleGroups(Setup__c s){
        ID groupRecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group'); 
        List <Section__c> sgList = new List <Section__c>(); //US1254
        List <Student__c> stuList = [select id, grade__c from Student__c where school__c =:s.school__c];
        Set <String> gradeSet = new Set <String>();
        for (Student__c stu: stuList){
            gradeSet.add(stu.grade__c);
        }
        String allgrades = '';
        for (String grade: gradeSet){
            sgList.add(new Section__c(RecordTypeId = groupRecordTypeId,  Name = 'Group '+grade+'A', All_Grades__c = grade, school__c =s.School__c, Time__c=s.Year__c));
            sgList.add(new  Section__c(RecordTypeId = groupRecordTypeId,  Name = 'Group '+grade+'B', All_Grades__c = grade, school__c =s.School__c, Time__c=s.Year__c));
            allgrades += grade+'; ';
        }
        allgrades = allgrades.substring(0,allgrades.length()-2);
        sgList.add(new Section__c(RecordTypeId = groupRecordTypeId, Name = 'Group A', All_Grades__c = allgrades, school__c =s.School__c, Time__c=s.Year__c));
        sgList.add(new Section__c(RecordTypeId = groupRecordTypeId, Name = 'Group B', All_Grades__c = allgrades, school__c =s.School__c, Time__c=s.Year__c));
        insert sgList;
        Map <String, Id> sgMap = new Map <String, Id>();
        for (Section__c sg: sgList){
            sgMap.put(sg.name, sg.id);
        }
        List <Student_Section__c> ssList = new List <Student_Section__c>();
        for (Student__c stu: stuList){
        //  stu.Primary_Schedule_Group__c=
            Student_Section__c ss = new Student_Section__c(Student__c = stu.id, Active__c = true);
            if(math.random() < 0.5) ss.section__c = sgMap.get('Group '+stu.grade__c+string.valueOf(math.random().round()==0?'A':'B'));
            else ss.section__c = sgMap.get('Group '+string.valueOf(math.random().round()==0?'A':'B'));
           stu.Primary_Schedule_Group__c=ss.section__c;
        } 
        update stuList;
    }
    
    global static void setupRooms(Setup__c s){
        List<Room__c> roomList = new List <Room__c>();
            integer startNum = 101;
            integer endNum = 111;
        for (Integer i=startNum; i<= endNum;i ++){
            Room__c newRoom = new Room__c(School__c = s.School__c);
                newRoom.number__c = i;
                newRoom.Usable__c= (math.random().round()==0?false:true);
                newRoom.Schedulable__c=(math.random().round()==0?false:true);
                newRoom.Size__c = 30;
                roomList.add(newRoom);
        }
        insert roomList;
    }
    
    global static void loadSections(Setup__c setup){
        List <Section__c> sectionList = new List <Section__c>();
            Setup = [select year__c, school__r.name, course_catalog__c, school__c, id, term__c , term__r.parent_time_element__c from Setup__c where id=:setup.id];
          //  for (Setup__c setup: [select school__r.name, course_catalog__c, school__c, id, term__c , term__r.parent_time_element__c from Setup__c where year__r.name__c =:sYear]){
                //Section__c sect = new Section__c(school__c = setup.school__c, time__c = setup.term__r.parent_time_element__c);
                List <Time_Element__c> rpList = core_SoqlUtils.getTimeElementsByTerm(setup.term__c, true);
                List<Course_Course_Catalog__c> cccList=[select id, course__r.number_of_reporting_periods__c, course__r.name, course__c from Course_Course_Catalog__c 
                                            where course_catalog__c =:setup.course_catalog__c
                                            order by course__r.name asc];                                      
                integer rpsRemaining = rpList.size();
                for (Time_Element__c te: rpList){
                    system.debug('te~~~~'+te);
                    for (Course_Course_Catalog__c c: cccList){
                        Set <Id> courseIds = new Set <Id>();
                        if (rpsRemaining>=c.course__r.number_of_reporting_periods__c){
                            Section__c section = new Section__c(RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Unpublished'),
                                    Record_Attendance__c=true,
                                    school__c = setup.school__c, 
                                    time__c = te.id);
                            section.Time__c = setup.Year__c;
                            section.Reporting_Period__c = te.id;
                            section.Course__c = c.course__c;
                            section.is_section__c = true;
                            section.Number_of_Reporting_Periods__c = string.valueOf(c.course__r.number_of_reporting_periods__c);
                            section.Color__c =  core_ColoringUtils.RGBToHex(math.floor(math.random()*256), math.floor(math.random()*256),math.floor(math.random()*256));
                            section.name = setup.school__r.name+'-'+c.course__r.name+'-'+te.name__c;
                            sectionList.add(section.clone(false));
                          
                        }
                    }
                  rpsRemaining--;
                  if (test.isRunningTest()){
                    break;
                  }
             }
                                         
                    
    
                
                
         //   }

            insert sectionList;
    }
    
    @future
    global static void randomizeScheduledSections_Group(Id setupID){
        Setup__c setup =  [select id, school__r.Reference_Id__c, Course_Catalog__c, room_dependent__c, term__c, term__r.parent_time_element__c, group_based__c, school__c from Setup__c where id = :setupID];
        List <Course_Course_Catalog__c> courseList =  [select id, course__r.number_of_reporting_periods__c, course__r.name, course__c from Course_Course_Catalog__c 
                                            where course_catalog__c =:setup.course_catalog__c
                                             order by course__r.name asc];
        List <Scheduled_Section__c>ssList = new List <Scheduled_Section__c>();
        List<Section__c> sgList = [select id from Section__c where School__c=:setup.school__c and RecordType.DeveloperName='Schedule_Group'];
        Set <String> refIdSet = new Set <String>();
        List <Staff__c> staffList = [select id, name   
                from Staff__c 
                where organization__c =:setup.school__c
                and Active__c=true 
                and instructional_staff__c = true
                order by name asc];
        List <Time_Element__c> rpList = core_SoqlUtils.getTimeElementsByTerm(setup.term__c, true);  
        for (Time_Element__c te: rpList){    
            for (Schedule_Template__c st: [select start_time__c, end_Time__c, id from Schedule_Template__c where reporting_period__c =:te.id and setup__c =:setup.id and has_class__c=true]){
                for (Section__c sg: sgList){
                    Integer scheduledCount = 0;
                    Map <String, Boolean> ssIntMap = new Map <String, Boolean>();
                    time iTime = st.start_time__c.time();
                    time endTime =  st.End_Time__c.time();
                    while (iTime < st.End_Time__c.time()){
                        ssIntMap.put(string.valueOf(iTime), false);
                        iTime = iTime.addMinutes(15);
                        system.debug(iTime);
                    }
                    system.debug(ssIntMap.keySet());
                            
                    while (scheduledCount+6  < ssIntMap.size()){
                        integer randomDuration = integer.valueOf(math.floor(4*math.random()))+1;

                        time randomStartTime;// = st.Start_Time__c.time().addMinutes(15*integer.valueOf(math.floor(ssIntMap.size()*math.random())));

                        boolean bValid = false;
                        while (!bValid){
                            randomStartTime = st.Start_Time__c.time().addMinutes(15*integer.valueOf(math.floor(ssIntMap.size()*math.random())));

                            if (!ssIntMap.get(string.valueOf(randomStartTime))){

                                            
                      
                                for (integer k =1; k<=randomDuration; k++){
                                  
                                    if (ssIntMap.keySet().contains(string.valueOf(randomStartTime.addMinutes(15*k)))){
                                        if (!ssIntMap.get(string.valueOf(randomStartTime.addMinutes(15*k)))){
                                            
                                            bValid = true;
                                        }   
                                    }
                                    else {
                                      
                                        bValid = false;
                                        break;
                                    }
                                }
                                            
                            }
                        }
                        for (integer k =0; k<randomDuration; k++){
                            ssIntMap.put(string.valueOf(randomStartTime.addMinutes(k*15)), true);
                            scheduledCount++;
                        }
                                
                                
                        Scheduled_Section__c ss = new Scheduled_Section__c();
                        ss.Schedule_Template__c = st.id;
                        ss.Schedule_Group_Section__c = sg.id;
                        ss.Staff__c = staffList[integer.valueOf(math.floor(math.random()*staffList.size()))].id;
                        ss.Start_Time__c = dateTime.newInstance(system.today(), randomStartTime);
                        ss.Start_Time_Text__c = ss.Start_Time__c.format('hh:mm a');
                        ss.Rounded_Start_Time__c = roundTime(ss.Start_Time_Text__c);
                        ss.End_Time__c = ss.Start_Time__c.addMinutes(15*randomDuration);
                        ss.End_Time_Text__c=ss.End_Time__c.format('hh:mm a');
                        ss.Rounded_End_Time__c = ss.End_Time__c.format('hh:mm a');
                        ss.Course__c = courseList[integer.valueOf(math.floor(math.random()*courseList.size()))].course__c;
                        ss.Account__c = setup.School__c;
                        ss.Record_Attendance__c = (math.random().round()==0?false:true);
                        ss.Daily_Attendance__c = (ss.Record_Attendance__c?(math.random().round()==0?false:true): false);
                        ss.Reporting_Period__c = te.id;
                        ss.Reference_Id__c = ImportUtils.createScheduledSectionKey(ss.Account__c,ss.Schedule_Group_Section__c,ss.Course__c,ss.Reporting_Period__c,ss.Schedule_Template__c);
                        ss.Section_Reference_Id__c = ImportUtils.createSectionReferenceKey(ss.Account__c,ss.Schedule_Group_Section__c,ss.course__c,ss.Reporting_Period__c);
                        ss.color__c = core_ColoringUtils.RGBToHex(math.floor(math.random()*256), math.floor(math.random()*256),math.floor(math.random()*256));
                
                        ss.Needs_Publish__c = true;
                        if (!refIdSet.contains(ss.reference_Id__c)){
                            
                            ssList.add(ss.clone(false));            
                            refIdSet.add(ss.reference_Id__c);
                        }      
                    }
                }
                if (test.isRunningTest()){
                    break;
                }
            }
            if (test.isRunningTest()){
                break;
            }
        }
       
        insert ssList;
    }
    
    
    
     
     
    @future
    global static void randomizeScheduledSections(Id setupId){
     Setup__c setup= [select id, school__r.Reference_Id__c, Course_Catalog__c, room_dependent__c, term__c, term__r.parent_time_element__c, group_based__c, school__c from Setup__c where id = :setupID];
        List <Scheduled_Section__c>ssList = new List <Scheduled_Section__c>();
        List <Section_ReportingPeriod__c> secRpUpdate = new List <Section_ReportingPeriod__c>();
        List <Staff__c> staffList = [select id, name   
                        from Staff__c 
                        where organization__c =:setup.school__c
                        and Active__c=true 
                        and instructional_staff__c = true
                        order by name asc];
        List <Time_Element__c> rpList = core_SoqlUtils.getTimeElementsByTerm(setup.term__c, true);
        List<Period__c> pList = [select id,Name , key__c from Period__c where schedule_template__r.setup__c =:setup.id];    
        for (Time_Element__c te: rpList){     
            Map <String, Period__c>periodMap = new Map<String, Period__c>();
            for (Period__c p: pList){
                periodMap.put(p.key__c, p);
            }
            List <String> tempperiodList = new List <String>{};//List of periods
            for (String s: periodMap.keySet()){
                tempperiodList.add(s);
            }
            tempperiodList.sort();
            List <Period__c> periodList = new List <Period__c>{};//List of periods
            for (String s: tempperiodList){
                periodList.add(periodMap.get(s));
            }       

            List <Section_ReportingPeriod__c> sectionRpList = [select id, Period__c, section__r.course__c, section__c, Time__c from Section_ReportingPeriod__c where Time__c =:te.id and Section__r.school__c=:setup.school__c];
            Map <String, Scheduled_Section__c> ssMap = new Map <String, Scheduled_Section__c>();
            Integer iMax = staffList.size()*periodList.size();
            for (Section_ReportingPeriod__c srp: sectionRpList){
                Scheduled_Section__c ss = new Scheduled_Section__c(Section__c =srp.section__c, reporting_period__c = srp.time__c );
              if (staffList.size()>0){
                   ss.staff__c = staffList[integer.valueOf(math.floor(math.random()*staffList.size()))].id;
                 ss.Period_Key__c =  periodList[integer.valueOf(math.floor(math.random()*periodList.size()))].key__c;
                 ss.reference_Id__c = ss.reporting_period__c+'-'+ss.Period_Key__c+'-'+ss.Staff__c;
                 ss.Account__c = setup.school__c;
                 ss.Course__c = srp.section__r.course__c;
                    ss.Section_ReportingPeriod__c = srp.id;
                 ss.Needs_Publish__c = true;
                while (ssMap.keySet().contains(ss.reference_Id__c)){
                 
                    ss.staff__c = staffList[integer.valueOf(math.floor(math.random()*staffList.size()))].id;
                    ss.Period_Key__c =  periodList[integer.valueOf(math.floor(math.random()*periodList.size()))].key__c;
                    ss.reference_Id__c =  ss.reporting_period__c+'-'+ss.Period_Key__c+'-'+ss.Staff__c;
                }
                if(srp.Period__c == null || srp.Period__c == '') srp.Period__c = ss.Period_Key__c;
                else srp.Period__c += ','+ss.Period_Key__c;
                ssMap.put(ss.reference_Id__c, ss.clone(false));
                if (iMax-ssMap.size()==0) break;
                }
            }
            ssList.addAll(ssMap.values());
            secRpUpdate.addAll(sectionRpList);
            ssMap.clear();
            if (test.isRunningTest()){
                break;
            }
        }
            
        insert ssList;
        update secRpUpdate;
    }
    
    
    global static void loadCourses(){
        Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Course__c');
        Course__c subj = new Course__c (Name='Dummy Subject', RecordTypeId=rtMap.get('Subject_Area'));
        insert subj;
            List<Course__c> defaultCourses = new List<Course__c>();
            List <Picklist_Value__c> gradeScales = [select id from Picklist_Value__c where RecordType.DeveloperName='Grade_Scale'];
            List<String> legacyScales = new List<String>();
            for(Schema.PicklistEntry plv: Schema.Course__c.Grade_Scale__c.getDescribe().getPicklistValues()){
                legacyScales.add(plv.getLabel());
            }
            String[] defaultCourseValues = core_SoqlUtils.processCSVFile('samp_Courses');
            for (Integer i=1;i<defaultCourseValues.size();i++){
                String[] inputvalues = defaultCourseValues[i].split(',');
                Course__c temp = new Course__c();  
                temp.NAME   = inputvalues[0]; 
                if (test.isRunningTest()){
                    temp.NAME = temp.NAME +'**';
                }
                temp.COURSE_NUMBER__C   = inputvalues[1];
             //   temp.COURSE_WEIGHTING_RECORDS__C  =decimal.valueOf(integer.valueOf(inputValues[2]));
                if(useLegacyScale)
                    temp.Grade_Scale__c = legacyScales[integer.valueOf(math.floor(math.random()*legacyScales.size()))];
                else
                    temp.Grade_Scale_Lookup__c = gradeScales[ integer.valueOf(math.floor(math.random()*gradeScales.size()))].id;
                // integer k = integer.valueOf(math.floor(math.random()*teList.size()));
                temp.CREDIT_HOURS__C    =decimal.valueOf(integer.valueOf(inputValues[3]));
                temp.CREDITS__C = decimal.valueOf(integer.valueOf(inputValues[4]));
                temp.DAILY_ATTENDANCE__C    = boolean.valueOf(inputvalues[5]);
                temp.DEPARTMENT__C  = inputvalues[6];
                temp.DISPLAY_ORDER__C= decimal.valueOf(i);
                temp.NUMBER_OF_REPORTING_PERIODS__C = decimal.valueOf(integer.valueOf(inputValues[7]));
                temp.REFERENCE_ID__C= inputvalues[8];
                temp.Has_Final_Grade__c =(math.random().round()==0?false:true);
                temp.Subject_Area_Lookup__c=subj.id;
                temp.RecordTypeId = rtMap.get('Course');
                if (test.isRunningTest()&&defaultCourses.size()==5){
                }
                else defaultCourses.add(temp);
            }
            insert defaultCourses;
    }
    
    global static void loadCourseWeightings(){
        List <Course_Weightings__c> courseWeightingsList = new List<Course_Weightings__c>();
        for (Course__c course: [select id, number_of_reporting_periods__c, Has_Final_Grade__c, name from Course__c]){
            if (test.isRunningTest()&&course.name.contains('**')||!test.isRunningTest()){
                integer rpNum = integer.valueOf(course.Number_of_Reporting_Periods__c);
                integer weightPercent = 100/(rpNum);
                if (course.Has_Final_Grade__c) weightPercent=weightPercent/2;
                for (Integer courseWeightingsItem=1; courseWeightingsItem<=rpNum; courseWeightingsItem++){
                    courseWeightingsList.add(new Course_Weightings__c(Course__c = course.id, Weighting__c=weightPercent, Key__c=string.valueOf(courseWeightingsItem)));
                
                    if(course.Has_Final_Grade__c){
                        courseWeightingsList.add(new Course_Weightings__c(Course__c = course.id,  Weighting__c=weightPercent, Key__c=string.valueOf(courseWeightingsItem)+'-Final'));
                    }
                }
            }
        }
        insert courseWeightingsList;
    }
    
    global static void setupDefaultAssignmentWeightings(){
        
        List<Picklist_Value__c> plValueList = core_SoqlUtils.getPlValuesList('Assignment Type', null);
        List <Default_Assignment_Weighting__c> dawList = new List<Default_Assignment_Weighting__c>();
        for (Course__c course: [select id, number_of_reporting_periods__c, Has_Final_Grade__c , name from Course__c]){
            if (test.isRunningTest()&&course.name.contains('**')||!test.isRunningTest()){
                for (Picklist_Value__c plv: plValueList){
                    if (math.random().round()==0?false:true){
                        dawList.add(new Default_Assignment_Weighting__c(Course__c=course.id, Picklist_Value__c=plv.id, Default_Weighting__c=double.valueOf((math.random()*10).round())+1));
                    }
                }
            }
        }
        insert dawList;
    }
    
    global static void setupCourses(){
        loadCourses();
       // loadCourseWeightings();
        setupDefaultAssignmentWeightings();
    }
    
    global static void setupCatalogs(){
        setupGradeScaleCatalog(); 
        setupCourseCatalog();
    }
    
    global static void setupCourseCatalog(){
        List <Course_Course_Catalog__c> ccList = new List <Course_Course_Catalog__c>();
        List<Course__c> courses = [select id, name, Grade_Scale__c, Grade_Scale_Lookup__r.Category__c from Course__c where RecordType.DeveloperName!='Subject_Area'];
        Map<Id,Setup__c> updateList = new Map<Id,Setup__c>();
        for (Setup__c s : [select id, school__r.name, Standards_Based_Grading__c, Standards_ONLY_Gradebook__c from Setup__c where year__r.name__c=:sYear.split(',')[0]]){
            if (test.isRunningTest()&&s.school__r.name.contains('**')||!test.isRunningTest()){
                Course_Catalog__c cc = new Course_Catalog__c(Course_Catalog_Status__c = true, Name = s.School__r.name+' - Course Catalog');
                insert cc;
                for (Course__c c: courses){
                    if (test.isRunningTest()&&c.name.contains('**')||!test.isRunningTest()){
                        boolean useCourse;
                        if(c.Grade_Scale_Lookup__c!=null){
                            useCourse = ((s.Standards_ONLY_Gradebook__c && c.Grade_Scale_Lookup__r.Category__c=='Standards') ||
                            (!s.Standards_ONLY_Gradebook__c && s.Standards_Based_Grading__c && math.random().round()==0) ||
                            (!s.Standards_Based_Grading__c && c.Grade_Scale_Lookup__r.Category__c!='Standards' && math.random().round()==0));
                        }
                        else{
                            useCourse = ((s.Standards_ONLY_Gradebook__c && c.Grade_Scale__c=='Standard') ||
                            (!s.Standards_ONLY_Gradebook__c && s.Standards_Based_Grading__c && math.random().round()==0) ||
                            (!s.Standards_Based_Grading__c && c.Grade_Scale__c!='Standard' && math.random().round()==0));
                        }
                        if (useCourse)
                            ccList.add(new Course_Course_Catalog__c( Course_Catalog__c= cc.id, Course__c = c.id));
                    }
                }
                s.Course_Catalog__c= cc.id;
                updateList.put(s.id,s);
            }
        }
        update updateList.values();
        insert ccList;
    }
    
    global static void setupGradeScaleCatalog(){
        List <Grade_Scale_Catalog_Scale__c> ccList = new List <Grade_Scale_Catalog_Scale__c>();
        List<Picklist_Value__c> plv = core_SoqlUtils.getPlValuesList('Grade Scale', null);
        Map<Id,Setup__c> updateList = new Map<Id,Setup__c>();
            for (Setup__c s : [select id, Standards_Based_Grading__c, Standards_ONLY_Gradebook__c, school__r.name from Setup__c where year__r.name__c=:sYear.split(',')[0]]){
                Grade_Scale_Catalog__c cc = new Grade_Scale_Catalog__c(Active__c = true, Name = s.School__r.name+' - Scale Catalog');
                insert cc;
                for (Picklist_Value__c c: plv){
                    if ((s.Standards_ONLY_Gradebook__c && c.Category__c=='Standards') ||
                            (!s.Standards_ONLY_Gradebook__c && s.Standards_Based_Grading__c && math.random().round()==0) ||
                            (!s.Standards_Based_Grading__c && c.Category__c!='Standards' && math.random().round()==0)){
                        ccList.add(new Grade_Scale_Catalog_Scale__c( Grade_Scale_Catalog__c= cc.id, Picklist_Value__c = c.id));
                    }
                }
                s.Grade_Scale_Catalog__c= cc.id;
                updateList.put(s.id,s);
            }
            update updateList.values();
            insert ccList;
    }
    
    global static void setupTermSetup(){
        id plValueId = core_SoqlUtils.getPlStringValues('Time', null).get('Term').id;
        List <Time_Element__c> teList = [select id from Time_Element__c where picklist_Value__c =:plValueId];
        List <Setup__c > setupList = new List <Setup__c>();
        for (Setup__c s: [select year__r.name__c,  school__r.reference_id__c, id from Setup__c where year__r.name__c=:sYear.split(',')[0]]){
             integer k = integer.valueOf(math.floor(math.random()*teList.size()));
             s.Term__c = teList[k].id;
             system.debug('sTerm~~~'+s.term__c);
            if (Test.isRunningTest()){
                if (s.School__r.reference_id__c.contains('**')) {
                                setupList.add(s);
                }
            }
            else {
            setupList.add(s);
            }
        }
        system.debug('setupList~~~'+setupList);
        update setupList;
    }
    
    global static void setupDefaultTerms(){
        Map <String, Picklist_Value__c> plVMap = core_SoqlUtils.getPlStringValues('Time', null);
        
        set <Id> timeIds = new Set <Id>();
        
        Picklist_Value__c semester = plVMap.get('Semester');
        semester.Corresponding_Value__c = 2;
        Picklist_Value__c trimester = plVMap.get('Trimester');
        trimester.Corresponding_Value__c=3;
        Picklist_Value__c quarter = plVMap.get('Quarter');
        quarter.Corresponding_Value__c=4;
        List <Picklist_Value__c> plVList = new List <Picklist_Value__c>{semester, trimester, quarter};
        for (Picklist_Value__c pl:plVList){
            pl.Type__c = 'Time';
        
        }
        
        update plVList;
        system.debug('plvList~~'+plVList);
        
        
        
        Time_Element__c masterYear = [select id from Time_Element__c where Name__c =:sYear.split(',')[0] limit 1];
        system.debug('~~~~masterYear'+masterYear);
        masterYear = core_SoqlUtils.getTimeElementById(masterYear.id);
        system.debug('~~~~masterYear'+masterYear);
        List <Time_Element__c> teList = new List <Time_Element__c>();
        
        for (Picklist_Value__c pl: plVList){
            
            integer daysAdd = integer.valueOf(math.floor((masterYear.Date_Start_Date__c.daysBetween(masterYear.End_Date__c)-pl.Corresponding_Value__c)/pl.Corresponding_Value__c));
            system.debug('~~~~~ daysToAdd for '+pl.Name+': '+daysAdd);
            Time_Element__c te = masterYear.clone(false);
            te.Parent_Time_Element__c = masterYear.id;
            te.picklist_Value__c=  plVMap.get('Term').id;
            te.Name__c = pl.Name+' Term';
            system.debug('term~~~~~'+te);
            insert te;
            Date d = masterYear.Date_Start_Date__c;
            for (integer i=0; i<pl.Corresponding_Value__c; i++){
                integer nameVal = i+1;
                Time_Element__c reportingPeriod = new Time_Element__c(Reporting_Period__c=true, Type__c= pl.name, Parent_Time_Element__c =te.id, Picklist_Value__c = pl.id, Name__c = pl.name+'-'+nameVal  );
                reportingPeriod.Date_Start_Date__c = d;
                reportingPeriod.End_Date__c = d.addDays(daysAdd);
                teList.add(reportingPeriod);
                d= reportingPeriod.End_Date__c.addDays(1);
               
            }
            system.debug('teList~~~~~'+teList);
         
        }
        
          insert teList;
            for (Time_Element__c te2: teList){
                timeIds.add(te2.id);
            }
          system.debug( [SELECT Reporting_Period_Value__r.name, Reporting_Period_Value__c
                             ,Name__c , Days_of_Week__c , StartTime__c , EndTime__c
                             ,Reporting_Period__c, Allow_Periods__c,  t.Picklist_Value__r.Name
                             ,t.Picklist_Value__r.Level__c, t.Type__c, t.SystemModstamp
                             ,t.Start_Time__c, t.School__c, t.Reference_Id__c
                             ,t.Parent_Time_Element__c, t.OwnerId, t.Number__c, t.Name
                             ,t.LastModifiedDate, t.LastModifiedById, t.IsDeleted, t.Id
                             ,t.End_Time__c, t.End_Date__c ,t.Date_Start_Date__c
                       FROM Time_Element__c t
                       WHERE picklist_value__r.type__c = 'Time'
                       and id in:timeIds]);
                       
    }
    
  
    
    
    
    global static void purgeData(){
        SchoolForce_Settings__c sf = SchoolForce_Settings__c.getOrgDefaults();
                sf.Triggers_Disabled__c = true;
                upsert sf;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Set<String> keyPrefixSet = gd.keySet();
        for(String sObj : keyPrefixSet) {
            Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
            String tempName = r.getName();
            if (r.isCustom()&&tempName.replace('SchoolForce__','')!='SchoolForce_Settings__c'||(tempName=='Account')||   (tempName=='Contact')){
                deleteSObject(tempName);
            }
        }
        sf.Triggers_Disabled__c = false;
        upsert sf;
    }
    
    global static void deleteSObject(string inputObject){
        
        if (limits.getLimitDMLRows() - limits.getDMLRows() > 0){
            integer iLimit = limits.getLimitDMLRows() - limits.getDMLRows()-1 ;
            delete database.query('select id from  '+inputObject + ' limit '+iLimit); 
            //delete aList;
        }
        
    }
    
    global static void setupDefaultPlValues(){
        for (Setup__c s : [select id from Setup__c]){
            createDefaultPicklistValues(s.id);
        }
    }
    
    
    global static void  createDefaultPicklistValues(Id setupId){
        core_LoadCsvData loader = new core_LoadCsvData();
        loader.setupId = setupId;
        loader.cSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'load');
        loader.selectedLoadType = 'Assignment Types';
        //this will not work because the default resource map was not populated
        //as test methods are not allowed to call getContent()
        loader.bUseDefault = true;
        loader.loadData();
        loader.insertList();
        
        loader.selectedLoadType = 'Attendance Values';
        loader.bUseDefault = true;
        loader.loadData();
        loader.insertList();
        
        loader.selectedLoadType = 'Behavior Types';
        loader.bUseDefault = true;
        loader.loadData();
        loader.insertList();
        
        loader.selectedLoadType = 'Behavior Consequences';
        loader.bUseDefault = true;
        loader.loadData();
        loader.insertList();
        
        loader.selectedLoadType = 'Homework Values';
        loader.bUseDefault = true;
        loader.loadData();
        loader.insertList();
        
    }
    
    global static void loadStaticResources(){
        testDataSetupUtil_v2.createScalesNormalizations();
        testDataSetupUtil_v2.createDefaultTimeValues();
    }
    
    /* Ensure that staff & Student Rosters have been loaded to static resources*/
    global static void insertSampStaff(){
        List<HoldingObj__c> staffList = new List<HoldingObj__c>();
        String[] defaultStaff = core_SoqlUtils.processCSVFile('samp_staffRoster');
        for (Integer i=0;i<defaultStaff.size();i++){
            String[] inputvalues = defaultStaff[i].split(',');
            HoldingObj__c temp = new HoldingObj__c();
            temp.Network_Code__c = inputvalues[0];
            temp.School_Dbn__c = inputvalues[1];
            if (test.isRunningTest()) temp.School_Dbn__c = temp.School_Dbn__c+'**';
            temp.First_Name__c = inputvalues[2];
            temp.Last_Name__c = inputvalues[3];
            temp.Staff_ID__c = inputvalues[4];
            temp.Staff_Code__c = inputvalues[5];
            temp.School_Name__c = inputvalues[6];
            temp.Username__c = inputvalues[7]+system.now().getTime()+i;
            temp.Email__c = inputvalues[8];
            temp.Type__c = inputvalues[9];
            temp.Phone__c = inputvalues[10];
            temp.Address__c = inputvalues[11];
            temp.City__c = inputvalues[12];
            temp.State__c = inputvalues[13];
            temp.Zip__c = inputvalues[14];
            temp.Sex__c = inputvalues[15];
            temp.Age__c = inputvalues[16];
            temp.Ethnic_Cde__c = inputvalues[17];
            temp.School_Year__c = sYear.split(',')[0];
            staffList.add(temp);
        }
        insert staffList;
      //  return defaultStaff;
     }
     
     
     
     global static void insertSampStudent(){
        List<HoldingObj__c> staffList = new List<HoldingObj__c>();
        String[] defaultStaff = core_SoqlUtils.processCSVFile('samp_studentRoster');
        for (Integer i=0;i<defaultStaff.size();i++){
            String[] inputvalues = defaultStaff[i].split(',');
            HoldingObj__c temp = new HoldingObj__c();
            temp.Network_Code__c = inputvalues[0];
            temp.School_Dbn__c = inputvalues[1];
            if (test.isRunningTest()) temp.School_Dbn__c+='**';
            temp.Student_Id__c = inputvalues[2];
            temp.First_Name__c = inputvalues[3];
            temp.Last_Name__c = inputvalues[4];
            temp.Grade_Level__c = inputvalues[5];
            temp.DOB__c = date.newInstance(integer.valueOf(inputvalues[6].split('/')[2]), integer.valueOf(inputvalues[6].split('/')[0]), integer.valueOf(inputvalues[6].split('/')[1]));
            temp.Ethnic_Cde__c = inputvalues[7];
            temp.Sex__c = inputvalues[8];
            temp.Disability_Flag__c = inputvalues[9];
            temp.ELL__c = inputvalues[10];
            //if (inputValues[11]!=null) temp.Admission_Date__c = date.valueOf(inputvalues[11]);
            temp.Email__c = inputvalues[12];
            temp.Type__c = inputvalues[13];
            temp.Address__c = inputvalues[14];
            temp.City__c = inputvalues[15];
            temp.State__c = inputvalues[16];
            temp.Zip__c = inputvalues[17];
            temp.Phone__c = inputvalues[18];
            temp.School_Year__c = sYear.split(',')[0];
            staffList.add(temp);
        }
        insert staffList;
        //  return defaultStaff;
    }
    
    global static void executeRosterLoad(string sType){
        Scheduler_HoldingProcessor s = new Scheduler_HoldingProcessor();
        s.mode = sType;
        Id batchId = database.executeBatch(s);
    }
    
    global static void createYearRecord(string Year, date startDate, date endDate){
        //EE 2/11 removing since this picklist value time element was already created in the loadStaticResources() method
        //and this method is only called by the runBaseSetup()
        //Picklist_Value__c plV = new Picklist_Value__c(Name='Year',  RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Time'));
        //insert plv;
        Time_Element__c te = new Time_Element__c(Name__c = Year);
        te.Date_Start_Date__c = startDate;
        te.End_Date__c = endDate;
        te.Current__c = true;
        te.Picklist_Value__c = core_SoqlUtils.getPlStringValues('Time', null).get('Year').id;
        insert te;
    }
    
    global static void createIndividualAccount(){
        Account a = new Account(Name='Individuals', recordTypeId = core_SoqlUtils.getRecordTypesBySobject('Account').get('Individuals'));
        insert a;
     }

    global static void populateGradeLevels(){
        try{
            List<Schedule_Group__c> allgroups = [SELECT id, Grade_Level__c, All_Grades__c FROM Schedule_Group__c];
            for(Schedule_Group__c sg: allgroups){
                if(sg.All_Grades__c==null) sg.All_Grades__c = sg.Grade_Level__c;
            }
            
            List<Section__c> allsections = [SELECT id, Grade_Level__c, All_Grades__c FROM Section__c];
            for(Section__c sec: allsections){
                if(sec.All_Grades__c==null) sec.All_Grades__c = sec.Grade_Level__c;
            }
             
            try{
                update allgroups;
                update allsections;
            }
            catch(Exception e){
                Global_Error__c ge = Error_Handling.handleError('','Grade Levels', 'Update of grade levels on sections and schedule groups failed', e);
                insert ge;
            }
        }
        catch(Exception e){
            Global_Error__c ge = Error_Handling.handleError('','Grade Levels', 'Unexpected error occurred while attempting to populate null field', e);
            insert ge;
        }   
    }

    @isTest static void testMockSetupUtil(){
        mock_SetupUtil.runBaseSetup();
        mock_SetupUtil.createSchools();
        mock_SetupUtil.runStudents();
        mock_SetupUtil.populateGradeLevels();
        Time mydate;
        mydate = datetime.now().time();
        String mystr = string.valueOf(mydate);
    }
    
    //  @isTest static void testMockSetupUtil2(){
//      mock_SetupUtil.runBaseSetup();
//      mock_SetupUtil.createSchools();
//      mock_SetupUtil.runStaff();
//      mock_SetupUtil.runStudents();
//      mock_SetupUtil.runCourses();
//      mock_SetupUtil.runSetup();
//
//      Test.startTest();
//          mock_SetupUtil.bGroupBased = true;
//          string yearName = mock_SetupUtil.sYear.split(',')[0];
//          mock_SetupUtil.runRandomizeSetup(yearName);
//          mock_SetupUtil.createSchedule(yearName);
//      Test.stopTest();
//  }
    
        
    @isTest static void testMockSetupUtil3(){
        mock_SetupUtil.runBaseSetup();
        mock_SetupUtil.createSchools();
        mock_SetupUtil.runStaff();
        mock_SetupUtil.runCourses();
        mock_SetupUtil.runSetup();
        mock_SetupUtil.bGroupBased = false;
        string yearName = mock_SetupUtil.sYear.split(',')[0];
        mock_SetupUtil.runRandomizeSetup(yearName);
    }
}
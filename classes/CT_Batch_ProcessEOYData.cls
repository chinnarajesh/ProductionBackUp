global class CT_Batch_ProcessEOYData implements Database.Batchable<SObject>, Database.Stateful {
    global static final String logClassName = 'CT_Batch_ProcessEOYData';
    global String query;
	global String setupId;
    global Set<Id> setupIds;
	global String mode;
	global String className;
	global Boolean bFlag;
	global Boolean continueBatch;
    global BatchProcessor processor;
    global static final Map<String, String> mapProcessors = new Map<String, String>{
            'Student__c' => 'CT_Batch_ProcessEOYData.BatchProcessorStudent',
            'Section__c' => 'CT_Batch_ProcessEOYData.BatchProcessorSection'
    };
    global static final Map<String, String> mapExecutions = new Map<String, String>{
            'Student__c' => 'Section__c',
            'Section__c' => ''
    };

    global CT_Batch_ProcessEOYData(String md, Id setupId) {
        this.mode = md;
        this.setupIds = new Set<Id>{setupId};
//        this.continueBatch = false;
        System.debug('@@@ md: '+md);
        System.debug('@@@ mapProcessors.get(md): '+mapProcessors.get(md));
        Type t = Type.forName(mapProcessors.get(md));
        processor = (BatchProcessor)t.newInstance();
        processor.init(setupIds, logClassName);
	}

    global CT_Batch_ProcessEOYData(String md, Set<Id> setupIds){
        this.mode = md;
        this.setupIds = setupIds;
//        this.continueBatch = false;
        System.debug('@@@ md: '+md);
        System.debug('@@@ mapProcessors.get(md): '+mapProcessors.get(md));
        Type t = Type.forName(mapProcessors.get(md));
        processor = (BatchProcessor)t.newInstance();
        processor.init(setupIds, logClassName);
    }

	global Database.QueryLocator start(Database.BatchableContext ctx) {
        try {
			System.debug('$$$$Mode$$$$' + mode);
			System.debug('setup$$$$' + setupIds);

            processor.className = className;
            processor.bFlag = bFlag;
            query = processor.startProcess(ctx.getJobId());

			return Database.getQueryLocator(query);
		} catch (Exception e) {
			return null;
		}
	}

	global void execute(Database.BatchableContext ctx, List<SObject> scope) {
		try {
            System.debug('SCOPE $$$$' + scope.size());
			processor.process(scope);
		} catch (Exception e) {
		}
	}

	global void finish(Database.BatchableContext ctx) {
        processor.logsFinish();

		if (String.isNotBlank(mapExecutions.get(mode))){ //continueBatch && mode == 'Student__c') {
			CT_Batch_ProcessEOYData processEOYBatch = new CT_Batch_ProcessEOYData(mapExecutions.get(mode), setupIds);
			processEOYBatch.bFlag = true;
			processEOYBatch.className = className;
			Database.executeBatch(processEOYBatch, 10);
		}

	}

    //==================================================================================================================
    //=============================================Processors===========================================================
    //==================================================================================================================
    public class BatchProcessorStudent extends BatchProcessor{
        public BatchProcessorStudent(){
        }

        public override void init(Set<Id> setupIds, String logClassName){
            this.logClassName = logClassName;
            this.setupIds = setupIds;
            logsInit(new List<String>{'Student__c'}, setupIds);
        }

        public override String processQuery(Set<String> currYears, Set<Id> schoolIds) {
            String queryToProcess = ' SELECT Id, School__c, Reference_Id__c, Archived__c, Active__c,School_Year__r.Name__c,Intent_to_Return_Following_Year__c, Grade__c,Individual__c FROM Student__c';
            if (schoolIds != null && currYears != null && !schoolIds.isEmpty() && !currYears.isEmpty()) {
                queryToProcess += ' WHERE School_Year__c IN(\''+String.join(new List<String>(currYears), '\',\'')+'\') ';
                queryToProcess += ' AND School__c IN (\''+String.join(new List<Id>(schoolIds), '\',\'')+'\') ';
            }

            return queryToProcess;
        }

        public override void process(List<SObject> scope){
            Student__c[] studentBatch = (Student__c[]) scope;
            processStudents(studentBatch);
        }

        public override Boolean execLogic(){
            List<Setup__c> lstSetups = new List<Setup__c>();

            fldSetActive = className=='EOY'? 'Processed_EOY_Data__c': 'Data_Activated__c';
            for(CT_core_SetupWrapper sw: setups.values()){
                Setup__c s = sw.setup;
                s.put(fldSetActive, true);
                lstSetups.add(s);
            }
            update lstSetups;
            return true;
        }

        private void processStudents(Student__c[] studentBatch) {
            Map<Id, Student__c> studentMap = new Map<Id, Student__c>();

            for (Student__c stu : studentBatch) {
                CT_core_SetupWrapper cSetup = setups.get(mapSchool2Setup.get(stu.School__c));
                if (className == 'EOY') {
                    if (stu.Active__c) {
                        stu.Active__c = bFlag;
                        stu.Archived__c = !bFlag;
                        studentMap.put(stu.Individual__c, stu);
                    }
                } else if (cSetup!=null && cSetup.isReactivate == false) {
                    stu.Active__c = bFlag;
                    stu.Archived__c = !bFlag;
                    studentMap.put(stu.Individual__c, stu);
                }
            }

            if (className != 'EOY') {
                List<Contact> updateContacts = new List<Contact>();
                for (Contact con : [SELECT Student__c FROM Contact WHERE Id in:studentMap.keyset()]) {
                    con.Student__c = studentMap.get(con.Id).Id;
                    updateContacts.add(con);
                }

                if (updateContacts.size() > 0) {
                    SchoolForce_Settings__c sf = SchoolForce_Settings__c.getOrgDefaults();
                    sf.Triggers_Disabled__c = true;
                    upsert sf;
                    update updateContacts;

                    sf.Triggers_Disabled__c = false;
                    update sf;
                }
            }
            System.debug('$$$$$STUDENTS SIZE' + studentMap.values().size());
            if (studentMap.values().size() > 0) {
                //deactivate trigger
                CT_core_triggerUtils.mealsTrigger = true;
                CT_core_triggerUtils.studentTriggerUpdate(false);
                processErrors(studentMap.values(), database.update(studentMap.values(), false));
                CT_core_triggerUtils.studentTriggerUpdate(true);
            }

        }
    }

    public class BatchProcessorSection extends BatchProcessor{
        public BatchProcessorSection(){
        }

        public override void init(Set<Id> setupIds, String logClassName){
            this.setupIds = setupIds;
            this.logClassName = logClassName;
            logsInit(new List<String>{'Staff_Section__c','Student_Section__c','Section__c'}, setupIds);
        }

        public override String processQuery(Set<String> currYears, Set<Id> schoolIds) {
            String queryToProcess = 'Select of_Time_by_Medium_of_Instruction__c, of_Students__c, of_Missing_Homework__c, of_Late_Homework__c,' +
                    'of_Homework_Completed__c, of_Homework_Assignments__c, of_Consecutive_Days_without_Grades__c, isGroup__c,' +
                    'Type__c, Time__c, Text_Color__c, Teachers__c, Staff__c, Show_in_portal__c, Section__c, Section_Number__c,' +
                    'School__c, Scheduler_Reference_Id__c, Schedule_Group__c, Period__c, Medium_of_Instruction__c, Maximum_of_Seats__c,' +
                    'MEP_Session_Type__c, Legacy_ID__c, Is_Section__c, Homework_Based__c, Homeroom__c, Holding_Source__c, Has_Homework__c,' +
                    'Grade_Scale__c, Grade_Level__c, Exclude_From_Storing_Final_Grades__c, Exclude_From_GPA__c, Exclude_From_Attendance__c,' +
                    'Daily_Attendance__c, Course__c, Active__c, Deactivated__c, Archived__c From Section__c ';
            if (schoolIds != null && currYears != null && !schoolIds.isEmpty() && !currYears.isEmpty()) {
                queryToProcess += ' WHERE Time__c IN(\''+String.join(new List<String>(currYears), '\',\'')+'\') ';
                queryToProcess += ' AND School__c IN(\''+String.join(new List<Id>(schoolIds), '\',\'')+'\') ';
            }

            return queryToProcess;
        }

        public override void process(List<SObject> scope){
            Section__c[] sectionBatch = (Section__c[]) scope;
            Map<Id, Section__c> sectionMap = processSections(sectionBatch);
            processStaffSections(sectionMap);
            processStudentSections(sectionMap);
        }

        public override Boolean execLogic(){
            List<Setup__c> lstSetups = new List<Setup__c>();

            fldSetActive = className=='EOY'? 'Processed_EOY_Data__c': 'Data_Activated__c';
            System.debug('@@@ fldSetActive: '+fldSetActive);
            for(CT_core_SetupWrapper sw: setups.values()){
                Setup__c s = sw.setup;
                s.put(fldSetActive, true);
                s.ActivateRelated__c = true;
                lstSetups.add(s);
                System.debug('@@@ s.ActivateRelated__c: '+s.ActivateRelated__c);
            }
            update lstSetups;
            return true;
        }

        private Map<Id, Section__c> processSections(Section__c[] sectionBatch) {
            Map<Id, Section__c> sectionMap = new Map<Id, Section__c>();

            for (Section__c sec : sectionBatch) {
                CT_core_SetupWrapper cSetup = setups.get(mapSchool2Setup.get(sec.School__c));
                if (className == 'EOY') {
                    if (sec.Active__c) {
                        sec.Active__c = bFlag;
                        sec.Archived__c = !bFlag;
                    }
                } else if (sec.Deactivated__c==false && cSetup!=null && cSetup.isReactivate==false){
                    sec.Active__c = bFlag;
                    sec.Archived__c = !bFlag;
                }
                sectionMap.put(sec.Id, sec);
            }
            System.debug('$$$$$SECTIONS SIZE' + sectionMap.values().size());
            if (sectionMap.values().size() > 0) {
                processErrors(sectionMap.values(), database.update(sectionMap.values(), false));
            }

            return sectionMap;
        }

        private void processStudentSections(Map<Id, Section__c> sectionMap) {
            Map<Id, Student_Section__c> studentSectionMap = new Map<Id, Student_Section__c>();
            Map<Id, Student__c> studentMap = new Map<Id, Student__c>();

            for (Student_Section__c stusec : [SELECT Archived__c,Section__r.School__c,Section__r.Time__r.Name__c,Student__c,Student__r.Archived__c,Student__r.Active__c,Student__r.Reference_Id__c,Active__c FROM Student_Section__c WHERE Section__c in:sectionMap.keyset()]) {
                CT_core_SetupWrapper cSetup = setups.get(mapSchool2Setup.get(stusec.Section__r.School__c));
                System.debug('@@@ cSetup.isReactivate: '+(cSetup!=null? cSetup.isReactivate: false));
                if (className == 'EOY') {
                    if (stusec.Active__c) {
                        stusec.Active__c = bFlag;
                        stusec.Archived__c = !bFlag;
                    }
                } else if (cSetup!=null && cSetup.isReactivate == false) {
                    stusec.Active__c = bFlag;
                    stusec.Archived__c = !bFlag;
                }
                studentSectionMap.put(stusec.Id, stusec);

            }
            System.debug('$$$$$STUDENT SECTONS SIZE' + studentSectionMap.values().size());
            if (studentSectionMap.values().size() > 0) {
                //deactivate trigger
                CT_core_triggerUtils.studentSectionTriggerUpdate(false);
                CT_core_triggerUtils.b = true;
                processErrors(studentSectionMap.values(), database.update(studentSectionMap.values(), false));
                CT_core_triggerUtils.studentSectionTriggerUpdate(true);
                CT_core_triggerUtils.b = false;
            }

        }

        private void processStaffSections(Map<Id, Section__c> sectionMap) {
            Map<Id, Staff_Section__c> staffSectionMap = new Map<Id, Staff_Section__c>();

            for (Staff_Section__c staffsec : [SELECT School__c,Archived__c,Reference_Id__c,Staff__r.Reference_Id__c,Is_Active__c,Section__r.Time__r.Name__c FROM Staff_Section__c WHERE Section__c in:sectionMap.keyset() AND Section__r.Is_Section__c = true]) {
                if (className == 'EOY') {
                    if (staffsec.Is_Active__c) {
                        staffsec.Is_Active__c = bFlag;
                        staffsec.Archived__c = !bFlag;
                    }
                } else {
                    staffsec.Is_Active__c = bFlag;
                    staffsec.Archived__c = !bFlag;
                }
                /*	PU: Since scheduling is done before EOY process staff sections should always have year appended to them, updated triggers and import utils to append year in the reference ID
            if(!staffsec.Reference_Id__c.contains(staffsec.Section__r.Time__r.Name__c))
                    staffsec.Reference_Id__c +='-'+staffsec.Section__r.Time__r.Name__c;
                    */
                staffSectionMap.put(staffsec.Id, staffsec);

            }
            System.debug('$$$$$STAFF SECTONS SIZE' + staffSectionMap.values().size());
            CT_core_triggerUtils.deactivate = true;
            if (staffSectionMap.values().size() > 0) {
                //deactivate trigger
                processErrors(staffSectionMap.values(), database.update(staffSectionMap.values(), false));
            }
            CT_core_triggerUtils.deactivate = false;
        }
    }

}
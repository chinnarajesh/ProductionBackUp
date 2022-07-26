public with sharing class ISTool{
    public  static final String SECTION_CURRICULUM = 'Curriculum';
    private Map<ID, SessionWrapper> sessionIDMap;
    private Map<Date, List<SessionWrapper>> sessionDateMap;
    private List<SessionWrapper> orderedSessions;

    private ID sectionID;
    private ID studentSectionID;
    private ID sessionID;
    private ID staffID;
    private Date sessionStartDate;
    private Date sessionEndDate;
    private Boolean hasLoadedData = false;
    private Boolean loadSessionResults = true;

    public ISTool(ID sectionID){
        this(sectionId, null, null, null, true);
    }

    public ISTool(ID sectionID, ID studentSectionID){
        this(sectionID, studentSectionID, null, null, true);
    }

    public ISTool(ID sectionID, ID studentSectionID, Date sessionDate){
        this(sectionID, studentSectionID, sessionDate, null, true);
    }

    public ISTool(ID sectionID, ID studentSectionID, Date sessionStartDate, Date sessionEndDate){
        this(sectionID, studentSectionID, sessionStartDate, sessionEndDate, true);
    }

    public ISTool(ID sectionID, Boolean loadResults){
        this(sectionId, null, null, null,loadResults);
    }

    public ISTool(ID sectionID, ID studentSectionID, Boolean loadResults){
        this(sectionID, studentSectionID, null, null,loadResults);
    }

    public ISTool(ID sectionID, ID studentSectionID, Date sessionDate, Boolean loadResults){
        this(sectionID, studentSectionID, sessionDate, null,loadResults);
    }

    public ISTool(ID sectionID, ID studentSectionID, Date sessionStartDate, Date sessionEndDate, Boolean loadResults){
        this.sectionID = sectionID;
        this.studentSectionID = studentSectionID;
        this.sessionStartDate = sessionStartDate;
        this.sessionEndDate = sessionEndDate;
        this.loadSessionResults = loadResults;
    }

    public void updateSessionSelection(ID sectionID){
        updateSessionSelection(sectionId, null, null, null);
    }

    public void updateSessionSelection(ID sectionID, ID studentSectionID){
        updateSessionSelection(sectionID, studentSectionID, null, null);
    }

    public void updateSessionSelection(ID sectionID, ID studentSectionID, Date sessionDate){
        updateSessionSelection(sectionId, studentSectionID, sessionDate, null);
    }

    public void updateSessionSelection(ID sectionID, ID studentSectionID, Date sessionStartDate, Date sessionEndDate){
        this.sectionID = sectionID;
        this.studentSectionID = studentSectionID;
        this.sessionStartDate = sessionStartDate;
        this.sessionEndDate = sessionEndDate;
        if(hasLoadedData){
            loadSessionData();
        }
    }

    public void updateSessionSelection(ID sectionID, ID studentSectionID, Date sessionStartDate, Date sessionEndDate, ID staffID){
        this.staffID = staffID;
        updateSessionSelection(sectionId, studentSectionID, sessionStartDate, sessionEndDate);
    }

    public void updateResultSelection(Boolean loadResults){
        this.loadSessionResults = loadResults;
    }

    public void setSingleSession(ID sessionID){
        this.sessionID = sessionID;
    }

    public void setAllSessions(){
        this.sessionID = null;
    }

    public void loadSessionData(){
        hasLoadedData = true;
        sessionIDMap = new Map<ID, SessionWrapper>();
        sessionDateMap = new Map<Date, List<SessionWrapper>>();
        orderedSessions = new List<SessionWrapper>();

        List<Intervention_Session__c> sessions = querySessions();
        for(Intervention_Session__c session:sessions){
            SessionWrapper wrapper = new SessionWrapper(session);
            orderedSessions.add(wrapper);
            sessionIDMap.put(wrapper.session.ID, wrapper);
            if(sessionDateMap.containsKey(wrapper.session.Date__c)){
                sessionDateMap.get(wrapper.session.Date__c).add(wrapper);
            } else {
                sessionDateMap.put(wrapper.session.Date__c, new List<SessionWrapper>{wrapper});
            }
        }
    }

    public SessionWrapper getSessionByID(ID sessionID){
        return sessionIDMap.get(sessionID);
    }

    public List<SessionWrapper> getSessionsByDate(Date sessionDate){
        return sessionDateMap.get(sessionDate);
    }

    public List<SessionWrapper> getOrderedSessions(){
        return orderedSessions;
    }

    private List<Intervention_Session__c> querySessions(){
        String query = 
            'select ID, Name,Tutoring_Model__c, Skills_Covered_for_the_Session__c, Date__c, All_avenues__c, Comments__c, Session_Time_Completed_For__c, Site_Details__c, '+
                'Session_Time_Completed_For__r.Name, Skill_Primary__c, Skill_Primary__r.Name, LastModifiedDate, Session_Type__c, Session_Format__c ';

        if(loadSessionResults){
            query += ',(select ID, Amount_of_Time__c, Student_Section__c, Student_Section__r.Dosage_to_Date__c, Student_Section__r.Student_Name__c,Exit_Ticket__c'+
                ' from Intervention_Session_Results__r';
            if(studentSectionID != null){
                query += ' where Student_Section__c =\''+String.escapeSingleQuotes(studentSectionID)+'\'';
            }
            query += ' order by Student_Section__r.Student__r.Name)';
        }
                
        query += ' from Intervention_Session__c';
        
        String[] queryFilters = new String[]{};
        if(sectionID != null){
            queryFilters.add('Section__c=\''+String.escapeSingleQuotes(sectionID)+'\'');
        }
        if(sessionStartDate != null && sessionEndDate == null){
            queryFilters.add('Date__c = '+reformatDate(sessionStartDate));
        } else if(sessionStartDate != null && sessionEndDate != null){
            queryFilters.add('Date__c >= '+reformatDate(sessionStartDate));
            queryFilters.add('Date__c <= '+reformatDate(sessionEndDate));
        }
        if(sessionID != null){
            queryFilters.add('ID = \''+sessionID+'\'');
        }
        if(staffID != null){
            queryFilters.add('Session_Time_Completed_For__c=\''+staffID+'\'');
        }

        if(!queryFilters.isEmpty()){
            query += ' where '+String.join(queryFilters,' AND ');
        }
        query+= ' order by Date__c desc';

        System.debug(query);
        List<Intervention_Session__c> results = Database.query(query);
        return results;
    }

    @TestVisible
    private String reformatDate(Date d){
        String[] vars = d.format().split('/',3);
        if(vars[0].length()==1) vars[0] = '0'+vars[0];
        if(vars[1].length()==1) vars[1] = '0'+vars[1];
        return vars[2]+'-'+vars[0]+'-'+vars[1];
    }

    public static final Map<String, String> mapSchoolProgram2Category = new Map<String, String>{
            'Tutoring: Literacy' => 'Literacy',
            'Tutoring: Math' => 'Math'
    };
    public static final String CATBEHAVIOR = 'SEL/Behavior and Attendance Interventions';
    public static void getAvaliableSkills(String schoolProgram, List<SelectOption> avaliableFields, List<SelectOption> allPrimaryFields){
        String category = mapSchoolProgram2Category.containsKey(schoolProgram)? mapSchoolProgram2Category.get(schoolProgram): CATBEHAVIOR;
        Set<String> categoryList = new Set<String>{CATBEHAVIOR};
        categoryList.add(category);
        System.debug('School Program>>'+schoolProgram);
        System.debug('@@@ categoryList: '+categoryList);

        for(Skill__c s :[SELECT Id, Category__c, Name, IsPrimary__c FROM Skill__c
        WHERE Category__c IN :categoryList ORDER BY Name, Category__c ASC]){
            if(s.IsPrimary__c && s.Category__c == category){
                allPrimaryFields.add(new SelectOption(s.Id, s.Name));
            }
            avaliableFields.add(new SelectOption(s.Id, s.Name));
        }
        System.debug('@@@ Skill List allPrimaryFields>>'+allPrimaryFields);
        System.debug('@@@ Skill List avaliableFields>>'+avaliableFields);
    }

    public static List<SelectOption> getAllAvenues(){
        List<SelectOption> allAvenuesOptions = new List<SelectOption>();
        allAvenuesOptions.add(new SelectOption('', 'None', true));
        Map<String, String> mapValues = CT_core_SoqlUtils.getPicklistValues('Intervention_Session__c' ,'All_avenues__c');
        for(String val: mapValues.keySet()){
            allAvenuesOptions.add(new SelectOption(val, mapValues.get(val)));
        }
         system.debug('@@ allAvenuesOptions'+allAvenuesOptions);
        return allAvenuesOptions;
    }

    public static List<SelectOption> getSiteDetailsOptions(){
        List<SelectOption> siteDetailsOptions = new List<SelectOption>();
        String usersSite = [Select Site__c From User Where Id = :UserInfo.getUserId()][0].Site__c;
        if (usersSite == '' || usersSite == null){
            siteDetailsOptions = null;
        } else {
            List<Site_Details_Mapping__mdt> mappings = [SELECT Values__c
                                                        FROM Site_Details_Mapping__mdt
                                                        WHERE Location__c = :usersSite];
            if (mappings.size() != 0 && mappings[0].Values__c != null && mappings[0].Values__c != '') {
                siteDetailsOptions.add(new SelectOption('', 'None', false));
                List<String> values = mappings[0].Values__c.split(';');
                for(String value : values) {
                    siteDetailsOptions.add(new SelectOption(value, value));
                }
            }
        }
        return siteDetailsOptions;
    }

    public class SessionWrapper{
        public Intervention_Session__c session  {get;set;}
        public List<Intervention_Session_Result__c> studentResults {get;set;}

        public SessionWrapper(Intervention_Session__c session){
            this.session = session;
            if(session.Intervention_Session_Results__r != null){
                this.studentResults = session.Intervention_Session_Results__r;
            } else {
                this.studentResults = new List<Intervention_Session_Result__c>();
            }
        }
    }

}
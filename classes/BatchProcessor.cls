/**
 * Created by Torubka Taras on 11/11/2019.
 */

public virtual class BatchProcessor{
    protected Map<String, Data_Load_Log__c> log;
    protected Map<Id, Id> mapSchool2Setup;
    protected Map<Id, CT_core_SetupWrapper> setups;
    protected Set<Id> setupIds;
    protected String fldSetActive;
    protected String logClassName;
    public String className;
    public Boolean bFlag;
    protected final Map<String, String> mapSOBJECT2SCHOOL = new Map<String, String>{
            'Student__c'=>'School__c',
            'Section__c'=>'School__c',
            'Student_Section__c'=>'Section__r.School__c',
            'Staff_Section__c'=>'School__c'
    };

    public BatchProcessor(){}

    public virtual void init(Set<Id> setupIds, String logClassName){this.setupIds = setupIds; this.logClassName=logClassName;}
    public virtual void process(List<SObject> scope){}
    public virtual String processQuery(Set<String> currYears, Set<Id> schoolIds){return '';}
    public virtual Boolean execLogic(){return true;}

    public String startProcess(Id jobId){
        setups = new Map<Id, CT_core_SetupWrapper>();
        mapSchool2Setup = new Map<Id, Id>();
        Set<String> years = new Set<String>();

        List<Setup__c> lstSetups = CT_core_SoqlUtils.getSetupByIds(setupIds);
        for(Setup__c s: lstSetups){
            setups.put(s.Id, new CT_core_SetupWrapper(s, ''));
            mapSchool2Setup.put(s.School__c, s.Id);
            years.add(s.Year__c);
        }

        String query = processQuery(years, mapSchool2Setup.keySet());
        System.debug('@@@ query ='+query);

        execLogic();
        logsStart(jobId);

        return query;
    }

    protected void logsInit(List<String> objs, Set<Id> setupIds){
        log = new Map<String, Data_Load_Log__c>();

        for(String obj: objs){
            for(Id idx: setupIds) {
                log.put(idx + '#' + obj, new Data_Load_Log__c(Setup__c = idx, Type__c = obj, Status__c = 'Pending', Class_Name__c = logClassName));
            }
        }

        insert log.values();
    }

    public void logsFinish(){
        for (Data_Load_Log__c d : log.values()) {
            d.Status__c = 'Completed';
            d.End_Time__c = System.now();
            d.End_Time_Text__c = d.End_Time__c.format('MM/dd/yyyy hh:mm a');
        }
        update log.values();
    }

    protected void logsStart(Id jobId){
        for (Data_Load_Log__c d : log.values()) {
//				d.Setup__c = cSetup.setup.id;
            d.Batch_ID__c = jobId;//ctx.getJobId();
            d.Status__c = 'Running';
            d.Total_Records__c = 0;
            d.Failed_Records__c = 0;
            d.Start_Time__c = System.now();
            d.Start_Time_Text__c = d.Start_Time__c.format('MM/dd/yyyy hh:mm a');
        }
        update log.values();
    }

    protected void processErrors(List<SObject> records, List<Database.SaveResult> results) {
        System.assertEquals(records.size(), results.size(), 'Records and results arrays must of equal size');
        String sobjName = String.valueOf(records[0].getSObjectType());
        sobjName = sobjName.contains('SchoolForce')? sobjName.replace('SchoolForce__', ''): sobjName;
        String fldSchool = mapSOBJECT2SCHOOL.containsKey(sobjName)? mapSOBJECT2SCHOOL.get(sobjName): '';
        Map<Id, Setup__c> mapUpdateSetups = new Map<Id, Setup__c>();

        for (Integer i = 0; i < results.size(); i++) {
            String setupId = (String)mapSchool2Setup.get((String)getFieldValue(records[i], fldSchool));
            String key = setupId + '#' + sobjName;
            Data_Load_Log__c clog = log.get(key);
            clog.Total_Records__c += 1;//records.size();
            if (!results[i].isSuccess()) {
                clog.Failed_Records__c++;
                for (Database.Error err : results[i].getErrors()) {
                    if (clog.Messages__c != '' && clog.Messages__c != null)
                        clog.Messages__c += '\n';
                    clog.Messages__c += results[i].getId() + ' - ' + err.getMessage();
                }

                if(String.isNotBlank(fldSetActive) && setups.containsKey(setupId)){
                    System.debug('@@@ fldSetActive false: '+setupId);
                    Setup__c s = setups.get(setupId).setup;
                    s.put(fldSetActive, false);
                    mapUpdateSetups.put(s.Id, s);
                }
            }
        }

        update log.values();
        if(!mapUpdateSetups.isEmpty()){
            update mapUpdateSetups.values();
        }
    }

    protected Object getFieldValue(SObject o, String fld){
        if(o==null && String.isBlank(fld)){ return null;}
        if(fld.contains('.')){
            String nextField = fld.substringAfter('.');
            String relation = fld.substringBefore('.');
            return getFieldValue((SObject)o.getSObject(relation),nextField);
        }else{
            return o.get(fld);
        }
    }
}
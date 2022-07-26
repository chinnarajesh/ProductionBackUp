global class DataLoadLogList {

	public static final String STUDENT_SUMMARY = 'Student Summary';
	public static final String STUDENT_SECTION_SUMMARY = 'Student Section Summary';
	public static final String SCHOOL_SUMMARY = 'School Summary';
	public static final String SCHOOL_SECTION_SUMMARY = 'School Section Summary';

	global Map<String, Data_Load_Log__c> logs {get; private set;}
	
	global DataLoadLogList() {}
	
	global DataLoadLogList(String className, Id setupId, List<String> logTypes) {
		initialize(className, setupId, logTypes);
	}
	
	global void initialize(String className, Id setupId, List<String> logTypes) {
		logs = new Map<String, Data_Load_Log__c>();
		for (String logType : logTypes) {
			logs.put(logType, new Data_Load_Log__c(
				Class_Name__c = className,
				Setup__c = setupId,
				Type__c = logType,
				Status__c = 'Pending',
				Total_Records__c = 0,
				Failed_Records__c = 0,
				Messages__c = ''
			));
		}
		insert logs.values();
	}

	public void setLogBatchId(String batchId){
		for(Data_Load_Log__c log:logs.values()){
			log.Batch_ID__c = batchId;
		}
	}
	
	global void startLog(String logType) {
		Data_Load_Log__c log = logs.get(logType);
		if (log != null) {
			log.Status__c = 'Running';
			log.Start_Time__c = System.now();
			log.Start_Time_Text__c = log.Start_Time__c.format('MM/dd/yyyy hh:mm a');
		}
	}
	
	global void startAll() {
		for (String logType : logs.keySet()) {
			startLog(logType);
		}
		saveLogs();
	}
	
	global void endLog(String logType) {
		Data_Load_Log__c log = logs.get(logType);
		if(log != null){
			if(log.Status__c != 'Failed')
				log.Status__c = 'Completed';
			log.End_Time__c = System.now();
			log.End_Time_Text__c = log.End_Time__c.format('MM/dd/yyyy hh:mm a');
		}
	}
	
	global void endAll() {
		for (String logType : logs.keySet()) {
			endLog(logType);
		}
		saveLogs();
	}
	
	global void incrTotal(String logType) {
		incrTotal(logType, 1);
	}
	
	global void incrFailed(String logType) {
		incrFailed(logType, 1);
	}
	
	global void incrTotal(String logType, Integer incrBy) {
		Data_Load_Log__c log = logs.get(logType);
		if (log != null) {
			log.Total_Records__c = log.Total_Records__c + incrBy;
		}
	}
	
	global void incrFailed(String logType, Integer incrBy) {
		Data_Load_Log__c log = logs.get(logType);
		if (log != null) {
			log.Failed_Records__c = log.Failed_Records__c + incrBy;
		}
		setLogStatus(logType,'Failed');
	}

	public void setLogStatus(String logType, String status){
		if(logType == null){
			for(Data_Load_Log__c log:logs.values()){
				log.Status__c = status;
			}
		} else {
			logs.get(logType).Status__c = status;
		}
	}

	public void saveLogs(){
		try{
			update logs.values();
		} catch(System.DMLException e){
			Global_Error__c ge=Error_Handling.handleError('','BatchSnapshot','Failure updating logs: '+logs.values()[0].Batch_ID__c,e);
			insert ge;
		}
	}

	public void addLogMessage(String logType, String message){
		if(logs.get(logType) != null)
			logs.get(logType).Messages__c += message+'\n';
		if(logs.get(logType).Messages__c.length()>32000)
			logs.get(logType).Messages__c = logs.get(logType).Messages__c.subString(0,31999);
	}
	
	global Integer countAllFailed() {
		Decimal failed = 0;
		for (Data_Load_Log__c log : logs.values()) {
			failed += log.Failed_Records__c;
		}
		
		return (Integer)failed;
	}

	public Boolean hasHadFailures(){
		for(Data_Load_Log__c log:logs.values()){
			if(log.Status__c == 'Failed'){
				return true;
			}
		}
		return false;
	}
}
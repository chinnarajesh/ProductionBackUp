global class Batch_SchoolSnapshotSessionCalc implements Database.Batchable<SObject>, Database.Stateful{	
	private String setupID;
	private Date startDate {get; set;}
	private Date endDate {get; set;}
	
	private Snapshot_Summary__c summary;
	private DataLoadLogList dataLogs;
	
	public Map<ID, Integer> sessionMap {get; set;}
	private Setup__c currentSetup {get; set;}
	private ID SchoolID {get; set;}
	
	global Batch_SchoolSnapshotSessionCalc(Snapshot_Summary__c s, DataLoadLogList d, String sID, Date sDate, Date eDate){
		summary = s;
		dataLogs = d;
		setupID = sID;
		startDate = sDate;
		endDate = eDate;
		sessionMap = new Map<ID, Integer>();
		currentSetup = core_SoqlUtils.getSetupById(setupID);
		schoolID = currentSetup.School__c;
	}
	
	global Database.QueryLocator start(Database.BatchableContext ctx){
		String query = '';
		try {
			query += 'SELECT ID, Section__c FROM Session__c '+
					'WHERE Section__r.School__c =: schoolID '+
					'AND Section__r.Course__r.Include_in_Section_Snapshot__c = TRUE '+
					'AND Start_DateTime__c >=: startDate '+
					'AND Start_DateTime__c <=: endDate '+
					'ORDER BY Section__c ASC';

			return Database.getQueryLocator(query);
		} catch(Exception e) {
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
			dataLogs.addLogMessage(null,'Failure when starting session batch.');
			insert Error_Handling.handleError('','Batch_SchoolSnapshotSessionCalc','Failure in start method',e);
		} finally{
			dataLogs.saveLogs();
		}
		return Database.getQueryLocator('select id from Session__c where ID = null');
	}
	
	global void execute(Database.BatchableContext ctx, List<SObject> scope){
		try{
			for(Session__c s : (List<Session__c>)scope) {
				if(!sessionMap.containsKey(s.ID)) {
					sessionMap.put(s.ID, 1);
				} else {
					Integer i = sessionMap.get(s.ID) + 1;
					sessionMap.put(s.ID, i);
				}
			}
		} catch (Exception e){
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SECTION_SUMMARY,'Failure when loading session map.');
			insert Error_Handling.handleError('','Batch_SchoolSnapshotSessionCalc','Exception starting Batch_SchoolSnapshotAttendanceCalc',e);
			sessionMap = null;
		} finally{
			dataLogs.saveLogs();
		}
	}
	
	global void finish(Database.BatchableContext ctx){
		try{
			Batch_SchoolSnapshotAttendanceCalc attendanceBatch = new Batch_SchoolSnapshotAttendanceCalc(summary, dataLogs, setupID, startDate, endDate, sessionMap);
			Database.executeBatch(attendanceBatch);		
		} catch(Exception e){
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SECTION_SUMMARY,'Failure starting attendance calculations.');
			insert Error_Handling.handleError('','Batch_SchoolSnapshotSessionCalc','Exception starting Batch_SchoolSnapshotAttendanceCalc',e);
		} finally {
			dataLogs.saveLogs();
		}
	}
}
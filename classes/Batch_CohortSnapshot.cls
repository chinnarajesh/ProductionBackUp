global class Batch_CohortSnapshot implements Database.Batchable<SObject>, Database.Stateful{
	public Setup__c setup;
	public Map <Id, Setup__c> activeSetups;
	 
	public String query;    
	public Time_Element__c activeYear;

	//why is there a single and a list of the same object type?
	private Map<ID, Snapshot_Log__c> schoolSnapshotlogMap;
	public Map<ID, Data_Load_Log__c> dataLogs = new Map<ID, Data_Load_Log__c>();
	private Boolean hasfailed = false;
	public static Boolean isFinal = false;

	public Set<ID> schoolSet {get; set;}

	//single school initialization
	public Batch_CohortSnapshot(String setupId, Boolean isFinalRun){
		activeSetups = new Map <Id, Setup__c>();
		Setup__c setup = [SELECT School__c,Year__c,Year__r.Date_Start_Date__c,Year__r.End_Date__c FROM Setup__c WHERE Id=:setupId];
		activeSetups.put(setup.School__c,setup);
		activeYear = setup.Year__r;
		isFinal = isFinalRun;
		
		//set specific query
		query = 'Select ID,School__c  from Cohort__c WHERE Expired__c = FALSE AND School__c =\''+setup.School__c+'\'';
		initSnapshotLogs(new List<Setup__c>{setup});
	}
	
	//multiple school initialization
	public Batch_CohortSnapshot(Set<Id> schoolIds){
		activeSetups = core_SoqlUtils.getActiveSetups(schoolIds);
		//we assume that all the setups are for the same year
		activeYear = activeSetups.values()[0].Year__r;
		schoolSet = schoolIDs;
		query = 'Select ID, School__c FROM Cohort__c WHERE Expired__c = FALSE AND School__c IN: schoolSet';
		initSnapshotLogs(activeSetups.values());
	}

	global Database.QueryLocator start(Database.BatchableContext BC){
		try{
			for(Setup__c s:activeSetups.Values()){
				dataLogs.put(s.id, new Data_Load_Log__c(
					Batch_ID__c=BC.getJobId(),
					Type__c='Cohort Summary',
					Status__c='Running',
					Class_Name__c ='Batch_CohortSnapshot',
					Setup__c = s.id,
					Total_Records__c = 0,
					Processed_Records__c = 0,
					Failed_Records__c = 0,
					Messages__c ='',
					Start_Time__c = System.now(),
					Start_Time_Text__c = System.now().format('MM/dd/yyyy hh:mm a')
				));         
			}
			
			//insert data log
			if(!dataLogs.isEmpty()) {
				insert dataLogs.values();   
			}
			
			system.debug('*~*~* query: ' + query);
			return Database.getQueryLocator(query);
		} catch(Exception e){
			for(Data_Load_Log__c log:dataLogs.values()){
				log.Status__c='Failed';
				log.Messages__c += 'Failure when starting cohort batch.';
			}
			insert Error_Handling.handleError('','Batch_CohortSnapshot','Failure in start method',e);
			update dataLogs.values();
		}

		return Database.getQueryLocator('select id from Cohort__c where ID= null');
	}
	
	global void execute(Database.BatchableContext BC, List<Cohort__c> scope){
		List<Snapshot_Summary__c> summaries = new List<Snapshot_Summary__c>();
		Map<ID, List<Snapshot_Child__c>> cohortToSnapshot = new Map<ID, List<Snapshot_Child__c>>();

		for(Cohort__c c: scope){
			dataLogs.get(activeSetups.get(c.School__c).ID).Total_Records__c++;

			List<Snapshot_Child__c> studentsToProcess = new List<Snapshot_Child__c>();
			Snapshot_Summary__c summaryToInsert = new Snapshot_Summary__c(Snapshot_ID__c = schoolSnapshotlogMap.get(c.School__c).Id);
			
			try{
				BatchSnapshotCohortCalcs bsc = new BatchSnapshotCohortCalcs();
				studentsToProcess = bsc.setCohortStats(c,activeYear.Id);
					
				summaryToInsert.Cohort__c = c.id;
				summaryToInsert.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Snapshot_Summary__c').get('Cohort');
				summaryToInsert.of_Students_Net_New__c = bsc.newStudentsNotInOriginalCohort;
				//PU Total Count of Students (original)
				summaryToInsert.Total_Original_Students_In_Cohort__c = bsc.totalStudentsInOriginalCohort;
				//PU: List of students associated to cohort as of today (original)
				summaryToInsert.Total_Students_In_Cohort__c = bsc.originalTotalStudents;
				//PU  Total Count of Students (today)
				summaryToInsert.Total_Count_of_Students_today__c = bsc.totalStudentsToday;

				summaryToInsert.Students_withdrawn_from_original_list__c = bsc.withdrawnStudentsPercent;
				summaryToInsert.Students_transferred_from_original_list__c = bsc.transferredStudentsPercent;
				summaryToInsert.Students_transferred_from_Current_Year__c = bsc.yoyTransferredStudentsPercent;
				summaryToInsert.Students_droppedout_from_original_list__c = bsc.dropOutStudentsStudentsPercent;
				summaryToInsert.Students_retained_from_original_list__c = bsc.retainedStudentsPercent;

				if(bsc.exitCodesmap.containsKey('1907')) {
					summaryToInsert.X1907__c = bsc.exitCodesmap.get('1907').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1907');
				}
				if(bsc.exitCodesmap.containsKey('1908')) {
					summaryToInsert.X1908__c = bsc.exitCodesmap.get('1908').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1908');
				}
				if(bsc.exitCodesmap.containsKey('1909')) {
					summaryToInsert.X1909__c = bsc.exitCodesmap.get('1909').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1909');
				}
				if(bsc.exitCodesmap.containsKey('1910')) {
					summaryToInsert.X1910__c = bsc.exitCodesmap.get('1910').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1910');
				}
				if(bsc.exitCodesmap.containsKey('1911')) {
					summaryToInsert.X1911__c = bsc.exitCodesmap.get('1911').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1911');
				}
				if(bsc.exitCodesmap.containsKey('1912')) {
					summaryToInsert.X1912__c = bsc.exitCodesmap.get('1912').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1912');
				}
				if(bsc.exitCodesmap.containsKey('1913')) {
					summaryToInsert.X1913__c = bsc.exitCodesmap.get('1913').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1913');
				}
				if(bsc.exitCodesmap.containsKey('1914')) {
					summaryToInsert.X1914__c = bsc.exitCodesmap.get('1914').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1914');
				}
				if(bsc.exitCodesmap.containsKey('1915')) {
					summaryToInsert.X1915__c = bsc.exitCodesmap.get('1915').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1915');
				}
				if(bsc.exitCodesmap.containsKey('1916')) {
					summaryToInsert.X1916__c = bsc.exitCodesmap.get('1916').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1916');
				}
				if(bsc.exitCodesmap.containsKey('1917')) {
					summaryToInsert.X1917__c = bsc.exitCodesmap.get('1917').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1917');
				}
				if(bsc.exitCodesmap.containsKey('1918')) {
					summaryToInsert.X1918__c = bsc.exitCodesmap.get('1918').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1918');
				}
				if(bsc.exitCodesmap.containsKey('1920')) {
					summaryToInsert.X1920__c = bsc.exitCodesmap.get('1920').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1920');
				}
				if(bsc.exitCodesmap.containsKey('1921')) {
					summaryToInsert.X1921__c = bsc.exitCodesmap.get('1921').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1921');
				}
				if(bsc.exitCodesmap.containsKey('1922')) {
					summaryToInsert.X1922__c = bsc.exitCodesmap.get('1922').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1922');
				}
				if(bsc.exitCodesmap.containsKey('1923')) {
					summaryToInsert.X1923__c = bsc.exitCodesmap.get('1923').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1923');
				}
				if(bsc.exitCodesmap.containsKey('1924')) {
					summaryToInsert.X1924__c = bsc.exitCodesmap.get('1924').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1924');
				}
				if(bsc.exitCodesmap.containsKey('1925')) {
					summaryToInsert.X1925__c = bsc.exitCodesmap.get('1925').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1925');
				}
				if(bsc.exitCodesmap.containsKey('1926')) {
					summaryToInsert.X1926__c = bsc.exitCodesmap.get('1926').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1926');
				}
				if(bsc.exitCodesmap.containsKey('1927')) {
					summaryToInsert.X1927__c = bsc.exitCodesmap.get('1927').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1927');
				}
				if(bsc.exitCodesmap.containsKey('1928')) {
					summaryToInsert.X1928__c = bsc.exitCodesmap.get('1928').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1928');
				}
				if(bsc.exitCodesmap.containsKey('1930')) {
					summaryToInsert.X1930__c = bsc.exitCodesmap.get('1930').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1930');
				}
				if(bsc.exitCodesmap.containsKey('1931')) {
					summaryToInsert.X1931__c = bsc.exitCodesmap.get('1931').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('1931');
				}
				if(bsc.exitCodesmap.containsKey('3499')) {
					summaryToInsert.X3499__c = bsc.exitCodesmap.get('3499').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3499');
				}
				if(bsc.exitCodesmap.containsKey('3500')) {
					summaryToInsert.X3500__c = bsc.exitCodesmap.get('3500').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3500');
				}
				if(bsc.exitCodesmap.containsKey('3501')) {
					summaryToInsert.X3501__c = bsc.exitCodesmap.get('3501').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3501');
				}
				if(bsc.exitCodesmap.containsKey('3502')) {
					summaryToInsert.X3502__c = bsc.exitCodesmap.get('3502').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3502');
				}
				if(bsc.exitCodesmap.containsKey('3503')) {
					summaryToInsert.X3503__c = bsc.exitCodesmap.get('3503').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3503');
				}
				if(bsc.exitCodesmap.containsKey('3504')) {
					summaryToInsert.X3504__c = bsc.exitCodesmap.get('3504').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3504');
				}
				if(bsc.exitCodesmap.containsKey('3505')) {
					summaryToInsert.X3505__c = bsc.exitCodesmap.get('3505').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3505');
				}
				if(bsc.exitCodesmap.containsKey('3508')) {
					summaryToInsert.X3508__c = bsc.exitCodesmap.get('3508').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3508');
				}
				if(bsc.exitCodesmap.containsKey('3509')) {
					summaryToInsert.X3509__c = bsc.exitCodesmap.get('3509').SF_Student_Exit__c+'-'+bsc.exitCodeCountMap.get('3509');
				}

				summaries.add(summaryToInsert);
				dataLogs.get(activeSetups.get(c.School__c).ID).Processed_Records__c++;
				cohortToSnapshot.put(c.id, studentsToProcess);
			} catch(Exception e){
				datalogs.get(activeSetups.get(c.School__c).ID).Failed_Records__c++;
				datalogs.get(activeSetups.get(c.School__c).ID).Status__c='Failed';
				datalogs.get(activeSetups.get(c.School__c).ID).Messages__c += 'Failure generating cohort summary for Cohort ' + c.ID+'\n';
				Error_Handling.handleMultiPartException('', 'Batch_CohortSnapshot', 'Cohort Summary error (cohort: ' + c.ID + ')', e);
			}
		}
		

		try{
			upsert summaries;

			List<Snapshot_Child__c> toUpsert = new List<Snapshot_Child__c>();
			for(Snapshot_Summary__c ss:summaries){
				for(Snapshot_Child__c sc:cohortToSnapshot.get(ss.Cohort__c)){
					sc.Snapshot_Summary__c = ss.id;
					toUpsert.add(sc);
				}
			}

			upsert toUpsert;
		} catch(Exception e){
			for(Data_Load_Log__c log:dataLogs.values()){
				log.Status__c='Failed';
				log.Failed_Records__c++;
				log.Messages__c += 'Failure when inserting cohort summaries and children.\n';
			}
			insert Error_Handling.handleError('', 'Batch_CohortSnapshot', 'Insertion failure for cohort snapshots', e);
		} finally{
			update datalogs.values();
			Error_Handling.insertMultiPartException();
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		for(Data_Load_Log__c log:dataLogs.Values()){
			if(log.Status__c != 'Failed')
				log.Status__c = 'Completed';
			log.End_Time__c = System.now();
			log.End_Time_Text__c = log.End_Time__c.format('MM/dd/yyyy hh:mm a');            
		}   
		update dataLogs.values();
	}

	public void initSnapshotLogs(List<Setup__c> setups){
		schoolSnapshotlogMap = new Map<ID, Snapshot_Log__c>();
		for(Setup__c s: setups){
			schoolSnapshotlogMap.put(s.School__c, 
				new Snapshot_Log__c(Snapshot_Type__c = 'Cohort', 
					School__c = s.School__c, Period_Start__c = s.Year__r.Date_Start_Date__c,
					Period_End__c = s.Year__r.End_Date__c,
					Snapshot_Taken__c = system.now(),
					is_Final__c = isFinal,
					Setup__c = s.ID)
				); 
		}

		insert schoolSnapshotlogMap.values();
	}
	
	WebService static String runCohortBatch() {
		Set<Id> schoolIds = new Set<Id>();
		try {
			for(AggregateResult ag : [SELECT School__c a FROM Cohort__c WHERE Expired__c = false GROUP BY School__c]){
				schoolIds.add((ID)ag.get('a'));	
			}

			Batch_CohortSnapshot cs = new	Batch_CohortSnapshot(schoolIds);	
			ID batchprocessid =Database.executeBatch(cs, 1);
			return 'success';
		} catch(Exception e) {
			system.debug(e.getMessage());
		}
		return 'error';
	}
}
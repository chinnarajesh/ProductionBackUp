global class BatchSnapshotCohortCalcs {
	global Cohort__c cohort                                 {get; private set;} 
	global integer totalStudentsInOriginalCohort            {get; private set;}
	global integer newStudentsNotInOriginalCohort           {get; private set;}
	global integer totalStudentsToday                       {get; private set;}
	global integer origCohortStudentsTransferredCount       {get; private set;}
	global integer origCohortYOYStudentsTransferredCount    {get; private set;}
	global integer origCohortStudentsWithdrawnCount         {get; private set;}
	global integer origCohortStudentsDropOutCount           {get; private set;}
	global integer origCohortStudentsRetainedCount          {get; private set;}
	global double withdrawnStudentsPercent					{get; private set;}
	global double yoyTransferredStudentsPercent				{get; private set;}
	global double transferredStudentsPercent				{get; private set;}
	global double dropOutStudentsStudentsPercent			{get; private set;}
	global double retainedStudentsPercent					{get; private set;}
	global Map<String,Integer> exitCodeCountMap 			{get;set;}
	global Map<String, Proactive_CS__c> exitCodesmap 		{get;set;}
	
	// The below global variables are depricated
	global integer originalActiveStudents 					{get; private set;}
    global integer originalTotalStudents 					{get; private set;}
    global integer newStudents 								{get; private set;}
    global integer currentStudents 							{get; private set;}
    global integer numStudentsWithdrawn 					{get; private set;}
    global double percentOriginalStudentsWithdrawn 			{get; private set;}
    global integer numStudentsWithdrawnFromOriginal			{get; private set;}
    global List<Student__c> originalStudentsList			{get; private set;}
    global List<Student__c> currentStudentsList				{get; private set;}
	
	// This method has been added back as they cannot be removed from Managed package
	global List<Snapshot_Child__c> setCohortStats(Cohort__c c){return null;}

	global List<Snapshot_Child__c> setCohortStats(Cohort__c c,String year){
		List<Snapshot_Child__c> snapshotChildren = new List<Snapshot_Child__c>();
		Map<String,Student__c>  contactStudentsOriginalCohortMap = new Map<String,Student__c>();
		exitCodeCountMap = new Map<String,Integer>();
		exitCodesmap = new Map<String,Proactive_CS__c >();
		originalTotalStudents = 0;
		totalStudentsInOriginalCohort = 0;
		newStudentsNotInOriginalCohort=0;
		totalStudentsToday = 0;
		origCohortStudentsTransferredCount = 0;
		origCohortYOYStudentsTransferredCount = 0;
		origCohortStudentsWithdrawnCount = 0;
		origCohortStudentsDropOutCount = 0;
		origCohortStudentsRetainedCount = 0;
		
		withdrawnStudentsPercent = 0;
		yoyTransferredStudentsPercent = 0;
		retainedStudentsPercent = 0;
		transferredStudentsPercent = 0;
		dropOutStudentsStudentsPercent = 0;
		
		for(Proactive_CS__c ec :[SELECT SF_Student_Exit__c,Student_Exit_Type__c,Proactive_Student_Exit__c FROM Proactive_CS__c WHERE Proactive_Student_Exit__c <> null]){
			exitCodesmap.put(ec.Proactive_Student_Exit__c, ec);
			exitCodeCountMap.put(ec.Proactive_Student_Exit__c,0);
		}
		List<Snapshot_Child__c> childrenRecords = new List<Snapshot_Child__c>();
		for(Student__c stu : [Select Name,Entry_Date__c,Exit_Reason__c,Exit_Date__c,Student_ID__c,Home_Language__c,School__c,Grade__c,OSSE_Code_Text__c,
								Original_Member_Of_Cohort__c,Active__c,Individual__c,Exit_Type__c,School_Year__c
							from Student__c 
							where Individual__r.Cohort__c = : c.id 
							AND School_Year__c =: year]){
			
			if(stu.Original_Member_Of_Cohort__c){ 
				if(stu.Exit_Type__c !='' && stu.Exit_Type__c !=null){
					Integer exitStudCount = exitCodeCountMap.get(stu.OSSE_Code_Text__c);
					exitCodeCountMap.put(stu.OSSE_Code_Text__c,exitStudCount++);
				}

				if(stu.Exit_Type__c=='Transfer'){
					origCohortStudentsTransferredCount++;
					if(stu.School_Year__c == year){
						origCohortYOYStudentsTransferredCount++;
					}
				} else if(stu.Exit_Type__c=='Withdraw'){
					origCohortStudentsWithdrawnCount++;
				} else if(stu.Exit_Type__c=='Dropout'){
					origCohortStudentsDropOutCount++;
				}

				if(stu.School_Year__c == year && stu.Active__c) {
					originalTotalStudents++;
				}
				
				contactStudentsOriginalCohortMap.put(stu.Individual__c,stu); 
			} else if(stu.School_Year__c == year && stu.Active__c){
				newStudentsNotInOriginalCohort++;
			}
			
			if(stu.School_Year__c == year && stu.Active__c) {
				totalStudentsToday++;
			}
			
			//generate a snapshot child regardless
			Snapshot_Child__c sn = new Snapshot_Child__c();
			sn.Original_Member_Of_Cohort__c = stu.Original_Member_Of_Cohort__c;
			sn.Withdraw_Date__c             = (Date)stu.Exit_Date__c;
			sn.Entry_Date__c                = stu.Entry_Date__c;
			sn.Student_OSSE_Exit_Code__c    = stu.OSSE_Code_Text__c;
			sn.Student_Exit_Reason__c       = stu.Exit_Reason__c;
			sn.Student_Name__c              = stu.Name;
			sn.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Snapshot_Child__c').get('Cohort');            
			snapshotChildren.add(sn);
			System.debug('Snapshot children$$'+sn); 
		}

		//Total Count of Students (original)
		totalStudentsInOriginalCohort = contactStudentsOriginalCohortMap.keyset().size();
		origCohortStudentsRetainedCount = totalStudentsInOriginalCohort - origCohortStudentsTransferredCount - origCohortStudentsWithdrawnCount - origCohortStudentsDropOutCount;
		
		if(totalStudentsInOriginalCohort>0){
			withdrawnStudentsPercent = double.valueOf(origCohortStudentsWithdrawnCount/totalStudentsInOriginalCohort*100);
			yoyTransferredStudentsPercent = double.valueOf(origCohortYOYStudentsTransferredCount/totalStudentsInOriginalCohort*100);
			transferredStudentsPercent = double.valueOf(origCohortStudentsTransferredCount/totalStudentsInOriginalCohort*100);
			dropOutStudentsStudentsPercent = double.valueOf(origCohortStudentsDropOutCount/totalStudentsInOriginalCohort*100);
			retainedStudentsPercent = double.valueOf(origCohortStudentsRetainedCount/totalStudentsInOriginalCohort*100);
		}
		
		return snapshotChildren;
	}
}
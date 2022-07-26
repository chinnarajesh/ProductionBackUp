global class BatchUpsertHoldingObj implements Database.Batchable<sObject>{
	   public String query;
	   public core_SetupWrapper cSetup;
	   public String repPeriodId;
	   
	   
	   
	   public static string processQuery(core_SetupWrapper cSetup, String repPeriodId){
		string queryToProcess;
		
		queryToProcess ='Select account__r.reference_Id__c ,  staff__r.reference_Id__c, Type__c,grade_level__c, schedule_group_name__c, Staff__c, Section__c, Schedule_Template__c, Schedule_Group_Section__c, Room__c, Reporting_Period__c, Reference_Id__c, Period_Key__c, Course__c, course_name__c, Account__c,'
     							+	 'reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c,'
     							+	 'staff__r.First_Name_Staff__c,'
								+	 'staff__r.Staff_Last_Name__c,'
						 		+	 'staff__r.Individual__r.Staff_Code__c,'
						 		+	 'No_Meeting__c,'
						 		+	 'Section__r.No_Meeting__c,'
						 		+	 'section_ReportingPeriod__r.Time__c,'
								+	 'staff__r.Individual__r.User_Name__c,'
								+	 'staff__r.Individual__r.Email,'
								+	 'staff__r.Individual__r.Phone,'
						 		+	 'staff__r.Individual__r.MailingStreet,'
								+	 'staff__r.Individual__r.MailingCity,'
								+	 'staff__r.Individual__r.MailingState,'
								+	 'staff__r.Individual__r.MailingPostalCode,'
								+	 'staff__r.Individual__r.Gender__c,'
								+	 'Section__r.Section_Number__c,'
								+	 'section__r.Name,'
								+	 'section__r.Grade_Level__c,'
								+	 'section__r.All_Grades__c,'
								+	 'section__r.Period__c,'
								+	 'section__r.record_Attendance__c,'
								+	 'section__r.daily_attendance__c,'
								+	 'section__r.reporting_period__c, '
								+	 'section__r.reference_Id__c, '
								+	 'section__r.time__r.Name__c, '
								+     ' record_attendance__c, '
								+    ' Daily_Attendance__c, '
								+	'Grade_Levels__c, '
								+	 'Room__r.name '
     							+	 ' FROM Scheduled_Section__c WHERE Reporting_Period__c = \'' +repPeriodId+'\''
     							+	 ' AND Needs_Publish__c = true'
     							+    ' AND account__c =\'' +cSetup.school.Id +'\'';
     							
			
			if(cSetup.setup.Group_Based__c)
			queryToProcess+=' AND Schedule_Group_Section__c <> null'; //Updated to Section Lookup for US1254
			else{
			queryToProcess+=' AND Schedule_Group_Section__c = null'; //Updated to Section Lookup for US1254
			queryToProcess+=' order by Section__r.Name ';
			}
			System.debug('---------------Query String ---------------------------'+queryToProcess);
		
		return queryToProcess;
	}
		
	   global Database.QueryLocator start(Database.BatchableContext BC){
	   	  system.debug('---------------###ReportingPeriodId---------------------------'+repPeriodId);
	   	  system.debug('---------------###cSetup---------------------------'+cSetup);
	   	  query = BatchUpsertHoldingObj.processQuery(cSetup,repPeriodId );
		  System.debug('---------------Query String ---------------------------'+query);
		  return Database.getQueryLocator(query);
	   }
	
	   global void execute(Database.BatchableContext BC, List<Scheduled_Section__c> scope){	
	   	Scheduler_UpsertHolding upho = new Scheduler_UpsertHolding( cSetup);
	   		System.debug('--------------- Scope  Size ---------------------------'+scope.size());
	   		System.debug('--------------- Mode  ---------------------------'+upho.cSetup.setup.Group_Based__c);
	   		
	     	if(upho.cSetup.setup.Group_Based__c)
	     		upho.upsertHoldingRecordsForScheduledSec(scope);
	     	else
	     		upho.upsertHoldingRecordsForPeriods(scope);
	    }
	
	   global void finish(Database.BatchableContext BC){
	   }

}
public class SharingUtils {
	/*
		Create static final strings representing indicator area types.
		These are the same strings that make up the picklist on Indicator Area
	*/
	public static final String MATH = 'Math';
	public static final String BEH = 'Behavior';
	public static final String ATT = 'Attendance';
	public static final String ELA = 'ELA/Literacy';
	
	/*
	* Author:			Liz Ellis
	* Name:				getSchoolAdminUserIDs
	* Access:			Public Static
	* Description:		Given a list of school IDs, return the user IDs of the school admins associated
						to those schools.
	* Param:			Set<ID> schoolIDs the IDs of the schools to return the school admin user IDs for
	* Return:			Set<ID> the user IDs of the school admins
	*/
	//public static Set<ID> getSchoolAdminUserIDs(Set<ID> schoolIDs){
	//	SharingControls__c profile = SharingControls__c.getInstance('SA');
	//	if(profile!=null){
	//		String profileName = '%'+profile.Profile_Name__c+'%';
	//		Set<ID> userIDs = new Set<ID>();
	//		for(Staff__c staff: [SELECT id, User_Id__c FROM Staff__c 
	//													WHERE Organization__c IN :schoolIDs 
	//													AND Active__c=true
	//													AND Individual__r.User__r.Profile.Name LIKE :profileName]){
	//			userIDs.add(staff.User_Id__c);
	//		}
	//		return userIDs;
	//	}
	//	return null;
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				updateSharingLog
	* Access:			Public Static
	* Description:		Given a list of user IDs, add the users to the next sharing batch run.
						This should be done by adding the users to the text area on the Data Load Log object,
						which is used by the sharing recalculation batch.
	* Param:			Set<ID> userIDs the user IDs that need to be added to the next sharing batch run to be recalculated
	* Return:			boolean indicator of whether or not this log exists already
	*/
	//public static void updateSharingLog(Set<ID> userIDs){
	//	Data_Load_Log__c dll = getLog('Pending');
	//	String userString = dll.Messages__c;
	//	if(userString==null) userString='';
	//	for(ID user: userIDs){
	//		if(user!=null){
	//			if(String.isNotBlank(userString)) userString += ',';
	//			userString += user;
	//		}
	//	}
	//	dll.Messages__c = userString;
	//	upsert dll;
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				kickOffBatch
	* Access:			Public Static
	* Description:		Updates the users whose sharing needs to be recalculated and 
						schedules the sharing recalculation batch to run.
	* Param:			Set<ID> userIDs the users whose sharing needs recalculated
	* Return:			VOID
	*/
	//public static void kickOffBatch(Set<ID> userIDs){
	//	//if(userIDs!=null && userIDs.size()>0){
	//	//	updateSharingLog(userIDs);
	//	//	List<AsyncApexJob> jobs = [SELECT id, MethodName FROM AsyncApexJob WHERE Status='Queued' OR Status='Preparing' OR Status='Processing'];
	//	//	if(!system.isBatch() && !system.isFuture() && jobs.size()<5){
	//	//		if(CYSharingRecalculator.hasBeenScheduled == false){
	//	//			CYSharingRecalculator.hasBeenScheduled = true;
	//	//			CYSharingRecalculator cysr = new CYSharingRecalculator(true);
	//	//			Database.executeBatch(cysr,1);
	//	//		}
	//	//	} else {
	//	//		//schedule batch to run in 5 minutes
	//	//		rescheduleBatch();
	//	//	}
	//	//}
	//}

	//public static void rescheduleBatch(){
	//	try{
	//		CronTrigger cron = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name='Future Sharing Recalculation'];
	//		if(cron!=null)
	//			System.abortJob(cron.id);
	//	} catch(Exception e){}
	//	Schedule_CYSharingRecalculator cys = new Schedule_CYSharingRecalculator(true);
	//	DateTime sched = system.now().addMinutes(5);
	//	String sch = sched.second()+' '+sched.minute()+' '+sched.hour()+' '+sched.day()+' '+sched.month()+' ? '+sched.year();
	//	if(!Test.isRunningTest()){
	//		System.schedule('Future Sharing Recalculation',sch,cys);
	//	}
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				getLog
	* Access:			Public Static
	* Description:		Returns the Data Load Log with type='Sharing' and the given status
	* Param:			String status the status of the Data Load Log we are looking for
	* Return:			Data_Load_Log__c the Data Load Log
	*/
	//public static Data_Load_Log__c getLog(String status){
	//	List<Data_Load_Log__c> logs = getAllLogs(status);
		
	//	Data_Load_Log__c dll;
	//	if(logs == null || logs.size()==0){
	//		return new Data_Load_Log__c(Type__c='Sharing', Status__c=status);
	//	} else {
	//		return logs[0];
	//	}
	//}

	//public static List<Data_Load_Log__c> getAllLogs(String status){
	//	List<Data_Load_Log__c> logs;

	//	try{
	//		logs = [SELECT id, Messages__c FROM Data_Load_Log__c WHERE Type__c='Sharing' AND Status__c=:status FOR UPDATE];
	//	}catch(System.QueryException e){}

	//	return logs;
	//}

	/*
	* Author:			Liz Ellis
	* Name:				getExistingSharing
	* Access:			Public Static
	* Description:		For the given set of users, return all existing student or section sharing rules 
	* Param:			Set<ID> userIDs the users that we need the existing sharing rules for
	* Return:			Map<ID,Map<ID,ID>> maps the existing sharing rule by user->map(section/student id->sharing rule id)
	*/
	//public static Map<ID,Map<ID,ID>> getExistingSharing(Set<ID> userIDs){
	//	List<Student__Share> studentShares = getStudentShares(userIDs);
	//	List<Section__Share> sectionShares = getSectionShares(userIDs);
	//	Map<ID,Map<ID,ID>> existingSharingRules = getUserToSharingRules(studentShares,sectionShares);
	//	return existingSharingRules;
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				getStudentShares
	* Access:			Public Static
	* Description:		Returns the list of existing student sharing rules for the given users.
	* Param:			Set<ID> userIDs the users to return sharing rules for
	* Return:			List<Student__Share> the existing sharing rules
	*/
	//public static List<Student__Share> getStudentShares(Set<ID> userIDs){
	//	return [SELECT Id, UserOrGroupId, ParentId FROM Student__Share WHERE UserOrGroupID IN :userIDs AND RowCause = :Schema.Student__Share.RowCause.CityYear_Core_Member_Student_Access__c];
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				getSectionShares
	* Access:			Public Static
	* Description:		Returns the list of existing section sharing rules for the given users.
	* Param:			Set<ID> userIDs the users to return sharing rules for
	* Return:			List<Section__Share> the existing sharing rules
	*/
	//public static List<Section__Share> getSectionShares(Set<ID> userIDs){
	//	return [SELECT Id, UserOrGroupId, ParentId FROM Section__Share WHERE UserOrGroupID IN :userIDs AND RowCause = :Schema.Student__Share.RowCause.CityYear_Core_Member_Student_Access__c];
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				getUserToSharingRules
	* Access:			Public Static
	* Description:		Given the existing sharing rules, create a map that outlines which users have permissions
						to which students & sections.
	* Param:			List<Student__Share> studentShares the existing student sharing rules
						List<Section__Share> sectionShares the existing section sharing rules
	* Return:			Map<ID,Map<ID,ID>> maps the existing sharing rule by user id->map(section/student id->sharing rule id)
	*/
	//public static Map<ID,Map<ID,ID>> getUserToSharingRules(List<Student__Share> studentShares, List<Section__Share> sectionShares){
	//	Map<ID,Map<ID,ID>> userToSharing = new Map<ID,Map<ID,ID>>();
	//	for(Student__Share sss: studentShares){
	//		Map<ID,ID> temp = new Map<ID,ID>();
	//		if(userToSharing.containsKey(sss.UserOrGroupID))
	//			temp = userToSharing.get(sss.UserOrGroupID);
	//		temp.put(sss.ParentId,sss.Id);
	//		userToSharing.put(sss.UserOrGroupID,temp);
	//	}
	//	for(Section__Share sss: sectionShares){
	//		Map<ID,ID> temp = new Map<ID,ID>();
	//		if(userToSharing.containsKey(sss.UserOrGroupID))
	//			temp = userToSharing.get(sss.UserOrGroupID);
	//		temp.put(sss.ParentId,sss.Id);
	//		userToSharing.put(sss.UserOrGroupID,temp);
	//	}
	//	return userToSharing;
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				createSectionShare
	* Access:			Public Static
	* Description:		Create a new section sharing rule for the given user and section.
	* Param:			ID userID the user the section should be shared with
						ID sectionID the section to be shared
	* Return:			Section__Share the new sharing rule
	*/
	//public static Section__Share createSectionShare(ID userID, ID sectionID){
	//	return new Section__Share(ParentId = sectionID,
	//											UserOrGroupID = userID,
	//											AccessLevel = 'Edit',
	//											RowCause = Schema.Section__Share.RowCause.CityYear_Core_Member_Student_Access__c);
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				createStudentShare
	* Access:			Public Static
	* Description:		Create a new student sharing rule for the given user and student.
	* Param:			ID userID the user the student should be shared with
						ID studentID the student to be shared
	* Return:			Student__Share the new sharing rule
	*/
	//public static Student__Share createStudentShare(ID userID, ID studentID){
	//	return new Student__Share(ParentId = studentID,  // create the "share" record for the student
	//											UserOrGroupID = userID,
	//											AccessLevel = 'Edit',
	//											RowCause = Schema.Student__Share.RowCause.CityYear_Core_Member_Student_Access__c);
	//}
	
	/*
	* Author:			Liz Ellis
	* Name:				deleteRemainingRules
	* Access:			Public
	* Description:		Given maps of obsolete sharing rules, delete them
	* Param:			Map<ID,Map<ID,Student__Share>> userToSharing - obsolete student & section sharing rules
	*/
	//public static void deleteRemainingRules(Set<ID> toDelete){
	//	List<Student__Share> studshares = [SELECT id FROM Student__Share WHERE id IN :toDelete];
	//	List<Section__Share> sectshares = [SELECT id FROM Section__Share WHERE id IN :toDelete];
		
	//	delete studshares;
	//	delete sectshares;
	//}
	
	//public static Set<ID> getIDsToDelete(Map<ID,Map<ID,ID>> userToSharing){
	//	Set<ID> toDelete = new Set<ID>();
	//	for(Map<ID,ID> mapVals: userToSharing.values()){
	//		if(mapVals!=null) toDelete.addAll(mapVals.values());
	//	}
	//	return toDelete;
	//}
	
	/*
	*	Author:			Liz Ellis
	*	Name:			addToStudentCount
	*	Access:			public static
	*	Description:	Given a set of ids for the Indicator Area/Student records, recalculate the values for the Student's specific fields.
						EE 9/9 - removed as part of CY-specific code
	*	Param:			List<Student_Section__c> studentSections - list to check sections for
	*	Return:			VOID
	*/
	public static void addToStudentCount(Set<ID> iasIDs, boolean toAdd){
		List<Indicator_Area_Student__c> triggerList = [SELECT id, Student__c, Indicator_Area__r.Indicator_Area_Type__c FROM Indicator_Area_Student__c WHERE id IN :iasIDs];
		
		Set<ID> studentIDs = new Set<ID>();
		for(Indicator_Area_Student__c record: triggerList){
			studentIDs.add(record.Student__c);
		}
		Map<ID, Student__c> students = new Map<ID,Student__c>([SELECT id, Attendance__c, Behavior__c, ELA_Literacy__c, Math__c
					FROM Student__c
					WHERE id IN :studentIDs]);
		
		//if no students in map, don't do anything
		if(students.size()>0){
			for(Indicator_Area_Student__c ias: triggerList){
				String iaType = ias.Indicator_Area__r.Indicator_Area_Type__c;
				//if student not in map, don't do anything
				if(students.containsKey(ias.Student__c)){
					if(toAdd){
						if(iaType==MATH) students.get(ias.Student__c).Math__c++;
						else if(iaType==BEH) students.get(ias.Student__c).Behavior__c++;
						else if(iaType==ATT) students.get(ias.Student__c).Attendance__c++;
						else if(iaType==ELA) students.get(ias.Student__c).ELA_Literacy__c++;
					}
					else{
						if(iaType==MATH) students.get(ias.Student__c).Math__c--;
						else if(iaType==BEH) students.get(ias.Student__c).Behavior__c--;
						else if(iaType==ATT) students.get(ias.Student__c).Attendance__c--;
						else if(iaType==ELA) students.get(ias.Student__c).ELA_Literacy__c--;
					}
				}
			}
			system.debug('~~~~~ students '+students);
			update students.values();
		}
	}
}
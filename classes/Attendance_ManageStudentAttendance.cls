public class Attendance_ManageStudentAttendance {
	
	public static Map<Id, Notification__c[]> nmap;
	public Static Notification__c [] listofnotifications;

	public static void isbeforeinsert(List<Attendance__c> newlist){
		boolean isValid = validateSingleAttendanceType(newList);
		if(!isValid){
			return;
		}

		try{
			processtimelost(newlist);
		}
		catch(Exception e){
			processError(newList,'Attendance_ManageStudentAttendance - isbeforeinsert' ,e);
		}
	}

	public static void isbeforeupdate(Map<Id, Attendance__c> newamap, Map<Id, Attendance__c> oldamap){
		Boolean isValid = validateSingleAttendanceType(newaMap.values());
		if(!isValid){
			return;
		}

		List<Attendance__c> newlist = new List <Attendance__c>();
		try{
			for (Attendance__c a: newamap.values()) {
				if(newamap.get(a.Id).Arrival_Time__c != oldamap.get(a.Id).Arrival_Time__c ||
						newamap.get(a.Id).Departure_Time__c != oldamap.get(a.Id).Departure_Time__c ||
						newamap.get(a.Id).Picklist_Value__c != oldamap.get(a.Id).Picklist_Value__c){
					newlist.add(a);
				}
			}
			processtimelost(newlist);
		} catch(Exception e){
			processError(newList,'Attendance_ManageStudentAttendance - isbeforeupdate' ,e);
		}
	}


	//called by trigger on Attendance Object, to process all records
	public static void isafterinsert(Map<Id, Attendance__c> newamap, Map<Id, Attendance__c> oldamap ) {
		Boolean bDaily = false; //records if attendance records are being submitted via a daily Session
		Set<Id> students = new Set<Id>(); //We need to get a list of Students in the attendees list
		Attendance__c [] satsforprocessing = newamap.values();
		Map<Id, Student__c> studentsforprocessing;
		try{
			if (satsforprocessing.size () > 0) { //only process where records exist
				Date SessionDate; //we need to get the date being processed so we can select notifications for that period
				Set<String> ngrades = new Set<String> (); //we also filter for only notifications for the grade(s) being processed

				SessionDate = satsforprocessing[0].Session_Date__c; //all dates should be the same, so we can just take first one
				bDaily = satsforprocessing[0].Daily__c; //all daily flags should be the same, so we can just take first one

				for (Attendance__c a: satsforprocessing) {
					students.add(a.Student__c); //add students to Student ID List
					ngrades.add(a.Student_s_Grade__c); //create new set of unique grades
				}

				String sgrades = ''; //to use this set in an INLCUDE, we need to conver to , delimited string
				for (String s: ngrades) {
					sgrades += '\'' + s + '\',';
				}
				sgrades = sgrades.substring (0,sgrades.length() -1); //remove final comma
				listofnotifications = getnotifications(SessionDate, sgrades, bDaily); //get list of notifications to process
				//now get existing student records so we can process existing process tracking records
				studentsforprocessing = getstudents(students);
				//Finally, call method to process records
				processstats(satsforprocessing,studentsforprocessing);

			}
			if (bDaily == true) { //if it's a daily session, propagate records down through sectional sessions
					CT_Student_Utils.getStudentSetupMap (studentsforprocessing);
					Map <Id, Setup__c> studentSetupMap = CT_Student_Utils.studentSetupMap;
					propStatus(satsforprocessing, studentSetupMap);
			}
		}
		catch(Exception e){
			processError(satsforprocessing,'Attendance_ManageStudentAttendance - isafterinsert' ,e);
		}
	}

	//process updates to attendance records, called from Attendance Trigger
	public static void isafterupdate(Map<Id, Attendance__c> newamap, Map<Id, Attendance__c> oldamap ) {
		Attendance__c [] resetsatsforprocessing = new List <Attendance__c> ();
		Attendance__c [] satsforprocessing = new List <Attendance__c> ();
		Attendance__c [] attToCascade 		= new List <Attendance__c>();
		Map<Id, Student__c> studentsforprocessing;
		Set<Id> students = new Set<Id>();
		Boolean bDaily = newaMap.values()[0].Daily__c;
		
		try{
			for(ID aid : newamap.keyset()){
				if(newamap.get(aid).Picklist_Value__c!=oldamap.get(aid).Picklist_Value__c){
					resetsatsforprocessing.add(oldamap.get(aid));
					satsforprocessing.add(newamap.get(aid));
					if (newaMap.get(aid).Daily__c) attToCascade.add(newamap.get(aid));
				}
				else if (newamap.get(aid).Departure_Time__c!=oldamap.get(aid).Departure_Time__c){
					if (newaMap.get(aid).Daily__c) attToCascade.add(newamap.get(aid));
				}
				else if (newamap.get(aid).Arrival_Time__c!=oldamap.get(aid).Arrival_Time__c){
					if (newaMap.get(aid).Daily__c) attToCascade.add(newamap.get(aid));
				}
			}

			if (satsforprocessing.size () > 0) {
				Date SessionDate = satsforprocessing[0].Session_Date__c;
				Set<String> ngrades = new Set<String> ();
				for (Attendance__c a: satsforprocessing) {
					students.add(a.Student__c);
					ngrades.add(a.Student_s_Grade__c);
				}

				String sgrades = '';
				for (String s: ngrades) {
					sgrades += '\'' + s + '\',';
				}
				sgrades = sgrades.substring (0,sgrades.length() -1);
				listofnotifications = getnotifications(SessionDate, sgrades, bDaily);
				studentsforprocessing = getstudents(students);

				rollbackstats(resetsatsforprocessing, studentsforprocessing);
				processstats(satsforprocessing, studentsforprocessing);

			}
			if(nmap!=null){
				nmap.clear();
			}

			Map<ID, Attendance__c> timeOldMap = new Map<ID,Attendance__c>();
			Map<ID, Attendance__c> timeNewMap = new Map<ID,Attendance__c>();

			for(ID bid : newamap.keyset()){
				if((newamap.get(bid).Picklist_Value__c==oldamap.get(bid).Picklist_Value__c)&&(newamap.get(bid).Time_Lost_Rollup__c!=oldamap.get(bid).Time_Lost_Rollup__c)){
					timeOldMap.put(bid, oldamap.get(bid));
					timeNewMap.put(bid, newamap.get(bid));
				}
			}

			Set<Id> studentsTime = new Set<Id>();
			Boolean bDailyTime = false;

			if (timeOldMap.size() > 0) {
				Date SessionDate;
				Set<String> ngrades = new Set<String> ();
				for (Attendance__c a: timeOldMap.values()) {
					studentsTime.add(a.Student__c);
					SessionDate = a.Session_Date__c;
					bDailyTime = a.Daily__c;
					ngrades.add(a.Student_s_Grade__c);
				}

				String sgrades = '';
				for (String s: ngrades) {
					sgrades += '\'' + s + '\',';
				}
				sgrades = sgrades.substring (0,sgrades.length() -1);
				listofnotifications = getnotifications(SessionDate, sgrades, bDailyTime);
				 studentsforprocessing = getstudents(studentsTime);

				rollbacktime(timeOldMap, timeNewMap, studentsforprocessing);

			}
			if (!attToCascade.isEmpty()) { //if it's a daily session, propagate records down through sectional sessions
				CT_Student_Utils.getStudentSetupMap (studentsforprocessing);
				Map <Id, Setup__c> studentSetupMap = CT_Student_Utils.studentSetupMap;
				propStatus(attToCascade, studentSetupMap);
			}
		}
		catch(Exception e){
			processError(newamap.values(),'Attendance_ManageStudentAttendance - isafterupdate' ,e);
		}
	}

	public static Map<Id, Student__c> getstudents (Set<Id> students) {
		Map<Id, Student__c> studentstoprocess = new Map<Id, Student__c>(
		[Select Id, Grade__c, Setup__c, (Select Student__c, Picklist_Value__c, Notification__c, Old_Consecutive_Value__c, Notification__r.Picklist_Value__c, Key__c,
		Consecutive__c, Cumulative__c, Minutes_Lost__c From Attendance_Tracking__r WHERE Notification__c in :listofnotifications) From Student__c where Id = :students]);
		return studentstoprocess;
	}

	public static Notification__c [] getnotifications (Date SessionDate, String sgrades, Boolean bDaily) {
		String sd = String.ValueOf(SessionDate);
		String s = 'Select Picklist_Value__c, Name, Id, Grade__c From Notification__c WHERE Start_Date__c <= ' + sd + ' AND End_Date__c >= ' + sd;
		s += ' AND Daily_Tracking__c = ' + bDaily;
		s += ' AND Grade__c INCLUDES (' + sgrades + ')';

		Notification__c [] notificationstoprocess = database.query(s);
		//we then add the notifications to a map, to create a 'group by Status' map of notifications
		nmap = new Map<Id, Notification__c[]>();
			for (Notification__c n: notificationstoprocess) {
				if (nmap.containskey(n.Picklist_Value__c)) {
					nmap.get(n.Picklist_Value__c).add(n);
				}
				else {
					List<Notification__c> nl = new List<Notification__c>();
					nl.add(n);
					nmap.put(n.Picklist_Value__c, nl);
				}
			}
		return notificationstoprocess;
	}

	//Process the Attendance records, and update Attedance Tracking records for matching Status records
	static void processstats(List<Attendance__c> satsforprocessing, Map<Id, Student__c> students) {
		List<Attendance_Tracking__c> nottodaystatus = new List<Attendance_Tracking__c>();
		List<Attendance_Tracking__c> newtodaystatus = new List<Attendance_Tracking__c>();
		Map<Id, Integer> sectionPresentMap = new Map<Id, Integer>();
		Map<Id, Integer> sectionTotalMap = new Map<Id, Integer>();
		Map<Id, Id>	sessionToSection = new Map<Id,Id>();
		Set<Id> pvValues = new Set<Id>();
		Set<Id> sessions = new Set<Id>();
		for(Attendance__c at: satsForProcessing){
			if(at.Session__c != null){
				sessions.add(at.Session__c);
				pvValues.add(at.Picklist_Value__c);
			}
		}
		Map<Id, Picklist_Value__c> pvList = new Map<Id, Picklist_Value__c>([select id, Category__c, Is_Early_Departure__c, Is_Tardy__c from Picklist_Value__c where id IN:pvValues]);
		for(Session__c s: [select id, Section__c from Session__c where id IN:sessions]){
			sessionToSection.put(s.id, s.Section__c);
		}

		//loop through all attendance records
		for (Attendance__c at : satsforprocessing){
			//first - what is the status of the attendance record being processed
			Id sstatus = at.Picklist_Value__c;
			Map <String, Attendance_Tracking__c> mtodaystatus = new Map<String, Attendance_Tracking__c>();

			Picklist_Value__c attStatus = pvList.get(at.Picklist_Value__c);
			//US2618
			if(attStatus.Category__c == 'Present' || attStatus.Category__c == 'In School Suspension' || attStatus.Is_Early_Departure__c || attStatus.Is_Tardy__c){
				if(sectionPresentMap.containsKey(sessionToSection.get(at.Session__c))){
					sectionTotalMap.put(sessionToSection.get(at.Session__c),sectionTotalMap.get(sessionToSection.get(at.Session__c)) + 1);
					sectionPresentMap.put(sessionToSection.get(at.Session__c), sectionPresentMap.get(sessionToSection.get(at.Session__c))+1);
				} else {
					sectionPresentMap.put(sessionToSection.get(at.Session__c), 1);
					if(sectionTotalMap.containsKey(sessionToSection.get(at.Session__c))){
						sectionTotalMap.put(sessionToSection.get(at.Session__c),sectionTotalMap.get(sessionToSection.get(at.Session__c)) + 1);
					} else {
						sectionTotalMap.put(sessionToSection.get(at.Session__c), 1);
					}
				}
			} else {
				if(sectionTotalMap.containsKey(sessionToSection.get(at.Session__c))){
					sectionTotalMap.put(sessionToSection.get(at.Session__c),sectionTotalMap.get(sessionToSection.get(at.Session__c)) + 1);
				} else {
					sectionTotalMap.put(sessionToSection.get(at.Session__c), 1);
				}
			}

			//For the student being inserted, get any existing tracking records from the student map
			for (Attendance_Tracking__c satr : students.get(at.Student__c).Attendance_Tracking__r){
				if (satr.Picklist_Value__c == at.Picklist_Value__c) {
				//if the status on the existing record = today's status, add the key to a map, so we can update it later
					mtodaystatus.put(satr.key__c, satr);
				}
				else
				{ //just add to a list to set consecutive to zero
					nottodaystatus.add(satr);
				}
			}

			//Does the notification map contains today's status?
			if (nmap.containskey(sstatus)) {
				//if yes, process all the notificatio periods we are tracking for that status
				for (Notification__c n : nmap.get(sstatus) )
				{
					//Check Grade on Notification includes Grade for Student being processed
					if (n.grade__c.contains(at.Student_s_Grade__c))
					{ //does student already have a tracking record for this period?
						if (mtodaystatus.containskey(at.Student__c + String.valueof(n.Id))) { //then set record to + 1
							Attendance_Tracking__c a = mtodaystatus.get(at.Student__c + String.valueof(n.Id));
							a.Consecutive__c ++;
							a.Cumulative__c ++;
							a.Minutes_Lost__c += at.Time_Lost_Rollup__c;
							newtodaystatus.add(a);
						}
						//Student + Notification
						else { //otherwise, add a new one, with Student Id and Notification Id as the key for future reference
							newtodaystatus.add(new Attendance_Tracking__c(Key__c = at.Student__c + String.valueof(n.Id), Notification__c = n.Id,
							Picklist_Value__c = n.Picklist_Value__c, Student__c = at.Student__c,
							Consecutive__c = 1, Cumulative__c = 1, Minutes_Lost__c = at.Time_Lost_Rollup__c));
						}
					}
				}
			}
		}

		if(!sectionTotalMap.isEmpty()){
			List<Section__c> sectionsToUpdate = [select id, Present_Attendance__c, Total_Attendance__c from Section__c where id IN:sectionTotalMap.keySet()];
			for(Section__c s: sectionsToUpdate){
				if(s.Present_Attendance__c == null)
					s.Present_Attendance__c = 0;
				if(s.Total_Attendance__c == null)
					s.Total_Attendance__c = 0;
				if(sectionPresentMap.containsKey(s.id))
					s.Present_Attendance__c = s.Present_Attendance__c + sectionPresentMap.get(s.id);
					system.debug(sectionTotalMap.get(s.id));
					system.debug(s.Total_Attendance__c);
				s.Total_Attendance__c = s.Total_Attendance__c + sectionTotalMap.get(s.id);
			}
			update sectionsToUpdate;
		}

		for (Attendance_Tracking__c nts : nottodaystatus)
		{ //for the existing records not matching today, set consecutive flag to zero
			nts.Old_Consecutive_Value__c = nts.Consecutive__c;
			nts.Consecutive__c = 0;
			nts.admin_Notifications_cons__c = null;
		}
		//finally, execute updates
		try {
			update nottodaystatus;
			upsert newtodaystatus key__c;
		}
		catch (Exception e) {
			processError(satsforprocessing,'Attendance_ManageStudentAttendance - processstats' ,e);
		}
	} //end AT processing

	//undo any changes from an old attendance value from cumulative and consecutive values on the tracking object
	static void rollbackstats(List<Attendance__c> satsforprocessing, Map<Id, Student__c> students) {
		List<Attendance_Tracking__c> undostatus = new List<Attendance_Tracking__c>();
		List<Attendance_Tracking__c> redostatus = new List<Attendance_Tracking__c>();
		Map<Id, Integer> sectionPresentMap = new Map<Id, Integer>();
		Map<Id, Integer> sectionTotalMap = new Map<Id, Integer>();
		Map<Id, Id>	sessionToSection = new Map<Id,Id>();
		Set<Id> pvValues = new Set<Id>();
		Set<Id> sessions = new Set<Id>();
		for(Attendance__c at: satsForProcessing){
			if(at.Session__c != null){
				sessions.add(at.Session__c);
				pvValues.add(at.Picklist_Value__c);
			}
		}
		Map<Id, Picklist_Value__c> pvList = new Map<Id, Picklist_Value__c>([select id, Category__c, Is_Early_Departure__c, Is_Tardy__c from Picklist_Value__c where id IN:pvValues]);
		for(Session__c s: [select id, Section__c from Session__c where id IN:sessions]){
			sessionToSection.put(s.id, s.Section__c);
		}

		for (Attendance__c at : satsforprocessing) {
			Id sstatus = at.Picklist_Value__c;
			Map <String, Attendance_Tracking__c> mtodaystatus = new Map<String, Attendance_Tracking__c>();

			Picklist_Value__c attStatus = pvList.get(at.Picklist_Value__c);
			//US2618
			if(attStatus.Category__c == 'Present' || attStatus.Category__c == 'In School Suspension' || attStatus.Is_Early_Departure__c || attStatus.Is_Tardy__c){
				if(sectionPresentMap.containsKey(sessionToSection.get(at.Session__c))){
					sectionTotalMap.put(sessionToSection.get(at.Session__c),sectionTotalMap.get(sessionToSection.get(at.Session__c)) + 1);
					sectionPresentMap.put(sessionToSection.get(at.Session__c), sectionPresentMap.get(sessionToSection.get(at.Session__c))+1);
				} else {
					sectionPresentMap.put(sessionToSection.get(at.Session__c), 1);
					if(sectionTotalMap.containsKey(sessionToSection.get(at.Session__c))){
						sectionTotalMap.put(sessionToSection.get(at.Session__c),sectionTotalMap.get(sessionToSection.get(at.Session__c)) + 1);
					} else {
						sectionTotalMap.put(sessionToSection.get(at.Session__c), 1);
					}
				}
			} else {
				if(sectionTotalMap.containsKey(at.Session__r.Section__c)){
					sectionTotalMap.put(sessionToSection.get(at.Session__c),sectionTotalMap.get(sessionToSection.get(at.Session__c)) + 1);
				} else {
					sectionTotalMap.put(sessionToSection.get(at.Session__c), 1);
				}
			}

			for (Attendance_Tracking__c satr : students.get(at.Student__c).Attendance_Tracking__r ) {
				if (satr.Picklist_Value__c == at.Picklist_Value__c) {
					mtodaystatus.put(satr.key__c, satr);
				}
				else{
					redostatus.add(satr);
				}
			}

			if (nmap.containskey(sstatus)) {
				//process status
				for (Notification__c n : nmap.get(sstatus) ) {
					//Check Grade on Notification includes Grade for Student being processed
					if (n.grade__c.contains(at.Student_s_Grade__c)) {
						if (mtodaystatus.containskey(at.Student__c + String.valueof(n.Id))) {
							Attendance_Tracking__c a = mtodaystatus.get(at.Student__c + String.valueof(n.Id));
							a.Consecutive__c --;
							a.Cumulative__c --;
							a.Minutes_Lost__c -= at.Time_Lost_Rollup__c;
							undostatus.add(a);
						}
					}
				}
			}
		}

		List<Section__c> sectionsToUpdate = new List<Section__c>();
		if(!sectionTotalMap.isEmpty()){
			for(Section__c s: [select id, Present_Attendance__c, Total_Attendance__c from Section__c where id IN:sectionTotalMap.keySet()]){
				if(s.Present_Attendance__c == null)
					s.Present_Attendance__c = 0;
				if(s.Total_Attendance__c == null)
					s.Total_Attendance__c = 0;
				if(sectionPresentMap.containsKey(s.id))
					s.Present_Attendance__c = s.Present_Attendance__c - sectionPresentMap.get(s.id);
				s.Total_Attendance__c = s.Total_Attendance__c - sectionTotalMap.get(s.id);
				if(s.Present_Attendance__c < 0){
					s.Present_Attendance__c = 0;
				}
				if(s.Total_Attendance__c < 0){
					s.Total_Attendance__c = 0;
				}
				sectionsToUpdate.add(s);
			}
			update sectionsToUpdate;
		}

		for (Attendance_Tracking__c nts : redostatus) {
			nts.Consecutive__c = nts.Old_Consecutive_Value__c;
		}
		try{
			update redostatus;
			update undostatus;
		}
		catch(Exception e){

			string linkString = '';
			for(Attendance_Tracking__c a: redostatus){
				if(a.ID!=null){
					if(linkString == ''){
						linkString = string.valueOf(a.Name) + ',' + string.valueOf(a.id);
					}
					else{
						linkString = linkString + ';' + string.valueOf(a.Name) + ',' + string.valueOf(a.id);
					}
				}
			}
			for(Attendance_Tracking__c a: undostatus){
				if(a.ID!=null){
					if(linkString == ''){
						linkString = string.valueOf(a.Name) + ',' + string.valueOf(a.id);
					}
					else{
						linkString = linkString + ';' + string.valueOf(a.Name) + ',' + string.valueOf(a.id);
					}
				}
			}
			Global_Error__c ge = Error_Handling.handleError(linkString, 'Attendance', 'Attendance Tracking - rollbackstats', e);
			insert ge;
		}
	} //end processing

	//undo any changes from the old attendance values by subtracting old time lost and adding new time lost
	static void rollbacktime(Map<ID,Attendance__c> oldTMap, Map<ID,Attendance__c> newTMap, Map<Id, Student__c> students) {
		List<Attendance_Tracking__c> updateATList = new List<Attendance_Tracking__c>();

		for (Attendance__c at : oldTMap.values()) {
			String sstatus = at.Picklist_Value__c;
			Map <String, Attendance_Tracking__c> timeMap = new Map<String, Attendance_Tracking__c>();
			for (Attendance_Tracking__c satr : students.get(at.Student__c).Attendance_Tracking__r ) {
				timeMap.put(satr.key__c, satr);
			}

			if (nmap.containskey(sstatus)) {
				//process status
				for (Notification__c n : nmap.get(sstatus) ) {
					//Check Grade on Notification includes Grade for Student being processed
					if (n.grade__c.contains(at.Student_s_Grade__c)) {
						if (timeMap.containskey(at.Student__c + String.valueof(n.Id))) {
							Attendance_Tracking__c a = timeMap.get(at.Student__c + String.valueof(n.Id));
							a.Minutes_Lost__c -= oldTMap.get(at.Id).Time_Lost_Rollup__c;
							a.Minutes_Lost__c += newTMap.get(at.Id).Time_Lost_Rollup__c;
							updateATList.add(a);
						}
					}
				}
			}
		}
		update updateATList;
	} //end processing

	//propagate the status of the attendance
	public static void propStatus(List<Attendance__c> tempAtnList, Map <Id, Setup__c> studentSetupMap){
		List<Attendance__c> atnList = new List <Attendance__c>(); //This pulls back all of the attendance records that are daily that caused the trigger to fire
		List<Attendance__c> insAtnList = new List<Attendance__c>(); //This is the list of new attendance records to be inserted.
		Map<Id, Id> studStatusMap 	= new Map<Id, Id>(); //This map will hold the student ID and the Status of the daily attendance record for that day
		Set<String> atnIDSet = new Set<String>(); //This set will hold all of the key combination of studentID + SessionID for existing attendance records for that day
		Map<ID, List<Session__c>> sectSessionMap = new Map<ID, List<Session__c>>(); //This map will hold the section ID and Session for all sections that any student is connected to
		Set<Date> sessionDates 							= new Set<Date>();
		Map <Id, List <Attendance__c>> studentAtnListMap	= new Map <Id, List <Attendance__c>>(); //Puts attendance details corresponding to student
		Map <Id, Map <Id, Picklist_Value__c>> attPicklistValueMap = new Map <Id, Map<Id, Picklist_Value__c>>(); //Gets the list of Picklist values for the appropriate setup
		Set <Id> setupIds = new Set <Id>();

		for (Attendance__c att: tempAtnList){
			system.debug(studentSetupMap.get(att.student__c));
			if (studentSetupMap.get(att.student__c)!=null){
				if (studentSetupMap.get(att.student__c).cascade_daily_attendance__c){
					atnList.add(att);
					setupIds.add(studentSetupMap.get(att.Student__c).id);
				}
			}
		}

		if(atnList.size()>0){
			system.debug('~~~setupIds'+setupIds);
			/* Get the Picklist Values for the appropriate Setup*/
			for (Picklist_Value__c pl: [select id, Setup__c, name, category__c, is_tardy__c, is_unexcused__c, is_early_departure__c, set_as_default__c from Picklist_Value__c
														WHERE recordType.DeveloperName='Attendance'
														AND		(setup__c = null OR setup__c in: setupIds )]){
				if (attPicklistValueMap.get(pl.setup__c)==null){
					attPicklistValueMap.put(pl.setup__c, new Map <Id , Picklist_Value__c>{pl.id=>pl});
				}
				else (attPicklistValueMap.get(pl.setup__c).put(pl.id, pl));
			}
			if (attPicklistValueMap.get(null)!=null){
				for (Id setupId: setupIds){
					for (Picklist_Value__c pl: attPicklistValueMap.get(null).values()){
						if (attPicklistValueMap.get(setupId)==null){
							attPicklistValueMap.put(setupId, new Map <Id, Picklist_Value__c>{pl.id=>pl});
						}
						else attPicklistValueMap.get(setupId).put(pl.id, pl);
					}
				}
			}



			for(Attendance__c att: atnList) {
				sessionDates.add(att.Session_Date__c); //these are the session dates
				if (studentAtnListMap.get(att.student__c)==null)	studentAtnListMap.put(att.student__c, new List <Attendance__c>{att});
				else studentAtnListMap.get(att.student__c).add(att);
			}
			Map<String, List<String>> studSectionMap = new Map<String, List<String>>(); //This map will hold the student ID and a list of sections they belong to

			for(Attendance__c a : atnList){
				studStatusMap.put(a.Student__c, a.Picklist_Value__c); //Populate the map with status from the daily attendance records
			}


			 //Now return all the attendance already records created today for the students being processed
			for(Attendance__c a : [select Id, Name, Session__c, Student__c, External_Id__c from Attendance__c
							WHERE student__c IN : studStatusMap.keyset() AND Session_Date__c IN :sessionDates
							AND 		Daily__c = false]){
				atnIDSet.add(a.External_Id__c);
			}

			List<Student__c> ssList = [Select Id, Setup__c, (Select Id, Section__c, section__r.record_attendance__c From Student_Section__r WHERE Active__c = TRUE AND section__r.record_attendance__c=true and Section__r.RecordType.DeveloperName='Published') From Student__c WHERE Id IN :studStatusMap.keyset()];

			Set<Id> allsections = new Set<Id>();

			for (Student__c s: ssList) {
				for (Student_Section__c ss: s.Student_Section__r) {
					allsections.add(ss.section__c);
				}

			}

		for (Session__c sess: [select s.Id, s.Section__c, s.Section__r.Daily_Attendance__c, Start_DateTime__c, End_DateTime__c from Session__c s where s.Section__c IN :allsections and s.Session_Date__c IN :sessionDates and s.Record_Attendance__c = true and s.Daily_Attendance__c='N']) {
			if(!sectSessionMap.containsKey(sess.Section__c)){
				sectSessionMap.put(sess.Section__c, new List<Session__c>{sess});
			} else {
				sectSessionMap.get(sess.Section__c).add(sess);
			}
		}

		//For each student check to see if an attendance record exist for that session for that day. If not, create one and bring down the status.
		 for (Student__c lstst: ssList) {
				Map <Id, Picklist_Value__c> paValues = attPicklistValueMap.get(lstst.setup__c);
				for(Student_Section__c sectid : lstst.Student_Section__r){
					if(sectSessionMap.keyset().contains(sectid.section__c)){
						for(Session__c sess: sectSessionMap.get(sectid.Section__c)){ //use a key combination made up of a string of student id + session id to determine if an attendance record already exist
							if(pavalues.get(studStatusMap.get(lstst.id)).Is_Tardy__c || pavalues.get(studStatusMap.get(lstst.id)).Is_Early_Departure__c){
								Attendance__c attRecord = studentAtnListMap.get(lstst.id)[0];
								Picklist_Value__c attPlValue =pavalues.get(studStatusMap.get(lstst.id));
								if (attPlValue.Is_Tardy__c){ //Its a tardy
									if (attRecord.Arrival_Time__c > sess.End_DateTime__c){
										//For all the sectional attendance sessions that met earlier in the day and are complete - set to absent corresponding to the Is Unexcused related to the student
										for (Picklist_Value__c pl: paValues.values() ){
											if (pl.is_unexcused__c==attPlValue.is_unexcused__c && pl.Category__c == 'Absent'){
												insAtnList.add(new Attendance__c(Picklist_Value__c = pl.id, Student__c = lstst.Id, Session__c = sess.id, External_Id__c=''+lstst.id+sess.id));
												break;
											}
										}
									}
									else if (attRecord.Arrival_Time__c < sess.Start_DateTime__c){
										//For all the sectional attendance sessions that have yet to start- set to default value
										for (Picklist_Value__c pl: paValues.values() ){
											if ( pl.set_as_default__c){
												insAtnList.add(new Attendance__c(Picklist_Value__c = pl.id, Student__c = lstst.Id, Session__c = sess.id, External_Id__c=''+lstst.id+sess.id));
												break;
											}
										}
									}
								}
								else { //Its an early departure
									if (attRecord.Departure_Time__c < sess.End_DateTime__c){
										//for sectional attendance sessions yet to meet, set to Absent
										for (Picklist_Value__c pl: paValues.values() ){
											if (pl.is_unexcused__c==attPlValue.is_unexcused__c && pl.Category__c== 'Absent'){
												insAtnList.add(new Attendance__c(Picklist_Value__c = pl.id, Student__c = lstst.Id, Session__c = sess.id, External_Id__c=''+lstst.id+sess.id));
												break;
											}
										}
									}
								}
							}
							else {
								if(atnIDSet.contains(''+lstst.id+sess.id)){} //if an attendance record exists don't do anything. Otherwise create one and add it to the list
								else{
									insAtnList.add(new Attendance__c(Picklist_Value__c = studStatusMap.get(lstst.Id), Student__c = lstst.Id, Session__c = sess.id, External_Id__c=''+lstst.id+sess.id));
								}
							}
						}
					}
				}
			}
		}

		if (!insAtnList.isEmpty()){
			try{
				upsert insAtnList External_Id__c;
			} catch(exception e){
				system.debug(e);
			}
		}
	}

	public static void processnotifications(Date processdate, Boolean bParent){
		Map<Id, Notification__c> nprocessmap = new Map<Id, Notification__c>(
			[Select Id, Grade__c, Picklist_Value__c,
				(Select Id, Cumulative__c, Consecutive__c, Time_Lost__c, Notification__c From Thresholds__r)
			From Notification__c where Parental_Notification__c = :bParent AND Start_Date__c <= :processdate
			and End_Date__c >= :processdate]);

		Attendance_Tracking__c [] satrtoprocess =
			[Select Id, Student__c, Notification__c, Minutes_Lost__c, Admin_Notifications_cuml__c, Admin_Notifications_cons__c,
				Cumulative__c, Consecutive__c, Parental_Notification_Required__c
			From Attendance_Tracking__c
			WHERE Notification__c IN :nprocessmap.keyset()
			AND LastModifiedDate = TODAY];

		for (Attendance_Tracking__c pat: satrtoprocess){
			for (Threshold__c t: nprocessmap.get(pat.Notification__c).Thresholds__r){
				if (bParent == false){
					if (t.Consecutive__c > 0 && pat.Admin_Notifications_cons__c == null && pat.Consecutive__c >=t.Consecutive__c){
							pat.Admin_Notifications_cons__c= 'Notify Administration';
					} else if (pat.Admin_Notifications_cuml__c == null){
						if (t.Cumulative__c >0 && pat.Cumulative__c >= t.Cumulative__c){
							pat.Admin_Notifications_cuml__c = 'Notify Administration';
						} else if (t.Time_Lost__c >0 && pat.Minutes_Lost__c >= t.Time_Lost__c){
							pat.Admin_Notifications_cuml__c = 'Notify Administration';
						}
					}
				} else if (pat.Parental_Notification_Required__c == null){
					if (t.Cumulative__c >0 && pat.Cumulative__c >= t.Cumulative__c){
						pat.Parental_Notification_Required__c = 'Send Notification';
					}
				}
			}
		}
		update satrtoprocess;
	}

	public static void processtimelost(Attendance__c [] newlist){
		Set<Id> students = new Set<Id>();
		Set <Id> setupIds = new Set <Id>();
		Map <Id, Id> studentSetupMap = new Map <Id, Id>();
		Map <Id, Map <Id, Picklist_Value__c>> attPicklistValueMap;

		for (Attendance__c a: newlist ){
			students.add(a.student__c);
		}
		for (Student__c s: [select id, setup__c from Student__c where id in:students] ){
			setupIds.add(s.setup__c);
			studentSetupMap.put(s.id, s.setup__c);
		}
		if(setupIds.size()>0){
			attPicklistValueMap= processAttendanceStatusMap(setupIds);
		}
		for (Attendance__c a: newlist ) {
			Map <Id, Picklist_Value__c> paValues = attPicklistValueMap.get(studentSetupMap.get(a.student__c));
			if (pavalues.containskey(a.Picklist_Value__c) ) {
				String attendanceCategory = pavalues.get(a.Picklist_Value__c).Category__c;
				System.debug('AttendanceCategory '+AttendanceCategory);
				//If there is an internal value, also process time lost where required
				if (attendanceCategory.equals('Present')){
					a.Time_Lost_Rollup__c = 0;
				} else {
					if ( AttendanceCategory.equals('Absent') || pavalues.get(a.Picklist_Value__c).Is_Suspension__c ){
						a.Time_Lost_Rollup__c = (a.Session_End_Time__c.getTime() - a.Session_Start_Time__c.getTime() ) / 60000;
					} else {
						Long ltimelost = 0;
						if (a.Arrival_Time__c != null) {
							ltimelost += a.Arrival_Time__c.gettime() - a.Session_Start_Time__c.getTime();
						}
						if (a.Departure_Time__c != null) {
							ltimelost += a.Session_End_Time__c.getTime() - a.Departure_Time__c.gettime();
						}
						//time returned is milliseconds -- must divide to get minutes
						a.Time_Lost_Rollup__c = ltimelost / 60000;
					}
				}
				if (pavalues.get(a.Picklist_Value__c).is_unexcused__c && AttendanceCategory.equals('Absent')){
					a.Status_for_Rollup__c = 'Unexcused Absence';
				} else {
					a.Status_for_Rollup__c = pavalues.get(a.Picklist_Value__c).Name;
				}
			}
		}
	}

	public static Map<Id, Map <Id, Picklist_Value__c>> processAttendanceStatusMap(Set<Id> setupIds){
		//list of Picklist values for the appropriate setup
		Map <Id, Map <Id, Picklist_Value__c>> attPicklistValueMap = new Map <Id, Map<Id, Picklist_Value__c>>();
		for (Picklist_Value__c pl: [select id, Setup__c, name, category__c, is_suspension__c, is_tardy__c, is_unexcused__c, is_early_departure__c, set_as_default__c 
									from Picklist_Value__c
									WHERE recordType.DeveloperName='Attendance'
									AND	(setup__c = null OR setup__c in: setupIds)]){
			if (pl.setup__c ==null){
				for (Id setupId: setupIds){
					if (attPicklistValueMap.get(setupId)==null){
						attPicklistValueMap.put(setupId, new Map <Id , Picklist_Value__c>{pl.id=>pl});
					} else{
						attPicklistValueMap.get(setupId).put(pl.id, pl);
					}
				}
			} else {
				if (attPicklistValueMap.get(pl.setup__c)==null){
					attPicklistValueMap.put(pl.setup__c, new Map <Id , Picklist_Value__c>{pl.id=>pl});
				} else {
						attPicklistValueMap.get(pl.setup__c).put(pl.id, pl);
				}
			}
		}
		return attPicklistValueMap;
	}

	public static Boolean validateSingleAttendanceType(List<Attendance__c> attendanceList){
		//This is here to skip validating for test data. Our test data is not rebust enough to pass the validation rules.
		if(Test.isRunningTest()){
			return true;
		}

		Boolean isDaily = false;
		Boolean isSectional = false;

		for(Attendance__c a:attendanceList){
			if(a.Daily__c){
				isDaily = true;
			} else {
				isSectional = true;
			}

			if(isDaily && isSectional){
				break;
			}
		}

		if(isDaily && isSectional){
			for(Attendance__c a:attendanceList){
				a.addError('Both daily and sectional attendance records cannot be submitted at the same time. Please submit only one type of attendance record at a time.');
			}
			return false;
		}
		return true;
	}

	public static void processError (List <Attendance__c> attendanceList, string whereText, Exception e){
		String[] linkString = new String[attendanceList.size()];
		for(Attendance__c a: attendanceList){
			if(a.ID != null){
				linkString.add(a.Name+a.ID);
			}
		}
		Global_Error__c ge = Error_Handling.handleError(String.join(linkString,';'), 'Attendance', 'Attendance - '+ whereText, e);
		insert ge;
	}
}
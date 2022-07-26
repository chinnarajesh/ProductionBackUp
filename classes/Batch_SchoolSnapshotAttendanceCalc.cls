global class Batch_SchoolSnapshotAttendanceCalc implements Database.Batchable<Sobject>, Database.Stateful {
	private BatchSnapshot bss {get; set;}
	private BatchSnapshotSectionCalcs bssc {get; set;}

	private Snapshot_Summary__c summary;
	private DataLoadLogList dataLogs;
	private String setupID;
	private Date startDate;
	private Date endDate;

	private Map<String, Integer> attendanceMap {get; set;}
	private Map<ID, Map<String, Integer>> sectionAttendanceMap {get; set;}
	//only used to calculate avgAttendance..... sigh*
	private Map<ID, Integer> sessionMap {get; set;}
	private Setup__c currentSetup {get; set;}

	public Map<String, ID> childRecordtypes {get; set;}
	private Map<ID, List<Staff_Section__c>> staffMap {get; set;}
	private Map<ID, Decimal> gpaMap {get; set;}

	private static final String TOTAL_DAYS_KEY = 'totalDays';
	private static final String PRESENT_KEY = 'present';
	private static final String UNEXCUSED_ABSENT_KEY = 'unexcusedAbsences';
	private static final String EXCUSED_ABSENT_KEY = 'excusedAbsences';
	private static final String UNEXCUSED_TARDY_KEY = 'unexcusedTardies';
	private static final String EXCUSED_TARDY_KEY = 'excusedTardies';
	private static final String TOTAL_ATTENDANCE = 'totalAttendance';

	global Batch_SchoolSnapshotAttendancecalc(Snapshot_Summary__c s, DataLoadLogList d, String sID, Date sDate, Date eDate, Map<ID, Integer> ssMap) {
		sessionMap = ssMap;
		summary = s;
		dataLogs = d;
		setupID = sID;
		startDate = sDate;
		endDate = eDate;
		attendanceMap = new Map<String, Integer>();
		sectionAttendanceMap = new Map<ID, Map<String, Integer>>();
		currentSetup = core_SoqlUtils.getSetupById(setupID);

		bss = new BatchSnapshot();
		bssc = new BatchSnapshotSectionCalcs();

		//get the dayCount and put it in the map
		List<AggregateResult> dayCount = [SELECT COUNT(Id) days FROM Schedule_Day__c WHERE Schedule_Template__r.Has_Class__c = true AND Schedule_Template__r.Setup__c =: setupID AND Day__c >=: startDate AND Day__c <=: endDate];
		if(dayCount.size() > 0) {
			attendanceMap.put(TOTAL_DAYS_KEY, (Integer)dayCount.get(0).get('days'));
		}

		childRecordTypes = bss.getSnapshotRecordtypes('Snapshot_Child__c');
		staffMap = bssc.getAssignedStaff(currentSetup.School__c);
		gpaMap = bssc.getGPAMap(setupID, startDate, endDate);
	}

	//Depricated
	global Batch_SchoolSnapshotAttendancecalc(Snapshot_Summary__c a, DataLoadLogList b, String c, Date d, Date e) {}

	global Database.QueryLocator start(Database.BatchableContext ctx) {
		try {
			String query = '';
			query += 'SELECT ID, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Is_Tardy__c, Daily__c, Session__r.Section__c, Session__c FROM Attendance__c ';
			query += 'WHERE Student__r.Setup__c = \'' + setupID + '\' ';
			query += 'AND Session_Date__c >=: startDate ';
			query += 'AND Session_Date__c <=: endDate ';
			query += 'AND isDeleted = FALSE ';

			return Database.getQueryLocator(query);
		} catch(Exception e) {
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SECTION_SUMMARY,'Failure starting attendance summary batch.');
			insert Error_Handling.handleError('','Batch_SchoolSnapshotAttendanceCalc','Failure in start method',e);
		} finally {
			dataLogs.saveLogs();
		}
		return Database.getQueryLocator('select id from Attendance__c where ID = null');
	}

	global void execute(Database.BatchableContext ctx, List<SObject> scope) {
		List<Attendance__c> attendanceBatch = (Attendance__c[])scope;
		List<Global_Error__c> insertGlobalErrors = new List<Global_Error__c>();

		for(Attendance__c a : attendanceBatch) {
			//ensure there is the count in the map
			if(a.Daily__c) {
				try {
					if(!attendanceMap.containsKey(TOTAL_ATTENDANCE)) {
						attendanceMap.put(TOTAL_ATTENDANCE, 1);
					} else {
						Integer i = attendanceMap.get(TOTAL_ATTENDANCE);
						attendanceMap.put(TOTAL_ATTENDANCE, i++);
					}

					if(a.Picklist_Value__r.Category__c == 'Present') {
						if(!attendanceMap.containsKey(PRESENT_KEY)) {
							attendanceMap.put(PRESENT_KEY, 1);
						} else {
							Integer j = attendanceMap.get(PRESENT_KEY);
							attendanceMap.put(PRESENT_KEY, j++);
						}
					} else if(a.Picklist_Value__r.Category__c == 'Absent') {
						if(a.Picklist_Value__r.Is_Unexcused__c) {
							if(!attendanceMap.containsKey(UNEXCUSED_ABSENT_KEY)) {
								attendanceMap.put(UNEXCUSED_ABSENT_KEY, 1);
							} else {
								Integer i = attendanceMap.get(UNEXCUSED_ABSENT_KEY);
								attendanceMap.put(UNEXCUSED_ABSENT_KEY, i++);
							}
						} else {
							if(!attendanceMap.containsKey(EXCUSED_ABSENT_KEY)) {
								attendanceMap.put(EXCUSED_ABSENT_KEY, 1);
							} else {
								Integer j = attendanceMap.get(EXCUSED_ABSENT_KEY);
								attendanceMap.put(EXCUSED_ABSENT_KEY, j++);
							}
						}
					} else if(a.Picklist_Value__r.Category__c == 'Partial') {
						if(a.Picklist_Value__r.Is_Tardy__c) {
							if(a.Picklist_Value__r.Is_Unexcused__c) {
								if(!attendanceMap.containsKey(UNEXCUSED_TARDY_KEY)) {
									attendanceMap.put(UNEXCUSED_TARDY_KEY, 1);
								} else {
									Integer i = attendanceMap.get(UNEXCUSED_TARDY_KEY);
									attendanceMap.put(UNEXCUSED_TARDY_KEY, i++);
								}
							} else {
								if(!attendanceMap.containsKey(EXCUSED_TARDY_KEY)) {
									attendanceMap.put(EXCUSED_TARDY_KEY, 1);
								} else {
									Integer j = attendanceMap.get(EXCUSED_TARDY_KEY);
									attendanceMap.put(EXCUSED_TARDY_KEY, j++);
								}
							}
						}
					} else {
						//unsupported category
					}
				} catch(Exception e){
					dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
					dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SECTION_SUMMARY,'Failure processing daily attendace for '+a.id);
					Error_Handling.handleMultiPartException('','Batch_SchoolSnapshotAttendanceCalc', 'Daily Attendance Error (Attendance:' + a + ')', e);
				}
			} else {
				try {
					//sectional attendance logic here
					if(a.Session__c != null) {
						if(a.Session__r.Section__c != null) {
							if(!sectionAttendanceMap.containsKey(a.Session__r.Section__c)) {
								Map<String, Integer> temp = new Map<String, Integer>();
								if(a.Picklist_Value__r.Category__c == 'Present') {
									temp.put(PRESENT_KEY, 1);
								} else if(a.Picklist_Value__r.Category__c == 'Absent') {
									if(a.Picklist_Value__r.Is_Unexcused__c) {
										temp.put(UNEXCUSED_ABSENT_KEY, 1);
									} else {
										temp.put(EXCUSED_ABSENT_KEY, 1);
									}
								} else if(a.Picklist_Value__r.Category__c == 'Partial') {
									if(a.Picklist_Value__r.Is_Tardy__c) {
										if(a.Picklist_Value__r.Is_Unexcused__c) {
											temp.put(UNEXCUSED_TARDY_KEY, 1);
										} else {
											temp.put(EXCUSED_TARDY_KEY, 1);
										}
									}
								}
								sectionAttendanceMap.put(a.Session__r.Section__c, temp);
								sectionAttendanceMap.get(a.Session__r.Section__c).put(TOTAL_ATTENDANCE, 1);
							} else {
								if(a.Picklist_Value__r.Category__c == 'Present') {
									if(!sectionAttendanceMap.get(a.Session__r.Section__c).containsKey(PRESENT_KEY)) {
										sectionAttendanceMap.get(a.Session__r.Section__c).put(PRESENT_KEY, 1);
									} else {
										Integer i = sectionAttendanceMap.get(a.Session__r.Section__c).get(PRESENT_KEY) + 1;
										sectionAttendanceMap.get(a.Session__r.Section__c).put(PRESENT_KEY, i);
									}
								} else if(a.Picklist_Value__r.Category__c == 'Absent') {
									if(a.Picklist_Value__r.Is_Unexcused__c) {
										if(!sectionAttendanceMap.get(a.Session__r.Section__c).containsKey(UNEXCUSED_ABSENT_KEY)) {
											sectionAttendanceMap.get(a.Session__r.Section__c).put(UNEXCUSED_ABSENT_KEY, 1);
										} else {
											Integer i = sectionAttendanceMap.get(a.Session__r.Section__c).get(UNEXCUSED_ABSENT_KEY) + 1;
											sectionAttendanceMap.get(a.Session__r.Section__c).put(UNEXCUSED_ABSENT_KEY, i);
										}
									} else {
										if(!sectionAttendanceMap.get(a.Session__r.Section__c).containsKey(EXCUSED_ABSENT_KEY)) {
											sectionAttendanceMap.get(a.Session__r.Section__c).put(EXCUSED_ABSENT_KEY, 1);
										} else {
											Integer i = sectionAttendanceMap.get(a.Session__r.Section__c).get(EXCUSED_ABSENT_KEY) + 1;
											sectionAttendanceMap.get(a.Session__r.Section__c).put(EXCUSED_ABSENT_KEY, i);
										}
									}
								} else if(a.Picklist_Value__r.Category__c == 'Partial') {
									if(a.Picklist_Value__r.Is_Tardy__c) {
										if(a.Picklist_Value__r.Is_Unexcused__c) {
											if(!sectionAttendanceMap.get(a.Session__r.Section__c).containsKey(UNEXCUSED_TARDY_KEY)) {
												sectionAttendanceMap.get(a.Session__r.Section__c).put(UNEXCUSED_TARDY_KEY, 1);
											} else {
												Integer i = sectionAttendanceMap.get(a.Session__r.Section__c).get(UNEXCUSED_TARDY_KEY) + 1;
												sectionAttendanceMap.get(a.Session__r.Section__c).put(UNEXCUSED_TARDY_KEY, i);
											}
										} else {
											if(!sectionAttendanceMap.get(a.Session__r.Section__c).containsKey(EXCUSED_TARDY_KEY)) {
												sectionAttendanceMap.get(a.Session__r.Section__c).put(EXCUSED_TARDY_KEY, 1);
											} else {
												Integer i = sectionAttendanceMap.get(a.Session__r.Section__c).get(EXCUSED_TARDY_KEY) + 1;
												sectionAttendanceMap.get(a.Session__r.Section__c).put(EXCUSED_TARDY_KEY, i);
											}
										}
									}
								}
								Integer j = sectionAttendanceMap.get(a.Session__r.Section__c).get(TOTAL_ATTENDANCE) + 1;
								sectionAttendanceMap.get(a.Session__r.Section__c).put(TOTAL_ATTENDANCE, j);
							}
						}//end of checking Session__r.Section__c
					}//end of checking Session__c
				}
				catch (Exception e) {
					dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
					dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SECTION_SUMMARY,'Failure processing sectional attendace for '+a.id);
					Error_Handling.handleMultiPartException('', 'Batch_SchoolSnapshotAttendanceCalc', 'Section Attendance Error (Attendance:' + a + ')', e);
				}
			}
		}
		dataLogs.saveLogs();
		Error_Handling.insertMultiPartException();
	}

	global void finish(Database.BatchableContext ctx) {
		try {
			summary.Daily_Attendance__c = avgDailyAttendance();
			summary.Percent_Excused_Absences__c = percentExcusedAbsences();
			summary.Percent_Unexcused_Absences__c = percentUnexcusedAbsences();
			summary.Percent_Excused_Tardies__c = percentExcusedTardies();
			summary.Percent_Unexcused_Tardies__c = percentUnexcusedTardies();
			update summary;
		} catch(Exception e) {
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SUMMARY,'Failure in populating school attendance summary.');
			insert Error_Handling.handleError('', 'Batch_SchoolSnapshotAttendanceCalc', 'Failure populating school attendance summary (setup:' + setupID + ')', e);
		}

		try {
			List<Snapshot_Child__c> sectionSummaries = calculateSectionSummaries();
			dataLogs.incrTotal(DataLoadLogList.SCHOOL_SECTION_SUMMARY, sectionSummaries.size());
			insert sectionSummaries;
		} catch(Exception e) {
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SECTION_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SECTION_SUMMARY, 'Failure populating section attendance summaries.');
			insert Error_Handling.handleError('', 'Batch_SchoolSnapshotAttendanceCalc', 'Failure populating section attendance summaries (setup:' + setupID + ')', e);
		}

		try{
			Setup__c currentSetup = core_SoqlUtils.getSetupById(setupID);
			currentSetup.Processed_Historical_Data__c = dataLogs.countAllFailed() == 0;
			update currentSetup;
		} catch(Exception e){
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SUMMARY, 'Failure updating setup status.');
			insert Error_Handling.handleError('', 'Batch_SchoolSnapshotAttendanceCalc', 'Failure updating setup status (setup:' + setupID + ')', e);
		}

		try{
			Batch_CohortSnapshot cohortBatch = new Batch_CohortSnapshot((String)currentSetup.ID, true);
			Database.executeBatch(cohortBatch);
		} catch(Exception e){
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SUMMARY, 'Failure starting cohort batch.');
			insert Error_Handling.handleError('', 'Batch_SchoolSnapshotAttendanceCalc', 'Failure starting cohort (setup:' + setupID + ')', e);
		}

		dataLogs.endAll(); //this saves the logs too
	}

	//formulas copied from BatchSnapshotSchoolCalc
	private Decimal zeroIfNull(Decimal num){
		return (num == null)?0:num;
	}

	private Decimal avgDailyAttendance() {
		Decimal present = zeroIfNull(attendanceMap.get(PRESENT_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_DAYS_KEY));

		return (total>0)?present/total:0;
	}

	private Decimal percentUnexcusedAbsences() {
		Decimal unexcused = zeroIfNull(attendanceMap.get(UNEXCUSED_ABSENT_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));

		return (total>0)?(unexcused/total)*100:0;
	}

	private Decimal percentExcusedAbsences() {
		Decimal excused = zeroIfNull(attendanceMap.get(EXCUSED_ABSENT_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));

		return (total>0)?(excused/total)*100:0;
	}

	private Decimal percentUnexcusedTardies() {
		Decimal unexcused = zeroIfNull(attendanceMap.get(UNEXCUSED_TARDY_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));

		return (total>0)?(unexcused/total)*100:0;
	}

	private Decimal percentExcusedTardies() {
		Decimal excused = zeroIfNull(attendanceMap.get(EXCUSED_TARDY_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));

		return (total!=0)?(excused/total)*100:0;
	}

	//Formulas captured from BatchSnapshotSectionCalcs
	private Decimal percentPresent(ID sectionID) {
		if(sectionAttendanceMap.containsKey(sectionID)){
			Decimal present = zeroIfNull(sectionAttendanceMap.get(sectionID).get(PRESENT_KEY));
			Decimal total = zeroIfNull(sectionAttendanceMap.get(sectionID).get(TOTAL_ATTENDANCE));

			return (total>0)?(present/total)*100:0;
		}
		return 0;
	}

	private Decimal percentUnexcusedAbsences(ID sectionID) {
		if(sectionAttendanceMap.containsKey(sectionID)) {
			if(sectionAttendanceMap.get(sectionID).containsKey(UNEXCUSED_ABSENT_KEY) && sectionAttendanceMap.get(sectionID).containsKey(TOTAL_ATTENDANCE)) {
				Decimal unexcused = zeroIfNull(sectionAttendanceMap.get(sectionID).get(UNEXCUSED_ABSENT_KEY));
				Decimal total = zeroIfNull(sectionAttendanceMap.get(sectionID).get(TOTAL_ATTENDANCE));
				if(total > 0) {
					return (unexcused/total)*100;
				}
				else {
					return 0;
				}
			}
		}
		return 0;
	}

	private Decimal percentExcusedAbsences(ID sectionID) {
		if(sectionAttendanceMap.containsKey(sectionID)) {
			if(sectionAttendanceMap.get(sectionID).containsKey(EXCUSED_ABSENT_KEY) && sectionAttendanceMap.get(sectionID).containsKey(TOTAL_ATTENDANCE)) {
				Decimal excused = zeroIfNull(sectionAttendanceMap.get(sectionID).get(EXCUSED_ABSENT_KEY));
				Decimal total = zeroIfNull(sectionAttendanceMap.get(sectionID).get(TOTAL_ATTENDANCE));
				if(total > 0) {
					return (excused/total)*100;
				}
				else {
					return 0;
				}
			}
		}
		return 0;
	}

	private Decimal percentUnexcusedTardies(ID sectionID) {
		if(sectionAttendanceMap.containsKey(sectionID)) {
			if(sectionAttendanceMap.get(sectionID).containsKey(UNEXCUSED_TARDY_KEY) && sectionAttendanceMap.get(sectionID).containsKey(TOTAL_ATTENDANCE)) {
				Decimal unexcused = zeroIfNull(sectionAttendanceMap.get(sectionID).get(UNEXCUSED_TARDY_KEY));
				Decimal total = zeroIfNull(sectionAttendanceMap.get(sectionID).get(TOTAL_ATTENDANCE));
				if(total > 0) {
					return (unexcused/total)*100;
				}
				else {
					return 0;
				}
			}
		}
		return 0;
	}

	private Decimal percentExcusedTardies(ID sectionID) {
		if(sectionAttendanceMap.containsKey(sectionID)) {
			if(sectionAttendanceMap.get(sectionID).containsKey(EXCUSED_TARDY_KEY) && sectionAttendanceMap.get(sectionID).containsKey(TOTAL_ATTENDANCE)) {
				Decimal excused = zeroIfNull(sectionAttendanceMap.get(sectionID).get(EXCUSED_TARDY_KEY));
				Decimal total = zeroIfNull(sectionAttendanceMap.get(sectionID).get(TOTAL_ATTENDANCE));
				if(total > 0) {
					return (excused/total)*100;
				}
				else {
					return 0;
				}
			}
		}
		return 0;
	}

	private Decimal avgGPA(ID sectionID) {
		Decimal gpa = gpaMap.get(sectionID);
		return (gpa == null)?0:gpa;
	}

	private String getStaff(ID sectionId) {
		List<Staff_Section__c> staffList = staffMap.get(sectionId);
		String staff = '';
		Boolean firstTime = true;

		if (staffList != null && !staffList.isEmpty()){
			for (Staff_Section__c s : staffList){
				if(staff != ''){
					staff += ', ';
				}
				String staffName = (String.isBlank(s.Staff__r.First_Name_Staff__c)?'':s.Staff__r.First_Name_Staff__c)+
									(String.isBlank(s.Staff__r.Middle_Name_Staff__c)?'':s.Staff__r.Middle_Name_Staff__c)+
									(String.isBlank(s.Staff__r.Staff_Last_Name__c)?'':s.Staff__r.Staff_Last_Name__c);
				staff += staffName;
			}
		}
		return staff;
	}

	private List<Snapshot_Child__c> calculateSectionSummaries() {
		List<Snapshot_Child__c> children = new List<Snapshot_Child__c>();

		for(Section__c section : bss.getSectionsForSchool(currentSetup.School__c)) {
			Snapshot_Child__c child = new Snapshot_Child__c();
			child.Snapshot_Summary__c = summary.ID;
			child.RecordtypeID = childRecordTypes.get('Section');
			child.Section__c = section.ID;
			child.Average_GPA__c = avgGPA(section.ID);
			child.Attendance_Percent__c = percentPresent(section.ID);
			child.Percent_Excused_Absence__c = percentExcusedAbsences(section.ID);
			child.Percent_Excused_Tardies__c = percentExcusedTardies(section.ID);
			child.Percent_Unexcused_Absence__c = percentUnexcusedAbsences(section.ID);
			child.Percent_Unexcused_Tardies__c = percentUnexcusedTardies(section.ID);
			child.Assigned_Staff__c = getStaff(section.ID);
			children.add(child);
		}
		return children;
	}
}
global class BatchSnapshotSectionCalcs {
	
	global static final String TOTAL_DAYS_KEY = 'totalDays';
	global static final String PRESENT_KEY = 'present';
	global static final String UNEXCUSED_ABSENT_KEY = 'unexcusedAbsences';
	global static final String EXCUSED_ABSENT_KEY = 'excusedAbsences';
	global static final String UNEXCUSED_TARDY_KEY = 'unexcusedTardies';
	global static final String EXCUSED_TARDY_KEY = 'excusedTardies';
	global static final String TOTAL_ATTENDANCE = 'totalAttendance';
	
	//US3508
	public static final Set<String> legalSectionRT = new Set<String>{'Gradebook Group', 'Published', 'Unpublished', 'Schedule Group'};
	
	global Setup__c setup {
		get; private set;
	}
	
	global Date startDate {
		get; private set;
	}
	
	global Date endDate {
		get; private set;
	}
	
	global Map<ID, Map<String, Integer>> attendanceMap {
		get; private set;
	}
	
	global Map<ID, Decimal> gpaMap {
		get; private set;
	}
	
	global Map<ID, List<Staff_Section__c>> staffMap {
		get; private set;
	}
	
	global BatchSnapshotSectionCalcs(){
	}
	
	global BatchSnapshotSectionCalcs(Setup__c someSetup, Date someStartDate, Date someEndDate) {
		initialize(someSetup, someStartDate, someEndDate);
	}
	
	global void initialize(Setup__c someSetup, Date someStartDate, Date someEndDate) {
		setup = someSetup;
		startDate = someStartDate;
		endDate = someEndDate;
		attendanceMap = getAttendanceMap(setup, startDate, endDate);
		gpaMap = getGPAMap(setup.id, startDate, endDate);
		staffMap = getAssignedStaff(setup.School__c);
	}
	
	global Map<ID, Decimal> getGPAMap(ID setupId, Date sdate, Date edate) {
		Map<ID, Decimal> gMap = new Map<ID, Decimal>();
		List<AggregateResult> results = [select Student_Section__r.Section__c section,
											AVG(Section_Weighted_GPA__c) avgGpa 
										from Section_Grade__c
										where Student_Section__r.Student__r.Setup__c = :setupId and
											Student_Section__r.Section__r.Course__r.Include_in_section_snapshot__c = true 
											//This is not used at all... in anywhere
											//AND isFinal__c = true
										group by Student_Section__r.Section__c];
		for (AggregateResult ar : results) {
			gMap.put((ID)ar.get('section'), (Decimal)ar.get('avgGpa'));
		}
		
		return gMap;
	}
	
	global Map<ID, List<SObject>> splitByField(List<SObject> alist, String fieldName) {
		ID lastValue;
		List<SObject> newList;
		Map<ID, List<SObject>> smap = new Map<ID, List<SObject>>();
		
		for (SObject ag : alist) {
			if ((ID)ag.get(fieldName) != lastValue) {
				if (lastValue != null) {
					smap.put(lastvalue, newList);
				}
				lastvalue = (ID)ag.get(fieldName);
				newList = new List<SObject>();
			}
			
			newList.add(ag);
		}
		if (lastValue != null) {
			smap.put(lastvalue, newList);
		}
		
		return smap;
	}
	
	global Map<String, Integer> calcAttendanceMap(List<AggregateResult> dayCount,
													List<AggregateResult> attend) {
		Integer totalAttendance = 0;
		Map<String, Integer> results = new Map<String, Integer>();

		if (dayCount.size() > 0) {
			results.put(TOTAL_DAYS_KEY, (Integer)dayCount.get(0).get('days'));
		}												
														
		for (AggregateResult ar : attend) {
			Integer cnt = (Integer)ar.get('cnt');
			String cat = (String) ar.get('cat');
			Boolean unexcused = (Boolean) ar.get('unexcused');
			Boolean tardy = (Boolean) ar.get('tardy');
			totalAttendance += cnt;
			if (cat == 'Present') {
				results.put(PRESENT_KEY, cnt);
			} else if (cat == 'Absent') {
				if (unexcused == true) {
					results.put(UNEXCUSED_ABSENT_KEY, cnt);
				}
				else {
					results.put(EXCUSED_ABSENT_KEY,  cnt);
				}
			} else if (cat == 'Partial') {
				if (tardy == true) {
					if (unexcused == true) {
						results.put(UNEXCUSED_TARDY_KEY, cnt);
					} 
					else {
						results.put(EXCUSED_TARDY_KEY, cnt);
					}
				}				
			}
		}
		results.put(TOTAL_ATTENDANCE, totalAttendance);
		return results;						 						
	}
	
	global Map<ID, List<AggregateResult>> getSplitDayCount(ID schoolId, Date sdate, Date edate) {
		List<AggregateResult> dcList = [select Section__c section, 
											count(id) days
										from Session__c 
										where Section__r.School__c = :schoolId and
											Section__r.Course__r.Include_in_section_snapshot__c = true and 
											Start_DateTime__C >= :sdate and
											Start_DateTime__c <= :edate
										group by Section__c];
		Map<ID, List<AggregateResult>> dcMap = splitByField(dcList, 'section');

		return dcMap;		
	}

	global Map<ID, List<AggregateResult>> getSplitAttendance(ID setupId, Date sdate, Date edate) {
		List<AggregateResult> atList = [select Session__r.Section__c section,
											Picklist_Value__r.Category__c cat, 
											Picklist_Value__r.Is_Unexcused__c unexcused, 
											Picklist_Value__r.Is_Tardy__c tardy, 
											count(id) cnt 
										from Attendance__c
										where Student__r.Setup__c = :setupId and
											Session__r.Start_DateTime__c >= :sdate and
											Session__r.Start_DateTime__c <= :edate and
											Session__r.Section__r.Course__r.Include_in_section_snapshot__c = true and
											Daily__c = false and 
											isDeleted = false
										group by Session__r.Section__c,
											Picklist_Value__r.Category__c, 
											Picklist_Value__r.Is_Unexcused__c, 
											Picklist_Value__r.Is_Tardy__c];
		Map<ID, List<AggregateResult>> atMap = splitByField(atList, 'section');
		
		return atMap;
	}

	global Map<ID, Map<String, Integer>> getAttendanceMap(Setup__c someSetup, Date sdate, Date edate) {
		Integer totalAttendance = 0;
		Map<ID, Map<String, Integer>> results = new Map<ID, Map<String, Integer>>();
		Map<ID, List<AggregateResult>> dcMap = getSplitDayCount(someSetup.School__c, sdate, edate);
		Map<ID, List<AggregateResult>> atMap = getSplitAttendance(someSetup.id, sdate, edate);

		for (ID key : dcMap.keySet()) {
			List<AggregateResult> dc = dcMap.get(key);
			List<AggregateResult> attnd = atMap.get(key);
			if (dc != null && attnd != null && dc.size() > 0 && attnd.size() > 0) {
				Map<String, Integer> rmap = calcAttendanceMap(dc, attnd);
				results.put(key, rmap);
			}
		}

		return results;												
	}
	
	global Decimal zeroIfNull(Decimal num) {
		if (num == null) {
			return 0;
		}
		else {
			return num;
		}
	}
	
	global Decimal getAttendStat(ID sectionId, String key) {
		Map<String, Integer> amap = attendanceMap.get(sectionId);
		if (amap == null) {
			system.debug('amap is null');
			return -1;
		}
		else {
			return zeroIfNull(amap.get(key));
		}
	}
	
	global Decimal avgAttendance(ID sectionId) {
		Decimal present = getAttendStat(sectionId, PRESENT_KEY);
		Decimal total = getAttendStat(sectionId, TOTAL_DAYS_KEY);
		if (total > 0) {
			return present/total;
		}
		else {
			return 0;
		}
	}
	
	global Decimal percentPresent(ID sectionId) {
		Decimal present = getAttendStat(sectionId, PRESENT_KEY);
		Decimal total = getAttendStat(sectionId, TOTAL_ATTENDANCE);
		if (total > 0) {
			return (present/total)*100;
		}
		else {
			return 0;
		}
	}

	global Decimal percentUnexcusedAbsences(ID sectionId) {
		Decimal unexcused = getAttendStat(sectionId, UNEXCUSED_ABSENT_KEY);
		Decimal total = getAttendStat(sectionId, TOTAL_ATTENDANCE);
		if (total > 0) {
			return (unexcused/total)*100;
		}
		else {
			return 0;
		}
	}

	global Decimal percentExcusedAbsences(ID sectionId) {
		Decimal excused = getAttendStat(sectionId, EXCUSED_ABSENT_KEY);
		Decimal total = getAttendStat(sectionId, TOTAL_ATTENDANCE);
		if (total > 0) {
			return (excused/total)*100;
		}
		else {
			return 0;
		}
	}

	global Decimal percentUnexcusedTardies(ID sectionId) {
		Decimal unexcused = getAttendStat(sectionId, UNEXCUSED_TARDY_KEY);
		Decimal total = getAttendStat(sectionId, TOTAL_ATTENDANCE);
		if (total > 0) {
			return (unexcused/total)*100;
		}
		else {
			return 0;
		}
	}

	global Decimal percentExcusedTardies(ID sectionId) {
		Decimal excused = getAttendStat(sectionId, EXCUSED_TARDY_KEY);
		Decimal total = getAttendStat(sectionId, TOTAL_ATTENDANCE);
		if (total > 0) {
			return (excused/total)*100;
		}
		else {
			return 0;
		}
	}
	
	global Decimal avgGPA(ID sectionId) { 

		Decimal gpa = gpaMap.get(sectionId);
		if (gpa == null) {
			return 0;
		}
		else {
			return gpa;
		}	
	}

	global Map<ID, List<Staff_Section__c>> getAssignedStaff(ID schoolId) {
		List<Staff_Section__c> dcList = [select Section__c,
											Staff__r.First_Name_Staff__c,
											Staff__r.Middle_Name_Staff__c,
											Staff__r.Staff_Last_Name__c 
										from Staff_Section__c 
										where Staff__r.Organization__c = :schoolId and 
											Staff__r.Instructional_Staff__c = true and
											Section__r.Course__r.Include_in_section_snapshot__c = true and
											//US3508
											Section__r.RecordType.Name IN: legalSectionRT and
											Staff__r.Active__c = true
										order by Section__c,
											Staff__r.Staff_Last_Name__c, 
											Staff__r.First_Name_Staff__c,
											Staff__r.Middle_Name_Staff__c];
		Map<ID, List<Staff_Section__c>> dcMap = splitByField(dcList, 'Section__c');
		return dcMap;
	}
	
	global String getStaff(ID sectionId) {
		List<Staff_Section__c> staffList = staffMap.get(sectionId);
		String staff = '';
		Boolean firstTime = true;
		
		if (staffList != null && staffList.size() > 0) {
			for (Staff_Section__c s : staffList) {
				if (!firstTime) {
					staff = staff + ', ';
				}
				firstTime = false;
				if (StringUtils.blankNull(s.Staff__r.First_Name_Staff__c).length() > 0) {
					staff = staff + s.Staff__r.First_Name_Staff__c + ' ';
				}
				
				if (StringUtils.blankNull(s.Staff__r.Middle_Name_Staff__c).length() > 0) {
					staff = staff + s.Staff__r.Middle_Name_Staff__c + ' ';
				}
	
				if (StringUtils.blankNull(s.Staff__r.Staff_Last_Name__c).length() > 0) {
					staff = staff + s.Staff__r.Staff_Last_Name__c;
				}
			}
		}
		
		return staff;
	}	

}
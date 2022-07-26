public with sharing class Course_Utils {

	/***************** Start of Course Util methods***********************************/
	public static Map <Id, String> courseRtMap;
	public static Map <Id, String> getCourseRtMap(){
		if (courseRtMap ==null){
			courseRtMap = new Map <Id, String>();
			Map <String, Id> rtNameMap = core_SoqlUtils.getRecordTypesBySobject('Course__c');
			for (string rtName: rtNameMap.keySet()){
				system.debug(rtName);
				system.debug(rtNameMap.get(rtName));
				courseRtMap.put(rtNameMap.get(rtName), rtName);
			}
		}
		return courseRtMap;
	}
	public static Map <Integer, Picklist_Value__c> rpValueMap;
	public static void resetReportingPeriodValueMap(){
		if (rpValueMap==null){
			rpValueMap = new Map <Integer, Picklist_Value__c>();
			for (Picklist_Value__c plv: [select id, corresponding_Value__c from Picklist_Value__c where setup__c=null and RecordType.DeveloperName = 'Time' and category__c = 'Reporting Period']){
				system.debug('timePlv~~~~'+plv);
				rpValueMap.put(integer.valueOf(plv.corresponding_value__c), plv);
			}
		}
	}

	public static void processBeforeInsert(List <Course__c> newList){
		populateSubjectArea(newList);
		for(Course__c c:newList){
			if(c.reference_id__c == null){
				c.reference_id__c = String.valueOf(c.Course_Number__c);
			}
		}
		preventDupCourse(newList, null);
	}
	public static void processAfterInsert(Map <Id, Course__c> newMap){
		insertWeightings(newMap);
	}
	public static void processBeforeUpdate(Map <Id, Course__c> newMap, Map<Id, Course__c> oldMap){
		populateSubjectArea(newMap.values());
		preventDupCourse(newMap.values(),oldMap);
		updateCourseNameOnSection(newMap, oldMap);
	}
	public static void processAfterUpdate(Map <Id, Course__c> newMap, Map<Id, Course__c> oldMap){
		//updateWeightings(newMap,oldMap); this is going to be done in the course catalog screen itself
		cascadeSectionGradeRecalcs(newMap,oldMap); //For Hawaii
	}
	public static void processBeforeDelete(Map <Id, Course__c> oldMap){
		preventCourseDelete(oldMap);
		cascadeDelete(oldMap);
	}

	public static void cascadeSectionGradeRecalcs (Map <Id, Course__c> newMap, Map<Id, Course__c> oldMap){
		//This is called when the course grade scale changes to cascade and update the calculations at the section grade/finalGrade level Hawaii release
		Set<Id> changedScaleIds = new Set <Id>();
		for(Course__c c:newMap.values()){
			if(c.grade_Scale_Lookup__c!=oldMap.get(c.id).grade_scale_lookup__c){
				changedScaleIds.add(c.id);
			}
		}
		if (!changedScaleIds.isEmpty()){
			try {
				Map<String, Gradebook_GradeUtils.aggregateResults> studentAggregateResults = new Map<String, Gradebook_GradeUtils.aggregateResults>();
				List<Section_Grade__c> upsertList = new List<Section_Grade__c>();
				
				Gradebook_GradeUtils gradeUtils = new Gradebook_GradeUtils();
				gradeUtils.setOverrideValues();
				
				if(gradeUtils.bCourseGradeScalesEmpty()) {
					gradeUtils.setCourseGradeScales(new Set<Course__c>(newMap.Values()));
				}
			
				//populate the aggregateResults
				for(Section_Grade__c sg : [SELECT ID, Student_Section__c, Time__c, Reference_ID__c, Student_Section__r.Section__r.Course__c, Grade__c, Grade_Overridden__c 
											FROM Section_Grade__c WHERE Student_Section__r.Section__r.Course__c IN: changedScaleIds
											AND Student_Section__r.Active__c = TRUE
											AND Student_Section__r.Section__r.Active__c = TRUE
											AND RecordType.DeveloperName != 'Semester'
											AND Grade__c != NULL]) {
					String key = sg.Reference_ID__c;
					Gradebook_GradeUtils.aggregateResults t = new Gradebook_GradeUtils.aggregateResults();
					t.Key = key;
					t.studentSection = sg.Student_Section__c;
					t.course = sg.Student_Section__r.Section__r.Course__c;
					t.reportingPeriod = sg.Time__c;
					t.overridden = sg.Grade_Overridden__c;
					t.gradePlaceHolder = sg.Grade__c;
					studentAggregateResults.put(key, t);
				}
				
				//loop throught the wrapper.  Not sure if we can optimize this process (other than writing another method to take X arguements)
				for(Gradebook_GradeUtils.aggregateResults ar : studentAggregateResults.Values()) {
					Gradebook_GradeUtils.CourseGradeScaleWrapper passCGSW = gradeUtils.courseGradeScales.get(ar.course);
					upsertList.add(ar.createCalculatedSectionGrade(passCGSW, gradeUtils.defaultCourseFinalGradeScale, ar.gradePlaceHolder));
				}
				
				if(upsertList.size() > 0) {
					upsert upsertList Reference_ID__c;
				}
			}
			catch(Exception e) {
				e.setMessage('Failed to recalculate section grades upon changing the course grade scale');
			}
		}
	}

	public static void populateSubjectArea(List<Course__c> newList){
		Set<String> subjectAreas = new Set<String>();
		Map<String, Id> subjectAreaMap = new Map<String, ID>();
		Map <Id, String> tempRtMap = getCourseRtMap();
		id saID = core_SoqlUtils.getRecordTypesBySobject('Course__c').get('Subject_Area');
		for(Course__c c:newList){
			if(tempRtMap.get(c.recordTypeId)=='Course'||c.recordTypeId==null){
				if((c.Subject_Area__c == null ||c.Subject_Area__c.trim() == '') && c.Subject_Area_Lookup__c == null){
					c.Subject_Area_Lookup__c.addError('Subject Area or Subject Area Lookup is required.');
				} else if(c.Subject_Area_Lookup__c == null) {
					subjectAreas.add(c.Subject_Area__c);
				}
			}
		}
		if(!subjectAreas.isEmpty()){
			List<Course__c> subjectAreaList = [select id, Name from Course__c where Name IN: subjectAreas and RecordTypeID=:saID];
			for(Course__c sa:subjectAreaList){
				subjectAreaMap.put(sa.Name, sa.Id);
			}
			subjectAreas.removeAll(new List<String>(subjectAreaMap.keySet()));
			if(!subjectAreas.isEmpty()){
				List<Course__c> newSubjectAreas = new List<Course__c>();
				for(String s:subjectAreas){
					newSubjectAreas.add(new Course__c(Name=s, RecordTypeID=saID));
				}

				insert newSubjectAreas;
				for(Course__c sa:newSubjectAreas){
					subjectAreaMap.put(sa.name, sa.ID);
				}
			}
			for(Course__c c:newList){
				if(tempRtMap.get(c.recordTypeId)=='Course'||c.recordTypeId==null){
					c.Subject_Area_Lookup__c = subjectAreaMap.get(c.Subject_Area__c);
				}
			}
		}
	}

	public static void updateCourseNameOnSection(Map <Id, Course__c> newMap, Map<Id, Course__c> oldMap){
		Set <Id> changedCourseNameIds = new Set <Id>();
		Map <String, Id> courseNameToIdMap = new Map <String, Id>();
		List <Section__c> updSectionList = new List <Section__c>();
		List <HoldingObj__c> updHoList = new List <HoldingObj__c>();
		for (Course__c c: newMap.values()){
			if (c.name!=oldMap.get(c.id).name){
				changedCourseNameIds.add(c.id);
				courseNameToIdMap.put(c.name, c.id);
			}
		}
		if (!changedCourseNameIds.isEmpty()){
			for (Section__c sec: [select name, course__c from Section__c
			where course__c in :changedCourseNameIds
			and active__c =true]){
				if (sec.name.contains(oldMap.get(sec.course__c).name)){
					sec.name=sec.name.replace(oldMap.get(sec.course__c).name, newMap.get(sec.course__c).name);
					updSectionList.add(sec);
				}
			}
			for (HoldingObj__c ho: [select id, course_name__c from HoldingObj__c
			where course_name__c in :courseNameToIdMap.keySet()]){
				ho.name=newMap.get(courseNameToIdMap.get(ho.course_name__c)).name;
				updHoList.add(ho);
			}
		}
		if (!updSectionList.isEmpty()){
			update updSectionList;
		}
		if (!updHoList.isEmpty()){
			update updHoList;
		}
	}

	public static void preventCourseDelete(Map<Id, Course__c> oldMap) {
		try {
			Set<ID> courseIDs = new Set<ID>();
			for(Course__c c: oldMap.values()) 				courseIDs.add(c.id);
			List<Section__c> sections = [SELECT id, Course__c FROM Section__c WHERE Active__c=true AND Course__c IN :courseIDs];
			if(sections!=null && sections.size() > 0){
				for(Section__c s: sections){
					oldMap.get(s.Course__c).addError('Unable to delete: This course still has active sections associated with it!');
				}
			}
		}
		catch (Exception e){ errorHandling(e, oldMap, 'Course', 'Course trigger: before delete' );}
	}
	
	public static void cascadeDelete(Map<Id, Course__c> oldMap){
		try{
			List<Course_Course_Catalog__c> ccc = [SELECT id FROM Course_Course_Catalog__c WHERE Course__c IN :oldMap.keySet()];
			delete ccc;
		} catch(Exception e) {
			errorHandling(e, oldMap, 'Course', 'Course trigger: cascade delete');
		}
	}

	public static void preventDupCourse(List <Course__c> newList, Map <Id, Course__c> oldMap){
		Set <String> courseNumberSet = new Set <String>();
		Set <String> courseNameSet = new Set <String>();
		Set<String> subjectAreaNameSet = new Set<String>();
		Map <Id, String> tempRtMap = getCourseRtMap();

		for (Course__c c : newList){
			if (tempRtMap.get(c.recordTypeId)=='Course' || tempRtMap.get(c.recordTypeId)=='Transfer' || tempRtMap.get(c.recordTypeId)=='Recovery'){
				if (oldMap==null){ //insert new course
					courseNumberSet.add(c.course_number__c);
					courseNameSet.add(c.name);
				}
				else { //update
					if (c.course_number__c!=oldMap.get(c.id).course_number__c){ //course number changed
						courseNumberSet.add(c.course_number__c);
					}
					if (c.name!=oldMap.get(c.id).name){ //name changed
						system.debug('adding~~'+c);
						courseNameSet.add(c.name);
					}
				}
			} else if(tempRtMap.get(c.RecordTypeID)=='Subject_Area') {
				if(oldMap==null) subjectAreaNameSet.add(c.Name);
				else{
					if(c.Name!=oldMap.get(c.id).Name) subjectAreaNameSet.add(c.Name);
				}
			}
		}

		Set <String> existingCourseSet = new Set <String>();
		Set <String> existingCourseNameSet = new Set <String>();
		Set<String> existingSubjectAreaNameSet = new Set<String>();

		if (!courseNumberSet.isEmpty()){
			for (Course__c c: getCoursesByKeys(courseNumberSet)){
				existingCourseSet.add(c.reference_id__c);
			}
		}
		if (!courseNameSet.isEmpty() || !subjectAreaNameSet.isEmpty()){
			for (Course__c c: [select id, recordTypeId, name from Course__c where (name in:courseNameSet or Name IN:subjectAreaNameSet)]){
				if (tempRtMap.get(c.recordTypeId)=='Course'||c.recordTypeId==null){
					existingCourseNameSet.add(c.name);
				}
				if (tempRtMap.get(c.recordTypeId)=='Subject_Area'){
					existingSubjectAreaNameSet.add(c.Name);
				}
			}
		}

		for (Course__c c: newList){
			if (tempRtMap.get(c.recordTypeId)=='Course' || tempRtMap.get(c.recordTypeId)=='Transfer' || tempRtMap.get(c.recordTypeId)=='Recovery' ||c.RecordTypeId==null){
				if (c.name!=null){
					if (c.name.length()>40) c.addError('Course Names must be under 40 characters');
				}
				if (existingCourseSet.contains(c.course_number__c)) c.addError ('Course with entered course number has already been created. Please verify that your data is correct.');
				if (existingCourseNameSet.contains(c.name)) c.addError ('Course with same name has already been created. Please use a different name.');
				if (oldMap==null && tempRtMap.get(c.recordTypeId)=='Course') {
					if (c.Subject_Area_Lookup__c==null) c.addError ('Subject Area Lookup is required');
				}
			} else if(tempRtMap.get(c.recordTypeId)=='Subject_Area'){
				if(existingSubjectAreaNameSet.contains(c.Name)){
					c.addError('A subject area with that name has already been created. Please verify your data.');
				}
			}
		}
	}

	public static List <Course__c> getCoursesByKeys(Set <String> courseKeys){
		List <Course__c> courseList = new List <Course__c>();
		for (Course__c c: [select id, reference_id__c from Course__c where reference_id__c in:courseKeys]){
			courseList.add(c);
		}
		return courseList;
	}

	public static void errorHandling(Exception e, Map<Id, Course__c> oldMap, string sObjectName, string context){
		string linkString;
		for(Course__c c : oldMap.values()){
			if(linkString == null){
				linkString = string.valueOf(c.Name) + ',' + string.valueOf(c.id);
			}
			else{
				linkString = linkString + ';' + string.valueOf(c.Name) + ',' + string.valueOf(c.id);
			}
		}
		Global_Error__c ge = Error_Handling.handleError(linkString, sObjectName, context, e);
		insert ge;
	}

	public static List<Course_Weightings__c> createCourseWeightings(Course__c c){
		resetReportingPeriodValueMap();
		List <Course_Weightings__c> tempCwList = new List <Course_Weightings__c>();
		decimal iSize = c.number_of_reporting_periods__c * (c.Has_Final_Grade__c == true ? 2 : 1);
		decimal iPer = 100/iSize;
		integer iNumRp = integer.valueOf(c.number_of_reporting_periods__c);
		system.debug('rpValueMap'+rpValueMap);

		Picklist_Value__c plv = rpValueMap.get(iNumRp);

		system.debug('plv~~~'+plv);
		for (Integer k=1; k<= iNumRp; k++){
			tempCwList.add(new Course_Weightings__c (Key__c=string.valueOf(k), Course__c=c.id, Weighting__c=iPer, Reporting_Period_Type__c=plv.id));
			if (c.Has_Final_Grade__c) tempCwList.add(new Course_Weightings__c (Key__c=string.valueOf(k)+'-Final', Course__c=c.id, Weighting__c=iPer, Reporting_Period_Type__c=plv.id));
		}
		//no call to update section grades; no need sections shouldnt have been created yet
		return tempCwList;
	}

	public static void insertWeightings(Map <Id, Course__c> newMap){
		List <Course_Weightings__c> csList = new List <Course_Weightings__c>();
		Map <Id, String> tempRtMap = getCourseRtMap();
		for (Course__c c: newMap.values()){
			if (tempRtMap.get(c.RecordtypeId)=='Course'){
				csList.addAll(createCourseWeightings(c));
			}
		}
		try {
			insert csList;
			system.debug('csList~~~~'+csList);
		}
		catch (Exception e){ errorHandling(e, newMap, 'Course', 'Course trigger: insert new weightings' );}
	}
}
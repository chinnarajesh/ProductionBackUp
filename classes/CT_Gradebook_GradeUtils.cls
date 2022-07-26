/*
	Developer's Notes:
	We are going to modify this file to perform the grade validation and operations.
	This class will need to know the gradeScale Maps and normalizations.  This will 
	deal with all types of grades: assignment grades, section grades, and final grades
	
	More Notes:
	Midpoint - applies upon assignment grade entry for category C/NC, Default, Faux Grades and NOT Points, 0-100.
	This is also applied to section and final grade overrides.
	
*/

public class CT_Gradebook_GradeUtils {
	//Notes: the assignmentGradeScaleWrapper matters during the beforeUpdate trigger state.  We use this scale to validate 
	//the user's grade entry and set the appropriate wgv on grade records.
	public AssignmentGradeScaleWrapper defaultAssignmentFinalGradeScale = new AssignmentGradeScaleWrapper();
	
	//ID -> picklist_Value__c aka gradescaleID
	public Map<ID, AssignmentGradeScaleWrapper> assignmentGradeScales = new Map<ID, AssignmentGradeScaleWrapper>();
	
	//Notes: the courseGradeScaleWrapper matter during the afterUpdate trigger state.  We use this scale to aid in the 
	//section grade calculations based off the grade scale on courses.  
	public CourseGradeScaleWrapper defaultCourseFinalGradeScale = new CourseGradeScaleWrapper();
	
	//ID -> Course__c
	public Map<ID, CourseGradeScaleWrapper> courseGradeScales = new Map<ID, CourseGradeScaleWrapper>();
	
	public Set<String> overrideValues = new Set<String>();

	public Grade_Normalization__c getNormalizationRecord(ID courseID, Decimal sGrade){
		Grade_Normalization__c gn;
		if(courseID != null){
			if(courseGradeScales.containsKey(courseID)){
				gn = courseGradeScales.get(courseID).getNormalizationRecord(sGrade);
			} else {
				CT_Error_Handling.schoolForceException e = new CT_Error_Handling.schoolForceException('Unable to find grade scales for course '+courseID+'. Please check that the grade scale lookup is set for this course.');
				insert CT_Error_Handling.handleError(courseID, 'CT_Gradebook_GradeUtils.getNormalizationRecord', e);
				throw e;
			}
		}
		if(gn == null){
			gn = defaultCourseFinalGradeScale.getNormalizationRecord(sGrade);
		}
		return gn;
	}
	
	public class AssignmentGradeScaleWrapper {
		public Picklist_Value__c gradeScale {get; set;}
		public Map<String, Grade_Normalization__c> normalizations = new Map<String, Grade_Normalization__c>();
		public Map<Grade_Normalization__c, Decimal> midPointMap = new Map<Grade_Normalization__c, Decimal>();
		
		public AssignmentGradeScaleWrapper() {}
		public AssignmentGradeScaleWrapper(Picklist_Value__c pv) {
			gradeScale = pv;
		}
		
		//this method will only work if we put validation on grade scale normalizations when generating grade scales.
		//We need to guarantee that there is no duplicate entries in the grade scale i.e. 1.0 -> XXX, 1.00 -> XXY
		public String doesContainsKey(String EnteredGrade) {
			//try decimal conversion
			Decimal d = decimal.valueOf(EnteredGrade);
			for(String s : normalizations.KeySet()) {
				if(decimal.valueOf(s) == d) {
					return s;
				}
			}
			return null;
		}
	}
	
	public class CourseGradeScaleWrapper {
		public Picklist_Value__c gradeScale {get; set;}
		public Boolean usePercentage {get; set;}
		public Map<Decimal, Grade_Normalization__c> normalizations = new Map<Decimal, Grade_Normalization__c>();
		public Map<String, Grade_Normalization__c> representationNormalizations = new Map<String, Grade_Normalization__c>();
		public Map<Grade_Normalization__c, Decimal> midPointMap = new Map<Grade_Normalization__c, Decimal>();
		public Map<ID, Decimal> assignmentTypePercentageWeightings = new Map<ID, Decimal>();
		public Boolean GPA_Multi_Added_VP {get; set;}
		public Decimal GPA_Added_VP {get; set;}
		public Decimal creditHour {get; set;}
		
		public CourseGradeScaleWrapper() {}
		public CourseGradeScaleWrapper(Picklist_Value__c pv) {
			gradeScale = pv;
		}
		
		public Grade_Normalization__c getNormalizationRecord(Decimal sGrade) {
			sGrade = (sGrade*100).divide(100,2);
			system.debug('*~*~* sGrade: ' + sGrade);
			try {
				//normalize the value to the hundreth decimal
				Decimal closestKey;
				system.debug('*~*~* grade scale: ' + gradeScale);
				for(Decimal d : normalizations.KeySet()) {
					if(d <= sGrade && closestKey == null) {
						closestKey = d;
					}
					else if(d <= sGrade  && closestKey != null) {
						if((sGrade - d).abs() < (sGrade - closestKey).abs()) {
							closestKey = d;
						}
					}
				}			
				system.debug('*~*~* closestKey: ' + closestKey);
				return normalizations.get(closestKey);
			}
			catch(Exception e) {
				e.setMessage('Gradescale does not have a normalization for this grade: ' + sGrade);
				return null;
			}
		}
	}
	
	public class aggregateResults {
		public String Key {get; set;}
		public ID studentSection {get; set;}
		public ID course {get; set;}
		public ID reportingPeriod {get; set;}
		public Set<Grade__c> grades = new Set<Grade__c>();
		public Boolean overridden {get; set;}
		
		//used simply as a utility value holder, typically for the section grade of the aggregate.
		public Decimal gradePlaceHolder {get; set;}
		
		//non-percentage
		public Decimal wgv_sum;
		public Decimal sta_sum;
		public Decimal aw_sum;
		public Decimal gn_sum;
		public Decimal pp_sum;		
		
		//percentages
		Map<ID, List<Decimal>> assignmentTypeToSum = new Map<ID, List<Decimal>>();
		
		public aggregateResults() {}
		
		public void sum(Grade__c g, CourseGradeScaleWrapper cgs) {
			if(g.Valid_Grade__c) {
				if(!cgs.usePercentage) {
					if(cgs.gradeScale.Category__c == 'Points') {
						if(pp_sum != null) {
							pp_sum += g.Possible_Points__c;
						}
						else {
							pp_sum = g.Possible_Points__c;
						}
						
						if(gn_sum != null) {
							gn_sum += g.Grade_Number__c;
						}
						else {
							gn_sum = g.Grade_Number__c;
						}
					}
					else if(cgs.gradeScale.Category__c == 'Standards') {
						if(wgv_sum != null) {
							wgv_sum += g.Weighted_Grade_Value__c;
						}
						else {
							wgv_sum = g.Weighted_Grade_Value__c;
						}
						
						if(sta_sum != null) {
							sta_sum += g.Standard_Times_Assignment__c;
						}
						else {
							sta_sum = g.Standard_Times_Assignment__c;
						}
					}
					else if(cgs.gradeScale.Category__c == 'Default' ||
							cgs.gradeScale.Category__c == 'Credit/No Credit' ||
							cgs.gradeScale.Category__c == '0-100') {
						if(wgv_sum != null) {
							wgv_sum += g.Weighted_Grade_Value__c;
						}
						else {
							wgv_sum = g.Weighted_Grade_Value__c;
						}
						
						if(aw_sum != null) {
							aw_sum += g.Assignment_Weighting__c;
						}
						else {
							aw_sum = g.Assignment_weighting__c;
						}
					}
				}
				else {  //wrong below
					if(cgs.gradeScale.Category__c == 'Points') {
						if(!assignmentTypeToSum.containsKey(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)) {
							List<Decimal> percentSum = new List<Decimal>();
							percentSum.add(decimal.valueOf(g.Entered_Grade__c) * 100);
							percentSum.add(g.Possible_Points__c);
							assignmentTypeToSum.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, percentSum);
						}
						else {
							assignmentTypeToSum.get(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)[0] += decimal.valueOf(g.Entered_Grade__c)*100;
							assignmentTypeToSum.get(g.Assignment__r.Assignment_Library__r.Picklist_value__c)[1] += g.Possible_Points__c;
						}
					}
					else if(cgs.gradeScale.Category__c == 'Standards') {
						if(!assignmentTypeToSum.containsKey(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)) {
							List<Decimal> percentSum = new List<Decimal>();
							percentSum.add(g.Weighted_Grade_Value__c);
							percentSum.add(g.Standard_Times_Assignment__c);
							assignmentTypeToSum.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, percentSum);
						}
						else {
							assignmentTypeToSum.get(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)[0] += g.Weighted_Grade_Value__c;
							assignmentTypeToSum.get(g.Assignment__r.Assignment_Library__r.Picklist_value__c)[1] += g.Standard_Times_Assignment__c;
						}
					}
					else if(cgs.gradeScale.Category__c == 'Default' ||
							cgs.gradeScale.Category__c == 'Credit/No Credit' ||
							cgs.gradeScale.Category__c == '0-100') {
						if(!assignmentTypeToSum.containsKey(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)) {
							List<Decimal> percentSum = new List<Decimal>();
							percentSum.add(g.Weighted_Grade_Value__c);
							percentSum.add(g.Assignment_Weighting__c);
							assignmentTypeToSum.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, percentSum);
						}
						else {
							assignmentTypeToSum.get(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)[0] += g.Weighted_Grade_Value__c;
							assignmentTypeToSum.get(g.Assignment__r.Assignment_Library__r.Picklist_value__c)[1] += g.Assignment_Weighting__c;
						}					
					}
				}
			}
			grades.add(g);
		}
		
		public Decimal calculateSectionGrade(CourseGradeScaleWrapper cgs) {
			Decimal returnValue;
			try {
				if(!overridden) {
					if(!cgs.usePercentage) {
						if(cgs.gradeScale.Category__c == 'Points') {
							if(gn_sum != null && pp_sum != null && pp_sum != 0) {
								returnValue = gn_sum.divide(pp_sum, 2) * 100;
								system.debug('*~*~* calculateSectionGrade: Category Points: ' + returnValue);
							}
						}
						else if(cgs.gradeScale.Category__c == 'Standards') {
							if(wgv_sum != null && sta_sum != null && sta_sum != 0) {
								returnValue = wgv_sum.divide(sta_sum, 2);
								system.debug('*~*~* calculateSectionGrade: Standards: ' + returnValue);
							}
						}
						else if (cgs.gradeScale.Category__c == 'Default' ||
								 cgs.gradeScale.Category__c == 'Credit/No Credit' ||
								 cgs.gradeScale.Category__c == '0-100') {
							if(wgv_sum != null && aw_sum != null && aw_sum != 0) {
								returnValue = wgv_sum.divide(aw_sum, 2);
								system.debug('*~*~* calculateSectionGrade: Default, Credit/No Credit, 0-100: ' + returnValue);
							}
						}
					}
					else {
						Decimal totalGrade = 0;
						Decimal totalWeightings = 0;
						
						for(ID pv : assignmentTypeToSum.KeySet()) {
							List<Decimal> value = assignmentTypeToSum.get(pv);
							totalGrade += (value[0]/value[1])*cgs.assignmentTypePercentageWeightings.get(pv);
							totalWeightings += cgs.assignmentTypePercentageWeightings.get(pv);
						}
						returnValue = totalWeightings != 0 ? (totalGrade.divide(totalWeightings,2) > 100 ? 100.00 : totalGrade.divide(totalWeightings,2)) : null;
					}
					
					returnValue = returnValue > 100 ? 100.00 : returnValue;
				}
			}
			catch(Exception e) {
				e.setMessage('Failed to calculate the sectionGrade for studentSection: ' + studentSection);
			}
			return returnValue;
		} 
		
		public Section_Grade__c createCalculatedSectionGrade(CourseGradeScaleWrapper cgs, CourseGradeScaleWrapper defaultCGS, Decimal sGrade) {
			Section_Grade__c sg = new Section_Grade__c(Student_Section__c = studentSection, 
														Reference_ID__c = Key,
														Key__c = string.valueOf(studentSection) + string.valueOf(reportingPeriod),
														Time__c = reportingPeriod );			
			Decimal weightedGPAValue;
			Grade_Normalization__c gn;
			
			if(sGrade != null) {
				gn = cgs.getNormalizationRecord(sGrade);
				if(gn == null) {
					try {
						gn = defaultCGS.getNormalizationRecord(sGrade);	
					}
					catch(Exception e) {
						e.setMessage('cannot find a normalization for sGrade: ' + sGrade);
						system.debug('*~*~* cannot find a default grade normalization for sGrade: ' + sGrade);
					}
				}
				try {
					if(gn.GP_Value__c != null) {
						if(cgs.GPA_Added_VP == null) {
							cgs.GPA_Added_VP = 0.0;
						}
						
						if(cgs.GPA_Multi_Added_VP) {
							weightedGPAValue = gn.GP_Value__c * cgs.GPA_Added_VP;
						}
						else {
							weightedGPAValue = gn.GP_Value__c + cgs.GPA_Added_VP;
						}
					}
					
					sg.Letter_Grade__c = gn.transformed_Grade__c;
					sg.Section_GPA__c = gn.GP_Value__c;
					sg.Section_Weighted_GPA__c = weightedGPAValue;
					sg.Grade__c = sGrade;
				}
				catch(Exception e) {
					e.setMessage('Failed to create the section grade record for studentSection: ' + studentSection);
				}
			}
			else {
				sg.Letter_Grade__c = null;
				sg.Section_GPA__c = null;
				sg.Section_Weighted_GPA__c = null;
				sg.Grade__c = null;
			}
			
			system.debug('*~*~* sg: ' + sg);
			return sg;
		}
	}
	
	public Boolean bAssignmentGradeScalesEmpty() {
		return assignmentGradeScales.isEmpty();
	}
	
	public Boolean bCourseGradeScalesEmpty() {
		return courseGradeScales.isEmpty();
	}
	
	public void setAssignmentGradeScales(List<Grade__c> grades) {
		Set<ID> gradeScaleIDs = new Set<ID>();
		//create the keys first
		for(Grade__c g: grades) {
			if(g.Grading_Type__c != null) {
				gradeScaleIDs.add(g.Grading_Type__c);
			}
			if(!assignmentGradeScales.containsKey(g.Grading_Type__c) && g.Grading_Type_RT__c=='Grade_Scale') {
				assignmentGradeScales.put(g.Grading_Type__c, new AssignmentGradeScaleWrapper(
						new Picklist_Value__c(
							Id=g.Grading_Type__c, 
							Category__c=g.Grading_Type_Category__c, 
							Name=g.Grading_Type_Name__c
					)));
			}
		}

		List<Grade_Normalization__c> gns = [SELECT ID, Is_Max_Value__c, Grade_Value__c, GP_Value__c, Transformed_Grade__c, Picklist_Value__c FROM Grade_Normalization__c WHERE GP_Value__c != NULL AND (Picklist_Value__c IN: gradeScaleIDs OR Picklist_Value__c = NULL) ORDER BY Picklist_Value__c, Grade_Value__c ASC];
		for(Integer i = 0; i < gns.size(); i++) {
			if(assignmentGradeScales.containsKey(gns[i].Picklist_Value__c)) {
				//going to used the transformed grade: the transformed grade is the value entered in gradebook.
				//used to store the grade_value__c as the key, but this is only useful when calculating the section grade normalization range
				assignmentGradeScales.get(gns[i].Picklist_Value__c).normalizations.put(gns[i].Transformed_Grade__c, gns[i]);

				Decimal firstGradeValue = gns[i].Grade_Value__c;
				//DE3479 need to check if next normalization is for the same grade scale
				if(i + 1 < gns.size() && gns[i].Picklist_Value__c == gns[i+1].Picklist_Value__c) {
					firstGradeValue = (firstGradeValue + gns[i+1].Grade_Value__c).divide(2,2);
				}
				else if(i + 1 == gns.size() || gns[i].Picklist_Value__c != gns[i+1].Picklist_Value__c) {
					//assumption is, these are normalized values, last value + 100 / 2
					firstGradeValue = (firstGradeValue + 100.00).divide(2,2);
				}
				system.debug('*~*~* firstGradeValue: ' + firstGradeValue);
				assignmentGradeScales.get(gns[i].Picklist_Value__c).midPointMap.put(gns[i], firstGradeValue);
				
			}
			if(gns[i].Picklist_Value__c == NULL) {
				defaultAssignmentFinalGradeScale.normalizations.put(gns[i].Transformed_Grade__c, gns[i]);
				
				Decimal firstGradeValue = gns[i].Grade_Value__c;
				//DE3479 need to check if next normalization is for the same grade scale
				if(i + 1 < gns.size() && gns[i].Picklist_Value__c == gns[i+1].Picklist_Value__c) {
					firstGradeValue = (firstGradeValue + gns[i+1].Grade_Value__c).divide(2,2);
				}
				else if(i + 1 == gns.size() || gns[i].Picklist_Value__c != gns[i+1].Picklist_Value__c) {
					//assumption is, these are normalized values, last value + 100 / 2
					firstGradeValue = (firstGradeValue + 100.00).divide(2,2);
				}
				system.debug('*~*~* firstGradeValue: ' + firstGradeValue);
				defaultAssignmentFinalGradeScale.midPointMap.put(gns[i], firstGradeValue);			
			}
		}
	}

	public void setCourseGradeScalesFromSObject(List<sObject> objects) {
		//create gradescaleToCourse set
		Set<String> allowedObjects = new Set<String>{'Section_Grade__c', 'Final_Grade__c', 'Grade__c', 'Course__c'};
		String sObjectType = objects.getSObjectType().getDescribe().getName();
		if(!objects.isEmpty() && !allowedObjects.contains(sObjectType)){
			objects[0].addError('setCourseGradeScalesFromSectionGrade: Type of object is denied.');
		}

		Map<Id, Set<Id>> gradeScaleToCourse = new Map<ID, Set<Id>>();
		Set<Id> courseIds = new Set<Id>();
		for(sObject o : objects){
			Id courseId = (Id)o.get('Course_Id__c');
			Id gradeScaleId = (Id)o.get('Grade_Scale_Id__c');
			String gradeScaleRT = (String)o.get('Grade_Scale_RT__c');
			String gradeScaleName = (String)o.get('Grade_Scale_Name__c');
			String gradeScaleCategory = (String)o.get('Grade_Scale_Category__c');
			Boolean useAssignment = (Boolean)o.get('Use_Assignment_Type_Percentages__c');
			Boolean multiplyGPA = (Boolean)o.get('Multiply_GPA_Added_Value_Points__c');
			Decimal gpaAdded = (Decimal)o.get('GPA_Added_Value_Points__c');
			Decimal creditHours = (Decimal)o.get('Credit_Hours__c');
			if(courseId != null){
				if(!gradescaleToCourse.containsKey(gradeScaleId)){
					gradeScaleToCourse.put(gradeScaleId, new Set<Id>());
				}
				gradescaleToCourse.get(gradeScaleId).add(courseId);
				courseIds.add(courseId);
			}

			if(!courseGradeScales.containsKey(courseId) && gradeScaleRT=='Grade_Scale'){
				CourseGradeScaleWrapper t = new CourseGradeScaleWrapper( new Picklist_Value__c(
					Id=gradeScaleId, Name=gradeScaleName, Category__c=gradeScaleCategory));
				t.usePercentage = useAssignment;
				t.GPA_Multi_Added_VP = multiplyGPA;
				t.GPA_Added_VP = gpaAdded;
				t.creditHour = creditHours;
				courseGradeScales.put(courseId, t);
			}
		}

		if(!courseIds.isEmpty()){
			setCourseGradeScales(courseIds, gradeScaleToCourse);
		}
	}

	public void setCourseGradeScales(Set<Id> courseSet, Map<ID, Set<Id>> gradeScaleToCourse) {
		List<Grade_Normalization__c> gns = [SELECT ID, Is_Max_Value__c, Grade_Value__c, GP_Value__c, Transformed_Grade__c, Picklist_Value__c FROM Grade_Normalization__c WHERE GP_Value__c != NULL AND (Picklist_Value__c IN: gradeScaleToCourse.KeySet() OR Picklist_Value__c = NULL) ORDER BY Picklist_Value__c, Grade_Value__c ASC];
		for(Integer i = 0; i < gns.size(); i++){
			Grade_Normalization__c gn = gns[i];

			Decimal firstGradeValue = gn.Grade_Value__c;
			//DE3479 need to check if next normalization is for the same grade scale
			if(i + 1 < gns.size() && gn.Picklist_Value__c == gns[i+1].Picklist_Value__c) {
				firstGradeValue = (firstGradeValue + gns[i+1].Grade_Value__c).divide(2,2);
			} else if(i + 1 == gns.size() || gn.Picklist_Value__c != gns[i+1].Picklist_Value__c) {
				//assumption is, these are normalized values, last value + 100 / 2
				firstGradeValue = (firstGradeValue + 100.00).divide(2,2);
			}
			system.debug('*~*~* firstGradeValue: ' + firstGradeValue);

			if(gn.Picklist_Value__c != null){
				for(Id course: gradeScaleToCourse.get(gn.Picklist_Value__c)){
					CourseGradeScaleWrapper cgsw = courseGradeScales.get(course);
					if(cgsw != null){
						//going to used the grade_value__c: the grade value is the normalization of the row.
						//used to store the grade_value__c as the key, but this is only useful when calculating the section grade normalization range
						cgsw.normalizations.put(gn.Grade_Value__c, gn);
						cgsw.representationNormalizations.put(gn.Transformed_Grade__c, gn);
						cgsw.midPointMap.put(gn, firstGradeValue);
					} else {
						system.debug('The course exists in the grade scale to course map, but not in the course to grade scale wrapper map? What is this magic?');
					}
				}
			} else {
				defaultCourseFinalGradeScale.normalizations.put(gn.Grade_Value__c, gn);
				defaultCourseFinalGradeScale.representationNormalizations.put(gn.Transformed_Grade__c, gn);
				defaultCourseFinalGradeScale.midPointMap.put(gn, firstGradeValue);
			}
		}
		
		//need optim
		for(Default_Assignment_Weighting__c daw : [Select ID, Picklist_Value__c, Percent_Of_Section_Grade__c, Course__c, Section__c from Default_Assignment_Weighting__c where (Course__c IN: courseSet AND Section__c != null) OR (Course__c IN: courseSet AND Section__c = null) ]){
			if(courseGradeScales.containsKey(daw.Course__c)) {
				//does not contain a mapping at all, simply insert the first one
				if(!courseGradeScales.get(daw.Course__c).assignmentTypePercentageWeightings.containsKey(daw.Picklist_Value__c)) {
					courseGradeScales.get(daw.Course__c).assignmentTypePercentageWeightings.put(daw.Picklist_Value__c, daw.Percent_Of_Section_Grade__c);
				} 
				else if(courseGradeScales.get(daw.Course__c).assignmentTypePercentageWeightings.containsKey(daw.Picklist_Value__c)) {
					//always use the section one if available
					if(daw.Section__c != null) {
						courseGradeScales.get(daw.Course__c).assignmentTypePercentageWeightings.put(daw.Picklist_Value__c, daw.Percent_Of_Section_Grade__c);
					}
				}  
			}
		}
	}	
	
	public void setOverrideValues() {
		OverrideSettings__c OS = OverrideSettings__c.getInstance(UserInfo.getUserID());
		if(OS == null) {
			OS = OverrideSettings__c.getInstance(UserInfo.getProfileID());
		}
		if(OS == null) {
			OS = OverrideSettings__c.getOrgDefaults();
		}
		
		if(OS != null) {
			if(String.isNotEMPTY(OS.Allowable_Grades__c)) {
				for(String s : OS.Allowable_Grades__c.split(',')) {
					overrideValues.add(s.trim());
				}
			}
		}
	}
	
	//requires setAssignmentGradeScales() && setOverrideValues()
	public void validateGrade(Grade__c g) {
		system.debug('*~*~* g: ' + g);
		//setting the state of the grade record based on related fields
		try {
			g.Valid_Grade__c = g.Entered_Grade__c != null && (!overrideValues.contains(g.Entered_Grade__c)) ? true : false;
			g.Points_Grade__c = g.Possible_Points__c != null && g.Possible_Points__c > 0 && g.Standard__c == null;
			g.Grade_With_Standard__c = g.Standard__c != null;
			g.Faux_Grade__c = g.Standard_Gradebook_Grade__c != null;
			
			//set calculated values
			if(g.Standard__c != null && g.Standard_Weighting__c == null) {
				g.Standard_Weighting__c = 1;  //set a default
			}
			if(g.Assignment_Weighting__c != null && g.Standard_Weighting__c != null) {
				g.Standard_Times_Assignment__c = g.Assignment_Weighting__c * g.Standard_Weighting__c;
			}
		}
		catch(Exception e) {
			g.addError('Cannot set base state of grade record ' + g.ID);
			system.debug('addError - Cannot set base state of grade record:' + g.ID);
		}
		
		
		//overrides and null entries do not need assignment weightings yet.  assignment weightings are only important on calculation
		if(g.Entered_Grade__c == null || overrideValues.contains(g.Entered_Grade__c)) {
			g.Weighted_Grade_Value__c = null;
			g.Grade_Number__c = null;
		}		
		//no assumption on assignment_Weighting__c, throw an error below
		else if(g.Entered_Grade__c != null && g.Assignment_weighting__c != null) {
			if(assignmentGradeScales.containsKey(g.Grading_Type__c)) {
				Picklist_Value__c currentGradeScale = assignmentGradeScales.get(g.Grading_Type__c).gradeScale;
				try {
					if(currentGradeScale.Category__c == 'Default' || currentGradeScale.Category__c == 'Credit/No Credit') {
						Grade_Normalization__c gn = assignmentGradeScales.get(g.Grading_Type__c).normalizations.get(g.Entered_Grade__c);
						g.Grade_Number__c = assignmentGradeScales.get(g.Grading_Type__c).midPointMap.get(gn);
						g.Weighted_Grade_Value__c = g.Grade_Number__c * g.Assignment_Weighting__c;
					}
					else if(currentGradeScale.Category__c == '0-100') {
						try {
							g.Grade_Number__c = g.Entered_Grade__c == null ? null : decimal.valueOf(g.Entered_Grade__c);
						}
						catch(Exception e) {
							g.addError('You have entered an invalid character into the highlighted cell(s). Remove the invalid character and press the Submit Grades button again.');
						}
						g.Weighted_Grade_Value__c = decimal.valueOf(g.Entered_Grade__c) * g.Assignment_Weighting__c;
					}
					else if(currentGradeScale.Category__c == 'Points') {
						if(g.Possible_Points__c != 0) {
							try {
								g.Grade_Number__c = g.Entered_Grade__c == null ? null : decimal.valueOf(g.Entered_Grade__c);	
							}
							catch(Exception e) {
								g.addError('You have entered an invalid character into the highlighted cell(s). Remove the invalid character and press the Submit Grades button again.');
							}
							g.Weighted_Grade_Value__c = (decimal.valueOf(g.Entered_Grade__c) / g.Possible_Points__c * 100) * g.Assignment_Weighting__c;
						}
						else {
							g.addError('Possible Points cannot be 0!');
							system.debug('addError - Possible Points cannot be 0!');
						}
					}
					//note: even the faux grades gradingtypeID is the same as the standards grade scale.
					else if(currentGradeScale.Category__c == 'Standards') {						
						try {
							//need to throw different error, we require these to be decimal values for now
							g.Grade_Number__c = decimal.valueOf(g.Entered_Grade__c);
							String tKey;
							try {
								tKey = assignmentGradeScales.get(g.Grading_Type__c).doesContainsKey(g.Entered_Grade__c);
								if(tKey != null) {
									Grade_Normalization__c gn = assignmentGradeScales.get(g.Grading_Type__c).normalizations.get(tKey);
									g.Grade_Number__c = assignmentGradeScales.get(g.Grading_Type__c).midPointMap.get(gn);
								}
								else {
									Grade_Normalization__c gn = assignmentGradeScales.get(g.Grading_Type__c).normalizations.get(g.Entered_Grade__c);
									system.debug('*~*~* standards gn: ' + gn);
									g.Grade_Number__c = assignmentGradeScales.get(g.Grading_Type__c).midPointMap.get(gn);
									if(g.Grade_Number__c == null) {
										g.addError('Entered grade \'' + g.Entered_Grade__c + '\' is not a representation in the grade scale \'' + currentGradeScale.Name + '\' ');
									}
									system.debug('*~*~* standards gNumber: ' + g.Grade_Number__c);
								}
							}
							catch(Exception e) {
								g.addError('Entered grade \'' + g.Entered_Grade__c + '\' is not a representation in the grade scale \'' + currentGradeScale.Name + '\' ');
								system.debug('doesContainsKey returned \'' + tKey + '\'; grade ' + g);
							}
							
							//still need to validate if in scale, reset the value
							if(g.Standard_Gradebook_Grade__c == null && g.Standard__c != null && g.Grade_With_Standard__c) {
								g.Grade_Number__c = decimal.valueOf(g.Entered_Grade__c);
							}							
						}
						catch(Exception e) {
							//g.addError('For a Standard Grade Scale the entered values must be of a numeric value.  Please consult your administrator in correcting this standard grade scale table. Entered Grade ' + g.Entered_Grade__c + ' (' + g.ID + ')');
							g.addError('You have entered an invalid character into the highlighted cell(s). Remove the invalid character and press the Submit Grades button again.');
						}
						
	
						g.Weighted_Grade_Value__c = g.Grade_Number__c * g.Standard_Times_Assignment__c;
					}
				}
				catch(Exception e) {
					g.addError('Entered Grade ' + g.Entered_Grade__c + ' (' + g.ID + ') is not a valid entry for Gradescale ' + currentGradeScale.Name);	
					system.debug('addError - The Entered Grade is not a valid entry for this ' + currentGradeScale.Category__c + ' category; Gradescale: ' + currentGradeScale.Name + ' grade: ' + g);
				}
			}
			else {
				g.addError('Unexpected Gradescale on grade record ' + g.ID);
				system.debug('addError - Unexpected Gradescale on grade record: ' + g);
			}
		}
		else if(g.Assignment_Weighting__c == null){
			g.addError('The Assignment Weighting is null');
			system.debug('addError - The Assignment Weighting is null; grade: ' + g);
		}
	}
	
	//requires setCourseGradeScales() && setOverrideValues()
	public List<Section_Grade__c> aggregateGrades(List<Grade__c> grades) {
		Map<String, aggregateResults> studentAggregateResults = new Map<String, aggregateResults>();
		List<Section_Grade__c> returnList = new List<Section_Grade__c>();
		
		//inefficiency: must get sg overrides, the CT_Gradebook_SoqlUtils is single RP specific. for now
		//just get it here
		Map<String, Boolean> getSGOverrides = new Map<String, Boolean>();
		for(Grade__c g: grades){
			Boolean t;
			String key = String.valueOf(g.Student_Section__c) + '-' + String.valueOf(g.Time__c);
			getSGOverrides.put(key, t);
		}
		
		for(Section_Grade__c sg : [SELECT ID, Reference_ID__c, Grade_Overridden__c FROM Section_Grade__c WHERE Reference_ID__c IN: getSGOverrides.KeySet()]) {
			if(getSGOverrides.containsKey(sg.Reference_ID__c)) {
				getSGOverrides.put(sg.Reference_ID__c, sg.Grade_Overridden__c);
			}
		}
		
		for(Grade__c g: grades){			
			//start of for loop logic: above is long query
			//generate the reference ID Key: studentSectionID + '-' + reportingPeriodID
			if(g.Assignment__c != null && g.Course__c != null && g.Exclude_From_Section_Grade__c != true && 
					((g.Faux_Grade__c == true && g.Standard_Gradebook_Grade__c != null) || g.Standard__c == null)){
				if(courseGradeScales.containsKey(g.Course__c) ) {
					//Note: this key is the same as the reference ID on section grades.
					String Key = g.Student_Section__c + '-' + g.Time__c;
					if(!studentAggregateResults.containsKey(Key)) {
						aggregateResults t = new aggregateResults();
						t.Key = Key;
						t.studentSection = g.Student_Section__c;
						t.course = g.Course__c;
						t.reportingPeriod = g.Time__c;
						t.sum(g, courseGradeScales.get(g.Course__c));
						studentAggregateResults.put(Key, t);
						if(getSGOverrides.containsKey(Key)) {
							if(getSGOverrides.get(Key) != null) {
								t.overridden = getSGOverrides.get(Key);
							}
						}
					}else {
						studentAggregateResults.get(Key).sum(g, courseGradeScales.get(g.Course__c));
					}
				}else {
					system.debug('addError - Grade record course lookup is not associated to the Coruse the section is for; grade: ' + g);
					g.addError('Grade record Course lookup is not associated to the Course the section is for ' + g.ID);
				}
			}
		}
		
		//create the section grades
		for(aggregateResults ar : studentAggregateResults.Values()) {
			if(!ar.overridden) {
				CourseGradeScaleWrapper passCGSW = courseGradeScales.get(ar.course);
				Decimal passSG = ar.calculateSectionGrade(passCGSW);
				returnList.add(ar.createCalculatedSectionGrade(passCGSW, defaultCourseFinalGradeScale, passSG));
			}
		}
		
		return returnList;
	}

	//DEAL with Final grades?  Make separate file? not sure, not enough time
	
	//setCourseGradeScales() && setOverrideValues()
	public void FG_processOverride(List<Final_Grade__c> newList) {
		for(Final_Grade__c fg : newList) {
			if(overrideValues.contains(fg.Grade_Override__c)) {
				fg.Grade_Overridden__c = true;
				fg.Final_Grade_Letter_v2__c = fg.Grade_Override__c;
				fg.Unweighted_GPA__c = NULL;
				fg.Weighted_GPA__c = NULL;
				fg.Final_GPA_Value__c = NULL;
				fg.Total_GPA_Credit_Value__c = NULL;
				fg.Total_Weighted_GPA_Credit_Value__c = NULL;
				fg.Final_Grade_Value__c = NULL;
			} else {
				if(fg.Course__c != null) {
					if(courseGradeScales.containsKey(fg.Course__c)) {
						try {
							Grade_Normalization__c gn;
							
							try {
								gn = courseGradeScales.get(fg.Course__c).representationNormalizations.get(fg.Grade_Override__c);
							}
							catch(Exception e) {
								gn = courseGradeScales.get(fg.Course__c).getNormalizationRecord(Decimal.valueOf(fg.Grade_Override__c));
							}
							if(gn == null) {
								try {
									gn = defaultCourseFinalGradeScale.representationNormalizations.get(fg.Grade_Override__c);
								}
								catch(Exception e) {
									gn = defaultCourseFinalGradeScale.getNormalizationRecord(Decimal.valueOf(fg.Grade_Override__c));
								}
							}
							
							//apply the midpoint  used to be gn.Grade_Value__c
							Decimal sGrade = gn.Grade_Value__c > 100 ? 100.00 : courseGradeScales.get(fg.Course__c).midPointMap.get(gn);
							fg.Grade_Overridden__c = TRUE;
							fg.Final_Grade_Value__c = sGrade;
							fg.Final_Grade_Letter_v2__c = gn.Transformed_Grade__c;
							fg.Final_GPA_Value__c = gn.GP_Value__c;
							fg.Unweighted_GPA__c = gn.GP_Value__c;  //huh?
							fg.Course_Credits__c = courseGradeScales.get(fg.Course__c).creditHour;
						}
						catch(Exception e) {
							fg.addError('there is not a grade normalization on grade scale ' + courseGradeScales.get(fg.Course__c).gradeScale.Name + ' for this override ' + fg.Grade_Override__c);
						}
					}
					else {
						fg.addError('There is an issue on the grade scale for this course \'' + fg.Course__c + '\' for this final grade \'' + fg.ID + '\'');
					}
				}
				else {
					fg.addError('final grade does not have a course lookup \'' + fg.ID + '\'');
				}		
			}
		}
	}
	
	//setCourseGradeScales() && setOverrideValues()
	public void SG_processBeforeUpdate(Map<ID, Section_Grade__c> newMap, Map<ID, Section_Grade__c> oldMap) {
		//why don't we have the course lookup on section grade????
		for(Section_Grade__c sg : newMap.Values()) {
			if(sg.Grade_Override__c != oldMap.get(sg.ID).Grade_Override__c) {
				if(String.isEmpty(sg.Grade_Override__c)) {
					sg.Grade_Overridden__c = false;
				}
				else {
					//need validation to ensure that grade scale does not contain an override key value as the representation!
					if(overrideValues.contains(sg.Grade_Override__c)) {
						sg.Grade_Overridden__c = true;
						sg.Letter_Grade__c = sg.Grade_Override__c;
						sg.Section_GPA__c = null;
						sg.Section_Weighted_GPA__c = null;
						sg.Grade__c = null;						
					}
					//try to calculate since it was not in the override setting
					else {
						try {
							String cKey = sg.Course_Id__c;
							if(courseGradeScales.containsKey(cKey)) {
								CourseGradeScaleWrapper cgs = courseGradeScales.get(cKey);
								Grade_Normalization__c gn;
								try {
									try {
										gn = cgs.representationNormalizations.get(sg.Grade_Override__c);
									}
									//sg.Grade_Override__c is not a decimal
									catch(Exception e) {
										gn = cgs.getNormalizationRecord(Decimal.valueOf(sg.Grade_Override__c));
									}
									//attempt to use the default
									if(gn == null) {
										try {
											gn = defaultCourseFinalGradeScale.representationNormalizations.get(sg.Grade_Override__c);
										}
										catch(Exception e) {
											gn = defaultCourseFinalGradeScale.getNormalizationRecord(Decimal.valueOf(sg.Grade_Override__c));
										}
									}
									
									//check this, suppose to get the midpoint of the normalized score
									//sg.Grade__c = gn.Grade_Value__c;
									try {
										sg.Grade__c = cgs.midPointMap.get(gn);
									}
									catch(Exception e) {
										sg.addError('can not find midpoint for GN: ' + gn);
									}					
				
									sg.Grade_Overridden__c = true;
	
									sg.Letter_Grade__c =gn.Transformed_Grade__c;
									sg.Section_GPA__c = gn.GP_Value__c;
	
									//US1202 update the weighted gpa as well
									if(sg.Section_GPA__c != null) {
										if (cgs.GPA_Added_VP == null){
											cgs.GPA_Added_VP = 0;
										}
										if(cgs.GPA_Multi_Added_VP) {
											sg.Section_Weighted_GPA__c = sg.Section_GPA__c * cgs.GPA_Added_VP;
										}
										else {
											sg.Section_Weighted_GPA__c = sg.Section_GPA__c + cgs.GPA_Added_VP;
										}
									}
								}
								catch(Exception e) {
									sg.addError('can not find any normalization in course ' + sg.Course_Id__c + ' for section grade override \'' + sg.Grade_Override__c + '\', GN(' + gn + ')');
								}			
							}
						}
						catch(Exception e) {
							sg.addError('can not find course grade scale based on section for student grade \'' + sg + '\'');
						}
					}
				}
			}
		}
	}
	
	//Summer 2014 iteration 2: maintain old code for now.
	public void SG_processAfterUpdate(Map<ID, Section_Grade__c> newMap, Map<ID, Section_Grade__c> oldMap) {
		Set<Id> allSections = new Set<Id>();
		Set<Id> sectionGrades = new Set<Id>();
		Set<Section_Grade__c> sgOverrideSet = new Set<Section_Grade__c>();
		for(Section_Grade__c sg : newMap.values()) {
			if(sg.Grade__c != oldMap.get(sg.id).Grade__c && sg.Section_RT__c=='Published'){
				allSections.add(sg.Section_Id__c);
			}
			if (sg.Grade_Override__c!=oldMap.get(sg.id).Grade_Override__c&&sg.Grade_Overridden__c){
				sgOverrideSet.add(sg);
			}
		}

		if (!allSections.isEmpty()){
			Map<Id, Map<ID, Decimal>> sectionToGradeMap = new Map<ID, Map<ID, Decimal>>();
			Map<Id, Integer> ssTotalSGMap = new Map<ID, Integer>();
			Map<Id, Decimal> ssToPassing = new Map<ID,Decimal>();
			Map<Id, Section__c> mapSections = new Map<Id, Section__c>();

			for(Section_Grade__c sg:
					[select Student_Section__r.Section__c, Student_Section__r.Section__r.Failing__c, Student_Section__c, Grade__c,Student_Section__r.Student__r.Setup__r.Passing_Grade_Threshold__c
					from Section_Grade__c
					where Student_Section__r.Section__c IN:allSections
					and Student_Section__r.Active__c=true
					and Student_Section__r.Section__r.Active__c=true
					and Grade__c !=null]){
				if(sectionToGradeMap.containsKey(sg.Student_Section__r.Section__c)){
					if(sectionToGradeMap.get(sg.Student_Section__r.Section__c).containsKey(sg.Student_Section__c)){
						if(Trigger.newMap.containsKey(sg.id))
						sectionToGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Student_Section__c, sectionToGradeMap.get(sg.Student_Section__r.Section__c).get(sg.Student_Section__c)+newMap.get(sg.id).Grade__c);
						else
						sectionToGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Student_Section__c, sectionToGradeMap.get(sg.Student_Section__r.Section__c).get(sg.Student_Section__c)+sg.Grade__c);
						ssTotalSGMap.put(sg.Student_Section__c, ssTotalSGMap.get(sg.Student_Section__c)+1);
					} else {
						if(Trigger.newMap.containsKey(sg.id))
						sectionToGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Student_Section__c, newMap.get(sg.id).Grade__c);
						else
						sectionToGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Student_Section__c, sg.Grade__c);
						ssTotalSGMap.put(sg.Student_Section__c,1);
					}
				} else {
					sectionToGradeMap.put(sg.Student_Section__r.Section__c, new Map<ID, Decimal>{sg.Student_Section__c => sg.Grade__c});
					ssTotalSGMap.put(sg.Student_Section__c,1);
					ssToPassing.put(sg.Student_Section__r.Section__c, sg.Student_Section__r.Student__r.Setup__r.Passing_Grade_Threshold__c);
				}
				mapSections.put(sg.Student_Section__r.Section__c, new Section__c(Id=sg.Student_Section__r.Section__c, Failing__c=sg.Student_Section__r.Section__r.Failing__c));
			}
			for(Section__c s: mapSections.values()){
				Integer failing = 0;
				for(Id ss:sectionToGradeMap.get(s.id).keySet()){
					if((sectionToGradeMap.get(s.id).get(ss)/ssTotalSGMap.get(ss)) < ssToPassing.get(s.id)){
						failing++;
					}
				}
				s.Failing__c = failing;
			}
			update mapSections.values();
		}
		if (!sgOverrideSet.isEmpty()){
			Set<String> allowSet = CT_Gradebook_SoqlUtils.getAllowedNaValues();
			OverrideSettings__c settings = CT_Gradebook_SoqlUtils.os;
			Set<Id> studentIds = new Set<Id>();
			Set<Id> courseIDs = new Set<Id>();
			Map<String, String> fgOverrideMap = new Map <String, String>();
			List<Final_Grade__c> fgUpdateList = new List <Final_Grade__c>();

			for (Section_Grade__c sg: sgOverrideSet){
				if (allowSet.contains(sg.Grade_override__c)){
					system.debug('sg~~~'+sg);
					studentIds.add(sg.Student_Id__c);
					courseIDs.add(sg.Course_Id__c);
					string fgKey = sg.Student_Id__c+'-'+sg.Course_Id__c;
					fgOverrideMap.put(fgKey, sg.Grade_Override__c);
				}
			}
			for (Final_grade__c fg:
				[select id, grade_override__c ,student__c,course__c
					from Final_Grade__c
					where student__c in :studentIds
					and Course__c in:courseIds]){
				string fgKey = fg.student__c+'-'+fg.course__c;
				if (fgOverrideMap.keySet().contains(fgKey)){
					fg.Grade_Override__c = fgOverrideMap.get(fgKey);
					fgUpdateList.add(fg);
				}
			}
			update fgUpdateList;
		}	
	}

}
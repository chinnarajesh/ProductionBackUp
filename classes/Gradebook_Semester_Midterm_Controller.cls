//Programmer's Notes:
//Need to batch this process.First thing, is the school setup Quarter's based, if it is, then for each student, if the course is 2 or 4 reporting periods long, 
//determine the semester/midterm grades.query for all of the section grades of the student and map them to courses.then if the course is 2 reporting periods long,
//sum all the data together of the section grades in to one. if the course is 4 reporting periods long, take half of the section grades and sum the data.
//ONLY DO THIS when today's date is greater than the 2 reporting period but before the last reporting period for this school year.oh, and for active students this year.

/*
	Summer 2014: iteration 2 modifications
		New Gradebook_GradeUtils class that contains the course grade scale relationship
		Use that instead of Gradebook_ManageGradebook
		Further robustness, pass list of students instead of a single
		//generate semester grades for all courses of students
*/

public with sharing class Gradebook_Semester_Midterm_Controller {
	public static ID rType {get; set;}
	public static ID qType {get; set;}
	
	//ID - Key -> studentSection
	public Map<ID, SemesterWrapper> semesterWrappers = new Map<ID, SemesterWrapper>();
	
	public Gradebook_GradeUtils gradeUtils {get; set;}
	
	public class SemesterWrapper {
		public ID studentSection {get; set;}
		public ID course {get; set;}
		public ID gradeScale {get; set;}
		public String rpRecordType {get; set;}
		
		public Gradebook_GradeUtils gradeUtils;
		Map<String, Section_Grade__c> sectionGrades = new Map<String, Section_Grade__c>();
	
		//semester verification
		Map <Integer, Set <Integer>> gradeCalcConfirmMap = new Map <Integer, Set<Integer>>{1=> new Set <Integer>(), 2=> new Set <Integer>()};	
		Map<String, ID> semesterKeyToRpMap = new Map <String, ID>();
	
		public List<Section_Grade__c> generateSemesterGrades() {
			List<Section_Grade__c> returnList = new List<Section_Grade__c>();

			for(String sgKey : sectionGrades.KeySet()) {
				Section_Grade__c sg = sectionGrades.get(sgKey);
				//Only for classes that are 2 or 4 rps long
				if (sg.student_Section__r.section__r.number_of_Reporting_periods__c =='2' || sg.student_Section__r.section__r.number_of_Reporting_periods__c =='4'){ 
					if (sgKey == '1')
						gradeCalcConfirmMap.get(1).add(1);
					else if (sgKey == '2') {
						semesterKeyToRpMap.put('S1',sg.Time__c);
						gradeCalcConfirmMap.get(1).add(2);
					}
					else if (sgKey == '3')
						gradeCalcConfirmMap.get(2).add(3);
					else if (sgKey == '4') {
						semesterKeyToRpMap.put('S2',sg.Time__c);
						gradeCalcConfirmMap.get(2).add(4);
					}
				}
			}
			
			//now that we know which semester grades we have to calculate; go ahead and calculate them
			if (gradeCalcConfirmMap.get(1).contains(1) && gradeCalcConfirmMap.get(1).contains(2)){
				Section_Grade__c sg = createSemSg(1);
				if (sg.Section_GPA__c!=null)		returnList.add(sg);
			}
			if (gradeCalcConfirmMap.get(2).contains(3) && gradeCalcConfirmMap.get(2).contains(4)){
				Section_Grade__c sg = createSemSg(2);
				if (sg.Section_GPA__c!=null)		returnList.add(sg);
			}
			
			return returnList;
		}

		public Section_Grade__c addGnToSg(Section_Grade__c sg){
			if(sg.Grade__c != null){
				Decimal rawSgValue = sg.grade__c; //per Colorado we are no longer rounding this
				if(rawSgValue>100) rawSgValue = 100; //Grade cannot be more than 100 for transform purposes; extra credit or mistake entries when points possible was used was likely the cause of this
				rawSgValue = rawSgValue.divide(1,2);
				system.debug('sg~~~'+sg);
				system.debug('rawValue~~'+rawSgValue);
				Grade_Normalization__c gn = gradeUtils.getNormalizationRecord(course, rawSgValue);
				sg.Letter_Grade__c =gn.Transformed_Grade__c;
				sg.Section_GPA__c = gn.GP_Value__c;
			}
			return sg;
		}
	
		public Section_Grade__c createSemSg(integer iSem){
			Decimal totalGradeValue=0.0;
			Decimal totalWeightings=0.0;
			Decimal sectionGPA =0.0;
			Decimal sectionWeightedGPA=0.0;
			String letterGrade;
			String referenceID;
			Set <String> validKeySet ;
			String semesterName;
				
			if (iSem==1) {
				validKeySet = new Set <String>{'1','2','1-Final','2-Final'};
				semesterName = 'S1';
			} else {
				validKeySet = new Set <String>{'3','4','3-Final','4-Final'};
				semesterName = 'S2';
			
			}
					
			for (Section_Grade__c sg : sectionGrades.Values()){
				if (validKeySet.contains(sg.Course_Weighting__r.Key__c)){
					ReferenceId		= semesterName+'-'+sg.student_Section__c+'-'+semesterKeyToRpMap.get(semesterName);
					totalGradeValue	+= sg.grade__c*sg.course_Weighting__r.weighting__c;
					totalWeightings	+= sg.course_Weighting__r.weighting__c;
				}
			}
	
			Section_Grade__c sg= new Section_Grade__c();
			sg.Student_Section__c = studentSection;
			sg.Reference_Id__c =referenceId;
			sg.grade__c = (totalWeightings != 0)?totalGradeValue/totalWeightings:null;
			sg.recordTypeId = rType;
			sg = addGnToSg(sg);
			return sg;
		}
	}
	
	public Gradebook_Semester_Midterm_Controller() {
		setRecordType();
		gradeUtils = new Gradebook_GradeUtils();
		gradeUtils.setOverrideValues();		
	}

	public void setRecordType() {
		rType = core_SoqlUtils.getRecordTypesBySobject('Section_Grade__c').get('Semester');
		qType = core_SoqlUtils.getRecordTypesBySobject('Section_Grade__c').get('Quarter');
	}

	public void calcSemesterMidtermGrades(List<Student__c> students) {
		//given a student, must find all of that student's sectionGrades
		//then check if any of the courses he attends meets the requirements
		//use student__r.Setup__r.Term__c, that's where you can tell if it's quarters, semesters, trimesters
		
		//use set of student section grades to populate the course grade scales
		Set<Course__c> courses = new Set<Course__c>();
		
		List<Section_Grade__c> upsertList = new List<Section_Grade__c>();
		
		List<Section_Grade__c> sectionGrades = 
			[SELECT s.ID,
				s.Student_section__r.Student__r.Setup__c,
				s.Student_section__r.Student__r.Setup__r.Term__c,
				s.Student_section__r.Student__r.Setup__r.Term__r.Name__c,
				s.Student_Section__r.Section__r.Course__c,
				s.Student_Section__r.Section__c,
				s.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c,
				s.Student_Section__r.Section__r.Course__r.Use_Assignment_Type_Percentages__c,
				s.Student_Section__r.Section__r.Course__r.Multiply_GPA_Added_Value_Points__c,
				s.Student_Section__r.Section__r.Course__r.GPA_Added_Value_Points__c,
				s.Student_Section__r.Section__r.Number_Of_Reporting_Periods__c,
				s.Student_Section__r.Section__r.Course__r.Credit_Hours__c,
				s.Course_Weighting__r.Key__c,
				s.Course_Weighting__r.Weighting__c,								
				s.Time__r.End_Date__c,
				s.Student_Section__c,
				s.Section_GPA__c,
				s.Section_Weighted_GPA__c,
				s.Grade__c,
				s.Key__c,
				s.Letter_Grade__c,
				s.Reference_ID__c,
				s.Time__r.Picklist_Value__r.Name
			FROM Section_Grade__c s
			where (s.Student_Section__r.Section__r.Number_Of_Reporting_Periods__c = '2' OR s.Student_Section__r.Section__r.Number_Of_Reporting_Periods__c = '4') 
			AND (s.RecordTypeID =: qType OR s.RecordType.Name = null)
			AND s.Student_Section__r.Student__c IN: students
			AND s.Student_Section__r.Student__r.Active__c = TRUE
			AND grade__c !=null
			AND (RecordTypeID = null OR RecordType.Name = 'Quarter')
			AND course_weighting__c !=null
			ORDER BY s.Student_Section__r.Section__c, s.Time__r.End_Date__c ASC];	
											
		//populate courses
		//build the semesterWrapper map
		for(Section_Grade__c sg : sectionGrades) {
			Course__c c = new Course__c(
				ID = Sg.Student_Section__r.Section__r.Course__c,
				Grade_Scale_Lookup__c = sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c,
				Use_Assignment_Type_Percentages__c = sg.Student_Section__r.Section__r.Course__r.Use_Assignment_Type_Percentages__c,
				Multiply_GPA_Added_Value_Points__c = sg.Student_Section__r.Section__r.Course__r.Multiply_GPA_Added_Value_Points__c,
				GPA_Added_Value_Points__c = sg.Student_Section__r.Section__r.Course__r.GPA_Added_Value_Points__c,
				Credit_Hours__c = sg.Student_Section__r.Section__r.Course__r.Credit_Hours__c
			);

			courses.add(c);
			
			if(!semesterWrappers.containsKey(sg.Student_Section__c)) {
				SemesterWrapper sw = new SemesterWrapper();
				sw.studentSection = sg.Student_Section__c;
				sw.course = sg.Student_Section__r.Section__r.Course__c;
				sw.gradeScale = sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c;
				sw.rpRecordType = sg.Time__r.Picklist_Value__r.Name;
				sw.sectionGrades.put(sg.Course_Weighting__r.Key__c, sg);
				semesterWrappers.put(sg.Student_Section__c, sw);
			}
			else {
				semesterWrappers.get(sg.Student_Section__c).sectionGrades.put(sg.Course_Weighting__r.Key__c, sg);
			}
		}
		
		//use this for course grade scales		
		if(gradeUtils.bCourseGradeScalesEmpty()) {
			gradeUtils.setCourseGradeScales(courses);
		}				
						
		for(SemesterWrapper sw : semesterWrappers.Values()) {
			sw.gradeUtils = gradeUtils;
			upsertList.addAll(sw.generateSemesterGrades());
		}		
		
		if(upsertList.size() > 0) {
			upsert upsertList Reference_ID__c;
		}
	}
}
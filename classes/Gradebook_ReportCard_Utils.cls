public with sharing class Gradebook_ReportCard_Utils {
	
	public static List<String> populateTimeList(Map<ID,Time_Element__c> rpMap){
		List<String> temp = new List<String>();
		for(ID i : rpMap.keySet()) {		
			//reformat the string
			String s1 = String.valueOf(rpMap.get(i).Date_Start_Date__c);
			List<String> s1split = s1.split('-');
			if(s1split[1].startsWith('0')) {
				s1split[1] = s1split[1].substring(1, s1split[1].length());
			}
			if(s1split[2].startsWith('0')) {
				s1split[2] = s1split[2].substring(1, s1split[2].length());
			}
			
			s1 = s1split[1] + '/' + s1split[2] + '/' + s1split[0];
			String s2 =  String.valueOf(rpMap.get(i).End_Date__c);
			List<String> s2split = s2.split('-');
			if(s2split[1].startsWith('0')) {
				s2split[1] = s2split[1].substring(1, s2split[1].length());
			}
			if(s2split[2].startsWith('0')) {
				s2split[2] = s2split[2].substring(1, s2split[2].length());
			}			
			s2 = s2split[1] + '/' + s2split[2] + '/' + s2split[0];
			temp.add(i+';'+s1+';'+s2);
		}
		return temp;
	}
	
	/* Start Document Batch Methods */
	public static List<Setup__c> getDocumentSchools(boolean filterInactive){
		String query = 'Select School__c, Standards_ONLY_Gradebook__c,Show_Homework_Percentage__c,'+
				'Display_Reading_Level_On_Report_Card__c, Include_Section_Grades__c, Progress_Report_Standard_Display__c,'+ 
				'Report_Card_Standard_Display__c,Show_Section_Comments__c, Show_Standard_Grades__c, Show_Class_Rank__c,'+
				'Show_Semester_Grades_On_Report_Cards__c,Evaluation_Documents__c, Term__c, Year__c, Year__r.Name__c, '+
				'Term__r.Name__c,Grade_Span__c, School__r.Name'+
			' from Setup__c'+
			((filterInactive)?' where Active__c = true':'')+
			' order by School__r.Name, Term__r.End_Date__c desc';
		List<Setup__c> setups= (List<Setup__c>) Database.query(query);
		return setups;
	}
	public static List<Time_Element__c> getReportingPeriods(Set<Id> termIds){
		List<Time_Element__c> rps= [SELECT Days_of_Week__c , Reporting_Period_Value__r.Name
					,Reporting_Period_Value__c, Name__c, StartTime__c, EndTime__c
					,Reporting_Period__c, Allow_Periods__c, Picklist_Value__r.Name
					,Picklist_Value__r.Level__c, Type__c, SystemModstamp, End_Date__c
					,Start_Time__c, School__c, Reference_Id__c
					,Parent_Time_Element__c, Id, Date_Start_Date__c
				From Time_Element__c
				WHERE Parent_Time_Element__c IN : termIDs
				AND Reporting_Period__c = true
				ORDER BY Parent_Time_Element__c, Date_Start_Date__c];
		return rps;
	}
	public static Map<ID, Student_Reporting_Period__c> getStudentReportingPeriods(Set<ID> students, string setupFilter){
		Map<ID, Student_Reporting_Period__c> studentSRPMap = new Map<ID, Student_Reporting_Period__c>();

		for(Student_Reporting_Period__c srp:getStudentReportingPeriodList(students,setupFilter)){
			studentSRPMap.put(srp.Student__c, srp);
		}
		return studentSRPMap;
	}

	public static List<Student_Reporting_Period__c> getStudentReportingPeriodList(Set<ID> students, string setupFilter){
		String query = 'select id, Show_In_Portal__c,Attachment_ID__c,Attachment_Link__c,Latest_Progress_Report__c,Student__r.Setup__c,'+
						'Most_Recent_Document_Created__c, Student__c, Time__r.Name__c, Time__r.Name_On_Report_Card__c, GPA__c, Reading_Level__c'+
						' from Student_Reporting_Period__c where Student__c IN:students';

		if(setupFilter != null && setupFilter != '')
			query += ' AND ('+setupFilter + ')';
		query+= ' ORDER BY Time__r.Date_Start_Date__c, Time__r.Reporting_Period__c desc';
		system.debug(query);
		return (List<Student_Reporting_Period__c>)Database.query(query);
	}
	/* End Document Batch Methods */
	/* Start Card Generation Methods */
	public static Student__c getStudentInfo(ID studentID){
		try{
			Student__c student = 
				[Select ID, Student_ID__c, Grade__c, Name,Reading_Level_Q1__c,Reading_Level_Q2__c,
					Reading_Level_Q3__c,Reading_Level_Q4__c,Promotional_Status__c,
					Date_of_Birth__c, Final_GPA_Value__c, GPA_To_Date__c, Final_Weighted_GPA_Value__c,
					Class_Rank__c, Home_Language__c,Comments__c,Alternate_Lang_Comments__c,
					Address__c,City__c,Zip_Code__c,State__c,Current_GPA__c,School__c,Setup__c,
					Setup__r.School_Picture__c, Setup__r.Display_GPA_on_Report_Cards__c,
					Individual__r.Service_Hours_Completed__c, School_Year__r.Name__c, Weighted_GPA_To_Date__c
				from Student__c
				where id = : studentID];
			return student;
		} catch (System.QueryException e){
			throw new DocumentRuntimeException('ERROR: The student with the id specified was not found in the system.');
		}
		return null;
	}
	
	public static Integer getStudentClassSize(String grade, ID schoolID){
		integer classSize = [select count() 
							from Student__c 
							where School__c =: schoolId
							AND Grade__c =: grade
							AND Active__c = true
							AND Archived__c = false];
		return classSize;
	}
	
	/*public static Student_Reporting_Period__c getStudentReportingPeriod(ID reportingPeriodId, ID studentId){
		try{
			Student_Reporting_Period__c srp = 
				[select gpa__c 
				from Student_reporting_period__c 
				where student__c = :studentID
				and time__c =:reportingPeriodId];
			return srp;
		} catch (System.QueryException e){
			throw new DocumentRuntimeException(e.getMessage().contains('no rows')?'The selected student does not have a student reporting period record for the generation period. Please rerun the final grade batch.':'The student has more then one student reporting period record for the generation period. Please review their data and delete the duplicated record.');
		}
		return new Student_Reporting_Period__c();
	}*/
	
	public static Setup__c getSetupInfo(ID setupId){
		try{
			Setup__c setup = [select id, Standard_Legend_1_Spanish__c, Standard_Legend_2_Spanish__c,
								Standard_Legend_3_Spanish__c, Standard_Legend_4_Spanish__c, Term__c,
								Standard_Legend_Description_1_Spanish__c, Standard_Legend_Description_2_Spanish__c,
								Standard_Legend_Description_3_Spanish__c, Standard_Legend_Description_4_Spanish__c,
								Standard_Legend_1__c, Standard_Legend_2__c, Standard_Legend_3__c, Standard_Legend_4__c,
								Standard_Legend_Description_1__c, Standard_Legend_Description_2__c,
								Standard_Legend_Description_3__c, Standard_Legend_Description_4__c,
								Standards_ONLY_Gradebook__c, Show_Normalizations_on_Report_Cards__c,
								Show_Standard_Scale_on_Report_Cards__c, Show_Sectional_Attendance_on_Report_Card__c,
								Display_GPA_on_Report_Cards__c, Display_Legend_on_Report_Cards__c,Include_Section_Grades__c,
								Display_Reading_Level_On_Report_Card__c, Show_Semester_Grades_On_Report_Cards__c,
								Show_Homework_Percentage__c,Show_Section_Comments__c,Progress_Report_Standard_Display__c,
								Show_Standard_Grades__c,Report_Card_Standard_Display__c,Display_Weighted_GPA_on_Documents__c,
								Display_Incomplete_Assignments__c,Display_Community_Service_Hours__c,Show_Class_Rank__c,Evaluation_Documents__c,
								School__c, School__r.Name, Term__r.Name__c, Year__r.Name__c, Display_Cumulative_Weighted_GPA__c,
								Use_1st_Reporting_Period_Start_Date_RC__c	
							from Setup__c
							where ID =: setupId];
			return setup;
		} catch (System.QueryException e){
			throw new DocumentRuntimeException('The system was unable to find the setup as listed on the student record. Check to make sure the student is linked to a setup.');
		}
		return new Setup__c();
	}
	
	public static Account getSchoolInfo(ID schoolId){
		try{
			Account school = [select Principal__r.Name,BillingStreet,BillingState,BillingPostalCode,BillingCountry,BillingCity,Name
								from Account
								where ID =: schoolID];
			return school;
		} catch (System.QueryException e){
			throw new DocumentRuntimeException('The system was unable to find the school as listed on the student record. Check to make sure the student is linked to a school.');
		}
	}
	
	public static List<Time_Element__c> getReportingPeriods(ID TermID){
		List<Time_Element__c> rps= 
				[Select ID, Name__c, Reporting_Period__c, Name_On_Report_Card__c, Date_Start_Date__c, End_Date__c, Parent_Time_Element__c
					from Time_Element__c 
					where Parent_Time_Element__c =:termID
					OR Parent_Time_Element__r.Parent_Time_Element__c =:termID
					order by Date_Start_Date__c, Reporting_Period__c desc];
		return rps;
	}

	public static List<Time_Element__c> getPrimaryReportingPeriods(ID TermID){
		List<Time_Element__c> rps= 
				[Select ID, Name__c, Reporting_Period__c, Name_On_Report_Card__c, Date_Start_Date__c, End_Date__c, Parent_Time_Element__c
					from Time_Element__c 
					where Parent_Time_Element__c =:termID
					order by Date_Start_Date__c, Reporting_Period__c desc];
		return rps;
	}
	
	public static List<Section_Grade__c> getSectionGrades(Date cutoffDate, ID studentID){
		List<Section_Grade__c> sgList = 
				[Select ID, Comments_Next_Steps__c, Alternate_Lang_Comments__c,
						Time__r.Name_On_Report_Card__c, Student_Section__r.Active__c,
						Student_Section__r.Student__c, Student_Section__r.Section__r.Name,
						Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c,
						Student_Section__r.Section__r.Course__r.Exclude_on_RC_Transcripts__c,
						Student_Section__r.Section__r.Name_Spanish__c, Student_Section__r.Section__r.Course__c,
						Student_Section__r.Section__r.Course__r.Name, Grade_Override__c,
						Student_Section__r.Section__r.Course__r.Name_Spanish__c,
						Display_Grade_Formula__c, Standard_Section_Grade_v2__c,
						Grade_Overridden__c, Grade__c, Student_Section__c, Time__c, Time__r.Name__c,
						Student_Section__r.Section__c, Letter_Grade__c, Teachers__c,
						Time__r.Reporting_Period__c, Time__r.End_Date__c, Time__r.Date_Start_Date__c, Section_GPA__c,
						Student_Section__r.Section__r.Course__r.Grade_Scale__c, Course_Weighting__r.Weighting__c,
						Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c,
						Student_Section__r.Section__r.Course__r.Use_Assignment_Type_Percentages__c,
						Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Category__c,
						Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Name
					from Section_Grade__c
					where Student_Section__r.Student__c = :studentId
					AND Time__r.End_Date__c <= :cutoffDate
					AND (RecordTypeID = null OR RecordType.Name = 'Quarter')
					AND Student_Section__r.Section__r.Course__r.Exclude_on_RC_Transcripts__c = false
					order by Student_Section__r.Section__r.Course__r.Name,Student_Section__r.Section__c, Time__r.End_Date__c ASC];
		return sgList;
	}
	
	public static List<Section_Grade__c> getSemesterGrades(ID studentId){
		List<Section_Grade__c> semesterGradeList =
				[Select ID,Grade_Override__c, Grade_Overridden__c, Grade__c, Standard_Section_Grade_v2__c,
					Reference_ID__c, Display_Grade_Formula__c, Student_Section__c, Comments_Next_Steps__c,
					Student_Section__r.Section__c, Student_Section__r.Section__r.Name,
					Letter_Grade__c, Time__c, Time__r.Name__c, Time__r.Reporting_Period__c,
					Time__r.End_Date__c, Time__r.Date_Start_Date__c, Section_GPA__c,
					Teachers__c, Student_Section__r.Section__r.Course__r.Grade_Scale__c,
					Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c
				from Section_Grade__c 
				where Student_Section__r.Student__c = :studentId 
				AND (RecordType.Name = 'Semester') 
				AND Reference_ID__c != null
				AND Student_Section__r.Section__r.Course__r.Exclude_on_RC_Transcripts__c = false
				order by Reference_ID__c ASC];
				//note
		return semesterGradeList;
	}
	
	public static List<Enrollment_Tracking__c> getSectionEnrollment(Set<Id> studentSectionIDs){
		List<Enrollment_Tracking__c> trackingList=
				[select id, Student_Section__c, Start_Date__c, End_Date__c 
				from Enrollment_Tracking__c 
				where Student_Section__c in:studentSectionIDs
				and Active__c = false 
				order by Student_Section__c, End_Date__c];
		return trackingList;
	}
	
	public static List<Final_Grade__c> getFinalGrades(ID studentID){
		List<Final_Grade__c> fgList=
			[Select ID,Student__c,final__c, Course__c,Course__r.Display_Numerical_Values_On_Report_Card__c,
				Final_Grade_Letter_v2__c,Final_Grade_Letter__c,Final_GPA_Value__c,Current_Grade_Letter_v2__c, 
				Display_Final_Grade_Formula__c, Final_Grade_Value__c, Course__r.Multiply_GPA_Added_Value_Points__c,
				Course__r.GPA_Added_Value_Points__c, Grade_Overridden__c, Unweighted_GPA__c, Weighted_GPA__c
			from Final_Grade__c 
			where Student__c = : studentId];
		return fgList;
	}
	
	public static List<Staff_Section__c> getInstructionalStaff(Set<Id> sectionIDs){
		List<Staff_Section__c> instructionalStaff=
				[Select ID, Section__c, Section__r.Course__c, Staff__r.Name 
				from Staff_Section__c 
				where Section__c IN : sectionIDs
				AND Display_Teacher_On_RC_PR__c = true
				AND Staff__r.Name != null
				AND Staff__r.Name != ''
				AND Section__r.RecordType.DeveloperName = 'Published'];
		return instructionalStaff;
	}
	
	public static List<HW_Tracker__c> getStudentHomework(ID studentID, Set<ID> sections, Date endDate){
		List<HW_Tracker__c> hw=
				[Select ID, HW_Status__c, Time__c, Student_Section__r.Section__c,
					Student_Section__r.Section__r.Course__c, Picklist_Value__c, 
					Picklist_value__r.Category__c from HW_Tracker__c 
				where Student__c = :studentId 
				AND Student_Section__r.Section__c IN: sections
				AND Picklist_Value__r.Category__c != 'Exempt'
				AND Due_Date__c <=: endDate
				order by Student_Section__r.Section__c];
		return hw;
	}
	
	public static List<Attendance__c> getStudentAttendance(Date endDate, ID studentId){
		List<Attendance__c> attendanceList=
			[Select ID,  Session__r.Section__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c,
				Picklist_Value__r.Is_Unexcused__c, Picklist_Value__c, Picklist_Value__r.Name, Daily__c 
			from Attendance__c 
			where Session_Date__c <=: endDate
			and Student__c = :studentId
			order By session__r.Section__c];
		return attendanceList;
	}

	public static Map<ID, Integer> getIncomplateAssignments(Date endDate, ID studentID){
		Map<ID, Integer> incAssign = new Map<ID, Integer>();
		for(AggregateResult inc:
				[select Assignment__r.Section__c section, COUNT_DISTINCT(Assignment__c) c
				from Grade__c
				where Student__c =: studentId
				and Time__r.End_Date__c <=: endDate
				and Exclude_From_Section_Grade__c = false
				and (Entered_Grade__c = 'I'
					OR Entered_Grade__c = 'INC' 
					OR Entered_Grade__c = 'IN'
					OR Entered_Grade__c = 'IC')
				GROUP BY Assignment__r.Section__c]){
			incAssign.put((ID)inc.get('section'),(Integer)inc.get('c'));
		}

		return incAssign;
	}
	
	public static List<Standard_Grade__c> getStandardGrades(ID StudentID, Date endDate){
		List<Standard_Grade__c> standardGrades=
			[Select ID, Standard_Grade__c, Grade_Overridden__c, Grade_Override__c, Standard__r.Standard_Subject__r.Name,
				Standard__r.Standard_Subject__c, Standard__r.Name, Standard__r.Description_Spanish__c, Grade__c, 
				Standard__r.Subject__c, Standard__r.Strand__r.Subject__c, Standard__r.Strand__c, 
				Standard__r.Strand__r.Name, Standard__r.Long_Text__c,
				Reporting_Period__c, Standard__c
			from Standard_Grade__c 
			where student__c = :studentId 
			and (Grade_Overridden__c = false
				or (Grade_Overridden__c=true and Grade_Override__c != null))
			AND Reporting_Period__r.End_Date__c <=: endDate 
			order by Standard__r.Name, Reporting_Period__r.End_Date__c, Reporting_Period__r.Reporting_Period__c DESC];
		return standardGrades;	
	}	
	
	public static List<Strand_Grade__c> getStrandGrades(ID StudentID, Date endDate){
		List<Strand_Grade__c> strandGrades=
			[Select ID, Grade_Overridden__c, Grade_Override__c, Strand__r.Standard_Subject__c, 
				Strand__r.Standard_Subject__r.Name, Reporting_Period__c, Grade__c, Strand__r.Subject__c, 
				Strand__r.Description_Spanish__c, Reporting_Period__r.Name__c, Name, Strand__r.Name, 
				Strand__r.Long_Text__c, Strand__c 
				from Strand_Grade__c 
				where student__c = :studentId 
				AND Reporting_Period__r.End_Date__c <= :endDate
				order by Strand__r.Subject__c, Strand__r.Name, Reporting_Period__r.End_Date__c, Reporting_Period__r.Reporting_Period__c DESC, Name ASC];
		return strandGrades;
	}
	
	public static List<normalizationWrapper> getFinalGradeNoralizations(){
		List<Grade_Normalization__c> gnList = 
			[Select ID, GP_Value__c, Grade_Value__c, Transformed_Grade__c 
			from Grade_Normalization__c where picklist_value__c =null 
			and gp_value__c!=null 
			order by Grade_value__c desc];
		
		return buildNormalizationTable(gnList);
	}

	public static List<normalizationWrapper> buildNormalizationTable(List<Grade_Normalization__c> gnList){
		List<NormalizationWrapper> normalizations = new List<normalizationWrapper>();
		if(!gnList.isEmpty()){
			try{
				String lastLetter = gnList[0].Transformed_Grade__c;
				decimal highestValue = 100;
				decimal lowestValue = gnList[0].Grade_value__c;
				//Whenever the transformed grade is not matching the old Grade value, add the range and grade letter to the list
				for(Integer i=0;i<gnList.size();i++){
					if(lastLetter != gnList[i].Transformed_Grade__c){
						normalizations.add(new normalizationWrapper(lowestValue+' - '+highestValue,lastLetter));
						highestValue = lowestValue - .01;
						lowestValue = gnList[i].Grade_value__c;
						lastLetter = gnList[i].Transformed_Grade__c;
					} else {
						lowestvalue = gnList[i].Grade_value__c;
					}
					
					if(i==(gnList.size()-1)){
						normalizations.add(new normalizationWrapper(lowestValue+' - '+highestValue,lastLetter));
					}
				}
			} catch(System.NullPointerException e){
				throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('A required field is blank. Please check your default normalizations.',e);
			}
		}
		return normalizations;
	}
	
	public class normalizationWrapper{
		public String range		{get;set;}
		public String letter	{get;set;}
		
		public normalizationWrapper(String range, String letter){
			this.range = range;
			this.letter = letter;
		}
	}
	
	public class DocumentRuntimeException extends Exception{}
}
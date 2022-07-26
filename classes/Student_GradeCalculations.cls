public with sharing class Student_GradeCalculations {
	public Student__c student								{get;set;}
	public Setup__c setup									{get;set;}
	public List<Student_Reporting_Period__c> srpList		{get;set;}
	public List<Time_Element__c> orderedReportingPeriods	{get;set;}
	public List<Time_Element__c> primaryReportingPeriods	{get;set;}
	public String selectedCourse							{get;set;}
	public String selectedRecord							{get;set;}

	public gradeTableWrapper gradeTable			{get;set;}
	public sectionWrapper	detailWrapper		{get;set;}
	public gradeWrapper		gradeDetailWrapper	{get;set;}

	private List<ID> sections = new List<ID>();

	public Student_GradeCalculations() {
		ID studentID = ApexPages.currentPage().getParameters().get('studentId');
		if(studentID == null){
			Error_Handling.errorMessage('No student id was provided. Please provide a student id.');
			return;
		}
		
		loadStudent(studentId);
		orderedReportingPeriods = Gradebook_ReportCard_Utils.getReportingPeriods(student.Setup__r.Term__c);
		setup = Gradebook_ReportCard_Utils.getSetupInfo(student.Setup__c);
		
		loadGradeTable();
		loadStudentReportingPeriods(orderedReportingPeriods);
		detailWrapper = new sectionWrapper(null);
		gradeDetailWrapper = new gradeWrapper();
	}

	public void drillFinalGrade(){
		try{
			sectionWrapper holderWrapper = getSectionWrapper();
			detailWrapper = new sectionWrapper(holderWrapper.sectionInfo.sectionId);
			Map<ID, Time_Element__c> teMap = new Map<ID, Time_Element__c>(orderedReportingPeriods);

			Decimal sumGrades = 0, sumWeightings = 0;
			for(sectionGradeWrapper sgw:holderWrapper.sectionGrades){
				if(sgw.sg.id != null && sgw.sg.Time__c != null && sgw.sg.Grade__c != null){ //time filter removes semester grades
					sumGrades += sgw.sg.Grade__c* (sgw.sg.Course_Weighting__r.Weighting__c/100);
					sumWeightings += (sgw.sg.Course_Weighting__r.Weighting__c/100);
					detailWrapper.sectionGrades.add(sgw);
					detailWrapper.sgRPs.add(sgw.sg.Time__r.Name_On_Report_Card__c);
				} else if (sgw.sg.Time__c != null){//grade place holders, filters semester grades
					if(teMap.get(sgw.sg.Time__c).Reporting_Period__c || sgw.sg.id != null){ // filters out final reporting periods that were "faked" from the master list
						detailWrapper.sgRPs.add(teMap.get(sgw.sg.Time__c).Name_On_Report_Card__c);
						detailWrapper.sectionGrades.add(new SectionGradeWrapper(new Section_Grade__c()));
					}
				}
			}
			detailWrapper.sumWeightings = sumWeightings;
			detailWrapper.sumGrades = sumGrades;
			detailWrapper.finalGradeValue = (sumWeightings!=0)?sumGrades/sumWeightings:0;
			if(holderWrapper.finalGrade != null && detailWrapper.finalGradeValue != null){
				detailWrapper.fgn = getNormalization(detailWrapper.finalGradeValue,holderWrapper.sectionGrades[0].sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c);
			}
			detailWrapper.sectionInfo = holderWrapper.sectionInfo;
			detailWrapper.finalGrade = holderWrapper.finalGrade;
			detailWrapper.gradeScaleName = holderWrapper.gradeScaleName;
			detailWrapper.finalGradeDisplayValue = holderWrapper.finalGradeDisplayValue;
		} catch(Exception e){
			Error_Handling.errorMessage('An error occured while processing the selected grade. Please verify your data and try again.');
			detailWrapper = null;
		}

	}

	public void drillSectionGrade(){
		sectionWrapper holderWrapper = getSectionWrapper();
		if(holderWrapper != null)
			gradeDetailWrapper = new gradeWrapper(getSelectedGrade(holderWrapper));
		else
			Error_Handling.errorMessage('A error occured while trying to load the selected grade.');
	}

	private sectionWrapper getSectionWrapper(){
		for(SectionWrapper sw: gradeTable.sections){
			if(sw.sectionInfo.courseID == selectedCourse){
				return sw;
			}
		}
		return null;
	}

	private sectionGradeWrapper getSelectedGrade(sectionWrapper sectionWrapper){
		for(sectionGradeWrapper sgw: sectionWrapper.sectionGrades){
			if(sgw.sg.id == selectedRecord){
				return sgw;
			}
		}
		return null;
	}

	public static Grade_Normalization__c getNormalization(Decimal grade, ID gradescale){
		try{
			return [select id, Grade_Value__c, Picklist_Value__c,
						Transformed_Grade__c, Picklist_Value__r.Name,
						GP_Value__c
					from Grade_Normalization__c
					where (Picklist_Value__c =: gradescale OR Picklist_Value__c = null)
					and Grade_Value__c <=: grade
					order by Picklist_Value__c NULLS LAST, Grade_Value__c desc limit 1];
		} catch (System.QueryException e){
			return new Grade_Normalization__c();
		}
	}

	public void loadStudent(ID studentId){
		try{
			student=
					[select id, Name, Current_GPA__c, Combined_Final_Grade_Values__c, Grade__c,
						Combined_Weighted_Final_Grade_Values__c,Final_GPA_Value__c,Final_Weighted_GPA_Value__c,
						Total_Credits_Earned__c, Setup__c, GPA_To_Date__c, Weighted_GPA_To_Date__c, Class_Rank__c,
						School_Year__r.End_Date__c, Setup__r.Term__c, School_Year__r.Name__c, Archived__c
					FROM Student__c
					where ID =: studentID];
			if(student.Archived__c){
				Error_Handling.warningMessage('The selected record has already been archived. This may result in errors when displaying calculations.');
			}
		} catch (System.QueryException e){
			Error_Handling.errorMessage('An error occured while loading the student record. Please verify that the provided id is correct.');
		}
	}

	public void loadGradeTable(){
		gradeTable = new gradeTableWrapper(student, orderedReportingPeriods, true, setup.Show_Semester_Grades_On_Report_Cards__c);
	}

	public void loadStudentReportingPeriods(List<Time_Element__c> allReportingPeriods){
		List<Student_Reporting_Period__c> holder = Gradebook_ReportCard_Utils.getStudentReportingPeriodList(new Set<ID>{student.id},null);
		primaryReportingPeriods = new List<Time_Element__c>();
		srpList = new List<Student_Reporting_Period__c>();
		for(Time_Element__c rp:allReportingPeriods){
			if(rp.Reporting_Period__c){
				primaryReportingPeriods.add(rp);
			}
		}
		Map<ID, Student_Reporting_Period__c> srpMap = new Map<ID, Student_Reporting_Period__c>();
		for(Student_Reporting_Period__c srp:holder){
			srpMap.put(srp.Time__c, srp);
		}
		for(Time_Element__c rp:primaryReportingPeriods){
			if(srpMap.containsKey(rp.id)){
				srpList.add(srpMap.get(rp.id));
			} else {
				srpList.add(new Student_Reporting_Period__c());
			}
		}
	}

	/*
		Writing this once so we never have to do it again.
	*/
	public class gradeTableWrapper{
		public List<String> tableDisplayList	{get;set;}
		public List<String> rpDisplayList		{get;set;}
		public List<sectionWrapper> sections	{get;set;}

		public boolean includeFinalGrades		{get;set;}
		public boolean includeSemesterGrades	{get;set;}
		
		public gradeTableWrapper(Student__c student, List<Time_Element__c> orderedReportingPeriods, boolean includeFinalGrades, boolean includeSemesterGrades){
			List<Section_Grade__c> sectionGrades = Gradebook_ReportCard_Utils.getSectionGrades(student.School_Year__r.End_Date__c,student.id);
			sections = new List<sectionWrapper>();

			this.includeFinalGrades = includeFinalGrades;
			this.includeSemesterGrades = includeSemesterGrades;
			
			Map<ID, Map<ID, Section_Grade__c>> semesterGradeMap;
			if(includeSemesterGrades){
				semesterGradeMap = loadSemesterGrades(student.ID, orderedReportingPeriods);
			}

			buildGradeDisplay(sectionGrades, semesterGradeMap, orderedReportingPeriods);
			if(includeFinalGrades){
				loadFinalGrades(student.id);
			}
		}

		public void loadFinalGrades(ID studentID){
			Map<ID, Final_Grade__c> fgMap = Report_Card_Controller.buildFGMap(studentID);
			for(sectionWrapper sw:sections){
				if(fgMap.containsKey(sw.sectionInfo.courseID)){
					sw.finalGrade = fgMap.get(sw.sectionInfo.courseID);
					if(sw.finalGrade.Final_Grade_Value__c == null || !sw.numericalValue){
						sw.finalGradeDisplayValue = sw.finalGrade.Display_Final_Grade_Formula__c;
					} else {
						sw.finalGradeDisplayValue = String.valueOf(sw.finalGrade.Final_Grade_Value__c);
					}
				}
			}
		}

		public Map<ID, Map<ID, Section_Grade__c>> loadSemesterGrades(ID studentID, List<Time_Element__c> orderedReportingPeriods){
			return Report_Card_Controller.buildSemesterGradeMap(studentId,orderedReportingPeriods[orderedReportingPeriods.size()-1].id,orderedReportingPeriods);
		}

		public void buildGradeDisplay(List<Section_Grade__c> sectionGrades, Map<Id,Map<Id, Section_Grade__c>> semesterGrades, List<Time_Element__c> orderedReportingPeriods){
			Map<ID, Map<ID, Section_Grade__c>> sectionGradeMap = new Map<ID,Map<ID, Section_Grade__c>>();
			
			List<ID> orderedSections = new List<ID>();
			Set<ID> usedReportingPeriods = new Set<ID>();

			for(Section_Grade__c sg:sectionGrades){
				if(sg.Student_Section__r.Active__c){
					if(sectionGradeMap.containsKey(sg.Student_Section__r.Section__c)){
						sectionGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Time__c, sg);
					} else {
						sectionGradeMap.put(sg.Student_Section__r.Section__c, new Map<Id, Section_Grade__c>{sg.Time__c=>sg});
						orderedSections.add(sg.Student_Section__r.Section__c);
					}
					usedReportingPeriods.add(sg.Time__c);
				}
			}

			Set<ID> rpBeforeSemesterGrade = new Set<ID>();
			if(semesterGrades!= null){
				for(ID id:semesterGrades.keySet()){
					rpBeforeSemesterGrade.addAll(semesterGrades.get(id).keySet());
				}
			}
			
			system.debug(rpBeforeSemesterGrade);

			List<Time_Element__c> gradedReportingPeriods = new List<Time_Element__c>();
			rpDisplayList = new List<String>();
			tableDisplayList = new List<String>();
			for(Integer i=0;i<orderedReportingPeriods.size();i++){
				Time_Element__c rp = orderedReportingPeriods[i];
				if(usedReportingPeriods.contains(rp.id)){
					gradedReportingPeriods.add(rp);
					tableDisplayList.add(rp.Name_On_Report_Card__c);
					rpDisplayList.add(rp.Name_On_Report_Card__c);
					if(i+1<orderedReportingPeriods.size() && !orderedReportingPeriods[i+1].Reporting_Period__c && rpBeforeSemesterGrade.contains(rp.id)){
						if(usedReportingPeriods.contains(orderedReportingPeriods[i+1].id)){
							tableDisplayList.add(orderedReportingPeriods[i+1].Name_On_Report_Card__c);
							rpDisplayList.add(orderedReportingPeriods[i+1].Name_On_Report_Card__c);
							gradedReportingPeriods.add(orderedReportingPeriods[i+1]);
						}
						tableDisplayList.add(rp.Name_On_Report_Card__c+'SEM');
						i++;
					}
				} else if(rp.Reporting_Period__c){ //we want all the primary reporting periods to show, so force them into the set
					tableDisplayList.add(rp.Name_On_Report_Card__c);
					rpDisplayList.add(rp.Name_On_Report_Card__c);
					gradedReportingPeriods.add(rp);
				}
			}

			for(ID sectionID: orderedSections){
				SectionWrapper sectionWrapper = new sectionWrapper(sectionID);
				boolean addNextCycle = false;
				Section_Grade__c semesterGradeToAdd;
				for(Integer i=0;i<gradedReportingPeriods.size();i++){
					Time_Element__c rp = gradedReportingPeriods[i];
					if(sectionGradeMap.get(sectionID).containsKey(rp.id)){
						Section_Grade__c sg = sectionGradeMap.get(sectionID).get(rp.id);
						if(sectionWrapper.sectionInfo.courseName == null){
							sectionWrapper.sectionInfo.courseName = sg.Student_Section__r.Section__r.Course__r.Name;
							sectionWrapper.sectionInfo.courseID = sg.Student_Section__r.Section__r.Course__c;
							sectionWrapper.numericalValue = sg.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c;
							sectionWrapper.gradeScaleName = sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Name;
						}
						sectionWrapper.sectionGrades.add(new SectionGradeWrapper(sg));
					} else {
						sectionWrapper.sectionGrades.add(new SectionGradeWrapper(new Section_Grade__c(Time__c = rp.id)));
					}

					if(addNextCycle){
						sectionWrapper.sectionGrades.add(new SectionGradeWrapper(semesterGradeToAdd));
						addNextCycle = false;
					}
				
					if(rpBeforeSemesterGrade.contains(rp.id)){
						if(semesterGrades.containsKey(sectionID) && semesterGrades.get(sectionId).containsKey(rp.id)){
							semesterGradeToAdd = semesterGrades.get(sectionID).get(rp.id);
						} else {
							semesterGradeToAdd = new Section_Grade__c();
						}

						if(i+1<gradedReportingPeriods.size() && !gradedReportingPeriods[i+1].Reporting_Period__c){
							addNextCycle = true;
						} else {
							sectionWrapper.sectionGrades.add(new SectionGradeWrapper(semesterGradeToAdd));
						}
					}
				}
				this.sections.add(sectionWrapper);
			}
		}
	}

	public class sectionWrapper{
		public Report_Card_Controller.sectionWrapper sectionInfo	{get;set;}
		public List<sectionGradeWrapper> sectionGrades				{get;set;}
		public Final_Grade__c finalGrade							{get;set;}
		public Boolean numericalValue								{get;set;}
		public String gradeScaleName								{get;set;}
		public String finalGradeDisplayValue						{get;set;}
		public List<String> sgRPs									{get;set;}

		public Decimal sumWeightings		{get;set;}
		public Decimal sumGrades			{get;set;}
		public Decimal finalGradeValue		{get;set;}
		public Grade_Normalization__c fgn	{get;set;}

		public sectionWrapper(ID sectionId){
			sectionInfo = new Report_Card_Controller.sectionWrapper(sectionId, '');
			sectionGrades = new List<sectionGradeWrapper>();
			finalGrade = new Final_Grade__c();
			numericalValue = false;
			sgRPS = new List<String>();
		}
	}

	public class gradeWrapper {
		public sectionGradeWrapper sgw						{get;set;}
		public Boolean percentageBased						{get;set;}
		public Boolean pointsBased							{get;set;}
		public List<Grade__c> grades						{get;set;}
		public List<dawWrapper> dawList						{get;set;}

		public Decimal sumWeightedGrades	{get;set;}
		public Decimal sumWeightings		{get;set;}
		public Grade_Normalization__c sgn	{get;set;}
		public Decimal midpoint				{get;set;}

		public gradeWrapper(){
			grades = new List<Grade__c>();
		}

		public gradeWrapper(sectionGradeWrapper gradeData){
			Section_Grade__c sg = gradeData.sg;
			sgw = gradeData;
			percentageBased = sg.Student_Section__r.Section__r.Course__r.Use_Assignment_Type_Percentages__c;
			pointsBased = sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Category__c=='Points';
			grades = loadGrades();

			if(grades.size()>0 && (!sg.Grade_Overridden__c || (sg.Grade_Overridden__c && sg.Grade__c != null))){
				sumWeightings = 0;
				sumWeightedGrades = 0;
				Set<ID> dawTypes = new Set<ID>();
				Map<ID, Decimal> groupedGrades = new Map<ID, Decimal>();
				Map<ID, Decimal> groupedWeightings = new Map<ID, Decimal>();
				for(Grade__c g:this.grades){
					dawTypes.add(g.Assignment__r.Assignment_Library__r.Picklist_Value__c); //we want to be able to include the daw types here, even if there are no grades
					if(g.Entered_Grade__c != null && !g.Exclude_From_Section_Grade__c && g.Assignment__r.Include_in_Final_Grade__c){
						Decimal gradeValue;
						Decimal weightingValue;
						if(!pointsBased){
							gradeValue = g.Weighted_Grade_Value__c;
							weightingValue = ((g.Standard_Times_Assignment__c==null)?g.Assignment_Weighting__c:g.Standard_Times_Assignment__c);
						} else if(pointsBased && g.Possible_Points__c != null){ //GB  excludes all non-points based grades from the calculation
							gradeValue = g.Grade_Number__c;
							weightingValue = g.Possible_Points__c;
						}

						if(weightingValue == null || gradeValue == null){
							system.debug('invalid grade');
							continue;
						}

						if(groupedGrades.containsKey(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)){
							groupedGrades.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, groupedGrades.get(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)+gradeValue);
							groupedWeightings.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, groupedWeightings.get(g.Assignment__r.Assignment_Library__r.Picklist_Value__c)+weightingValue);
						} else {
							groupedGrades.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, gradeValue);
							groupedWeightings.put(g.Assignment__r.Assignment_Library__r.Picklist_Value__c, weightingValue);
						}
					}
				}

				dawList= new List<dawWrapper>();
				List<Default_Assignment_Weighting__c> dawHolder = getCourseDAW(sg.Student_Section__r.Section__r.Course__c, dawTypes);
				if(dawHolder.size()>groupedGrades.size()){
					Error_Handling.warningMessage('Warning: This course appears to have multiple default assignment weightings for the same assignment type. Your calculations may not be correct.');
				} else if(dawHolder.size()<groupedGrades.size()){
					Error_Handling.warningMessage('Warning: This course appears to be missing default assignment types for some used assignment types. Your calculations may not be correct.');
				}

				for(Default_Assignment_Weighting__c daw:dawHolder){
					if(groupedWeightings.containsKey(daw.Picklist_Value__c) && groupedGrades.containsKey(daw.Picklist_Value__c)){
						if(percentageBased){
							sumWeightings += daw.Percent_Of_Section_Grade__c;
							sumWeightedGrades += (groupedGrades.get(daw.Picklist_Value__c)/groupedWeightings.get(daw.Picklist_Value__c))*daw.Percent_Of_Section_Grade__c;
						} else {
							sumWeightings += groupedWeightings.get(daw.Picklist_Value__c);
							system.debug(groupedGrades.get(daw.Picklist_Value__c));
							sumWeightedGrades += groupedGrades.get(daw.Picklist_Value__c);
						}
						dawList.add(new dawWrapper(daw,groupedGrades.get(daw.Picklist_Value__c),groupedWeightings.get(daw.Picklist_Value__c)));
					}
				}
				if(sumWeightings > 0){
					if(!pointsBased || (pointsBased && percentageBased))
						midpoint = sumWeightedGrades.divide(sumWeightings,2);
					else
						midpoint = (sumWeightedGrades.divide(sumWeightings,4)*100).divide(1,2);
					sgn = Student_GradeCalculations.getNormalization(midpoint, sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c);
				} else if(sg.Grade_Overridden__c && sg.Grade__c != null){
					sgn = Student_GradeCalculations.getNormalization(sg.Grade__c.divide(1,2), sg.Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__c);
				}
			}
		}

		public List<Grade__c> loadGrades(){
			return [select id, Entered_Grade__c, Assignment__r.Name, Grade_Number__c, Standard_Times_Assignment__c, Assignment_Weighting__c, Possible_Points__c, 
						Assignment__r.Assignment_Library__r.Picklist_Value__c, Assignment__r.Assignment_Library__r.Picklist_Value__r.Name, Weighted_Grade_Value__c,
						Exclude_From_Section_Grade__c, Assignment__r.Include_in_Final_Grade__c
					from Grade__c
					where Student__c =: sgw.sg.Student_Section__r.Student__c
					and Assignment__r.Section__c =: sgw.sg.Student_Section__r.Section__c
					and Time__c =: sgw.sg.Time__c
					and Standard__c = null
					and Assignment__r.Include_In_Final_Grade__C = true
					order by Assignment__r.Due_Date__c,Assignment__r.Name];
		}

		public List<Default_Assignment_Weighting__c> getCourseDAW(ID courseID, Set<ID> assignmentTypes){
			return [select id, Picklist_Value__r.Name, Percent_Of_Section_Grade__c 
					from Default_Assignment_Weighting__c
					where Course__c =: courseID
					and Picklist_Value__c IN: assignmentTypes
					and Picklist_Value__c != null
					order by Picklist_Value__r.Name];
		}
	}

	public class dawWrapper{
		public Default_Assignment_Weighting__c daw	{get;set;}
		public Decimal sumGrades					{get;set;}
		public Decimal totalGrades					{get;set;}

		public dawWrapper(Default_Assignment_Weighting__c daw, Decimal sum, Decimal total){
			this.daw = daw;
			sumGrades = sum;
			totalGrades = total;
		}
	}

	public class sectionGradeWrapper{
		public Section_Grade__c sg		{get;set;}
		public String displayValue		{get;set;}
		public boolean isOverridden		{get;set;} //doesn't directly track overrides, just uncalculatable overrides.

		public sectionGradeWrapper(Section_Grade__c sg){
			this.sg = sg;
			isOverridden = false;
			if(sg.Grade__c == null || !sg.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c){
				displayValue = sg.Display_Grade_Formula__c;
				//because we only flag this on Grade__c == null, we get true only on grades that cannot be normalized
				isOverridden = sg.Grade_Overridden__c;
			} else if(sg.Grade__c != null) {
					displayValue = String.valueOf(sg.Grade__c.divide(1,2));	
			} else {
				displayValue = '';
			}
		}
	}

}
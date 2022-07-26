public with sharing class Report_Card_Controller{
	/*DOCUMENT CONTROL VARIABLES */
	public boolean bIncludeInactiveStudentSections	{get;set;}
	public boolean bIncludeInactiveStudents			{get;set;}
	public boolean bIncludeTransferedSections		{get;set;}
	public boolean bDisplaySectionGrades			{get;set;}
	public boolean bDisplayReadingLevel				{get;set;}
	public boolean bDisplayStrands					{get;set;}
	public boolean bDisplayStandards				{get;set;}
	public boolean bProgressReport					{get;set;}
	public boolean bOverallComments					{get;set;}
	public boolean bShowSectionComments				{get;set;}
	public boolean bShowSemesterGrades				{get;set;}
	public boolean bShowClassRank					{get;set;}
	public boolean bShowHomework					{get;set;}
  	public boolean renderPDF						{get;set;}
  	public boolean displayAltLangFields				{get;set;}
  	public boolean languageOverride					{get;set;}
	
	/*PAGE CONTROL VARIABLES */
	public boolean displaySpanish	{get;set;}
	
	
	/*PAGE DISPLAY VARIABLES */
	public reportCardWrapper card	{get;set;}
	public List<Time_Element__c> orderedReportingPeriods {get;set;}
	public Map<String, String> ldw	{get;set;}	//language display wrapper
	
	/*INTERNAL VARIABLES */
	transient private ID studentID;
	transient private ID reportingPeriodID;
	transient private Set<Id> sections;
	transient public List<ID> orderedSections; //used to maintain the ordering of sections for the display table.
	transient private Set<Id> courses;
	transient private Set<ID> rpBeforeSemesterGrade;
	transient private Set<ID> includedFinalRPs;
	private ID logID;
	private Document_Log__c log;
	
	public Report_Card_Controller(){
		try{
			card = new ReportCardWrapper();
			loadConfigParameters();
			loadStudentInfo();
			loadLanguageSettings();
			loadSchoolInfo();
			loadStudentRP();
			loadFinalGradeNormalizations();
			loadSectionGrades(); //loads section and semester grades
			loadFinalGrades();
			loadSectionTeachers();
			
			if(bShowHomework)
				loadHomeworkInfo();
				
			//this has to happen as daily attendance has to calculate no matter what
			loadAttendanceInfo();
			
			if(card.setup.Display_Incomplete_Assignments__c)
				loadAssignmentInfo();
				
			if(bDisplayStandards && !bDisplayStrands){
				loadStandardGrades();
			} else if(bDisplayStandards && bDisplayStrands) {
				loadStrandGrades();
			}
		} catch(Gradebook_ReportCard_Utils.DocumentRuntimeException e){
			writeError(e.getMessage());
		} catch(Exception e){
			system.debug(e);
			writeError('An unknown exception has occured:'+e.getMessage()+':'+e.getStackTraceString());
			log.Status__c = 'Failed';
		}
		if(log.Status__c == null){
			log.Status__c = 'Complete';
		}
		system.debug(log);
	}
	
	private void loadConfigParameters(){
		Map<String, String> params = System.currentPageReference().getParameters();
		studentId						= params.get('studentId');
		reportingPeriodID				= params.get('rpId');
		bIncludeInactiveStudentSections = params.get('incInactiveSS')=='true';
		bIncludeInactiveStudents		= params.get('incInactiveS')=='true';
		bIncludeTransferedSections		= params.get('incTranSS')=='true';
		bProgressReport					= params.get('bPR')=='true';
		bOverallComments				= params.get('bOC')=='true';
		renderPDF						= params.get('pdf')==null;
		languageOverride				= params.get('langOvr')!=null;
		logID							= params.get('logID');

		log = new Document_Log__c(
			ID = logID, 
			Log__c = '',
			Error_Message__c='',
			RecordTypeID=core_soqlUtils.getRecordTypesBySobject('Document_Log__c').get('Report_Card')
		);

		if(languageOverride){
			writeLog('The language of the document was overriden to english.');
		}
		if(reportingPeriodID == null){
			throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('FATAL: Report cards cannot be run for a null reporting period. Please check your data.');
		}
	}
	
	private void loadStudentInfo(){
			Student__c student = Gradebook_ReportCard_Utils.getStudentInfo(studentID);
			card.studentInfo = new studentWrapper(student);
			card.studentInfo.finalWeightedGPA = card.studentInfo.student.Final_Weighted_GPA_Value__c != null?String.valueOf(card.studentInfo.student.Final_Weighted_GPA_Value__c.divide(1,2)):'';
			card.studentInfo.cumulativeWeightedGPA = card.studentInfo.student.Weighted_GPA_To_Date__c != null?String.valueOf(card.studentInfo.student.Weighted_GPA_To_Date__c.divide(1,2)):'';
			
			//controls the display language (loads later)
			if(card.StudentInfo.student.Home_Language__c != null && card.StudentInfo.student.Home_Language__c.contains('Spanish') && !languageOverride){
				displaySpanish = true;
				displayAltLangFields = true;
			} else {
				displaySpanish = false;
				displayAltLangFields = ((card.studentInfo.student.Home_Language__c != 'English' && card.studentInfo.student.Home_Language__c != null) && !languageOverride);
			}
	}
	
	private void loadLanguageSettings(){
		StaticResource langFile;
		String fileName = 'ReportCardsTranslation_'+((displaySpanish && !languageOverride)?'Spanish':'English');

		for(StaticResource sr: [select Name, Description, Body from StaticResource where Name LIKE: fileName order By Description]){
			if(langFile == null || !langFile.name.contains('SchoolForce')){
				langFile = sr;
			}
		}
		
		ldw = new Map<String, String>();
		String[] fileLines = StringUtils.splitAndTrim(langFile.Body.toString(),'\n');
		langFile = null;
		for(String s:fileLines){
			if(s.trim().startsWith('//')){
				continue;
			} else if(s.length() == 0){
				continue;
			} else {
				String[] entry = s.split(':',2);
				if(entry.size() != 2){
					continue;
				}
				ldw.put(entry[0].trim(),entry[1].trim());
			}
		}
	}
	
	private void loadSchoolInfo(){
		card.setup = Gradebook_ReportCard_Utils.getSetupInfo(card.studentInfo.student.Setup__c);
		card.school = Gradebook_ReportCard_Utils.getSchoolInfo(card.studentInfo.student.School__c);
		
		orderedReportingPeriods = Gradebook_ReportCard_Utils.getReportingPeriods(card.Setup.Term__c);
		Map<Id, Time_Element__c> reportingPeriodMap = new Map<ID, Time_Element__c>(orderedReportingPeriods);
		card.reportingPeriod = reportingPeriodMap.get(reportingPeriodId);
		
		if(card.reportingPeriod == null){
			//this will probably never happen, but if for some reason it would, it would be very hard to find.
			throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('FATAL:The selected reporting period is not part of the term listed on the schools setup.');
		}

		bDisplaySectionGrades 	= card.setup.Include_Section_Grades__c;
		bDisplayReadingLevel	= card.setup.Display_Reading_Level_On_Report_Card__c;
		bShowSemesterGrades		= card.setup.Show_Semester_Grades_On_Report_Cards__c;
		bShowHomework			= card.setup.Show_Homework_Percentage__c;
		bShowSectionComments	= card.setup.Show_Section_Comments__c;
		bDisplayStrands			= (bProgressReport)?card.setup.Progress_Report_Standard_Display__c=='Strands':card.setup.Report_Card_Standard_Display__c=='Strands';
		bDisplayStandards		= card.setup.Show_Standard_Grades__c;
		bShowClassRank			= card.setup.Show_Class_Rank__c;

		if(bShowClassRank){
			card.studentInfo.classSize = Gradebook_ReportCard_Utils.getStudentClassSize(card.studentInfo.student.Grade__c, card.StudentInfo.student.School__c);
			
			if(card.studentInfo.student.Class_Rank__c == null){
				writeLog('Show class rank is enabled, but the students class rank is blank. Please rerun the Final Grade batch.');
			}
		}
	}

	private void loadStudentRP(){
		if(card.studentInfo.student.Setup__r.Display_GPA_on_Report_Cards__c || bDisplayReadingLevel){
			List<Student_Reporting_Period__c> srps = Gradebook_ReportCard_Utils.getStudentReportingPeriodList(new Set<ID>{studentID},null);

			Student_Reporting_Period__c srp;
			Map<ID, Student_Reporting_Period__c> rpToSRPMap = new Map<ID, Student_Reporting_Period__c>();

			for(Student_Reporting_Period__c s:srps){
				rpToSRPMap.put(s.Time__c, s);
				if(s.Time__c == reportingPeriodID && srp == null){
					if(srp == null){
						srp = s;
						break; //by breaking here we force only the reporting period up to the generation period to display.
					} else {
						throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('The student has more then one student reporting period record for the generation period. Please review their data and delete the duplicated record.');
					}
				}
				
			}

			if(bDisplayReadingLevel){
				for(Time_Element__c t:orderedReportingPeriods){
					if(rpToSRPMap.containsKey(t.id)){
						card.srps.add(rpToSRPMap.get(t.id));
					} else if(t.Reporting_Period__c) {
						card.srps.add(new Student_Reporting_Period__c(Time__r=t));
					}
				}
			}

			if(card.studentInfo.student.Setup__r.Display_GPA_on_Report_Cards__c){
				if(srp == null){
					throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('The selected student does not have a student reporting period record for the generation period. Please rerun the final grade batch.');
				}

				if(srp.GPA__c != null){
					card.studentInfo.overallGPA = string.valueOf(srp.gpa__c.divide(1,2));
				} else {
					writeLog('The students GPA for this reporting period is null. Please rerun the final gpa batch.');
					card.studentInfo.overallGPA = '';
				}
			}
		}
	}
	
	private void loadFinalGradeNormalizations(){
		//all the error handling for this is within the method, throws DocumentRuntimeException
		card.normalizations = Gradebook_ReportCard_Utils.getFinalGradeNoralizations();
		if(card.normalizations.isEmpty()){
			writeLog('There were no valid default normalizations. Please check your default normalizations.');
		}
	}
	
	private void loadSectionGrades(){
		List<Section_Grade__c> sectionGrades = Gradebook_ReportCard_Utils.getSectionGrades(card.reportingPeriod.End_Date__c, studentID);
		sectionGrades = getActiveGrades(sectionGrades);
		sectionGrades = validateSectionGrades(sectionGrades);
		
		Map<ID, Map<Id, Section_Grade__c>> SectionToSemesterGrades;
		if(bShowSemesterGrades){
			//map is section id to last rp grade covers id to section grade
			SectionToSemesterGrades = loadSemesterGrades();
		}

		
		buildReportingPeriodDisplayList();
		buildGradeDisplay(sectionGrades, sectionToSemesterGrades);
	}

	public void buildReportingPeriodDisplayList(){
		for(Integer i=0;i< orderedReportingPeriods.size();i++){
			Time_Element__c rp = orderedReportingPeriods[i];
			if(rp.Reporting_Period__c || includedFinalRPs.contains(rp.id)){
				String rpName = (rp.Name_On_Report_Card__c != null)?rp.Name_On_Report_Card__c:rp.Name__c;
				card.reportingPeriodDisplayList.add(rpName);
				if(bShowSemesterGrades && rpBeforeSemesterGrade.contains(rp.id)){
					if(!orderedReportingPeriods[i+1].Reporting_Period__c && includedFinalRPs.contains(orderedReportingPeriods[i+1].id)){
						String frpName = (orderedReportingPeriods[i+1].Name_On_Report_Card__c!=null)?orderedReportingPeriods[i+1].Name_On_Report_Card__c:orderedReportingPeriods[i+1].Name__c;
						card.reportingPeriodDisplayList.add(frpName);
						i++;
					}
					card.reportingPeriodDisplayList.add(rpName+'SEM');
				}
			} else { //we need to get rid of final reporting periods that are not in use
				orderedReportingPeriods.remove(i);
				i--;
			}
		}
	}
	
	private void loadFinalGrades(){
		//Map is course ID to final grade
		Map<ID, Final_Grade__c> finalGradeMap = buildFGMap(studentId);
		
		for(SectionWrapper sw:card.sectionWrappers){
			if(finalGradeMap.containsKey(sw.courseID)){
				Final_Grade__c fg = finalGradeMap.get(sw.courseId);
				//don't let this confuse you, display numerical = true always outputs the students raw 0-100 grade
				//display numerical = false outputs values based on the grade scale type
				if(fg.Final__c || bProgressReport){
					if(fg.Course__r.Display_Numerical_Values_On_Report_Card__c){
						sw.sectionGrade = string.valueOf(fg.Final_Grade_Value__c);
					} else {
						sw.sectionGrade = fg.Display_Final_Grade_Formula__c;
					}

					if(sw.sectionGrade == null || sw.sectionGrade == ''){
						writeLog('A final grade with ID '+ fg.id+ ' has a blank or null value. Please verify the value is correct.');
					}
				} else if(!bProgressReport){
					writeLog('The final grade value for the final grade with ID '+fg.id+ ' was excluded because it was not marked final.');
				}
			}
		}
	}

	public static Map<ID, Final_Grade__c> buildFGMap(ID studentID){
		//Map is course ID to final grade
		Map<ID, Final_Grade__c> finalGradeMap = new Map<Id, Final_Grade__c>();
		
		for(Final_Grade__c fg : Gradebook_ReportCard_Utils.getFinalGrades(studentID)){
			finalGradeMap.put(fg.Course__c, fg);
		}
		return finalGradeMap;
	}
	
	private void loadSectionTeachers(){
		Map<ID, List<String>> sectionStaff = new Map<ID, List<String>>();
		for(Staff_Section__c ss : Gradebook_ReportCard_Utils.getInstructionalStaff(sections)){
			if(sectionStaff.containsKey(ss.Section__c)){
				sectionStaff.get(ss.Section__c).add(ss.Staff__r.Name);
			} else {
				sectionStaff.put(ss.Section__c, new List<String>{ss.Staff__r.Name});
			}
		}
		
		for(SectionWrapper sw:card.sectionWrappers){
			if(sectionStaff.containsKey(sw.sectionId)){
				sw.teachers = String.join(sectionStaff.get(sw.sectionId),', ');
			} else {
				writeLog('There are no staff listed for display for section '+sw.sectionID);
			}
		}
	}
	
	private void loadHomeworkInfo(){
		//map is section id to homework completion percentage
		Map<ID,String> sectionToHWMap = new Map<ID, String>();
		ID sectionID;
		decimal totalHW = 0;
		decimal totalIncomplete = 0;
		List<HW_Tracker__c> hwList = Gradebook_ReportCard_Utils.getStudentHomework(studentID, sections, card.reportingPeriod.End_Date__c);
		for(Integer i=0;i<hwlist.size();i++){
			HW_Tracker__c hw = hwList[i];
			sectionId = hw.Student_Section__r.Section__c;
			totalHW++;
			if(hw.Picklist_Value__c == null){
				writeLog('A homework record with ID '+hw.id+' has a null status. Please verify the status of that record.');
			}
			if(hw.Picklist_Value__r.Category__c == 'Incomplete'){
				totalIncomplete++;
			}
			if(i == hwList.size()-1 || hwList[i+1].Student_Section__r.Section__c != sectionID){
				if(sectionID != null){
					long hwpercent = (totalHW>0)?((totalHW - totalIncomplete)/totalHW*100).round():0;
					sectionToHWMap.put(sectionID, String.valueof(hwPercent));
				}
					
				sectionId = hw.Student_Section__r.Section__c;
				totalHW = 0;
				totalIncomplete = 0;
			}
		}
		
		for(SectionWrapper sw:card.sectionWrappers){
			if(sectionToHWMap.containsKey(sw.sectionID)){
				sw.homeworkPercentage = sectionToHWMap.get(sw.sectionID);
			}
		}
	}
	
	public void loadAttendanceInfo(){
		List<Attendance__c> attendanceList = Gradebook_ReportCard_Utils.getStudentAttendance(card.reportingPeriod.End_Date__c, studentID);
		//daily totals
		Decimal totalUnexcusedAbs = 0;
		Decimal totalAbsent = 0;
		Decimal totalTardy = 0;
		Decimal totalPresent = 0;
		
		//sectional Totals
		Decimal sectionAbsent = 0;
		Decimal sectionTardy = 0;
		Decimal sectionUnexcusedAbs = 0;
		
		//going to be a bit lazy here and use maps
		//Map is section id to sectionTardy
		Map<Id, String> sectionToTardy = new Map<ID,String>();
		//Map is section id to % unexcused absence
		Map<ID, String> sectionToUAPercent = new Map<Id, String>();
		//Map is section Id to sectionAbsent
		Map<ID, String> sectionToAbs = new Map<Id, String>();		
		
		for(Integer i=0;i<attendanceList.size();i++){
			Attendance__c a = attendanceList[i];
			if(a.Picklist_Value__c == null){
				writeLog('An attendance record with ID '+a.id+' does not have a status. Please verify the status of that record.');
				continue;
			}
			if(a.Daily__c){
				if(a.Picklist_Value__r.Category__c=='Absent'){
					totalAbsent++;
                    if(a.Picklist_Value__r.Is_Unexcused__c){
						totalUnexcusedAbs++;
					}
				} else if(a.Picklist_Value__r.Category__c=='Partial' || a.Picklist_Value__r.Category__c=='Present'){
					totalPresent++;
					if(a.Picklist_Value__r.Category__c=='Partial' && a.Picklist_Value__r.Is_Tardy__c){
						totalTardy++;
					}
				}
			}
			
			if(card.setup.Show_Sectional_Attendance_on_Report_Card__c){
				if(a.Picklist_Value__r.Category__c=='Absent'){
					sectionAbsent++;
					if(a.Picklist_Value__r.Is_Unexcused__c){
						sectionUnexcusedAbs++;
					}
				}else if(a.Picklist_Value__r.Category__c=='Partial' && a.Picklist_Value__r.Is_Tardy__c){
					sectionTardy++;
				}
				
				if(i == attendanceList.size()-1 || attendanceList[i+1].Session__r.Section__c != a.Session__r.Section__c){
					long UApercent = (sectionAbsent>0)?((sectionUnexcusedAbs)/sectionAbsent*100).round():0;
					sectionToUAPercent.put(a.Session__r.Section__c, String.valueof(UAPercent));
					sectionToTardy.put(a.Session__r.Section__c, String.valueof(sectionTardy));
					sectionToAbs.put(a.Session__r.Section__c, String.valueof(sectionAbsent));
					
					sectionAbsent = 0;
					sectionTardy = 0;
					sectionUnexcusedAbs = 0;
				}
			}
		}
		
		card.totalAbsent = String.valueOf(totalAbsent);
		card.totalTardy = String.valueOf(totalTardy);
		//card.unexcusedPercent = String.valueOf((totalAbsent>0)?((totalUnexcusedAbs)/totalAbsent*100).round():0);
		//US2970
		card.unexcusedPercent = String.valueOf(totalUnexcusedAbs);
		
		for(SectionWrapper sw:card.sectionWrappers){
			if(sectionToAbs.containsKey(sw.sectionId)){
				sw.totalAbsent = sectionToAbs.get(sw.sectionId);
				sw.totalTardies = sectionToTardy.get(sw.sectionId);
				sw.unexcusedPercent = sectionToUAPercent.get(sw.sectionID);
			}
		}
	}

	private void loadAssignmentInfo(){
		//Map is section id to count of assignment with incomplete grades
		Map<ID, Integer> incompletAssignements = Gradebook_ReportCard_Utils.getIncomplateAssignments(card.reportingPeriod.End_Date__c, studentID);
		for(SectionWrapper sw:card.sectionWrappers){
			if(incompletAssignements.containsKey(sw.sectionId)){
				sw.incompleteGrades = incompletAssignements.get(sw.sectionId);
			}
		}
	}
	
	//convert this to loadstrandgrades -> loadstandardgrades
	private void loadStandardGrades(){
		List<Standard_Grade__c> standardGrades = Gradebook_ReportCard_Utils.getStandardGrades(StudentID, card.reportingPeriod.End_Date__c);
		Map<String, List<standardWrapper>> standardSubjectMap = new Map<String, List<standardWrapper>>();
		
		for(Integer i=0;i<standardGrades.size();i++){		
			String standard = standardGrades[i].Standard__c;
			standardWrapper sw = new standardWrapper();
			sw.subject = (standardGrades[i].Standard__r.Strand__r.Subject__c != null)?standardGrades[i].Standard__r.Strand__r.Subject__c:(standardGrades[i].Standard__r.Subject__c!=null)?standardGrades[i].Standard__r.Subject__c:'';			
			
			sw.Name = standardGrades[i].Standard__r.Name;
			sw.strandName = standardGrades[i].Standard__r.Strand__r.Name;
			sw.Description = (displaySpanish && standardGrades[i].Standard__r.Description_Spanish__c!=null)?standardGrades[i].Standard__r.Description_Spanish__c:standardGrades[i].Standard__r.long_text__c;
			
			for(Time_Element__c rp:orderedReportingPeriods){
				if(i < standardGrades.size()){
					Standard_Grade__c sg = standardGrades[i];
					String sgSubject = (standardGrades[i].Standard__r.Strand__r.Subject__c != null) ? standardGrades[i].Standard__r.Strand__r.Subject__c : (standardGrades[i].Standard__r.Subject__c != null) ? standardGrades[i].Standard__r.Subject__c : '';
					if(sgSubject == sw.subject && sg.Standard__c == standard && sg.Reporting_Period__c == rp.id) {
						if(i>0){
							Standard_Grade__c lastProcessed = standardGrades[i-1];
							String lpSubject = (standardGrades[i-1].Standard__r.Strand__r.Subject__c != null) ? standardGrades[i-1].Standard__r.Strand__r.Subject__c : (standardGrades[i-1].Standard__r.Subject__c != null) ? standardGrades[i-1].Standard__r.Subject__c : '';
							if(sg.Reporting_Period__c == lastProcessed.Reporting_Period__c && sgSubject == lpSubject && sg.Standard__c == lastProcessed.Standard__c && (sgSubject != null)){
								throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('FATAL:Duplicate standard grades were detected (IDs'+lastProcessed.id+' and '+sg.id+'). Please delete the duplicate.');
							}
						}
						if(sg.Standard_Grade__c == null || (sg.Grade_Overridden__c && sg.Grade_Override__c==null)){
							sw.grades.add(new StandardGradeWrapper('',false));
							writeLog('A standard grade with ID '+sg.id+' has a blank or null value. It will not be displayed.');
						} else {
							sw.grades.add(new StandardGradeWrapper(String.valueOf(((sg.Grade_Overridden__c)?sg.Grade_Override__c:sg.Standard_Grade__c).divide(1,1)),false));
						}
						i++;
					} else{
						sw.grades.add(new StandardGradeWrapper('',true));
					}
				} else {
					sw.grades.add(new StandardGradeWrapper('',true));
				}
			}
			i--;
			//sorting standards due to conditional subject?
			if(standardSubjectMap.containsKey(sw.subject)){
				standardSubjectMap.get(sw.subject).add(sw);
			} else{
				standardSubjectMap.put(sw.subject, new List<StandardWrapper>{sw});
			}
		}	
	
		List<String> subjects = new List<String>(standardSubjectMap.keySet());
		subjects.sort();
		for(String subject:subjects){
			card.subjectWrappers.add(new subjectWrapper(standardSubjectMap.get(subject)));   
		}
	}	
	
	private void loadStrandGrades(){
		List<Strand_Grade__c> strandGrades = Gradebook_ReportCard_Utils.getStrandGrades(StudentID, card.reportingPeriod.End_Date__c);
		
		List<standardWrapper> strands = new List<standardWrapper>();
		for(Integer i=0;i<strandGrades.size();i++){
			String strand = strandGrades[i].Strand__c;
			standardWrapper sw = new standardWrapper();
			sw.subject = strandGrades[i].Strand__r.Subject__c;
			sw.Name = strandGrades[i].Strand__r.Name;
			sw.Description = (displaySpanish && strandGrades[i].Strand__r.Description_Spanish__c!=null)?strandGrades[i].Strand__r.Description_Spanish__c:strandGrades[i].Strand__r.long_text__c;
			for(Time_Element__c rp:orderedReportingPeriods){
				if(i<strandGrades.size()){
					Strand_Grade__c sg = strandGrades[i];
					if(sg.Strand__r.Subject__c == sw.subject && sg.Strand__c == strand && sg.Reporting_Period__c == rp.id){
						if(i>0){
							Strand_Grade__c lastProcessed = strandGrades[i-1];
							if(sg.Reporting_Period__c == lastProcessed.Reporting_Period__c && sg.Strand__r.Subject__c == lastProcessed.Strand__r.Subject__c && sg.Strand__c == lastProcessed.Strand__c && sg.Strand__r.Subject__c != null){
								throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('FATAL:Duplicate strand grades where detected (IDs'+lastProcessed.id+' and '+sg.id+'). Please delete the duplicate.');
							}
						}
						if(sg.Grade__c == null || (sg.Grade_Overridden__c && sg.Grade_Override__c==null)){
							sw.grades.add(new StandardGradeWrapper('',false));
							writeLog('A strand grade with ID '+sg.id+' has a blank or null value. It will not be displayed.');
						} else {
							sw.grades.add(new StandardGradeWrapper(String.valueOf(((sg.Grade_Overridden__c)?sg.Grade_Override__c:sg.Grade__c).divide(1,1)),false));
						}
						i++;
					} else{
						sw.grades.add(new StandardGradeWrapper('',true));
					}
				} else {
					sw.grades.add(new StandardGradeWrapper('',true));
				}
			}
			i--; //go back one because we're going to go forward one when we loop, and we haven't used the current i.
			strands.add(sw);
			if(i>=strandGrades.size()-1 || sw.subject != strandGrades[i+1].Strand__r.Subject__c){
				card.subjectWrappers.add(new subjectWrapper(strands));
				strands = new List<standardWrapper>();
			}
		}	
	}
	
	private Map<Id, Map<ID, Section_Grade__c>> loadSemesterGrades(){
		try{
			Map<Id, Map<ID, Section_Grade__c>> sectionToSemesterGrades = buildSemesterGradeMap(card.studentInfo.student.id, reportingPeriodID, orderedReportingPeriods);
			rpBeforeSemesterGrade = new Set<ID>();
			for(ID id:sectionToSemesterGrades.keySet()){
				rpBeforeSemesterGrade.addAll(sectionToSemesterGrades.get(id).keySet());
			}
			return sectionToSemesterGrades;
		} catch (Exception e){ //usually from the .split(), where the ref id is bad.
			writeLog('A semester grade is invalid. Semester grades cannot display until this is corrected. Please verify the semester grades. Rerunning the final GPA batch may correct this issue.');
		}
		return new Map<Id, Map<ID, Section_Grade__c>>();
	}

	public static Map<Id, Map<ID, Section_Grade__c>> buildSemesterGradeMap(ID studentID, ID currentRP, List<Time_Element__c> orderedReportingPeriods){
		//map is section id to last rp grade covers id to section grade
		Map<Id, Map<ID, Section_Grade__c>> sectionToSemesterGrades = new Map<Id, Map<ID, Section_Grade__c>>();
		Map<Id, Time_Element__c> reportingPeriodMap = new Map<ID, Time_Element__c>(orderedReportingPeriods);
		for(Section_Grade__c sg: Gradebook_ReportCard_Utils.getSemesterGrades(studentID)){
			string rpPrev= sg.Reference_ID__c.split('-')[2];
			if(reportingPeriodMap.get(rpPrev).End_Date__c <= reportingPeriodMap.get(currentRP).End_Date__c){
				if(sectionToSemesterGrades.containsKey(sg.Student_Section__r.Section__c)){
					sectionToSemesterGrades.get(sg.Student_Section__r.Section__c).put(rpPrev, sg);
				} else {
					sectionToSemesterGrades.put(sg.Student_Section__r.Section__c, new Map<Id, Section_Grade__c>{rpPrev=>sg});
				}
			}
		}
		
		return sectionToSemesterGrades;
	}
	
	private List<Section_Grade__c> getActiveGrades(List<Section_Grade__c> sgList){
		includedFinalRPs = new Set<ID>();
		List<Section_Grade__c> activeGrades = new List<Section_Grade__c>();
		Set<ID> studentSectionIds = new Set<ID>();
		for(Section_Grade__c sg:sgList){
			if(!bIncludeTransferedSections && !bIncludeInactiveStudentSections && sg.Student_Section__r.Active__c){
				activeGrades.add(sg);
			} else if(bIncludeTransferedSections && !bIncludeInactiveStudentSections){
				studentSectionIDs.add(sg.Student_Section__c);
			} else if(bIncludeInactiveStudentSections){
				activeGrades.add(sg);
			}
		}
		
		if(!studentSectionIDs.isEmpty()){
			Map<Id, List<Enrollment_Tracking__c>> trackingMap =  new Map<Id, List<Enrollment_Tracking__c>>();
			for(Enrollment_Tracking__c et:Gradebook_ReportCard_Utils.getSectionEnrollment(studentSectionIDs)){
				if(trackingMap.containsKey(et.Student_Section__c)){
					trackingMap.get(et.Student_Section__c).add(et);
				} else {
					trackingMap.put(et.Student_Section__c, new List<Enrollment_Tracking__c>{et});
				}
			}
			
			for(Section_Grade__c sg:sgList){
				if(trackingMap.containsKey(sg.Student_Section__c)){
					boolean include = true;
					for(Enrollment_Tracking__c et:trackingMap.get(sg.Student_Section__c)){
						if(et.End_Date__c!=null && et.End_Date__c.date() <= sg.Time__r.End_Date__c){
							//if the period ended before the rp in question, skip it
							continue;
						}
						if(et.End_Date__c == null && et.Start_Date__c.date() <= sg.Time__r.End_Date__c){
							//if they were removed and never put back in that class
							include = false;
							break;
						}
						if(et.Start_Date__c.date() <= sg.Time__r.End_Date__c && et.End_Date__c!=null && et.End_Date__c.date() > sg.Time__r.End_Date__c){
							//if they were removed and then put back after the end of that reporting period
							include = false;
							break;
						}
					}
					if(include){
						activeGrades.add(sg);
					}
				}
			}
		}
		
		return activeGrades;
	}
	
	public List<Section_Grade__c> validateSectionGrades(List<Section_Grade__c> sgList){
		List<Section_Grade__c> validGrades = new List<Section_Grade__c>();
		sections = new Set<Id>();
		orderedSections = new List<ID>();
		courses = new Set<ID>();
		
		for(Section_Grade__c sg:sgList){
			boolean isValid = true;
			//error checking

			if((!sg.Grade_Overridden__c && sg.Grade__c == null) || sg.Grade_Overridden__c && sg.Grade_Override__c==null){
				writeLog('A section grade with ID '+sg.id+' has a null grade or override. It will be not be displayed.');
			}

			if(isValid){
				//we need to know what final reporting periods are in use, so we make a set of the final reporting periods pulled in
				if(!sg.Time__r.Reporting_Period__c)
					includedFinalRPs.add(sg.Time__c);
				validGrades.add(sg);
				if(!sections.contains(sg.Student_Section__r.Section__c)){
					orderedSections.add(sg.Student_Section__r.Section__c);
					sections.add(sg.Student_Section__r.Section__c);
				}
				courses.add(sg.Student_Section__r.Section__r.Course__c);
			}
		}
		
		return validGrades;
	}
	
	public void buildGradeDisplay(List<Section_Grade__c> sectionGrades, Map<Id,Map<Id, Section_Grade__c>> semesterGrades){
		Map<ID, Map<ID, Section_Grade__c>> sectionGradeMap = new Map<ID,Map<ID, Section_Grade__c>>();
		for(Section_Grade__c sg:sectionGrades){
			if(sectionGradeMap.containsKey(sg.Student_Section__r.Section__c)){
				sectionGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Time__c, sg);
			} else {
				sectionGradeMap.put(sg.Student_Section__r.Section__c, new Map<Id, Section_Grade__c>{sg.Time__c=>sg});
			}
		}
		
		string cssClass = 'odd';
		for(ID sectionID: orderedSections){
			SectionWrapper sectionWrapper = new sectionWrapper(sectionID, cssClass);
			boolean addNextCycle = false;
			String semesterGradeToAdd = '';
			for(Integer i=0;i<orderedReportingPeriods.size();i++){
				Time_Element__c rp = orderedReportingPeriods[i];
				if(sectionGradeMap.get(sectionID).containsKey(rp.id)){
					Section_Grade__c sg = sectionGradeMap.get(sectionID).get(rp.id);
					if(sectionWrapper.courseName == null){
						sectionWrapper.courseName = (displaySpanish && sg.Student_Section__r.Section__r.Course__r.Name_Spanish__c != null)?sg.Student_Section__r.Section__r.Course__r.Name_Spanish__c:sg.Student_Section__r.Section__r.Course__r.Name;
						sectionWrapper.courseID = sg.Student_Section__r.Section__r.Course__c;
					}
					string grade = '';
					if(sg.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c && sg.Grade__c != null){
						grade = String.valueOf(sg.Grade__c.divide(1,2));
					} else if(!sg.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c || sg.Grade_Overridden__c) {
						grade = sg.Display_Grade_Formula__c;
					}
					//check for null here, section grades without any entered grades need blank spots
					sectionWrapper.displayGrades.add((grade!=null)?grade:'');
					
					//section comments only display for reporting periods not final reporting periods
					if(bShowSectionComments && sg.Time__c == card.reportingPeriod.id && sg.Time__r.Reporting_Period__c){
						sectionWrapper.sectionComments = (displayAltLangFields && sg.Alternate_Lang_Comments__c != null)?sg.Alternate_Lang_Comments__c:(sg.Comments_Next_Steps__c != null)?sg.Comments_Next_Steps__c:'';
					}
				} else {
					sectionWrapper.displayGrades.add('');
				}

				if(addNextCycle){
					sectionWrapper.displayGrades.add(semesterGradeToAdd);
					addNextCycle = false;
				}
				
				if(bShowSemesterGrades && rpBeforeSemesterGrade.contains(rp.id)){
					//check for semester grades. Uses almost the same logic as above.
					if(semesterGrades.containsKey(sectionID) && semesterGrades.get(sectionId).containsKey(rp.id)){
						Section_Grade__c semG = semesterGrades.get(sectionId).get(rp.id);
						system.debug('Found semester grade with id '+ semG.id);
						string grade = '';
						if(semG.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c){
							grade = String.valueOf(semG.Grade__c.divide(1,2));
						} else if(!semG.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c) {
							grade = semG.Display_Grade_Formula__c;
						}
						semesterGradeToAdd=(grade!=null)?grade:'';
					} else {
						semesterGradeToAdd='';
					}

					if(i+1<orderedReportingPeriods.size() && !orderedReportingPeriods[i+1].Reporting_Period__c){
						addNextCycle = true;
					} else {
						sectionWrapper.displayGrades.add(semesterGradeToAdd);
					}
				}
				
			}
			card.sectionWrappers.add(sectionWrapper);
			cssClass = (cssClass=='odd')?'even':'odd';
		}
	}
	
	/* WRAPPER CLASSES */
	public class reportCardWrapper{
		public studentWrapper studentInfo											{get;set;}
		public Setup__c setup														{get;set;}
		public Account school														{get;set;}
		public Time_Element__c reportingPeriod										{get;set;}
		public List<Gradebook_ReportCard_Utils.normalizationWrapper> normalizations	{get;set;}
		public List<String> reportingPeriodDisplayList								{get;set;}
		public List<sectionWrapper> sectionWrappers									{get;set;}
		public List<subjectWrapper>	subjectWrappers									{get;set;}
		public List<Student_Reporting_Period__c> srps								{get;set;}
		
		public String totalAbsent		{get;set;}
		public String totalTardy		{get;set;}
		public String unexcusedPercent	{get;set;}
		
		public reportCardWrapper(){
			sectionWrappers = new List<SectionWrapper>();
			subjectWrappers = new List<subjectWrapper>();
			reportingPeriodDisplayList = new List<String>();
			srps = new List<Student_Reporting_Period__c>();
		}
	}
	
	public class studentWrapper{
		public Student__c student			{get;set;}
		public Integer classSize			{get;set;}
		public String overallGPA			{get;set;}
		public String finalWeightedGPA		{get;set;}
		public String cumulativeWeightedGPA	{get;set;}
		public String address				{get;set;}
		
		public studentWrapper(Student__c s){
			this.student = s;
			
			this.address = ((s.Address__c!=null)?s.Address__c:'')+
					((s.City__c != null)?(', '+s.City__c):'')+
					((s.State__c != null)?(', '+s.State__c):'')+
					((s.Zip_Code__C != null)?(' '+s.Zip_Code__c):'');
		}
	}
	
	public class sectionWrapper{
		public List<String> displayGrades	{get;set;}
		public String courseName			{get;set;}
		public String teachers				{get;set;}
		public String homeworkPercentage	{get;set;}
		public Integer incompleteGrades		{get;set;}
		public String sectionGrade			{get;set;}
		
		public String totalAbsent			{get;set;}
		public String unexcusedPercent		{get;set;}
		public String totalTardies			{get;set;}
		
		public String sectionComments		{get;set;}
		
		//This is here because renderAs="pdf" sucks and doesn't support nth-child css selectors
		public String cssClass				{get;set;}
		
		public ID sectionId;
		public ID courseId					{get;set;}
				
		public sectionWrapper(ID secID, String rowColor){
			this.sectionId = secID;
			displayGrades = new List<String>();
			cssClass = rowColor;
			
			sectionGrade = '';
			homeworkPercentage = '';
			incompleteGrades = 0;
			
			totalAbsent = '';
			totalTardies = '';
			unexcusedPercent = '';
		}
	}
	
	public class subjectWrapper{
		public List<standardWrapper> standards	{get;set;} //can be strands too
		public String subject					{get;set;}
		
		public subjectWrapper(List<standardWrapper> standards){
			this.standards = standards;
			this.subject = this.standards[0].subject;
		}
	}
	
	public class standardWrapper{
		public List<standardGradeWrapper> grades	{get;set;}
		public String description					{get;set;}
		public String strandName					{get;set;}
		public String Name							{get;set;}
		public String cssClass						{get;set;}
		
		transient public String subject;
		
		public standardWrapper(){
			grades = new List<standardGradeWrapper>();
		}
		
	}

	public class standardGradeWrapper{
		public String grade				{get;set;}
		public Boolean isMissingRecord	{get;set;}

		public standardGradeWrapper(String grade, Boolean isMissingRecord){
			this.grade = grade;
			this.isMissingRecord = isMissingRecord;
		}
	}

	public void saveLog(){
		upsert log;
	}

	private void writeLog(String message){
		log.Log__c += message+'\n';
		log.Status__c = 'Complete - With Warnings';
	}

	private void writeError(String message){
		log.Error_Message__c += message+'\n';
		log.Status__c = 'Failed';
	}
}
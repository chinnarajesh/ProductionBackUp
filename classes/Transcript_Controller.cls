public class Transcript_Controller {
	public Student__c student					{get;set;}									
	public Student__c pictureHolder				{get;set;} 
	public List<GradeWrapper> studentGradeList	{get;set;} 
	public studentWrapper studentWrapper		{get;set;} 
	public Time_Element__c reportingPeriod		{get;set;} 
	public string debug							{get;set;} 
	public boolean bSchoolPicture				{get;set;}
	public string imageString					{get;set;}
	public List<String> GradeScale				{get;set;}
	public List<ReportingKey> rkList1			{get;set;}
	public List<ReportingKey> rkList2			{get;set;}
	public Decimal cumCredits					{get;set;}
	public Boolean renderPDF					{get;set;}
	public Boolean bOfficialTranscript			{get;set;}
	private Document_Log__c log;
	
	public Transcript_Controller(){
		renderPDF = System.currentPageReference().getParameters().get('pdf')==null;
		Map<String, Final_Grade__c> finalGradeMap					   = new Map<String, Final_Grade__c>();	 
		List<String> gradeTransformMap								  = new List<String>();
		Map<String, Boolean> letterDisplayMap						   = new Map<String, Boolean>();
		studentGradeList												= new List<GradeWrapper>();   
		String standardDisplaySelectionPR;
		List<Assesment__c> AssesmentList								= new List<Assesment__c>();
		cumCredits = 0;
		
		student = new Student__c();
		List<Student_PG__c> parent_Gaurdian = new List<Student_PG__c>();
		reportingPeriod = new Time_Element__c();
		studentWrapper = new studentWrapper();
		string studentId; 
		string contactId;
		string currRepPdId; 
		debug = '<table border="2"cellpadding="3"><tr><td>';
		try{
			studentId = System.currentPageReference().getParameters().get('student');
			contactId = System.currentPageReference().getParameters().get('contactId');
			
			//US3281
			bOfficialTranscript = Boolean.valueOf(System.currentPageReference().getParameters().get('Official'));
			
			log = new Document_Log__c(ID = System.currentPageReference().getParameters().get('logID'),
					RecordTypeId = core_soqlUtils.getRecordTypesBySobject('Document_Log__c').get('Transcript'));
			
			system.debug('studentID ' + studentId);
			
			OverrideSettings__c settings = OverrideSettings__c.getInstance(UserInfo.getUserId());
			String[] allow = new List<String>();
			if(settings.Allowable_Grades__c != null){
				allow = settings.Allowable_Grades__c.split(',');
			}
			Set<String> allowSet = new Set<String>();
			if(!allow.isEmpty()){
				for(String ovg: allow)
					allowSet.add(ovg.trim());
			}

			bSchoolPicture = false;
			pictureHolder = [Select ID, Setup__r.Standards_Only_Gradebook__c, Setup__r.School_Picture__c from Student__c where ID = : studentId]; //grab the school picture seperately to minimize view state
			
			if(pictureHolder.Setup__r.School_Picture__c==null || pictureHolder.Setup__r.School_Picture__c==''){
				pictureHolder = [Select ID, Setup__r.Standards_Only_Gradebook__c, School__r.School_picture__c from Student__c where ID = : studentId];	 
				bSchoolPicture = true;
			}
			else{	
				try{
					String tempSRC = string.valueOf(pictureHolder.Setup__r.School_Picture__c);
					integer startSRC = tempSRC.indexOf('src="')+5;
					integer endSRC = tempSRC.indexOf('"></img>');
					imageString = string.valueOf(pictureHolder.Setup__r.School_Picture__c).substring(startSRC, endSRC);
					imageString = imageString.replace('amp;','');
				} catch (Exception e){
					system.debug('Error: School Picture malformed. Unable to display.');
				}
			}
			
			student = [Select   ID,
								Student_ID__c,
								Individual__c,
								Grade__c,
								Name,
								Date_of_Birth__c,
								Final_GPA_Value__c,
								GPA_To_Date__c,
								Weighted_GPA_To_Date__c,
								Final_Weighted_GPA_Value__c,
								Class_Rank__c,
								School__c,
								School__r.Principal__r.Name,
								School__r.BillingStreet,
								School__r.BillingState,
								School__r.BillingPostalCode,
								School__r.BillingCountry,
								School__r.BillingCity,
								School__r.Name,
								School__r.School_Full_Name__c,
								School__r.phone,
								School__r.Website,
								Comments__c,
								Alternate_Lang_Comments__c,
								Address__c,
								City__c,
								Zip_Code__c,
								State__c,
								Actual_graduation_date__c,
								Setup__r.CEEB_Code__c,
								Setup__r.Registrar__c,
								Setup__r.Registrar_Phone__c,
								Setup__r.Counselor__c,
								Setup__r.Show_Normalizations_on_Report_Cards__c,
								Setup__r.Show_Standard_Scale_on_Report_Cards__c,
								Setup__r.Standard_Legend_1__c,
								Setup__r.Standard_Legend_2__c,
								Setup__r.Standard_Legend_3__c,
								Setup__r.Standard_Legend_4__c,
								Setup__r.Display_GPA_on_Report_Cards__c,
								
								//US3229 release: Fall 2013
								Setup__r.Show_Class_Rank_on_Transcripts__c,
								
								//US3230 release: Fall 2013 iteration 2
								Setup__r.Show_Assessments_on_Transcripts__c,
								Setup__r.Show_Activities_on_Transcripts__c,
								Setup__r.Show_Honors_on_Transcripts__c,
								
								//US3254 release: Fall 2013 iteration 2
								Setup__r.Show_Notes_on_Transcripts__c,
								Setup__r.Notes_on_Transcripts__c,
								Setup__r.Show_Signature_on_Transcripts__c,
								
								Graduation_Indicator__c,
								Legacy_ID__c
								from Student__c where id = : studentID];
			
			parent_Gaurdian=[select PG_First_Name__c ,PG_Last_Name__c from Student_PG__c where Student__c = :studentID Limit 2];
			
			
			AssesmentList=[select Type__r.Name,Assessment_Results__c from Assesment__c where Show_On_Transcript__c=:true and (Student__c =: studentID or Contact__c=:student.Individual__c)];
			
								
			integer classSize = [select count() from Student__c 
								where School__c =: student.School__c
								AND Grade__c =: student.Grade__c
								AND Active__c = true
								AND Archived__c = false];

		   
			studentWrapper.StudentID			= student.Student_ID__c;
		   
			studentWrapper.Grade				= student.Grade__c;
			string deNulledAddress = '';
			if(student.City__c != null && deNulledAddress!= '') deNulledAddress += ', ' + student.City__c;
			else if(student.City__c != null) deNulledAddress += student.City__c;
			if(student.State__c != null && deNulledAddress!= '') deNulledAddress += ', ' + student.State__c;
			else if(student.State__c != null) deNulledAddress += student.State__c;
			if(student.Zip_Code__c != null ) deNulledAddress += ' ' + student.Zip_Code__c;
			studentWrapper.Address1 = (student.Address__c != null)?student.Address__c:'';
			studentWrapper.Address2 = deNulledAddress;
			studentWrapper.StateID = (student.Legacy_Id__c != null)?student.Legacy_Id__c:'';
			
			studentWrapper.schoolStreetAddress1 = student.School__r.BillingStreet;
			studentWrapper.schoolStreetAddress2 = student.School__r.BillingCity + ', ' + student.School__r.BillingState + ' '+ student.School__r.BillingPostalCode ;
			studentWrapper.principal			= student.School__r.Principal__r.Name;
			studentWrapper.dateOfBirth			= string.valueOf(date.valueOf(student.Date_of_Birth__c));
			studentWrapper.studentName			= student.Name;
			studentWrapper.overallGPA			= (student.Weighted_GPA_To_Date__c != null)?string.valueOf(student.Weighted_GPA_To_Date__c.divide(1,2)):'';
			studentWrapper.overallUnWeightedGPA	= (student.GPA_To_Date__c != null)?string.valueOf(student.GPA_To_Date__c.divide(1,2)):'';
			studentWrapper.classRank			= string.valueOf(student.Class_Rank__c);
			studentWrapper.classSize			= string.valueOf(classSize);
			studentWrapper.counselor 			= student.Setup__r.Counselor__c;
			studentWrapper.CEEB 				= student.Setup__r.CEEB_Code__c;
			studentWrapper.registrar			= student.Setup__r.Registrar__c;
			studentWrapper.registrarPhone		= student.Setup__r.Registrar_Phone__c;
			
			//EE 11/2 changed from Name to School Full Name for DE2510
			studentWrapper.schoolName = student.School__r.School_Full_Name__c!=null?student.School__r.School_Full_Name__c:student.School__r.Name;
			if(student.School__r.phone != null) studentWrapper.schoolPhone = student.School__r.phone;
			if(student.School__r.Website != null) studentWrapper.schoolWebsite = student.School__r.Website;
			
			studentWrapper.ActualGraduationDate=string.valueOf(student.Actual_graduation_date__c);
			
			if(student.Graduation_Indicator__c==true)
			{
				studentWrapper.Grade='Graduated';
			}
			
			string tempPGInfo = '';
			for(Student_PG__c pg:parent_Gaurdian)
			{
				if(tempPGInfo!='')
				{
					tempPGInfo+=',';
				}
				
				if(pg.PG_First_Name__c!=null)
				{
					tempPGInfo+=pg.PG_First_Name__c;
				}
				if(pg.PG_Last_Name__c!=null)
				{
					tempPGInfo+= '  '+pg.PG_Last_Name__c;
				}
				
			}
			studentWrapper.parentInfo=tempPGInfo;
			
			string tempAssess = '';
			for(Assesment__c a: AssesmentList){
				if(tempAssess!='')
					tempAssess+=',';
				
				if(a.Type__c!=null)
					tempAssess += a.Type__r.Name + ': ';
				
				if(a.Assessment_Results__c!=null)
					tempAssess += a.Assessment_Results__c;
			}
			studentWrapper.Assessment=tempAssess;

			if (contactId != null) {
				List<Integer> StartDate=new  List<Integer>();
				List<Integer> EndDate=new  List<Integer>();
				List<Student__c> studentList = [SELECT Setup__c ,School_Year__r.Date_Start_Date__c
											,School_Year__r.End_Date__c,Id,School__r.Name
											,Setup__r.Year__c
											,Setup__r.Standards_ONLY_Gradebook__c
											,Setup__r.Term__c,School_Year__r.Name__c
											,School_Year__c,Combined_Final_Grade_Values__c
											,Final_GPA_Value__c
											,Setup__r.Passing_Grade_Threshold__c 
										FROM Student__c 
										WHERE Individual__c = :contactId
										and School__r.RecordType.Name = 'School'
										and School__c =: student.School__c
										order by School_Year__r.Date_Start_Date__c ASC];
			   	Double transferPassingThreshold = -1;
			   	if(!studentList.isEmpty()){
			   		transferPassingThreshold = studentList[studentList.size()-1].Setup__r.Passing_Grade_Threshold__c;
			   	}
				for(Student__c stu: studentList){			  							
					//make a new grade wrapper for each student year
					GradeWrapper grade=new GradeWrapper();
					grade.reportingYear=stu.School_Year__r.Name__c;
					grade.finalGPA=stu.Final_GPA_Value__c;
					if(stu.School_Year__r.Date_Start_Date__c!=null){
						StartDate.add(Integer.valueof(stu.School_Year__r.Date_Start_Date__c.year()));
					}
					if(stu.School_Year__r.End_Date__c!=null){
						EndDate.add(Integer.valueof(stu.School_Year__r.End_Date__c.year()));
					}
					
					Decimal creditsEarned = 0;
					
					Map<String, List<FinalGradeWrapper>> schoolGradeMap = new Map<String, List<FinalGradeWrapper>>(); 
					for(Final_Grade__c fg : [Select ID,Student__c,Course__c
													,Course_Credits__c,Course__r.Name, Credits_Earned__c
													,Course__r.Display_Numerical_Values_On_Report_Card__c
													,Final_Grade_Letter_v2__c,Final_Grade_Value__c
													,Display_Final_Grade_Formula__c,Transfer_School__c
												from Final_Grade__c 
												where Student__c = : stu.id
												AND Final__c = true
												AND Course__r.Exclude_from_GPA__c = false
												and Course__r.Exclude_on_RC_Transcripts__c = false
												order by Transfer_School__c, Course__r.Name]){
						
						FinalGradeWrapper fgWrapper=new FinalGradeWrapper();
						fgWrapper.courseName=fg.Course__r.Name;
						
						if(fg.Course__r.Display_Numerical_Values_On_Report_Card__c){
							fgWrapper.finalGrade = String.ValueOf(fg.Final_Grade_Value__c.divide(1,1));
						} else {
							fgWrapper.finalGrade = fg.Display_Final_Grade_Formula__c;
						}
						
					 	decimal fgCreditsEarned; //only concerned about credits earned here since GPA credits calculated in GPA batch/rollup fields
						 fgCreditsEarned = fg.Credits_Earned__c==null ? 0 : fg.Credits_Earned__c; // Credits earned is a formula on FG that looks at override or the threshold to determine credit
						creditsEarned += fgCreditsEarned; //Add to total creditsEarned 
						cumCredits += fgCreditsEarned;  //Add to total cumulative credits Earned
						fgWrapper.creditEarned=String.ValueOf(fgCreditsEarned);
						
						if(fg.Transfer_School__c == null || fg.Transfer_School__c == ''){
							//build the school map
							if(schoolGradeMap.containsKey(stu.School__r.Name)){
								schoolGradeMap.get(stu.School__r.Name).add(fgWrapper);
							} else {
								schoolGradeMap.put(stu.School__r.Name, new List<FinalGradeWrapper>{fgWrapper});
							}
						} else {
							//build the school map
							if(schoolGradeMap.containsKey(fg.Transfer_School__c)){
								schoolGradeMap.get(fg.Transfer_School__c).add(fgWrapper);
							} else {
								schoolGradeMap.put(fg.Transfer_School__c, new List<FinalGradeWrapper>{fgWrapper});
							}
						}
					}
					
					for(string s:schoolGradeMap.keySet()){
						SchoolWrapper sWrap = new SchoolWrapper(s, schoolGradeMap.get(s));
						grade.schools.add(sWrap);
					}
					
					grade.creditAccu = creditsEarned.divide(1,2);
					studentGradeList.add(grade);
					if(studentGradeList.size() > 6){
						studentGradeList.remove(0);
					}
				}
				studentWrapper.cumCredits = String.ValueOf(cumCredits);
				if(EndDate!=null && StartDate!=null)
				{
				 EndDate.sort();
				 StartDate.sort();
				 studentWrapper.PeriodInfo=StartDate[0]+' - '+ EndDate[EndDate.size()-1];
				}
				
				for(integer i=0;studentGradeList.size()<6;i++){
					GradeWrapper tempGradePerYear=new GradeWrapper();
					tempGradePerYear.isFake = true;
					tempGradePerYear.reportingYear='		 ';
					tempGradePerYear.schools.add(new schoolWrapper('N/A', new List<finalGradeWrapper>()));
					studentGradeList.add(tempGradePerYear);
				}	
				
				Contact studentContact=[Select Activities__c,Honors__c
													,Service_Hours_Completed__c
													,Actual_Graduation_Date__c
													,Projected_Cohort_Graduation_Date__c 
												from Contact
												where id=:contactId limit 1];
												
				studentWrapper.Activities=studentContact.Activities__c;
				studentWrapper.Honors=studentContact.Honors__c;
		  		studentWrapper.totalServicehours=String.ValueOf(studentContact.Service_Hours_Completed__c) ;	   
		   		studentWrapper.projectedGraduationDate=String.ValueOf(studentContact.Projected_Cohort_Graduation_Date__c);
				studentWrapper.ActualGraduationDate=String.valueOf(studentContact.Actual_Graduation_Date__c);
			}else{
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,' The Student is not associated to the Contact'));
			}
			
			//build normalization map for progress report grade display
			List<Grade_Normalization__c> gnList = new List<Grade_Normalization__c>();
			for(Grade_Normalization__c gn: [Select ID, GP_Value__c, Grade_Value__c, Transformed_Grade__c from Grade_Normalization__c where picklist_value__c =null and gp_value__c!=null order by Grade_value__c desc]){
				gnList.add(gn);
				//build display lists for grade scale key
			}
			List<ReportingKey> rkList = new List<ReportingKey>();//taken from old report card controller
			String lastLetter;
			decimal lowestValue;
			decimal higestValue;
			//Whenever the transformed grade is not matching the old Grade value, add the range and grade letter to the list
			for(Integer i=0;i<gnList.size();i++){
				if(lastLetter == null){
					lastLetter = gnList[i].Transformed_Grade__c;
					higestValue = gnList[i].Grade_value__c;
					lowestvalue = gnList[i].Grade_value__c;
					continue;
				}
				if(lastLetter != gnList[i].Transformed_Grade__c){
					rkList.add(new ReportingKey(lastLetter, lowestValue+' - '+higestValue,rkList.size()));
					higestValue = lowestValue - .01;
					lowestValue = gnList[i].Grade_value__c;
					lastLetter = gnList[i].Transformed_Grade__c;
				} else {
					lowestvalue = gnList[i].Grade_value__c;
				}
				
				if(i==(gnList.size()-1)){
					rkList.add(new ReportingKey(lastLetter, lowestValue+' - '+higestValue,rkList.size()));
				}
			}

			//Split the rkList into 2 separate list so the reporting key can be shown in 2 different tables in UI
			rkList1 = new List<ReportingKey>();
			rkList2 = new List<ReportingKey>();
			Integer i = 0;
			Integer counter = 0;
			Boolean reset = false;
			for(ReportingKey rk : rkList)
			{
				//if(rkList1.size()<=(math.round(rkList.size()/2)))
				//{
					//provide styling class					
					rk.column = 'column' + String.valueOf(counter);
					if(reset && i == 0) {
						rk.column += ' reset';
					}
										
					if(Math.mod(counter,2)==0) {
						rk.bgColor = '#FFFFFF';
					}
					else {
						rk.bgColor = '#D8D8D8';
					}											
										
					rkList1.add(rk);
					i++;
					if(i == 3) {
						i = 0;
						counter++;
						reset = true;						
					}
				/*
				}
				else
				{
					//if the rklist.size is a odd number then interchange the colors to maintain the alternating white & gray rows in UI
					if(math.mod(rkList.size(),2)!=0)
					{
						if(rk.bgColor=='#D8D8D8')
						{
							rk.bgColor = '#FFFFFF';
						}
						else if(rk.bgColor=='#FFFFFF')
						{
							rk.bgColor = '#D8D8D8';
						}
					}
					rkList2.add(rk);
				}
				*/
			}
			
			
			Map<String , List<Double>> tempgradeScale=new Map<String , List<Double>>();
			for(Grade_Normalization__c gn: [Select ID, GP_Value__c, Grade_Value__c, Transformed_Grade__c from Grade_Normalization__c where IsFinal__c = true order by Grade_value__c desc]){
				
				if(tempgradeScale!=null && tempgradeScale.containskey(gn.Transformed_Grade__c))
				{
					List<Double> temp=tempgradeScale.get(gn.Transformed_Grade__c);
					temp.add(gn.GP_Value__c);
					temp.sort();
					tempgradeScale.put(gn.Transformed_Grade__c,temp);
					
				}
				else
				{ 
				List<Double> temp=new List<Double>();   
				temp.add(gn.GP_Value__c);
				tempgradeScale.put(gn.Transformed_Grade__c, temp);
				}
				
			}
			if(tempgradeScale!=null)
			{
				for(String a:tempgradeScale.keySet())
				{
					List<Double> temp=tempgradeScale.get(a);
					String range='';
					if(temp.size()>1)
					{
						system.debug('temp[0] ***'+temp[0]+'temp[temp.size()-1]  ******* '+temp[temp.size()-1] );
						if(temp[0]!=temp[temp.size()-1])
						{
						range=string.valueOf(temp[0]);
						range+='-';
						range+=string.valueOf(temp[temp.size()-1]);
						}
						else
						{
							range=string.valueOf(temp[temp.size()-1]);
						}
					}
					gradeTransformMap.add(a+' '+range);
				}
				gradeScale =gradeTransformMap;
			}
			system.debug('Generation complete.');
			log.Status__c = 'Complete';
		} catch (Exception e){
			Apexpages.addMessage(new apexpages.message(apexpages.severity.FATAL, 'Error pulling the data for the transcript template'));
			log.Status__c = 'Failed';
		}
	}

	public void saveLog(){
		upsert log;
	}
	
	/* Outer wrapper, contains info for the student */
	public class studentWrapper{
		public String StudentID				 	{get;set;}
		public String Grade					 	{get;set;}
		public String Address1				  	{get;set;}
		public String Address2					{get;set;}
		public String schoolStreetAddress1		{get;set;}
		public String schoolStreetAddress2		{get;set;}
		public String dateOfBirth			   	{get;set;}
		public String principal				 	{get;set;}
		public String studentName			   	{get;set;}
		public String issueDate				 	{get;set;}
		public String overallGPA				{get;set;}
		public String overallUnWeightedGPA	  	{get;set;}
		public String transcriptYear			{get;set;}
		public String PeriodInfo				{get;set;}
		public String counselor					{get;set;}
		public String registrar					{get;set;}
		public String registrarPhone			{get;set;}
		public String CEEB						{get;set;}
		public String projectedGraduationDate   {get;set;}
		public String ActualGraduationDate	  	{get;set;}
		public String cumCredits				{get;set;}
		public String StateID					{get;set;}
		
		public String Honors					{get;set;}
		public String totalServicehours		 	{get;set;}
		public string classRank				 	{get;set;}
		public string classSize				 	{get;set;}
		public string schoolName				{get;set;}
		public string schoolWebsite				{get;set;}
		public string schoolPhone				{get;set;}
		public string parentInfo				{get;set;}
		public string Activities				{get;set;}
		public string Assessment				{get;set;}
		
		public list<GradeWrapper> gradeList	 {get;set;}
		
		

		public studentWrapper(){
			issueDate = string.valueOf(system.today());
			gradeList = new list<GradeWrapper>();
		}
	}
	
	/* inner wrapper, contains info for each grade in the system */
	public class GradeWrapper{
		public string cssClass				{get;set;}
		public string reportingYear			{get;set;}
		public decimal finalGPA				{get;set;}
		public decimal creditAccu			{get;set;}
		public List<SchoolWrapper> schools	{get;set;}
	   	public boolean isFake				{get;set;}
		
		public GradeWrapper(){
			this.schools = new List<schoolWrapper>();
			this.isFake = false;
		}
	}
	
	public class schoolWrapper{
		public List<FinalGradeWrapper> FinalGrades  {get;set;}
		public String schoolName					{get;set;}
		
		public schoolWrapper(string s, List<FinalGradeWrapper> fgList){
			schoolName = s;
			finalGrades = fgList;
		}
	}
	
	/* inner wrapper, contains info for each final grade */
	public class FinalGradeWrapper{
		public String cssClass			  {get;set;}
		public List<String> sectionGrades   {get;set;}
		public String comments			  {get;set;}
		public String courseName			{get;set;}
		public String sectionName		   {get;set;}
		public String finalGrade			{get;set;}
		public String creditEarned		  {get;set;}

		public FinalGradeWrapper(){
			sectionGrades = new List<String>();
		}
	}
	public class reportingKey{
		public String range {get;set;}
		public String grade {get;set;}
		public String bgColor {get;set;}
		public String column {get; set;}
		public reportingKey(String g, String r, Integer bg){
			range = r;
			grade = g;
			bgColor = (Math.mod(bg,2)==0)?'#FFFFFF':'#D8D8D8';
		}
	}

	static testMethod void test_runreportcardscontroller(){
		testdatasetuputil_v2.setUPCoreData(3);
		testdatasetuputil_v2.setUPStaffData(3);
		testdatasetuputil_v2.setUPStudentData(3);
		testdatasetuputil_v2.setupSessiondata();
		
		List<Picklist_Value__c> picklistVals = new List <Picklist_Value__c>();
		 string recTypeGradeScale = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Grade_Scale');
		pickListVals.add(new Picklist_Value__c(Name = 'Points', Type__c = 'Grade_Scale', Display_Code__c = 'test',RecordTypeId = recTypeGradeScale));//8
		pickListVals.add(new Picklist_Value__c(Name = 'CCS', Type__c = 'Grade_Scale', Display_Code__c = 'test',RecordTypeId =recTypeGradeScale));//9
		pickListVals.add(new Picklist_Value__c(Name = 'Letter Grade', Type__c = 'Grade_Scale', Display_Code__c = 'test',RecordTypeId = recTypeGradeScale));//10
		pickListVals.add(new Picklist_Value__c(Name = '0-100', Type__c = 'Grade_Scale', standard_Scale__c = true,Display_Code__c = 'test',RecordTypeId = recTypeGradeScale));//11

		pickListVals.add(new Picklist_Value__c(Name = 'Points', Type__c = 'Grade_Scale', Display_Code__c = 'testxx',RecordTypeId = recTypeGradeScale));//12
		pickListVals.add(new Picklist_Value__c(Name = 'CCS', Type__c = 'Grade_Scale', Display_Code__c = 'testxx',RecordTypeId =recTypeGradeScale));//13

		pickListVals.add(new Picklist_Value__c(Name = 'Letter Grade', Type__c = 'Grade_Scale', Display_Code__c = 'testxx',RecordTypeId = recTypeGradeScale));//14
		pickListVals.add(new Picklist_Value__c(Name = '0-100', Type__c = 'Grade_Scale', Display_Code__c = 'testxx',RecordTypeId = recTypeGradeScale));//15

		pickListVals.add(new Picklist_Value__c(Name = 'Standard', Type__c = 'Grade_Scale', Display_Code__c = 'testxx',RecordTypeId = recTypeGradeScale));//16

		insert picklistVals;
		
		List<Grade_Normalization__c> gradeNormList = new List <Grade_Normalization__c>();
		gradeNormList.add(new Grade_Normalization__c(Name = '85', Grade_Value__c = 85.00 ,Picklist_Value__c= pickListVals[7].Id, isFinal__c = FALSE,Transformed_Grade__c = 'B',GP_Value__c = 3) );
		gradeNormList.add(new Grade_Normalization__c(Name = '75', Grade_Value__c = 75.00 ,Picklist_Value__c= pickListVals[7].Id, isFinal__c = FALSE,Transformed_Grade__c = 'B-',GP_Value__c = 2.7) );

		gradeNormList.add(new Grade_Normalization__c(Name = '75', Grade_Value__c = 75.00 ,Picklist_Value__c= pickListVals[7].Id, isFinal__c = true,Transformed_Grade__c = 'B-',GP_Value__c = 2.7) );
		gradeNormList.add(new Grade_Normalization__c(Name = '85', Grade_Value__c = 85.00 ,Picklist_Value__c= pickListVals[7].Id, isFinal__c = true,Transformed_Grade__c = 'B',GP_Value__c = 3) );

		//For CCS Tests
		gradeNormList.add(new Grade_Normalization__c(Name = '3', Grade_Value__c = 3 ,Picklist_Value__c= pickListVals[5].Id, isFinal__c = FALSE,Transformed_Grade__c = 'B',GP_Value__c = 3) );
		gradeNormList.add(new Grade_Normalization__c(Name = '3', Grade_Value__c = 3 ,Picklist_Value__c= pickListVals[5].Id, isFinal__c = true,Transformed_Grade__c = 'B',GP_Value__c = 3) );

		gradeNormList.add(new Grade_Normalization__c(Name = '4', Grade_Value__c = 4 ,Picklist_Value__c= pickListVals[8].Id, isFinal__c = FALSE,Transformed_Grade__c = 'A',GP_Value__c = 4) );
		gradeNormList.add(new Grade_Normalization__c(Name = '4', Grade_Value__c = 4 ,Picklist_Value__c= pickListVals[8].Id, isFinal__c = TRUE,Transformed_Grade__c = 'A',GP_Value__c = 4) );

		insert gradeNormList;
	
		pageReference rcPage = Page.Transcript;
		rcPage.getParameters().put('student', testdatasetuputil_v2.studentsList[0].id);
		rcPage.getParameters().put('contactId', testdatasetuputil_v2.studentsList[0].Individual__c);
		rcPage.getParameters().put('Official', 'true');
		
		//start the test
		Test.startTest();
		Test.setCurrentPage(rcPage);
		Transcript_Controller controller = new Transcript_Controller();
		//done
	}
}
public class CT_Gradebook_SoqlUtils {

		public static Set <String> allowableNaVals {get;set;}
		public static Map<Id, Standard__c> standardMap {get;set;}
		public static string		currentNormsGsId		='-1';
		public static Map <Decimal, Grade_Normalization__c> detailedFinalGnMap {get;set;}
		public static Grade_Normalization__c maxValueGn;
		public static Map <String, Id>				gsNameMap;
		public static OverrideSettings__c os;
		public static List <Grade_Normalization__c> standardsNormList {get;set;}
		
		
		public static Set <String> getAllowedNaValues(){
			Set <String> enteredGradeNaVals = new Set <String>();
			os = OverrideSettings__c.getInstance(UserInfo.getUserID());
			if (os==null)	os = OverrideSettings__c.getInstance(UserInfo.getProfileID());
			if (os==null) 	os = OverrideSettings__c.getOrgDefaults();
        	if(os!=null) {
        		if(os.Allowable_Grades__c != null && os.Allowable_Grades__c != '') {
	        		for(String s: os.Allowable_Grades__c.split(',')){
	            		enteredGradeNaVals.add(s.trim());
	        		}        	
        		}        		
        	}
        	return enteredGradeNaVals;
		}



		public static Map<Id, Standard__c> getStandardMap(Set <Id> standardSet){
			if (standardMap==null){
				standardMap = new Map <Id, Standard__c>();
				for (Standard__c s: [select id, Strand__c, Strand__r.Name, long_text__c, name from Standard__c where Id IN :standardSet]){
            			standardMap.put(s.id, s);
            		}
			}
			return standardMap;
		}
				
		
		public static Map <Decimal, Grade_Normalization__c>	getNormalizationMap(string GradeScaleId){
			if (gradeScaleId != currentNormsGsId){
				currentNormsGsId = gradeScaleId;
				detailedFinalGnMap = new Map <Decimal, Grade_Normalization__c>();
				Map <Decimal, Grade_Normalization__c> finalGnMap = new Map <Decimal, Grade_Normalization__c>();
				system.debug('scale~~~'+GradeScaleId);
				//system.debug()
				for (Grade_Normalization__c gn: [Select 	is_max_value__c,	Grade_Value__c, GP_Value__c, Transformed_Grade__c
																			from		Grade_Normalization__c 
																			where 	GP_Value__c != NULL
																			and			picklist_value__c = :gradeScaleId
																			order by Grade_Value__c asc]) {
					maxValueGn = gn;
					finalGnMap.put(gn.Grade_Value__c, gn);
				}
				if (finalGnMap.isEmpty()){
					for (Grade_Normalization__c gn: [Select 	is_max_value__c,	Grade_Value__c, GP_Value__c, Transformed_Grade__c
																			from		Grade_Normalization__c 
																			where 	GP_Value__c != NULL
																			and			picklist_value__c = null
																			order by Grade_Value__c asc]) {
						finalGnMap.put(gn.Grade_Value__c, gn);
						maxValueGn = gn;
					}
				}
				if (!finalGnMap.isEmpty()){
					Grade_Normalization__c currentGn = finalGnMap.values()[0];
					if (!finalGnMap.keySet().isEmpty()){
						for (Integer k=0;  k<=99; k++){
							for (Integer j=0;  j<=99; j++){
								decimal thisVal = decimal.ValueOf(k)+decimal.valueOf(j).divide(100,2);
								if (finalGnMap.get(thisVal)!=null) currentGn = finalGnMap.get(thisVal);
								detailedFinalGnMap.put(thisVal, currentGn);
							}	
						}
					//For 100
						if (finalGnMap.get(100.00)!=null) currentGn = finalGnMap.get(100.00);
						system.debug('currentGn~~~'+currentGn);
						detailedFinalGnMap.put(100.00, currentGn);
					}
				}
			}
			return detailedFinalGnMap;
		}
		 
		
		public static Map <Id, Section_Grade__c> getSectionGradeMap(Id SectionId, Id TimeId){
			
			Map <Id, Section_Grade__c> sectionGradeMap = new Map <Id, Section_Grade__c>();
			//US1284
			for(Section_Grade__c sg : [select reference_id__c, student_section__r.section__r.name, s.Letter_Grade__c, s.ID, s.Name, s.Time__c, s.Student_Section__r.Student__c, s.Student_Section__c, s.Student_Section__r.Section__c, s.Grade__c, s.Grade_Overridden__c, s.Standard_Section_Grade_v2__c, s.Credit_No_Credit_Section_Grade__c   , Display_Grade_Formula__c
									      From Section_Grade__c s 
									      where s.Student_Section__r.Section__c = :SectionId 
									      AND s.Time__c = :timeId
									      AND (RecordTypeID = null OR RecordType.Name = 'Quarter')]){

				sectionGradeMap.put(sg.Student_Section__r.Student__c, sg);
				}
			return sectionGradeMap;
		}
		
		public static List<Grade__c> getGradeList (Id SectionId, Id TimeId, String AssignmentTypeId){
			List <Grade__c> gradeList = new List <Grade__c>();
			for (Grade__c g: 		[select g.Id, g.Name, g.Entered_Grade__c,(Select Id From Attachments), g.Student_Section__r.Active__c,	g.Assignment__r.color__c, g.Assignment__r.Picklist_Value__c, g.Assignment__r.Possible_Points__c ,
											g.Student_Section__r.Section__c,	g.Student_Section__r.Student__r.Name, 	g.Student_Section__r.Student__c, 	g.Student_Section__c,	g.Standard__r.Name,
											g.Standard__c,g.exclude_From_Section_Grade__c,g.Standard__r.Strand__c,g.Standard__r.Strand__r.Name, g.Assignment__c,g.Assignment__r.Due_Date__c, g.Assignment__r.Name_in_Gradebook__c  ,	g.Assignment__r.Name, g.Assignment__r.Weighting_Value__c, g.Time__c,g.Comment__c,g.Publish_Comment__c,	g.Locked_for_Final__c
											From Grade__c g
											WHERE g.Time__c = :timeId
											AND g.Student_Section__r.Section__c = :SectionId
											AND ((g.Student_Section__r.Archived__c = false AND g.Student_Section__r.Active__c = true) OR (g.Student_Section__r.Archived__c = true AND g.Student_Section__r.Active__c = false))
											order by g.Assignment__r.Due_Date__c asc, g.Assignment__r.Name asc, g.Student_Section__r.Student__r.Student_Last_Name__c asc, g.Student_Section__r.Student__r.Student_first_Name__c]){
				if (AssignmentTypeId!='%'){
					if (g.Assignment__r.Picklist_Value__c==AssignmentTypeId) gradeList.add(g);
				}
				else gradeList.add(g);
			}
			return gradeList;
		}
		public static List<Grade__c> getGradeList_SO (Id SectionId, Id TimeId, String AssignmentTypeId){
			List <Grade__c> gradeList = new List <Grade__c>();
			for (Grade__c g: 		[select g.Id, g.Name, g.Entered_Grade__c,(Select Id From Attachments), g.Student_Section__r.Active__c,	g.Assignment__r.color__c, g.Assignment__r.Picklist_Value__c, g.Assignment__r.Possible_Points__c ,
											g.Student_Section__r.Section__c, Standard_Gradebook_Grade__c,	g.Student_Section__r.Student__r.Name, 	g.Student_Section__r.Student__c, 	g.Student_Section__c,	g.Standard__r.Name,
											g.Standard__c,g.exclude_From_Section_Grade__c,g.Standard__r.Strand__c,g.Standard__r.Strand__r.Name, g.Assignment__c,g.Assignment__r.Due_Date__c, g.Assignment__r.Name_in_Gradebook__c  ,	g.Assignment__r.Name, g.Assignment__r.Weighting_Value__c, g.Time__c,g.Comment__c,g.Publish_Comment__c,	g.Locked_for_Final__c
											From Grade__c g
											WHERE g.Time__c = :timeId
											AND g.Student_Section__r.Section__c = :SectionId
											AND ((g.Student_Section__r.Archived__c = false AND g.Student_Section__r.Active__c = true) OR (g.Student_Section__r.Archived__c = true AND g.Student_Section__r.Active__c = false))
											AND g.Faux_Grade__c = false
											order by g.Assignment__r.Due_Date__c asc, g.Assignment__r.Name asc, g.Student_Section__r.Student__r.Student_Last_Name__c asc, g.Student_Section__r.Student__r.Student_first_Name__c]){
				if (AssignmentTypeId!='%'){
					if (g.Assignment__r.Picklist_Value__c==AssignmentTypeId) gradeList.add(g);
				}
				else gradeList.add(g);
			}
			return gradeList;
		}
		public static List<Grade__c> getGradeList_SO_assignment_grades (Id SectionId, Id TimeId, String AssignmentTypeId){
			List <Grade__c> gradeList = new List <Grade__c>();
			for (Grade__c g: 		[select g.Id, g.Name, g.Entered_Grade__c,(Select Id From Attachments), g.Student_Section__r.Active__c,	g.Assignment__r.color__c, g.Assignment__r.Picklist_Value__c, g.Assignment__r.Possible_Points__c ,
											g.Student_Section__r.Section__c, exclude_From_Section_Grade__c, Standard_Gradebook_Grade__c,	g.Student_Section__r.Student__r.Name, 	g.Student_Section__r.Student__c, 	g.Student_Section__c,	g.Standard__r.Name,
											g.Standard__c,g.Standard__r.Strand__c,g.Standard__r.Strand__r.Name, g.Assignment__c,g.Assignment__r.Due_Date__c, g.Assignment__r.Name_in_Gradebook__c  ,	g.Assignment__r.Name, g.Assignment__r.Weighting_Value__c, g.Time__c,g.Comment__c,g.Publish_Comment__c,	g.Locked_for_Final__c
											From Grade__c g
											WHERE g.Time__c = :timeId
											AND g.Student_Section__r.Section__c = :SectionId
											AND ((g.Student_Section__r.Archived__c = false AND g.Student_Section__r.Active__c = true) OR (g.Student_Section__r.Archived__c = true AND g.Student_Section__r.Active__c = false))
											AND g.Faux_Grade__c = true
											order by g.Assignment__r.Due_Date__c asc, g.Assignment__r.Name asc, g.Student_Section__r.Student__r.Student_Last_Name__c asc, g.Student_Section__r.Student__r.Student_first_Name__c]){
				if (AssignmentTypeId!='%'){
					if (g.Assignment__r.Picklist_Value__c==AssignmentTypeId) gradeList.add(g);
				}
				else gradeList.add(g);
			}
			return gradeList;
		}
		
		
		public static List<Grade__c> getGradeListSoql (String SectionId, String TimeId, String AssignmentTypeId, String AssignmentId, String StandardId, String StudentId, Date endDate, Date startDate){
			List <Grade__c> gradeList ;
			//US 1240 - Added Short Assignment Description field
			String qString =  'select g.Id, g.Name, (Select Id From Attachments), g.Entered_Grade__c, g.Assignment__r.Possible_Points__c, g.Student_Section__r.Active__c, g.Student_Section__r.Section__c, g.Student_Section__r.Student__r.Name,g.Student_Section__r.Student__r.Student_First_Name__c,g.Student_Section__r.Student__r.Student_Last_Name__c,g.Student_Section__r.Student__r.Id,	g.Student_Section__r.Student__c, g.Student_Section__c, g.Standard__r.Name, g.Standard__r.Long_Text__c, g.Standard__c,g.Standard__r.Strand__c,g.Standard__r.Strand__r.Name, g.Assignment__c, g.Assignment__r.Due_Date__c, g.Assignment__r.Standard_Scale__r.Name, g.Assignment__r.Name, g.Assignment__r.Name_in_Gradebook__c, g.Assignment__r.Weighting_Value__c, g.Assignment__r.Picklist_Value__r.Name, g.Assignment__r.Due_Date_for_Gradebook__c, g.Assignment__r.color__c, g.Assignment__r.Description__c, g.Time__c,g.exclude_From_Section_Grade__c, g.Comment__c, g.Publish_Comment__c, g.Locked_for_Final__c From Grade__c g WHERE  g.Assignment__r.Due_Date__c>= :startDate AND g.Assignment__r.Due_Date__c<= :endDate AND g.Time__c = :timeId AND g.Student_Section__r.Section__c = :SectionId AND ((g.Student_Section__r.Archived__c = false AND g.Student_Section__r.Active__c = true) OR (g.Student_Section__r.Archived__c = true AND g.Student_Section__r.Active__c = false)) ';
	
		if (AssignmentTypeId!='All'){
			qString += 'AND g.Assignment__r.Assignment_Library__r.Picklist_Value__c  = \''+STRING.escapeSingleQuotes(AssignmentTypeId)+'\'';
			
		}
	
		if(AssignmentId!='All'){
			qString += 'AND g.Assignment__c = \''+STRING.escapeSingleQuotes(AssignmentId)+'\'';
		}
		else if(StandardId!='All'){
			qString += 'AND g.Standard__c = \''+STRING.escapeSingleQuotes(StandardId)+'\'';
		}
		
		if(StudentId!='All'){
			qString += ' AND g.Student_Section__r.Student__c = \''+STRING.escapeSingleQuotes(StudentId)+'\'';
		}
		
		String qOrder = 'order by g.Standard__r.Name asc, g.Assignment__r.Due_Date__c asc, g.CreatedDate asc';
		
		qString += qOrder;		
		gradeList =  Database.query(qString);
			return gradeList;
		}
		public static List<Grade__c> getGradeListSoql_SO (String SectionId, String TimeId, String AssignmentTypeId, String AssignmentId, String StandardId, String StudentId, Date endDate, Date startDate){
			List <Grade__c> gradeList ;
			//US 1240 - Added Short Assignment Description field
			String qString =  'select g.Id, g.Name, (Select Id From Attachments), g.Entered_Grade__c, g.Assignment__r.Possible_Points__c, g.Standard_Gradebook_Grade__c, g.Student_Section__r.Active__c, g.Student_Section__r.Section__c, g.Student_Section__r.Student__r.Name,g.Student_Section__r.Student__r.Student_First_Name__c,g.Student_Section__r.Student__r.Student_Last_Name__c,g.Student_Section__r.Student__r.Id,	g.Student_Section__r.Student__c, g.Student_Section__c, g.Standard__r.Name, g.Standard__r.Long_Text__c, g.Standard__c,g.Standard__r.Strand__c,g.Standard__r.Strand__r.Name, g.Assignment__c, g.Assignment__r.Due_Date__c, g.Assignment__r.Standard_Scale__r.Name, g.Assignment__r.Name, g.Assignment__r.Name_in_Gradebook__c, g.Assignment__r.Weighting_Value__c, g.Assignment__r.Picklist_Value__r.Name, g.Assignment__r.Due_Date_for_Gradebook__c, g.Assignment__r.color__c, g.Assignment__r.Description__c, g.Time__c,g.exclude_From_Section_Grade__c, g.Comment__c, g.Publish_Comment__c, g.Locked_for_Final__c From Grade__c g WHERE g.Assignment__r.Due_Date__c>= :startDate AND g.Assignment__r.Due_Date__c<= :endDate AND g.Time__c = :timeId AND g.Student_Section__r.Section__c = :SectionId AND g.Standard_Gradebook_Grade__c = null AND ((g.Student_Section__r.Archived__c = false AND g.Student_Section__r.Active__c = true) OR (g.Student_Section__r.Archived__c = true AND g.Student_Section__r.Active__c = false)) ';
	
		if (AssignmentTypeId!='All'){
			qString += 'AND g.Assignment__r.Assignment_Library__r.Picklist_Value__c  = \''+STRING.escapeSingleQuotes(AssignmentTypeId)+'\'';
			
		}
	
		if(AssignmentId!='All'){
			qString += 'AND g.Assignment__c = \''+STRING.escapeSingleQuotes(AssignmentId)+'\'';
		}
		else if(StandardId!='All'){
			qString += 'AND g.Standard__c = \''+STRING.escapeSingleQuotes(StandardId)+'\'';
		}
		
		if(StudentId!='All'){
			qString += ' AND g.Student_Section__r.Student__c = \''+STRING.escapeSingleQuotes(StudentId)+'\'';
		}
		
		String qOrder = 'order by g.Standard__r.Name asc, g.Assignment__r.Due_Date__c asc, g.CreatedDate asc';
		
		qString += qOrder;		
		gradeList =  Database.query(qString);
			return gradeList;
		}
		public static List<Grade__c> getGradeListSoql_SO_Assignment_Grades (String SectionId, String TimeId, String AssignmentTypeId, String AssignmentId, String StandardId, String StudentId, Date endDate, Date startDate){
			List <Grade__c> gradeList ;
			//US 1240 - Added Short Assignment Description field
			String qString =  'select g.Id, g.Name, (Select Id From Attachments), g.Entered_Grade__c, g.Assignment__r.Possible_Points__c, g.Standard_Gradebook_Grade__c, g.Student_Section__r.Active__c, g.Student_Section__r.Section__c, g.Student_Section__r.Student__r.Name,g.Student_Section__r.Student__r.Student_First_Name__c,g.Student_Section__r.Student__r.Student_Last_Name__c,g.Student_Section__r.Student__r.Id,	g.Student_Section__r.Student__c, g.Student_Section__c, g.Standard__r.Name, g.Standard__r.Long_Text__c, g.Standard__c,g.Standard__r.Strand__c,g.Standard__r.Strand__r.Name, g.Assignment__c, g.Assignment__r.Due_Date__c, g.Assignment__r.Standard_Scale__r.Name, g.Assignment__r.Name, g.Assignment__r.Name_in_Gradebook__c, g.Assignment__r.Weighting_Value__c, g.Assignment__r.Picklist_Value__r.Name, g.Assignment__r.Due_Date_for_Gradebook__c, g.Assignment__r.color__c, g.Assignment__r.Description__c, g.Time__c, g.exclude_From_Section_Grade__c,g.Comment__c, g.Publish_Comment__c, g.Locked_for_Final__c From Grade__c g WHERE g.Assignment__r.Due_Date__c>= :startDate AND g.Assignment__r.Due_Date__c<= :endDate AND g.Time__c = :timeId AND g.Student_Section__r.Section__c = :SectionId AND g.Standard_Gradebook_Grade__c != null AND ((g.Student_Section__r.Archived__c = false AND g.Student_Section__r.Active__c = true) OR (g.Student_Section__r.Archived__c = true AND g.Student_Section__r.Active__c = false)) ';
	
		if (AssignmentTypeId!='All'){
			qString += 'AND g.Assignment__r.Assignment_Library__r.Picklist_Value__c  = \''+STRING.escapeSingleQuotes(AssignmentTypeId)+'\'';
			
		}
	
		if(AssignmentId!='All'){
			qString += 'AND g.Assignment__c = \''+STRING.escapeSingleQuotes(AssignmentId)+'\'';
		}
		else if(StandardId!='All'){
			qString += 'AND g.Standard__c = \''+STRING.escapeSingleQuotes(StandardId)+'\'';
		}
		
		if(StudentId!='All'){
			qString += ' AND g.Student_Section__r.Student__c = \''+STRING.escapeSingleQuotes(StudentId)+'\'';
		}
		
		String qOrder = 'order by g.Standard__r.Name asc, g.Assignment__r.Due_Date__c asc, g.CreatedDate asc';
		
		qString += qOrder;		
		gradeList =  Database.query(qString);
			return gradeList;
		}
		
		
		public static Map <Id, Assignment__c> getAssignmentMap (Set <Id> assignSet){
			
			Map <Id, Assignment__c> assignmentMap = new Map <Id, Assignment__c>();
			//US 1240 - added short description field in the query to display it in the hover over in gradebook page
			for (Assignment__c a: 							[	select ID, Name, Name_in_Gradebook__c , Due_Date__c, Weighting_Value__c , Color__c, Possible_Points__c, Picklist_Value__r.Name, Standard_Scale__c, Standard_Scale__r.Name, Description__c
															from Assignment__c 
															where ID IN :assignSet]){
				assignmentMap.put(a.id, a);													
															}
			return assignmentMap;
		}
		
		public static List <AggregateResult> getAggregatedGrades(Id StandardId, Set<Id>StudentSections, Id gReportingPeriod){
			system.debug([select Assignment_Weighting__c from Grade__c WHERE Student_Section__c IN :StudentSections limit 1]);
			if(standardID!=null){
				List <AggregateResult> groupedResults =  [
	                SELECT Student_Section__c ss,
	                sum(Assignment_Weighting__c) aw, sum(Weighted_Grade_Value__c) wgv
	                FROM Grade__c 
	                WHERE Student_Section__c IN :StudentSections
	                AND Time__c = :gReportingPeriod
	                AND Standard__c =:StandardId
	                AND Valid_Grade__c = true 
	                AND exclude_From_Section_Grade__c != TRUE
	                AND Assignment__r.Include_in_Final_Grade__c =TRUE
	                GROUP BY Student_Section__c];
	                return groupedResults;
			}
			else{
				List <AggregateResult> groupedResults =  [
	                SELECT Student_Section__c ss,
	                sum(Assignment_Weighting__c) aw, sum(Weighted_Grade_Value__c) wgv
	                FROM Grade__c 
	                WHERE Student_Section__c IN :StudentSections
	                AND Time__c = :gReportingPeriod
	                AND Grade_With_Standard__c = false
	                AND Valid_Grade__c = true 
	                AND exclude_From_Section_Grade__c != TRUE
	                AND Assignment__r.Include_in_Final_Grade__c =TRUE
	                GROUP BY Student_Section__c];
	                return groupedResults;
			}
		}
		
		public static Map <String, Section_Grade__c> getSectionGradeMap(Set<Id>StudentSections, Id gReportingPeriod){
			Map<String, Section_Grade__c> sectGradeMap = new Map<String, Section_Grade__c>();
			//US1284
			system.debug('studentSections~~~~'+studentSections);
			system.debug('gReportingPeriod~~~~'+gReportingPeriod);
			for(Section_Grade__c sg:[SELECT ID, 
											Grade_Overridden__c, 
											Student_Section__c, 
											Time__c ,
											Reference_Id__c
											FROM Section_Grade__c 
											WHERE Student_Section__c IN :StudentSections
                							AND Time__c = :gReportingPeriod
                							AND (RecordTypeID = null OR RecordType.Name = 'Quarter')]){
                							
               	sectGradeMap.put(sg.Student_Section__c, sg); 								
            }
            return sectGradeMap;
		}
}
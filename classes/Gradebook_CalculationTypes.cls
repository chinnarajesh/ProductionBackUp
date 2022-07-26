/*
	Summer 2014 Developer's Notes:  
		For incoming student/standard/reporting period set combination, 
		it's not guaranteed that all of the grades are for one calculation type
		Need to accomodate sets of data by separating grade records to setups
		The list of grades should be same that is being worked on per calculation type, 
		create a method to organize the grades.
*/

global without sharing class Gradebook_CalculationTypes {

	public static Map<String, Standard_Grade__c> keysToStandardGrades;  //used to check overridden state
	public static Map<ID, List<ID>> selectedRPtoSetRP;
	public static Map<ID, Setup__c> setupCalculationSettings;
	public static Map<Setup__c, List<Grade__c>> setupToGrades;

	public class calcWrapper {
		public String cKey;
		public ID cStudent;
		public ID cStandard;
		public ID cReportingPeriod;
				
		public List<Grade__c> cNonRollingGrades = new List<Grade__c>();
		public List<Grade__c> cRollingGrades = new List<Grade__c>();
		
		public calcWrapper() {}
	}

	//=========================== Helper Methods ============================================//

	public static Map<ID, List<ID>> setRPMap(Set<ID> reportingPeriods) {
		Map<ID, List<Time_Element__c>> tempMap = new Map<ID, List<Time_Element__c>>();
		Map<ID, List<ID>> returnMap = new Map<ID, List<ID>>();
				
		//getting parent (Term) Key
		for(Time_Element__c rp : [SELECT ID, Parent_Time_Element__c, Reporting_Period__c, Parent_Time_Element__r.Parent_Time_Element__c FROM Time_Element__c WHERE ID IN: reportingPeriods ORDER BY Date_Start_Date__c ASC]) { //can reporting periods contain frps
			//parent time element
			if(rp.Reporting_Period__c) {
				if(!tempMap.containsKey(rp.Parent_Time_Element__c)) {
					tempMap.put(rp.Parent_Time_Element__c, new List<Time_Element__c>());
				}
			}
			//final time element
			else {
				if(rp.Parent_Time_Element__c != null) {
					if(!tempMap.containsKey(rp.Parent_Time_Element__r.Parent_Time_Element__c)) {
						tempMap.put(rp.Parent_Time_Element__r.Parent_Time_Element__c, new List<Time_Element__c>());
					}
				}
			}
		}
		
		//need another query to get all the children of the parent (not guaranteed above to have all Time Elements), this will create
		for(Time_Element__c crp: [SELECT ID, Date_Start_Date__c, Parent_Time_Element__c, (SELECT ID, Date_Start_Date__c FROM Time__r ORDER BY Date_Start_Date__c ASC) FROM Time_Element__c WHERE Parent_Time_Element__c IN: tempMap.KeySet() ORDER BY Date_Start_Date__c ASC]) {
			try {
				tempMap.get(crp.Parent_Time_Element__c).add(crp);
				system.debug('*~*~* crp.Time__r: ' + crp.Time__r);
				tempMap.get(crp.Parent_time_Element__c).addAll(crp.Time__r);
			}
			catch(Exception e) {
				
			}
		}
		
		//generate a map of the rp to its rp set and lower.
		for(ID parent : tempMap.KeySet()) {
			for(Time_Element__c te : tempMap.get(parent)) {
				if(!returnMap.containsKey(te.ID)) {
					List<ID> tList = new List<ID>();
					for(Time_Element__c cte : tempMap.get(Parent)) {
						if(cte.Date_Start_Date__c >= te.Date_Start_Date__c) {
							tList.add(cte.ID);
						}
					}
					returnMap.put(te.ID, tList);
				}
			}
		}	
		return returnMap;
	}
	
	public static Map<ID, Setup__c> getCalcTypeSetups(Set<ID> students) {
		Map<ID, Setup__c> returnMap = new Map<ID, Setup__c>();
		
		//need to query Students again to get the setup information, only care about 2 items
		for(Student__c s : [SELECT ID, Setup__c, Setup__r.Calculation_Type__c, Setup__r.Law_of_Decaying_Average_Weight__c, Setup__r.Rolling_Standard_Grade__c FROM Student__c WHERE ID IN: students]) {
			Setup__c t = new Setup__c();
			t.Calculation_Type__c = s.Setup__r.Calculation_Type__c;
			t.Law_of_Decaying_Average_Weight__c = s.Setup__r.Law_of_Decaying_Average_Weight__c;
			t.Rolling_Standard_Grade__c = s.Setup__r.Rolling_Standard_Grade__c;
			returnMap.put(s.Setup__c, t);
		}
		return returnMap;
	}
	
	public static Map<Setup__c, List<Grade__c>> organizeGradesBySetup(Set<ID> sts, Set<ID> stds, Set<ID> rps) {
		Map<Setup__c, List<Grade__c>> returnMap = new Map<Setup__c, List<Grade__c>>();

		for(Grade__c g : [SELECT ID,Student__r.Setup__c, Student__c, Standard__c, Time__c, Standard_Times_Assignment__c, Weighted_Grade_Value__c, Grade_Number__c FROM Grade__c 
						  WHERE Student__c IN: sts AND Standard__c IN: stds AND Include_In_Standard_Grade__c  = TRUE 	
						  AND Valid_Grade__c = TRUE AND Grade_With_Standard__c = TRUE AND Weighted_Grade_Value__c != null 
						  AND Standard_Times_Assignment__c != null ORDER BY Student__c, Standard__c, Time__c, Assignment__r.Due_Date__c ASC]) {		
			
			//first check the setupCalculationSettings
			if(setupCalculationSettings.containsKey(g.Student__r.Setup__c)) {
				//use the value as the key
				Setup__c sKey = setupCalculationSettings.get(g.Student__r.Setup__c);
				if(!returnMap.containsKey(sKey)) {
					returnMap.put(sKey, new List<Grade__c>{g});
				}
				else {
					returnMap.get(sKey).add(g);
				}
			}
		}
		system.debug(returnMap.values());
		return returnMap;
	}
	
	//literally for standard grade overrides
	public static Map<String, Standard_Grade__c> getStandardGrades(Set<ID> sts, Set<ID> stds, Set<ID> rps) {
		Map<String, Standard_Grade__c> returnMap = new Map<String, Standard_Grade__c>();

		for(Standard_Grade__c sg : [SELECT Name, Id, Student__c, Standard__c, Standard__r.Strand__c, Reporting_Period__c, Key__c, Grade_Overridden__c, Weighted_Average_Grade__c, Mean_Grade__c
	                           								 FROM Standard_Grade__c 
	                           								 WHERE Student__c IN: Sts
	                           								 AND Standard__c IN: Stds
	                           								 AND Key__c != null
	                           								 ]) {
	    
	    	//reminder new summer 2014 Key is: StudentID + StandardID + reportingPeriodID
	    	returnMap.put(sg.Key__c, sg);
		}
		
		return returnMap;
	}

	public static Map<String, Strand_Grade__c> calculateStrandGrades(Set<ID> students, Set<ID> standards, Set<ID> reportingPeriods) {
		Map<String, Strand_Grade__c> returnMap = new Map<String, Strand_Grade__c>();
		Map<String, Boolean> overriddenMap = new Map<String, Boolean>();
		Map<String, List<Standard_Grade__c>> calculateMap = new Map<String, List<Standard_Grade__c>>();

		try{
			Set<ID> strands = new Set<ID>();
			for(Standard__c std : [SELECT ID, Strand__c FROM Standard__c WHERE ID IN: standards]) {
				strands.add(std.Strand__c);
			}
			
			//create override map
			for(Strand_Grade__c strandGrade: [SELECT ID, Student__c, Strand__c, Reporting_Period__c, Grade_Overridden__c FROM Strand_Grade__c WHERE Student__c IN: students AND Strand__c IN: strands]) {
				String key = string.valueOf(strandGrade.Student__c) + string.valueOf(strandGrade.Strand__c) + string.valueOf(strandGrade.Reporting_Period__c);
				overriddenMap.put(key, strandGrade.Grade_Overridden__c);
			}

			//organize standard grades to average them
			for(Standard_Grade__c sg : [SELECT ID, Student__c, Standard__r.Strand__c, Reporting_Period__c, Standard_Grade__c FROM Standard_Grade__c WHERE Student__c IN: students AND Standard__r.Strand__c IN: strands AND Grade_Overridden__c = FALSE AND Reporting_Period__c != null ORDER BY Student__c, Standard__r.Strand__c, Reporting_Period__c]) {
				String key = string.valueOf(sg.Student__c) + string.valueOf(sg.Standard__r.Strand__c) + string.valueOf(sg.Reporting_Period__c);	
				if(!calculateMap.containsKey(key)) {
					calculateMap.put(key, new List<Standard_Grade__c>{sg});
				}
				else {
					calculateMap.get(key).add(sg);
				}
			}
			
			//average
			for(String k : calculateMap.KeySet()) {
				Decimal numerator;
				Decimal denominator;
				ID student;
				ID strand;
				ID reportingPeriod;
				for(Standard_Grade__c sg : calculateMap.get(k)) {
					student = sg.Student__c;
					strand = sg.Standard__r.Strand__c;
					reportingPeriod = sg.Reporting_Period__c;
					
					if(sg.Standard_Grade__c != null) {
						if(numerator == null) {
							numerator = sg.Standard_Grade__c;
						}
						else {
							numerator += sg.Standard_Grade__c;
						}
						if(denominator == null) {
							denominator = 1;
						}
						else {
							denominator++;
						}
					}
				}
				if(numerator != null && denominator > 0) {
					if(overriddenMap.containsKey(k)) {
						if(!overriddenMap.get(k)) {
							system.debug('*~*~* strand: ' + strand + ' rp: ' + reportingPeriod);
							system.debug('*~*~* strand grade average - numerator: ' + numerator + ' denominator: ' + denominator);
							returnMap.put(k, new Strand_Grade__c(Key__c = k, Grade__c = numerator.divide(denominator, 2), Student__c = student, Strand__c = strand, Reporting_Period__c = reportingPeriod));
						}
					}
					else {
						returnMap.put(k, new Strand_Grade__c(Key__c = k, Grade__c = numerator.divide(denominator, 2), Student__c = student, Strand__c = strand, Reporting_Period__c = reportingPeriod));
					}
				}
				else {
					returnMap.put(k, new Strand_Grade__c(Key__c = k, Grade__c = null, Student__c = student, Strand__c = strand, Reporting_Period__c = reportingPeriod));
				}
			}
		} catch(Exception e){
			system.debug(e);
			insert Error_Handling.handleError(null, 'Strand grade calculations',e);
		}
		return returnMap;
	}
	
	public static Map<String, calcWrapper> getCalcWrapperMap(List<Grade__c> grades) {
		Map<String, calcWrapper> returnMap = new Map<String, calcWrapper>();

		for(Grade__c g : grades) {
			String key = string.valueOf(g.Student__c) + string.valueOf(g.Standard__c) + string.valueOf(g.Time__c);
			if(!returnMap.containsKey(key)) {
				calcWrapper cw = new calcWrapper();
				cw.cKey = key;
				cw.cStudent = g.Student__c;
				cw.cStandard = g.Standard__c;
				cw.cReportingPeriod = g.Time__c;
				
				cw.cNonRollingGrades.add(g);
				returnMap.put(key, cw);
				
				if(selectedRPtoSetRP.containsKey(g.Time__c)) {
					for(ID rp : selectedRPtoSetRP.get(g.Time__c)) {
						String tKey = string.valueOf(g.Student__c) + string.valueOf(g.Standard__c) + string.valueOf(rp);
						if(keysToStandardGrades.containsKey(tKey)) {
							if(!returnMap.containsKey(tKey)) {
								calcWrapper tcw = new calcWrapper();
								tcw.cKey = tKey;
								tcw.cStudent = g.Student__c;
								tcw.cStandard = g.Standard__c;
								tcw.cReportingPeriod = rp;
								
								tcw.cRollingGrades.add(g);
								returnMap.put(tKey, tcw);
							}
							else {
								returnMap.get(tKey).cRollingGrades.add(g);
							}
						}
					}
				}
			}
			else {
				returnMap.get(key).cNonRollingGrades.add(g);

				if(selectedRPtoSetRP.containsKey(g.Time__c)) {
					for(ID rp : selectedRPtoSetRP.get(g.Time__c)) {
						String tKey = string.valueOf(g.Student__c) + string.valueOf(g.Standard__c) + string.valueOf(rp);
						if(keysToStandardGrades.containsKey(tKey)) {
							if(!returnMap.containsKey(tKey)) {
								calcWrapper cw = new calcWrapper();
								cw.cKey = tKey;
								cw.cStudent = g.Student__c;
								cw.cStandard = g.Standard__c;
								cw.cReportingPeriod = rp;
								
								cw.cRollingGrades.add(g);
								returnMap.put(tKey, cw);
							}
							else {
								returnMap.get(tKey).cRollingGrades.add(g);
							}
						}
					}
				}
			}
		}
		return returnMap;
	}
	
	@future
	public static void triggerCalcNow(set<ID> studentsNow, Set<ID> standardsNow, Set<ID> rpsNow) {
		determineCalculationNow(studentsNow, standardsNow, rpsNow);
	}
	
	@future
	public static void triggerCalculateLater(Set<ID> studentsLater, Set<ID> standardsLater, Set<ID> rpsLater) {
		calculateLater(studentsLater, standardsLater, rpsLater, false);
	}

	public static void determineCalculationNow(Set<ID> studentsNow, Set<ID> standardsNow, Set<ID> rpsNow) {
		//prep work
		try { 
			if(selectedRPtoSetRP == null) {
				selectedRPtoSetRP = setRPMap(rpsNow);
			}
			if(setupCalculationSettings == null) {
				setupCalculationSettings = getCalcTypeSetups(studentsNow);
			}
			//organize the grades
			if(setupToGrades == null) {
				setupToGrades = organizeGradesBySetup(studentsNow, standardsNow, rpsNow);
			}
			//always get this data
			keysToStandardGrades = getStandardGrades(studentsNow, standardsNow, rpsNow);
		}
		catch(Exception e) {
			system.debug(e);
			insert Error_Handling.handleError(null, 'Standard Grade calculate now prep',e);
		}
		
		List<Standard_Grade__c> upsertSG = new List<Standard_Grade__c>();
		try{
			for(Setup__c s : setupToGrades.KeySet()) {
				if(s.calculation_Type__c == 'Mean') {
					//provide aggregate results
					upsertSG.addAll(meanCalculation(setupToGrades.get(s)).Values());
				}
				else if(s.calculation_Type__c == 'Power Law') {
					upsertSG.addAll(powerLawCalculation(setupToGrades.get(s)).Values());
				}
				else if(s.calculation_Type__c == 'Highest') {
					upsertSG.addAll(highestCalculation(setupToGrades.get(s)).Values());
				}
				else if(s.calculation_Type__c == 'Most Recent') {
					upsertSG.addAll(mostRecentCalculation(setupToGrades.get(s)).Values());
				}
				else if(s.calculation_Type__c == 'Law of Decaying Average') {
						upsertSG.addAll(lawOfDecayingAverageCalculation(setupToGrades.get(s), s.Law_of_Decaying_Average_Weight__c).Values());
				}
			}
		} catch(Exception e){
			system.debug(e);
			insert Error_Handling.handleError(null, 'Standard Grade calculate now calculate',e);
		}
		
		try{
			if(upsertSG.size() > 0) {
				for(Standard_Grade__c sg : upsertSG) {
					system.debug('*~*~* calc now sg: ' + sg);
				}
				upsert upsertSG Key__c;	
			}
		} catch(Exception e){
			system.debug(e);
			insert Error_Handling.handleError(null, 'Standard Grade calculate now upsert',e);
		}	
	}

	public static void calculateLater(set<ID> studentsLater, Set<ID> standardsLater, Set<ID> rpsLater, Boolean calcAll) {
		try {
			if(selectedRPtoSetRP == null) {
				selectedRPtoSetRP = setRPMap(rpsLater);
			}
			if(setupCalculationSettings == null) {
				setupCalculationSettings = getCalcTypeSetups(studentsLater);
			}
			//organize the grades
			if(setupToGrades == null) {
				setupToGrades = organizeGradesBySetup(studentsLater, standardsLater, rpsLater);
			}
			//always get this data
			keysToStandardGrades = getStandardGrades(studentsLater, standardsLater, rpsLater);
		}
		catch(Exception e) {
			system.debug(e);
			insert Error_Handling.handleError(null, 'Standard Grade calculate later prep',e);
		}

		Map<String, Standard_Grade__c> consolidateRecords = new Map<String, Standard_Grade__c>();

		system.debug(setupToGrades.keySet());
		system.debug(setupToGrades.values());
		try{
			for(Setup__c s : setupToGrades.KeySet()) {
				if(s.calculation_Type__c != 'Mean' || calcAll) {
					Map<String, Standard_Grade__c> tMap = meanCalculation(setupToGrades.get(s));
					for(String key : tMap.KeySet()) {
						if(!consolidateRecords.containsKey(key)) {
							consolidateRecords.put(key, tMap.get(key));
						}
						else {
							consolidateRecords.get(key).Mean_Grade__c = tMap.get(key).Mean_Grade__c;
							consolidateRecords.get(key).Rolling_Mean_Grade__c = tMap.get(key).Rolling_Mean_Grade__c;
						}
					}
				}

				if(s.calculation_Type__c != 'Highest' || calcAll) {
					Map<String, Standard_Grade__c> tMap = highestCalculation(setupToGrades.get(s));
					for(String key : tMap.KeySet()) {
						if(!consolidateRecords.containsKey(key)) {
							consolidateRecords.put(key, tMap.get(key));
						}
						else {
							consolidateRecords.get(key).Highest_Grade__c = tMap.get(key).Highest_Grade__c;
							consolidateRecords.get(key).Rolling_Highest_Grade__c = tMap.get(key).Rolling_Highest_Grade__c;
						}
					}
				}
				
				if(s.calculation_Type__c != 'Most Recent' || calcAll) {
					Map<String, Standard_Grade__c> tMap = mostRecentCalculation(setupToGrades.get(s));
					for(String key : tMap.KeySet()) {
						if(!consolidateRecords.containsKey(key)) {
							consolidateRecords.put(key, tMap.get(key));
						}
						else {
							consolidateRecords.get(key).Most_Recent_Grade__c = tMap.get(key).Most_Recent_Grade__c;
							consolidateRecords.get(key).Rolling_Most_recent_Grade__c = tMap.get(key).Rolling_Most_Recent_Grade__c;
						}
					}
				}
				
				if(s.calculation_Type__c != 'Power Law' || calcAll) {
					Map<String, Standard_Grade__c> tMap = powerLawCalculation(setupToGrades.get(s));
					for(String key: tMap.KeySet()) {
						if(!consolidateRecords.containsKey(key)) {
							consolidateRecords.put(key, tMap.get(key));
						}
						else {
							consolidateRecords.get(key).Power_Law_Grade__c = tMap.get(key).Power_Law_Grade__c;
							consolidateRecords.get(key).Rolling_Power_Law_Grade__c = tMap.get(key).Rolling_Power_Law_Grade__c;
						}
					}
				}

				if(s.calculation_Type__c != 'Law of Decaying Average' || calcAll) {
					Map<String, Standard_Grade__c> tMap = lawOfDecayingAverageCalculation(setupToGrades.get(s), s.Law_of_Decaying_Average_Weight__c);
					for(String key : tMap.KeySet()) {
						if(!consolidateRecords.containsKey(key)) {
							consolidateRecords.put(key, tMap.get(key));
						}
						else {
							consolidateRecords.get(key).Law_Of_Decaying_Average_Grade__c = tMap.get(key).Law_Of_Decaying_Average_Grade__c;
							consolidateRecords.get(key).Rolling_Law_Of_Decaying_Average_Grade__c = tMap.get(key).Rolling_Law_Of_Decaying_Average_Grade__c;
						}
					}
				}
			}
		} catch(Exception e){
			system.debug(e);
			insert Error_Handling.handleError(null, 'Standard Grade calculate later calc',e);
		}
		
		try{
			Set<String> unprocessedKeys = keysToStandardGrades.keySet();
			unprocessedKeys.removeAll(consolidateRecords.keySet());

			//if we had a standard grade, but it was not returned in the consolidateRecords, we need to blank it out.
			for(String key:unprocessedKeys){
				Standard_Grade__c sg = keysToStandardGrades.get(key);
				sg.Law_of_Decaying_Average_Grade__c = null;
				sg.Highest_Grade__c = null;
				sg.Mean_Grade__c = null;
				sg.Most_Recent_Grade__c = null;
				sg.Power_Law_Grade__c = null;
				sg.Rolling_Highest_Grade__c = null;
				sg.Rolling_Law_of_Decaying_Average_Grade__c = null;
				sg.Rolling_Mean_Grade__c = null;
				sg.Rolling_Most_Recent_Grade__c = null;
				sg.Rolling_Power_Law_Grade__c  = null;
				consolidateRecords.put(key, sg);
			}

			system.debug(consolidateRecords);

			if(consolidateRecords.Values().size() > 0) {
				for(Standard_Grade__c sg : consolidateRecords.Values()) {
					system.debug('*~*~* cal later sg: ' + sg);
				}
				upsert consolidateRecords.Values() Key__c;	
			}	
		} catch(Exception e){
			system.debug(e);
			insert Error_Handling.handleError(null, 'Standard Grade calculate later upsert',e);
		}
	}
	
	//=================== Modularlized calc methods ============================================//
	
	//The list of grades should be the grade records for standards!

	public static Decimal calcMean(List<Grade__c> grades) {
		Decimal numerator;
		Decimal denominator;
		
		for(Grade__c g : grades) {
			if(numerator == null) {
				numerator = g.Weighted_Grade_Value__c;
			}
			else {
				numerator += g.Weighted_Grade_Value__c;
			}
			
			if(denominator == null) {
				denominator = g.Standard_Times_Assignment__c;
			}
			else {
				denominator += g.Standard_Times_Assignment__c;
			}
		}
		
		if(numerator != null && denominator != null) {
			return numerator.divide(denominator, 2);
		}
		return null;
	}

	public static Decimal calcPowerLaw(List<Grade__c> grades) {
		Decimal N = grades.size();
		Decimal NM = 0;  //subtract from N for null Grade_Number__c
		//if N is not Greater than 0, then there are no grades, do nothing
		//need to check for null, and 0 as entered grades/grade numbers
		if(N > 0){
			Decimal Y = 0.0;  //predicted value max of scores at that time period
			Decimal powerLaw = 0.0;
			Decimal S = 0.0;
			Decimal X = 0.0;			
			Decimal XS = 0.0;			
			Decimal XX = 0.0;					
						
			for(Integer i = 0; i < N; i++) {
				//check for null and 0
				if(grades[i].Grade_Number__c != null) {
					if(grades[i].Grade_Number__c != 0) {
						S += Math.log(grades[i].Grade_Number__c);
						X += Math.log(i+1);
						XS += Math.log(i+1)*Math.log(grades[i].Grade_Number__c);
						XX += Math.log(i+1)*Math.log(i+1);
					}
					else {
						//do not add to S and XS for 0, only X and XX
						X += Math.log(i+1);
						XX += Math.log(i+1)*Math.log(i+1);
					}
				}
				else {
					//need to subtract one from N for each grade taht has null as a grade entered
					NM++;
				}
			}
			if((N-NM) > 0) {
				S = S.divide(1.0,1);
				X = X.divide(1.0, 1);
				XS = XS.divide(1.0, 1);
				XX = XX.divide(1.0, 1);
				
				Decimal numerator = XS - (X*S)/(N-NM);
				Decimal denomenator = XX - (X*X)/(N-NM);
				Decimal m;
				//very close to 0
				if(denomenator > -.00000001 && denomenator < .00000001) {
					m = 0.0;
				}
				else {
					m = numerator/denomenator;
					m = m.divide(1.0, 1);
				}
				Decimal b = (S - X*m)/(N-NM);
				b = b.divide(1.0, 1);
				
				Decimal mxb = m*(Math.log((N-NM))).divide(1.0,1) + b;

				powerLaw = math.exp(mxb);
				
				return powerLaw;
			}
		}
		return null;
	}
	
	public static Decimal calcMostRecent(List<Grade__c> grades) {
		Integer length = grades.size();
		Decimal mostRecent;
		
		if(grades.size() <= 3) {
			mostRecent = grades[length - 1].Grade_Number__c;
		}
		else {
			//average of the most recent 3
			Decimal A = grades[length - 1].Grade_Number__c;
			Decimal B = grades[length - 2].Grade_Number__c;
			Decimal C = grades[length - 3].Grade_Number__c;
			mostRecent = (A + B + C)/3.0;
		}
		
		return mostRecent;	
	}

	public static Decimal calcHighest(List<Grade__c> grades) {
		
		Decimal Highest;
		
		for(Grade__c g : grades) {
			if(Highest == null) {
				Highest = g.Grade_Number__c;
			}
			else {
				if(Highest < g.Grade_Number__c) {
					Highest = g.Grade_Number__c;
				}
			}
		}
		
		return Highest;
	}
	
	public static Decimal calcLawOfDecayingAverage(List<Grade__c> grades, Decimal decayingAverageWeight) {
		Decimal x;
		Decimal weighting = 0.0;
		
		if(decayingAverageWeight != null) {
			weighting = decayingAverageWeight/100.00;
		}
		
		Decimal inverseWeighting = 1.00 - weighting;
		
		//determine what x should be
		if(grades.size() == 0) {
			x = null;
		}
		else if(grades.size() >= 1) {
			x = grades[0].Grade_Number__c;
		}

		if(grades.size() > 1){
			for(Integer i = 0; i < grades.size() - 1; i++) {
				x =  x * inverseWeighting + grades[i+1].Grade_Number__c * weighting;
			}
		}	
		return x;
	}
	
	/*
		DEVELOPER'S NOTES:  Need to update the calculations to also calculate the rolling standard grade.
	*/
	
	public static Map<String, Standard_Grade__c> meanCalculation(List<Grade__c> grades) {
		Map<String, Standard_Grade__c> upsertStandardGrades = new Map<String, Standard_Grade__c>();
		
		//create a map of students to standards to grade records
		Map<String, calcWrapper> sgKeyToCalcWrapper = getCalcWrapperMap(grades);

		for(calcWrapper cw : sgKeyToCalcWrapper.Values()) {
			try {			
				Standard_Grade__c tSG = new Standard_Grade__c(
					Student__c = cw.cStudent,
					Standard__c = cw.cStandard,
					Reporting_Period__c = cw.cReportingPeriod,
					Key__c = cw.cKey
					);

				if(cw.cNonRollingGrades.size() > 0) {
					system.debug('*~*~* Mean cw.cNonRollingGrades: ' + cw.cNonRollingGrades);
					tSG.Mean_Grade__c = calcMean(cw.cNonRollingGrades);
				}
				else {
					tSG.Mean_Grade__c = null;
				}

				if(cw.cRollingGrades.size() > 0) {
					system.debug('*~*~* Mean cw.cRollingGrades: ' + cw.cRollingGrades);
					tSG.Rolling_Mean_Grade__c = calcMean(cw.cRollingGrades);
				}

				system.debug('*~*~* Mean tSG: ' + tSG);

				if(!keysToStandardGrades.containsKey(cw.cKey)) {
					upsertStandardGrades.put(cw.cKey, tSG);
				}
				else {
					if(!keysToStandardGrades.get(cw.cKey).Grade_Overridden__c) {
						upsertStandardGrades.put(cw.cKey, tSG);
					}
				}
			}
			catch(Exception e) {
				e.setMessage('failed to upsert mean type standard grade');
			}
		}
		
		return upsertStandardGrades;
	}
	
	public static Map<String, Standard_Grade__c> powerLawCalculation(List<Grade__c> grades) {
		Map<String, Standard_Grade__c> upsertStandardGrades = new Map<String, Standard_Grade__c>();
		
		//create a map of students to standards to grade records
		Map<String, calcWrapper> sgKeyToCalcWrapper = getCalcWrapperMap(grades);
		
		//reminder: need to calc nonRolling and rolling, currently code works for rolling
		for(calcWrapper cw : sgKeyToCalcWrapper.Values()) {
			try {			
				Standard_Grade__c tSG = new Standard_Grade__c(
					Student__c = cw.cStudent,
					Standard__c = cw.cStandard,
					Reporting_Period__c = cw.cReportingPeriod,
					Key__c = cw.cKey
				);
				
				if(cw.cNonRollingGrades.size() > 0) {
					system.debug('*~*~* Power Law cw.cNonRollingGrades: ' + cw.cNonRollingGrades);
					tSG.Power_Law_Grade__c = calcPowerLaw(cw.cNonRollingGrades);
				}
				else {
					tSG.Power_Law_Grade__c = null;
				}

				if(cw.cRollingGrades.size() > 0) {
					system.debug('*~*~* Power Law cw.cRollingGrades: ' + cw.cRollingGrades);
					tSG.Rolling_Power_Law_Grade__c = calcPowerLaw(cw.cRollingGrades);
				}
					
				system.debug('*~*~* Power Law tSG: ' + tSG);

				if(!keysToStandardGrades.containsKey(cw.cKey)) {
					upsertStandardGrades.put(cw.cKey, tSG);
				}
				else {
					if(!keysToStandardGrades.get(cw.cKey).Grade_Overridden__c) {
						upsertStandardGrades.put(cw.cKey, tSG);
					}
				}
			}
			catch(Exception e) {
				e.setMessage('failed to upsert power law type standard grade');
			}
		}	

		return upsertStandardGrades;
	}	
	
	public static Map<String, Standard_Grade__c> mostRecentCalculation(List<Grade__c> grades) {
		Map<String, Standard_Grade__c> upsertStandardGrades = new Map<String, Standard_Grade__c>();

		//create a map of students to standards to grade records
		Map<String, calcWrapper> sgKeyToCalcWrapper = getCalcWrapperMap(grades);		
		
		//reminder: need to calc nonRolling and rolling, currently code works for rolling
		for(calcWrapper cw : sgKeyToCalcWrapper.Values()) {
			try {
				Standard_Grade__c tSG = new Standard_Grade__c(
					Student__c = cw.cStudent,
					Standard__c = cw.cStandard,
					Reporting_Period__c = cw.cReportingPeriod,
					Key__c = cw.cKey
					);

				if(cw.cNonRollingGrades.size() > 0) {
					system.debug('*~*~* Most Recent cw.cNonRollingGrades: ' + cw.cNonRollingGrades);
					tSG.Most_Recent_Grade__c = calcMostRecent(cw.cNonRollingGrades);
				}
				else {
					tSG.Most_Recent_Grade__c = null;
				}

				if(cw.cRollingGrades.size() > 0) {
					system.debug('*~*~* Most Recent cw.cRollingGrades: ' + cw.cRollingGrades);
					tSG.Rolling_Most_Recent_Grade__c = calcMostRecent(cw.cRollingGrades);
				}

				system.debug('*~*~* Most Recent tSG: ' + tSG);

				if(!keysToStandardGrades.containsKey(cw.cKey)) {
					upsertStandardGrades.put(cw.cKey, tSG);
				}
				else {
					if(!keysToStandardGrades.get(cw.cKey).Grade_Overridden__c) {
						upsertStandardGrades.put(cw.cKey, tSG);
					}
				}
			}
			catch(Exception e) {
				e.setMessage('failed to upsert most recent type standard grade');
			}
		}	
		
		return upsertStandardGrades;		
	}
	
	public static Map<String, Standard_Grade__c> highestCalculation(List<Grade__c> grades) {
		Map<String, Standard_Grade__c> upsertStandardGrades = new Map<String, Standard_Grade__c>();

		//create a map of students to standards to grade records
		Map<String, calcWrapper> sgKeyToCalcWrapper = getCalcWrapperMap(grades);

		//reminder: need to calc nonRolling and rolling, currently code works for rolling
		for(calcWrapper cw : sgKeyToCalcWrapper.Values()) {
			try {			
				Standard_Grade__c tSG = new Standard_Grade__c(
					Student__c = cw.cStudent,
					Standard__c = cw.cStandard,
					Reporting_Period__c = cw.cReportingPeriod,
					Key__c = cw.cKey
					);

				if(cw.cNonRollingGrades.size() > 0) {
					system.debug('*~*~* Highest cw.cNonRollingGrades: ' + cw.cNonRollingGrades);
					tSG.Highest_Grade__c = calcHighest(cw.cNonRollingGrades);
				}
				else {
					tSG.Highest_Grade__c = null;
				}

				if(cw.cRollingGrades.size() > 0) {
					system.debug('*~*~* Highest cw.cRollingGrades: ' + cw.cRollingGrades);
					tSG.Rolling_Highest_Grade__c = calcHighest(cw.cRollingGrades);
				}

				system.debug('*~*~* Highest tSG: ' + tSG);

				if(!keysToStandardGrades.containsKey(cw.cKey)) {
					upsertStandardGrades.put(cw.cKey, tSG);
				}
				else {
					if(!keysToStandardGrades.get(cw.cKey).Grade_Overridden__c) {
						upsertStandardGrades.put(cw.cKey, tSG);
					}
				}
			}
			catch(Exception e) {
				e.setMessage('failed to upsert highest type standard grade');
			}
		}
		
		return upsertStandardGrades;			
	}	
	
	public static Map<String, Standard_Grade__c> lawOfDecayingAverageCalculation(List<Grade__c> grades, Decimal decayingAverageWeight) {
		Map<String, Standard_Grade__c> upsertStandardGrades = new Map<String, Standard_Grade__c>();

		//create a map of students to standards to grade records
		Map<String, calcWrapper> sgKeyToCalcWrapper = getCalcWrapperMap(grades);		

		//reminder: need to calc nonRolling and rolling, currently code works for rolling
		for(calcWrapper cw : sgKeyToCalcWrapper.Values()) {
			try {
				Standard_Grade__c tSG = new Standard_Grade__c(
					Student__c = cw.cStudent,
					Standard__c = cw.cStandard,
					Reporting_Period__c = cw.cReportingPeriod,
					Key__c = cw.cKey
					);

				if(cw.cNonRollingGrades.size() > 0 && decayingAverageWeight != null) {
					system.debug('*~*~* Law of Decaying Average cw.cNonRollingGrades: ' + cw.cNonRollingGrades);
					tSG.Law_Of_Decaying_Average_Grade__c = calcLawOfDecayingAverage(cw.cNonRollingGrades, decayingAverageWeight);
				} else {
					tSG.Law_Of_Decaying_Average_Grade__c = null;
				}

				if(cw.cRollingGrades.size() > 0 && decayingAverageWeight != null) {
					system.debug('*~*~* Law of Decaying Average cw.cRollingGrades: ' + cw.cRollingGrades);
					tSG.Rolling_Law_Of_Decaying_Average_Grade__c = calcLawOfDecayingAverage(cw.cRollingGrades, decayingAverageWeight);
				} else {
					tSG.Law_of_Decaying_Average_Grade__c = null;
				}
				
				system.debug('*~*~* Law of Decaying Average tSG: ' + tSG);

				if(!keysToStandardGrades.containsKey(cw.cKey)) {
					upsertStandardGrades.put(cw.cKey, tSG);
				}
				else {
					if(!keysToStandardGrades.get(cw.cKey).Grade_Overridden__c) {
						upsertStandardGrades.put(cw.cKey, tSG);
					}
				}
			}
			catch(Exception e) {
				e.setMessage('failed to upsert law of decaying average type standard grade');
			}
		}
		
		return upsertStandardGrades;		
	}				
}
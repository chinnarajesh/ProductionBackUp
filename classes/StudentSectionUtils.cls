global class StudentSectionUtils {

	//fill field Student_Program__c on Student_Section__c object 
	public static void fillStudentProgramField(List<Student_Section__c> listStudentSection, Map<Id, Student_Section__c> oldMap){
		Set<String> programIds = new Set<String>();
		Set<String> studentIds = new Set<String>();
		List<Student_Section__c> lstSS = new List<Student_Section__c>();
		for(Student_Section__c ss: listStudentSection){
			if(ss.Student__c != null && ss.Program__c != null && (oldMap==null || ss.Student_Program__c == null || 
					ss.Program__c != oldMap.get(ss.Id).Program__c || ss.Student__c != oldMap.get(ss.Id).Student__c)){
				programIds.add(ss.Program__c);
				studentIds.add(ss.Student__c);
				lstSS.add(ss);
			}
		}
		if(programIds.isEmpty() || studentIds.isEmpty()){
			return;
		}

		Map<String, Student_Program__c> mapStudent2Program = new Map<String, Student_Program__c>();
		for(Student_Program__c studentProgram: [SELECT Id, Student__c, Program1__c, Program__c, Reference__c FROM Student_Program__c 
					WHERE Program1__c IN :programIds AND Student__c IN :studentIds]){
			String key = studentProgram.Student__c + '#' + studentProgram.Program1__c;
			mapStudent2Program.put(key, studentProgram);
		}

		for(Student_Section__c studentSection: lstSS){
			String key = studentSection.Student__c + '#' + studentSection.Program__c;
			//check if Student_Program exists
			if(!mapStudent2Program.containsKey(key)){
				Student_Program__c studentProgram = new Student_Program__c(
						Student__c = studentSection.Student__c, 
						Program1__c = studentSection.Program__c,
						Reference__c = key
						);
				mapStudent2Program.put(key, studentProgram);			
			}
		}

		//upsert Student_Program__c objects
		if(!mapStudent2Program.isEmpty()){
			upsert mapStudent2Program.values();
		}
		
		//update field Student_Program__c
		for(Student_Section__c studentSection: lstSS){
			String key = studentSection.Student__c + '#' + studentSection.Program__c;
			studentSection.Student_Program__c = mapStudent2Program.get(key).Id;
		}
	}

    public static void calculateAmountOfTime(List<Student_Section__c> lstSS, Map<Id, Student_Section__c> oldMap){
		Set<String> studentProgramIds = new Set<String>();
		for(Student_Section__c ss: lstSS){
			if(oldMap==null || (ss.Amount_of_Time__c != oldMap.get(ss.Id).Amount_of_Time__c && ss.Student_Program__c!=null)){
				studentProgramIds.add(ss.Student_Program__c);
			}
		}

		if(!studentProgramIds.isEmpty()){
			List<Student_Section__c> lSS = new List<Student_Section__c>( [SELECT Id, Amount_of_Time__c, Student_Program__c 
					FROM Student_Section__c WHERE Student_Program__c != NULL AND Student_Program__c IN :studentProgramIds]);
	        if(!lSS.isEmpty()){
	        	//calculate sum of time			
	       	 	Map<String, Decimal> mapIdToSum = calcSP2Hours(lSS);
	        	//save sum
				List<Student_Program__c> listSP = populateSPs(mapIdToSum);
				update listSP;
			}
		}
    }   

    //remove studentprogram
    public static void removeStudentPrograms(List<Student_Section__c> lstSS){
    	List<Student_Section__c> lSS = new List<Student_Section__c>();
    	Set<Id> spIds = new Set<Id>();
    	for(Student_Section__c ss: lstSS){
    		spIds.add(ss.Student_Program__c);
    	}
    	spIds.remove(null);

    	if(!spIds.isEmpty()){
			lSS = new List<Student_Section__c>( [SELECT Id, Amount_of_Time__c, Student_Program__c FROM Student_Section__c 
	                    WHERE Student_Program__c != NULL AND Student_Program__c IN :spIds AND Id NOT IN :lstSS]);
    	}

    	//recalc hours
    	if(!lSS.isEmpty()){
    		Map<String, Decimal> mapIdToSum = calcSP2Hours(lSS);
			List<Student_Program__c> listSP = populateSPs(mapIdToSum);
	        //update SP
	        update listSP;
    	}

    	for(Student_Section__c ss: lSS){
 	        //uses another sections
 	        spIds.remove(ss.Student_Program__c);
    	}
    	//remove SP    	
    	if(!spIds.isEmpty()){
	    	List<Student_Program__c> lstSP = new List<Student_Program__c>();
	    	for(Id idx: spIds){
	    		lstSP.add(new Student_Program__c(Id = idx));
	    	}
	    	delete lstSP;
	    }
    }

    public static void removeStudentPrograms(List<Section__c> lstS){
	    List<Student_Section__c> lstSS = [SELECT Id, Amount_of_Time__c, Student_Program__c FROM Student_Section__c 
	            WHERE Student_Program__c != NULL AND Section__c IN :lstS];

	    if(lstSS!=null && !lstSS.isEmpty()){
	    	StudentSectionUtils.removeStudentPrograms(lstSS);
	    }
    }

    private static Map<String, Decimal> calcSP2Hours(List<Student_Section__c> lstSS){
        Map<String, Decimal> mapSP2Sum = new Map<String, Decimal>();
        for(Student_Section__c ss: lstSS){
        	//recalc hours
        	Decimal currentValue =  mapSP2Sum.containsKey(ss.Student_Program__c)?mapSP2Sum.get(ss.Student_Program__c):0;
        	mapSP2Sum.put(ss.Student_Program__c, currentValue + ss.Amount_of_Time__c); 	        	
    	}
    	return mapSP2Sum;
    }

    private static List<Student_Program__c> populateSPs(Map<String, Decimal> mapSP2Sum){
        List<Student_Program__c> listSP = new List<Student_Program__c>();
        for(String key: mapSP2Sum.keySet()){
            listSP.add(new Student_Program__c(Id = key, Amount_of_Time__c = mapSP2Sum.get(key)));
        }
        return listSP;
    }
 
}
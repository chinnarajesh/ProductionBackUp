public with sharing class ProactiveCS_CsvLoader {
	
	public void loadProactive(){
		try{
			List<Proactive_CS__c> procsv = [SELECT Id FROM Proactive_CS__c];
			delete procsv;
			Map<String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Proactive_CS__c');
			
			List<Proactive_CS__c> proactiveCSLoad = new List<Proactive_CS__c>();
			//String[] proA = blobToArray('ProactiveCustomSettingCSV');
			StaticResource sr = [Select  s.Name, s.Id, s.Body From StaticResource s  where name = 'ProactiveCustomSettingCSV'];
			blob tempBlob = sr.Body;
       		String tempString = tempBlob.toString();
			CSVUtils.CSVParser parser = new CSVUtils.CSVParser(tempString, true);
			parser.parse();
			system.debug('---------------------parsedData: ' + parser.parsedData);
			system.debug('---------------------parseError: ' + parser.parseError);
			for(List<String> inputvalues : parser.parsedData){
				system.debug('-----------------inputvalues: ' + inputvalues[13]);
				system.debug('-----------------inputvalues: ' + inputvalues[14]);
				Proactive_CS__c a = new Proactive_CS__c();
				a.Name = inputvalues[0];
				a.Name_Type__c = inputvalues[1];  
				a.Proactive_Attendance_Status__c = inputvalues[2];
				a.Proactive_Attendance_Type__c = inputvalues[3];
				a.Proactive_PG_Relationship__c = inputvalues[4];
				a.Proactive_SPED_School__c = inputvalues[5];
				a.Proactive_Student_Entry__c = inputvalues[6];
				a.Proactive_Student_Exit__c = inputvalues[7];
				a.Proactive_TitleI__c = inputvalues[8];
				a.SF_Attendance_Status__c = inputvalues[9];
				a.SF_Attendance_Type__c = inputvalues[10];
				a.SF_PG_Relationship__c = inputvalues[11];
				a.SF_SPED_School__c = inputvalues[12];
				a.SF_Student_Entry__c = inputvalues[13];
				a.SF_Student_Exit__c = inputvalues[14];
				a.SF_TitleI__c = inputvalues[15];
				a.Student_Exit_Type__c = inputvalues[16];
				proactiveCSLoad.add(a);
				
			}
			
			system.debug('file----------------------------------------------------------------------: ' + proactiveCSLoad);
			List<Proactive_CS__c> isempty = [SELECT Id FROM Proactive_CS__c];
			if(isempty.size() < 1 || isempty == null){
				insert proactiveCSLoad;
			}
			
		}catch(Exception e){
	 		Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'An error occurred while processing student/section data.  Please ensure that all required fields are present and that the load is associated with a setup record.'));
			throw e;
	 	}
	}
	
}
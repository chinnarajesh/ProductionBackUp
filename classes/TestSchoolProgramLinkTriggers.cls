@isTest
private class TestSchoolProgramLinkTriggers {
	
	static testMethod void TestSchoolCreate() {
		TestDataUtil.setupData(1);
		TestDataUtil.SchoolWrapper SW = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Program__c> addPrograms = TestDataUtil.createPrograms(5,true,ia);
		insert addPrograms;
		
		Account a = new Account();
		a.name = 'school';
		a.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName='School' and sObjectType='Account'].id;
		insert a;
		a  = [select (select id from Accounts_Programs__r) from Account where id=:a.id];
		
		System.assertEquals(5, a.Accounts_Programs__r.size());
	}
	
	static testMethod void TestReqProgramCreate() {
		TestDataUtil.setupData(5);
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		
		program  = [select (select id from Accounts_Programs__r) from Program__c where id=:program.id];
		System.assertEquals(5,program.Accounts_Programs__r.size());
	}
	
	 static testMethod void TestConnectionDelete() {
		TestDataUtil.setupData(1);
		TestDataUtil.SchoolWrapper SW = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Program__c> addPrograms = TestDataUtil.createPrograms(5,true,ia);
		insert addPrograms;
		
		Account a = new Account();
		a.name = 'school';
		a.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName='School' and sObjectType='Account'].id;
		insert a;
		
		List<Account_Program__c> connections  = [select id from Account_Program__c where School__c=:a.id];
		System.assertEquals(5,connections.size());
	
		try{
			delete connections;
		}
		catch(Exception e){
		}
		
		connections  = [select id from Account_Program__c where School__c=:a.id];
		System.assertEquals(5,connections.size());
	}

	static testMethod void testAssignSchoolYear(){
		TestDataUtil.setupData(1);
		TestDataUtil.SchoolWrapper SW = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		
		//delete setups associated with school to check error message
		List<Setup__c> setups = [SELECT id FROM Setup__c WHERE School__c=:SW.school.id];
		delete setups;
		
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW.school, program);
		Database.SaveResult result = Database.insert(ap,false);
		system.assert(!result.isSuccess());
		system.assertEquals('There is no active setup for school with id: '+SW.school.id+'.  Please activate a setup for this school.', result.getErrors()[0].getMessage());
		
		//create a setup, but don't add a school year
		Setup__c setup = new Setup__c(School__c=SW.school.id, Active__c=true);
		insert setup;
		result = Database.insert(ap,false);
		system.assert(!result.isSuccess());
		system.assertEquals('There is no current school year for this school.  Please check that the active setup for '+SW.school.Name+' has an associated year record.', result.getErrors()[0].getMessage());
		
		//add a school year, should succeed
		setup.Year__c = TestDataUtil.masterYear.id;
		update setup;
		result = Database.insert(ap,false);
		system.assert(result.isSuccess());
	}
	
	static testMethod void testReferenceId(){
		TestDataUtil.setupData(1);
		TestDataUtil.SchoolWrapper SW = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW.school, program);
		insert ap;
		ap = [SELECT Reference_ID__c FROM Account_Program__c WHERE id=:ap.id];
		system.assertEquals(SW.school.id+'_'+program.id+'_'+TestDataUtil.masterYear.id,ap.Reference_ID__c);
	}
	
	static testMethod void testNoYearChange(){
		TestDataUtil.setupData(1);
		TestDataUtil.SchoolWrapper SW = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW.school, program);
		insert ap;
		ap.Current_Year_ID__c = null;
		Database.SaveResult result = Database.update(ap,false);
		system.assert(!result.isSuccess());
		system.assertEquals('School year on Account/Program cannot be changed.',result.getErrors()[0].getMessage());
	}
}
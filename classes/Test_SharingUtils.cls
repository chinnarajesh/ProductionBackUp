@isTest(seeAllData=true)
private class Test_SharingUtils {
	static testMethod void test_FLS(){
		User user = [select id from User where Profile.Name IN ('System Administrator','CY System Administrator') and ISActive = true limit 1];
		system.runAs(user){
			Section__c obj = new Section__c();
			DescribeSObjectResult describeObject = obj.getSObjectType().getDescribe();

			Map<String, Schema.SObjectField> objectFields = describeObject.fields.getMap();

			List<String> restrictedFields = new List<String>();

			for(String nm : objectFields.keyset()){
					DescribeFieldResult fr = objectFields.get(nm).getDescribe();
					if((!fr.isCalculated()) && !fr.isCreateable()) {
						system.debug(fr.getName());
					}  // there is not an isDeletable method at the field level
			}
		}
	}
}
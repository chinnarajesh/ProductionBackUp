public class AWSKeys {
	public class AWSKeysException extends Exception {}
	
	AWSKey__c keyObj = null;
	public string key { get { return keyObj.key__c; } private set; }
	public string secret { get { return keyObj.secret__c; } private set; }
	// constructor
	public AWSKeys(string name) {
		try {
			keyObj = [select key__c,secret__c,id from AWSKey__c where name = :name limit 1]; 
			
			//Check that key__c is not null
			if(keyObj.key__c == null || keyObj.key__c == ''){
			   //ApexPages.addMessages();
			   ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Error: No key is specified for the AWSKey__c record with name of [' +name+']. Pleaes enter the Key value and retry.');
			   ApexPages.addMessage(errorMsg);
			   throw new AWSKeysException('Error: No key is specified for the AWSKey__c record with name of [' +name+']. Pleaes enter the Key value and retry.'); 	
			}
			
			//Check that secret__c is not null
			if(keyObj.secret__c == null || keyObj.secret__c == ''){
			   ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Error: No secret is specified for the AWSKey__c record with name of [' +name+']. Pleaes enter the Secret value and retry.');
			   ApexPages.addMessage(errorMsg);
			   throw new AWSKeysException('Error: No secret is specified for the AWSKey__c record with name of [' +name+']. Pleaes enter the Secret value and retry.'); 	
			}
			
		} catch (QueryException queryEx) {
			system.debug('Error when querying the AWSKey__c custom object. Did not find any record with name of ['+name+']. Please make sure the name is correct or create a record with the proper AWS credentials and retry.');
			//ApexPages.addMessages(queryEx);
			throw new AWSKeysException('Error when querying the AWSKey__c custom object. Did not find any record with name of ['+name+']. Please make sure the name is correct or create a record with the proper AWS credentials and retry.');
			//keyObj = new AWSKey__c( key__c='not set', secret__c='not set' );
		} 
		//don't catch other exceptions, let them fall through to the calling class....  
	}
}
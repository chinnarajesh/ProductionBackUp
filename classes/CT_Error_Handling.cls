global with sharing class CT_Error_Handling {
	public static List<Global_Error__c> multipartExceptions = new List<Global_Error__c>();

	global static String createLinks(string passedString){
		if(passedString != null){
			String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
			string returnString = 'Links:';
			List<String> errors;
			if (passedString.contains(';')) errors = passedString.split(';');
			else errors = new List <String> {passedString};
			for(integer i = 0; i<errors.size(); i++){
				List<String> innerErrors = errors[i].split(',');
				if(innerErrors.size()==2){
					innerErrors[0] = innerErrors[0].trim();
					innerErrors[1] = innerErrors[1].trim();
					returnString += '<br/> ' + '<a href="'+baseURL + '/' + string.valueOf(innerErrors[1]) + '" target="_blank">'+innerErrors[0]+'</a>';
				}
			}
			return returnString;
		}
		return null;
	}

	public static void handleMultiPartException(String Links, String module, String Info, Exception e){
		multipartExceptions.add(handleError(links,module,info,e));
	}

	public static void insertMultiPartException(){
		if(!multipartExceptions.isEmpty())
			insert multipartExceptions;
	}
	
	global static Global_Error__c handleError(String Links, String module, String Info, Exception e){
		Global_Error__c ge = new Global_Error__c();
		ge.Errors__c = '<br/><b>Exception:</b></br> ' + e.getMessage() +		 '<br/><br/><b>Stack:</b> ' + e.getStackTraceString() + '<br/> Cause: ' + e.getCause() + '<br/>'+ '<br/> Line: ' + e.getLineNumber() + '<br/>' + createLinks(Links);
		ge.Errors__c = ge.Errors__c + '<br/> ' + '<br/><b>Additional Information: </b>' + Info;
		ge.name = userinfo.getFirstName() + ' ' + userinfo.getLastName() + ' - Error From - ' + module;
		ge.User__c = userInfo.getUserId();
		ge.Module__c = module;
	 return ge;
	}
	
	global static Global_Error__c handleError(String Links, String module, Exception e){
		Global_Error__c ge = new Global_Error__c();
		ge.Errors__c = '<br/><b>Exception:</b></br> ' + e.getMessage() + '<br/><br/><b>Stack:</b> ' + e.getStackTraceString() + '<br/> Cause: ' + e.getCause()+ '<br/> Line: ' + e.getLineNumber() + '<br/>'+ '<br/>' +  createLinks(Links);
		ge.name = userinfo.getFirstName() + ' ' + userinfo.getLastName() + ' - Error From - ' + module;
		ge.User__c = userInfo.getUserId();
		ge.Module__c = module;
	 return ge;
	}
	
	global static Global_Error__c handleError(String Links, String module, String Info){
		Global_Error__c ge = new Global_Error__c();
		ge.Errors__c = createLinks(Links);
		ge.Errors__c = ge.Errors__c + '<br/> ' + '<br/><b>Additional Information: </b>' + Info;
		ge.name = userinfo.getFirstName() + ' ' + userinfo.getLastName() + ' - Error From - ' + module;
		ge.User__c = userInfo.getUserId();
		ge.Module__c = module;
	 return ge;
	}

	public static void errorMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
	}

	public static void infoMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,message));
	}

	public static void successMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,message));
	}

	public static void warningMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,message));
	}
	
	global class schoolForceException extends Exception {
		
	} 
	
}
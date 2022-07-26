public class Portal_AddAttachmentsController {
	public String fileDesc			{get;set;}
	public String fileName			{get;set;}
	public String fileSize			{get;set;}
	public Blob fileBlob			{get;set;}
	public String fileContentType	{get;set;}
	public List<Attachment> attach	{get;set;}

	public PageReference upload(){
		if(attach == null)
			attach = new List<Attachment>();
		if(ApexPages.currentPage().getParameters().get('aID') != null){
			for(String s: ApexPages.currentPage().getParameters().get('aID').split(',')){
				attach.add(new Attachment(ParentId = s,Body = fileBlob,Description = fileDesc,name = fileName));
			}
				
		}

		try{
			insert attach;
			boolean sent = sendNotificationEmails(attach[0].id, ApexPages.currentPage().getParameters().get('stud'), ApexPages.currentPage().getParameters().get('section'));
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'The file has been uploaded successfully.'));
			if(!sent){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'There was an error sending notification emails.'));
			}
			//system.debug('--------attachmentID---->'+attach);
		}catch (DMLException e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading file'));
			Global_Error__c ge = Error_Handling.handleError('Portal Add Attachments, ', 'Portal Attachments', 'An error has occurred while uploading an attachment for the assignment'+attach[0].ParentId, e);
		    insert ge;
		} 
		finally {
			Attachment a = new Attachment();
			a.body = null;
			fileBlob = null;
			attach = new List<Attachment>();
			attach.add(a);
			return null;
		}
		return null;
	}

	private boolean sendNotificationEmails(id fileID, string studentId, string section){
		string assignmentName = ApexPages.currentPage().getParameters().get('aName');
		string portalPage = ApexPages.currentPage().getParameters().get('page');
		
		Student__c student = [select id, Email__c, Name 
								from Student__c
								where id =: studentId
								limit 1];

		//Make student email
		Messaging.SingleEmailMessage studentEmail = new Messaging.SingleEmailMessage();
		studentEmail.setUseSignature(false);
		studentEmail.setSubject('Assignment Upload Successful');
		studentEmail.setPlainTextBody(student.Name + ',\n' + 
									'Your file submission for ' + assignmentName +
									' was successful.\n' +
									'Your submission can be viewed here:' +
									URL.getSalesforceBaseUrl().toExternalForm() + portalPage + '&tab=Portfolio');
		studentEmail.setToAddresses(new List<String>{student.Email__c});
    	
		//Get the staff for that section.
		List<Staff_Section__c> staffList= [SELECT Id, Staff__r.Staff_Email__c, Section__r.Name
											FROM Staff_Section__c
											WHERE Section__c =: section
											limit 99]; //SF single email limit is 100/send op.
		List<String> staffAddressList = new List<String>();
		String sectionName;
    	
		//Reserve email space
		Messaging.reserveSingleEmailCapacity(1 + staffList.size());
    	
		//Get the emails emails for all the staff on that session
		for(Staff_Section__c ss: staffList){
			if(ss.Staff__r.Staff_Email__c!= null){
				staffAddressList.add(ss.Staff__r.Staff_Email__c);
			}
			sectionName = ss.Section__r.Name;
		}
    	
		//Use pageref as a way to get the attachment id
		PageReference pref = new PageReference('/' + fileId);
    	
		Messaging.SingleEmailMessage teacherEmail = new Messaging.SingleEmailMessage();
		teacherEmail.setToAddresses(staffAddressList);
		teacherEmail.setUseSignature(false);
		teacherEmail.setBccSender(false);
		teacherEmail.setSubject('New Assignment Submission For ' + sectionName);
		teacherEmail.setPlainTextBody('A new assignment submission for ' + assignmentName +
										' was submitted by ' + student.Name + '.\n' +
										'Their submission can be viewed here: ' +
										URL.getSalesforceBaseUrl().toExternalForm() + '/' + fileID);
    	
		//send the emails
		Messaging.SendEmailResult[] results = new Messaging.SendEmailResult[]{};
		if(student.Email__c != null){
			results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{studentEmail});
		}
		results.addAll(Messaging.sendEmail(new Messaging.SingleEmailMessage[]{teacherEmail}, false));
    	
		//make sure they sent
		for(Messaging.SendEmailResult result:results){
			if(!result.isSuccess()){ //note: this is a method, not a field.
				return false;
			}	
		}
		return true; 
	}
}
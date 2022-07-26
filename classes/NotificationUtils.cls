public class NotificationUtils{

	public class sendnotification {

		public sendnotification (Student_PG__c pgnotifier, Map<String, String> sComms) {
			//Check they have a Email address, should receive email alerts, and that there is text for an email alert for this notification
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			List<String> aemail = new List<String>();
			Notification_Settings__c ns = Notification_Settings__c.getOrgDefaults();
			
			mail.setReplyTo(ns.reply_to__c);  
			mail.setSenderDisplayName(ns.display_name__c);  
			mail.setSubject(ns.Subject__c);  
			if (pgnotifier.Parent_Guardian_c__r.Notify_via_Email__c == true && pgnotifier.Parent_Guardian_c__r.Email != null && sComms.containskey('Email')) {
				aemail.add(pgnotifier.Parent_Guardian_c__r.Email);
				mail.setPlainTextBody(pgnotifier.Student_c__r.FirstName + ' ' + pgnotifier.Student_c__r.LastName + ' ' + sComms.get('Email'));
				}
				//Check they have a SMS address, should receive alerts, and that there is text for an sms alert for this notification
			if (pgnotifier.Parent_Guardian_c__r.Notify_via_SMS__c == true && pgnotifier.Parent_Guardian_c__r.Email_to_SMS_Address__c != null && sComms.containskey('SMS')) {
				aemail.add(pgnotifier.Parent_Guardian_c__r.Email_to_SMS_Address__c);			
				mail.setPlainTextBody(pgnotifier.Student_c__r.FirstName + ' ' + pgnotifier.Student_c__r.LastName + ' ' + sComms.get('SMS'));
			}
			mail.setToAddresses(aemail);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

			
		} //end send Notification constructor
	} //end send Notification class
}
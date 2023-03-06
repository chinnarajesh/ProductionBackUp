trigger StudentEnrollmentTrigger on Contact (after insert,after update) {
    
   if(core_triggerUtils.contactTrigger){
    Id ConRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
    
   Profile integrationProfile =[select id,name from Profile where name='Int_Sys_Admin'];
    Id profileId = UserInfo.getProfileId();
    
    System.debug('ConRecordTypeId'+ConRecordTypeId);
          Set<Id> SchoolId = new Set<Id>();
          Set<String> gradeSet = new Set<String>();
          Set<Id> ContactId = new Set<Id>();
          Set<Id> StudentIdSet = new Set<Id>();
    for(Contact con:Trigger.new){
        if(con.RecordTypeId == ConRecordTypeId && profileId != integrationProfile.id){
        ContactId.add(con.id);
        }
    }
        List<Contact> contactList =[select id,name,Student__c,Student_Current_Grade__c,Student__r.School__c,Student__r.Grade__c from Contact where  Id IN:ContactId];
    System.debug('Keyset'+trigger.newMap.keyset());
    System.debug('contactList'+contactList);
       for(Contact con:contactList){          
              SchoolId.add(con.Student__r.School__c);
              gradeSet.add(con.Student__r.Grade__c);
              StudentIdSet.add(con.Student__c);
            }
           System.debug('SchoolId'+SchoolId);
           System.debug('gradeSet'+gradeSet);
    
      Map<string,Account> accountMap = new Map<string,Account>();
         for(Account account:[select id,name, (select id,name,School__c,Reference_Id__c,Available_Grade_Levels__c from Sections__r where Available_Grade_Levels__c IN: gradeSet and (Period__c='ELA/Literacy' or  Period__c='Math'))from Account where id IN: SchoolId ]){
            accountMap.put(account.id,account);
           }
       System.debug('accountMap'+accountMap);
      Map<string,Student_Section__c> studentMap = new Map<String,Student_Section__c>();
      for(Student_Section__c studentsection :[select id,name,Section__c,Student__c from Student_Section__c where Student__c IN: StudentIdSet]){
        studentMap.put(studentsection.Section__c,studentsection);
      }
      System.debug('studentMap****'+studentMap);
    System.debug('contactList'+contactList);
     List<Student_Section__c> studentsectionList = new List<Student_Section__c>();
    
      for(Contact contact:contactList){
          system.debug('****'+accountMap);
          system.debug('++++'+contact.Student__r.School__c);
         if(accountMap.containsKey(contact.Student__r.School__c)){
             
             for(Section__c section:accountMap.get(contact.Student__r.School__c).Sections__r){
                 
                system.debug('****'+contact.Student_Current_Grade__c);
                 system.debug('++'+section.Available_Grade_Levels__c);
                  if(contact.Student_Current_Grade__c==section.Available_Grade_Levels__c){
                      Student_Section__c studentSection = new Student_Section__c();
                     if(studentMap.containsKey(section.id)){
                        studentSection = new Student_Section__c(
                        id=studentMap.get(Section.id).id,
                        Student__c=studentMap.get(Section.id).Student__c);
                        studentsectionList.add(studentSection);
                     }
                     else{
                        studentSection = new Student_Section__c(
                        Student__c=contact.Student__c,
                        Section__c=section.id,
                        Original_School__c=section.School__c,
                        Reference_ID__c=section.Reference_Id__c,
                        Active__c=True);
                        studentsectionList.add(studentSection);
                        System.debug('studentList'+studentsectionList);
                     }
                    
                     }
                  }
              }
          }
           if(studentsectionList.size()>0){
                upsert studentsectionList;
            }
            System.debug('studentsectionList'+studentsectionList);
        }
    }
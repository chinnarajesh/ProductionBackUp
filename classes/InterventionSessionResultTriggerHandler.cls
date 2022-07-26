public with sharing class InterventionSessionResultTriggerHandler {

    public void isBeforeInsert(List<Intervention_Session_Result__c> onBeforeInsertList) {
        isBeforeInsertHelper(onBeforeInsertList);
    }

    private void isBeforeInsertHelper(List<Intervention_Session_Result__c> onBeforeInsertList) {
        Set<Id> intervensionSessionIds = new Set<Id>();
        for (Intervention_Session_Result__c isr : onBeforeInsertList) {
            intervensionSessionIds.add(isr.Intervention_Session__c);
        }
        List<Intervention_Session__c> sessionsWithISR = [SELECT Id, (SELECT Id, Student_Section__c FROM Intervention_Session_Results__r)
                                                        FROM Intervention_Session__c
                                                        WHERE Id IN: intervensionSessionIds];
        Map<Id, Set<Id>> sessionIdtoStudentSections = new Map<Id, Set<Id>>();
        for(Intervention_Session__c session : sessionsWithISR)
        {
            List<Intervention_Session_Result__c> isrs = session.Intervention_Session_Results__r;
            Set<Id> studentSectionIds = new Set<Id>();
            for (Intervention_Session_Result__c isr : isrs) {
                studentSectionIds.add(isr.Student_Section__c);
            }
            sessionIdtoStudentSections.put(session.Id, studentSectionIds);
        }
        checkIntervensionSessionResultDuplicates(onBeforeInsertList, sessionIdtoStudentSections);
    }

    private void checkIntervensionSessionResultDuplicates(
            List<Intervention_Session_Result__c > onBeforeInsertISR,
            Map<Id, Set<Id>> sessionIdtoStudentSections) {

        for (Intervention_Session_Result__c isr : onBeforeInsertISR) {
            Id sessionId = isr.Intervention_Session__c;
            Set<Id> existingStudentSectionsInSession = sessionIdtoStudentSections.get(sessionId);
            System.debug('existingStudentSectionsInSession ' + existingStudentSectionsInSession);
            System.debug('isr.Student_Section__c ' + isr.Student_Section__c);
            if (existingStudentSectionsInSession != null) {
                if (existingStudentSectionsInSession.size() > 0 && existingStudentSectionsInSession.contains(isr.Student_Section__c)) {
                    isr.addError('Record with this student already exists');
                }
            }
        }
    }


}
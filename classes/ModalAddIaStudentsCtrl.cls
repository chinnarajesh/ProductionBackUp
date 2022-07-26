/**
 * Created by TarasTorubka on 24.09.2020.
 */

public with sharing class ModalAddIaStudentsCtrl {
    public static final String IA_NONSPECIFIC 	= 				'Non-specific IA';
    public Date                     dtIA                        {get;set;}
    public Section__c               section                     {get;set;}
    public List<StudentInfoWrapper> studentSections				{get;set;}
    public Map<String, Indicator_Area_Student__c>   changesIAS;


    public void startAddIAToStudents(){
        Id cidIA = section.Program__r.Indicator_Area__r.Id;
        for(StudentInfoWrapper siw: studentSections){
            if(siw.areaIDs.containsKey(cidIA)) {
                siw.dtIA = siw.areaIDs.get(cidIA).IA_Effective_Date__c;
            }
        }
    }

    public void saveIAToStudents(){
        List<String> errorMessages = new List<String>();
        changesIAS = new Map<String, Indicator_Area_Student__c>();

        List<StudentInfoWrapper> lstStudentSections = new List<StudentInfoWrapper>();
        for(StudentInfoWrapper sew: studentSections){
            if(sew.selected){
                lstStudentSections.add(sew);
                sew.dtIA = dtIA;
                if(sew.student.Entry_Date__c > dtIA || sew.student.Expiration_Date__c < dtIA){
                    errorMessages.add('Student '+sew.name+' should have the IA Effective Date in the range of '+(sew.student.Entry_Date__c!=null?sew.student.Entry_Date__c.format():'-')+' to '+(sew.student.Expiration_Date__c!=null?sew.student.Expiration_Date__c.format():'-')+'.');
                }
                if((sew.studentSection.Intervention_Enrollment_Start_Date__c != null && sew.studentSection.Intervention_Enrollment_Start_Date__c.date() > dtIA) || (sew.studentSection.Enrollment_End_Date__c != null && sew.studentSection.Enrollment_End_Date__c.date() < dtIA)) {
                    errorMessages.add('Student '+sew.name+' should have the IA Effective Date in the range of Intervention Start and Exit dates');
                }
            }
        }

        if(dtIA == null) {
            CyUtil.errorMessage('Please select an IA Effective Date.'); return;
        }
        if(lstStudentSections.isEmpty()){
            CyUtil.errorMessage('Please select a student to Indicator Area.'); return;
        }
        if(String.isBlank(section.Program__r.Indicator_Area__r.Id)){
            CyUtil.errorMessage('Current section has not a Indicator Area.'); return;
        }
        if(section.Program__r.Indicator_Area__r.Name == IA_NONSPECIFIC){
            CyUtil.errorMessage('Non-Specific IA cannot be assigned.'); return;
        }

        Indicator_Area__c curIA = section.Program__r.Indicator_Area__r;
        for(StudentInfoWrapper s: lstStudentSections){
            Indicator_Area_Student__c IA_S = s.areaIds.get(curIA.Id);

            if(IA_S == null){
                IA_S = new Indicator_Area_Student__c();
                IA_S.Indicator_Area__c = curIA.Id;
                IA_S.Indicator_Area__r = curIA;
                IA_S.Student__c = s.studentSection.Student__c;
                IA_S.Student__r = s.student;
                IA_S.Reference_ID__c = s.student.Id+'_'+curIA.Id;
                IA_S.Active__c = true;
                s.addArea(IA_S);
            }

            IA_S.Active__c = true;
            IA_S.IA_Effective_Date__c = dtIA;
            if(!changesIAS.containsKey(IA_S.Reference_ID__c)){
                changesIAS.put(IA_S.Reference_ID__c, IA_S);
            }
            s.refreshIndicatorAreaDisplay();
        }

        if(!changesIAS.isEmpty() && errorMessages.isEmpty()){
            errorMessages.addAll(saveChangesIA());
        }

        if(errorMessages.isEmpty()){
            CYUtil.successMessage('Your changes have been saved.');
        }else{
            CYUtil.errorMessage(String.join(errorMessages, '<br/>')+'<br/>Please verify that your changes have been saved.');
        }
    }

    public List<String> saveChangesIA(){
        List<Database.UpsertResult> results = Database.upsert(changesIAS.values(), Indicator_Area_Student__c.Reference_ID__c.getDescribe().getSObjectField(),false);
        List<String> errorMessages = new List<String>();
        for(integer i=0; i<results.size(); i++){
            List<Database.Error> errors = results[i].getErrors();
            for(Database.Error er : errors){
                errorMessages.add('For student '+changesIAS.values()[i].Student__r.Name+'. '+er.getMessage()+'.');
            }
        }
        changesIAS = new Map<String, Indicator_Area_Student__c>();

        return errorMessages;
    }
}
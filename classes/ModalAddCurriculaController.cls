public with sharing class ModalAddCurriculaController {
    public static final String      SECTION_NAME = 'Unknown';
    public Curriculum__c            curriculum      			{get;set;}
	public List<StudentInfoWrapper> studentSections				{get;set;}
    public List<Curriculum__c>      curriculumStudents 		    {get;set;}
    public Section__c               section                     {get;set;}
    public String                   curriculumId                {get;set;}

	public modalAddCurriculaController() {
		
	}

//=============================================Curricula Functions=======================================================
	public void startAddCurricula(){
        curriculum = new Curriculum__c();
        curriculum.Date_of_Module__c = Date.today();

        populateStudents();
	}

    public void startEditCurricula(){
        curriculumStudents = new List<Curriculum__c>();
        if(String.isNotBlank(curriculumId)){
            curriculum = getCurriculum(curriculumId);
        }
        curriculum = curriculum==null? new Curriculum__c(): curriculum;
        curriculumStudents.add(curriculum);
    }

	public void saveCurricula(){
        // cannot be a date in the future
        if (curriculum.Date_of_Module__c == null || curriculum.Date_of_Module__c < section.Start_Date__c ||
                curriculum.Date_of_Module__c > section.End_Date__c) {
            curriculum.Date_of_Module__c.addError('Date should be within the start and end of the section.'); return;
        }
        // Cannot have blank curriculum name
        if (String.isBlank(curriculum.Curriculum_Name__c)) {
            curriculum.Curriculum_Name__c.addError('Curriculum Name is required.'); return;
        }
        // Cannot have blank module name
        if (String.isBlank(curriculum.Module_Name__c)) {
            curriculum.Module_Name__c.addError('Module Name is required.'); return;
        }
        // Cannot have blank module assignments
        if (String.isBlank(curriculum.Module_Assignments__c)) {
            curriculum.Module_Assignments__c.addError('Module Assignments is required.'); return;
        }
        for(Curriculum__c curr: curriculumStudents){
            if (curr.Module_Score__c == null) {
                curr.Module_Score__c.addError('Module Score is required.'); return;
            }
        }

        try{
            for(Curriculum__c curr: curriculumStudents){
                curr.Date_of_Module__c = curriculum.Date_of_Module__c;
                curr.Curriculum_Name__c = curriculum.Curriculum_Name__c;
                curr.Module_Name__c = curriculum.Module_Name__c;
                curr.Module_Assignments__c = curriculum.Module_Assignments__c;
                curr.Comments__c = curriculum.Comments__c;
            }
            upsert curriculumStudents;
        }catch(Exception e){
            CYUtil.errorMessage('We have get errors when trying to save records.');
            return;
        }

        curriculumStudents = new List<Curriculum__c>();        
        for (StudentInfoWrapper ss : studentSections){
            ss.selected = false;
        }
        CYUtil.successMessage(System.Label.CurriculumMessage);
	}

    public void removeStudentFromCurriculum() {
        Id sID = Apexpages.currentPage().getParameters().get('sID');
        
        for (Curriculum__c curr: curriculumStudents){
            if (curr.Student__c == sID){
                curriculumStudents.remove(curriculumStudents.indexOf(curr));
                break;
            }
        }
        
        return;
    }

    public void populateStudents(){
        curriculumStudents = new List<Curriculum__c>();
        for(StudentInfoWrapper sew: studentSections){
            if(sew.selected){
                Curriculum__c newCurriculum = generateCurriculum(sew);
                curriculumStudents.add(newCurriculum);
            }
        }

        if(curriculumStudents.isEmpty()){
            CyUtil.errorMessage('Please select a student to add curriculum for.');
        }
    }

    public Curriculum__c generateCurriculum(StudentInfoWrapper sew){
        return new Curriculum__c(
                Student__c = sew.studentSection.Student__c,
                Student__r = sew.studentSection.Student__r,
                Section__c = sew.studentSection.Section__c,
                Student_Section__c = sew.studentSection.Id,
                Student_Section__r = sew.studentSection
        );
    }

    public Curriculum__c getCurriculum(String cId){
        return [SELECT Id, Name, Student__c, Student__r.Name, Section__c, Section__r.Name, Section__r.Start_Date__c,
            Section__r.End_Date__c, Student_Section__c,
            Date_of_Module__c, Curriculum_Name__c, Module_Name__c, Module_Assignments__c,
            Module_Score__c, Comments__c
            FROM Curriculum__c
            WHERE Id = :cId LIMIT 1];
    }
//=============================================End Curricula Functions===================================================
}
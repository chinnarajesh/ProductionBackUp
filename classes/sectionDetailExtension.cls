public with sharing class sectionDetailExtension {
    public Section__c section { get; set; }
    public List<StudentInfoWrapper> studentSections { get; set; }
    public Boolean isCM { get; set; }
    public Boolean isCurriculum { get; set; }

    //Add Students to section
    public Student_Section__c studentSectionHolder { get; set; }
    public List<StudentInfoWrapper> selectedStudents { get; set; }
    public String selectedSectionFilter { get; set; }
    public String selectedIndicatorAreaFilter { get; set; }
    public String selectedGradeFilter { get; set; }
    public List<SelectOption> sectionFilters { get; set; }
    public List<SelectOption> indicatorAreaFilters { get; set; }
    public List<SelectOption> gradeFilters { get; set; }

    //Withdraw students
    public List<StudentInfoWrapper> studentsToWithdraw { get; set; }

    //Add time
    public String selectedStaff { get; set; }
    public List<SelectOption> availableStaff { get; set; }

    //Edit time
    public List<ISTool.SessionWrapper> sessions { get; set; }
    public String sessionID { get; set; }
    public String sectionID { get; set; }
    public Intervention_Session__c sessionFilter { get; set; }

    //Add Students to IA
    public Boolean enabledStudentIAFilter { get; set; }

    private ISTool sessionLoader;
    private Set<ID> enrolledStudentIDs;
    private Set<ID> selectedStudentIDs;


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    public String letter { get; set; }
    //+++++++++++++++++++++++++++++++++++++++++++++

    public SectionDetailExtension() {

        ID sectionID = ApexPages.currentPage().getParameters().get('sectionID');
        enabledStudentIAFilter = false;
        selectedIndicatorAreaFilter = 'all';
        selectedGradeFilter = 'all';
        if (sectionID != null) {
            loadSectionData(sectionID);
        }

        if (section != null) {
            checkProfileType();
            sessionLoader = new ISTool(sectionID, false);
        } else {
            CYUtil.errorMessage('The system was unable to locate the id of the section you wish to view. Please return to the section detail page and try again.');
        }
    }

    private void loadSectionData(ID sectionID) {
        Set<String> allowedRT = new Set<String>{
                'Intervention Section', 'Curriculum'
        };
        section = [
                SELECT Id, Name, Auto_Name__c, Start_Date__c, Program__c, Intervention_Primary_Staff__c, End_Date__c,
                        School__c, Active__c, School__r.Name, Time__r.Name__c, Program__r.Indicator_Area__r.Id,
                        Program__r.Indicator_Area__r.Name, RecordTypeID, RecordType.Name, Account_Program__r.Name,
                        In_After_School__c, (
                        SELECT Active__c, Student__c, Student__r.Id, Student__r.Name, Student__r.Student_ID_Auto_Number__c, Student__r.Grade__c,
                                Student__r.Local_Student_ID__c, Student_Name__c, Student_Grade__c,
                                Section__c, Dosage_to_Date__c, Intervention_Enrollment_Start_Date__c,
                                Enrollment_Start_Date__c, Enrollment_End_Date__c
                        FROM Student_Section__r
                        ORDER BY Student__r.Student_First_Name__c ASC
//                        LIMIT 1000
                ), (
                        SELECT Is_Active__c, Staff__r.Name, Intervention_Primary_Staff__c
                        FROM Staff_Section__r
                )
                FROM Section__c
                WHERE Id = :sectionID
        ];

        if (!allowedRT.contains(section.RecordType.Name)) {
            CYUtil.errorMessage('The section you selected is not an intervention section. There is no data to display.');
            section = new Section__c();
        } else {
            isCurriculum = section.In_After_School__c == 'Curriculum';
            buildStudentSectionWrapper(section.Student_Section__r);
            if (studentSections.isEmpty()) {
                CyUtil.errorMessage('There are currently no active students in this section.');
            }

            availableStaff = new List<SelectOption>();
            if (section.Staff_Section__r.isEmpty()) {
                CyUtil.errorMessage('There are currently no active staff for this section.');
            } else {
                for (Staff_Section__c s : section.Staff_Section__r) {
                    availableStaff.add(new SelectOption(s.Staff__c, s.Staff__r.Name));
                }
            }
        }
    }

    private void checkProfileType() {
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        SharingControls__c sharingSettings = SharingControls__c.getInstance('CM');

        isCM = (sharingSettings != null && profileName.contains(sharingSettings.Profile_Name__c));
    }

    private void buildStudentSectionWrapper(List<Student_Section__c> ssList) {
        studentSections = new List<StudentInfoWrapper>();
        enrolledStudentIDs = new Set<ID>();
        selectedStudentIDs = new Set<Id>();
        for (Student_Section__c ss : ssList) {
            studentSections.add(new StudentInfoWrapper(ss));
            selectedStudentIDs.add(ss.Student__c);
            //enrolledStudentIDs.add(ss.Student__c);
            if (ss.Active__c) {
                enrolledStudentIDs.add(ss.Student__c);
            }
        }

        if (!selectedStudentIDs.isEmpty()) {
            selectedIndicatorAreaFilter = 'all';
            selectedGradeFilter = 'all';
            enabledStudentIAFilter = true;
            String query = buildAvailableStudentQuery(false);
            Map<Id, Student__c> students = new Map<Id, Student__c>((List<Student__c>) Database.query(query));
            enabledStudentIAFilter = false;
            for (StudentInfoWrapper sw : studentSections) {
                if (students.containsKey(sw.studentSection.Student__c)) {
                    Map<String, Object> data = new Map<String, Object>{
                            'Name' => students.get(sw.studentSection.Student__c).Name,
                            'Student_First_Name__c' => students.get(sw.studentSection.Student__c).Student_First_Name__c,
                            'Id' => students.get(sw.studentSection.Student__c).Id,
                            'Student_Last_Name__c' => students.get(sw.studentSection.Student__c).Student_Last_Name__c,
                            'Student_ID_Auto_Number__c' => students.get(sw.studentSection.Student__c).Student_ID_Auto_Number__c,
                            'Local_Student_ID__c' => students.get(sw.studentSection.Student__c).Local_Student_ID__c,
                            'Grade__c' => students.get(sw.studentSection.Student__c).Grade__c
                    };
                    Student__c record = (Student__c) JSON.deserialize(
                            JSON.serialize(data), Student__c.class
                    );
                    sw.updateStudentInfoWrapper(record, students.get(sw.studentSection.Student__c).Indicator_Area_Student__r);
                }
            }
            selectedStudentIDs = new Set<Id>();
        }
    }

    private String buildAvailableStudentQuery(Boolean isActive) {
        String query = 'SELECT Id,Name,Student_Last_Name__c,Student_First_Name__c,Grade__c,Student_Id__c,Student_ID_Auto_Number__c,Local_Student_ID__c,Entry_Date__c,Expiration_Date__c';
        query += ',(SELECT Indicator_Area__c, Indicator_Area__r.Name, Student__r.Name, Active__c, IA_Effective_Date__c, Reference_ID__c' +
                ' FROM Indicator_Area_Student__r';
        if (!enabledStudentIAFilter) {
            query += ' WHERE Active__c = true';
        }
        if (String.isNotBlank(selectedIndicatorAreaFilter) && selectedIndicatorAreaFilter != 'all') {
            query += (enabledStudentIAFilter ? ' WHERE' : ' AND') + ' Indicator_Area__c=\'' + selectedIndicatorAreaFilter + '\'';
        }
        query += ' ORDER BY Indicator_Area__r.Name)';

        query += ',(SELECT Id, Section__c, Section__r.Name, Section_Exit_Reason__c, Section__r.Program__r.Indicator_Area__r.Name, Enrollment_Start_Date__c, Enrollment_End_Date__c from Student_Section__r ';//where Active__c = true
        if (String.isNotBlank(selectedSectionFilter) && selectedSectionFilter != 'all') {
            query += ' WHERE Section__c=: selectedSectionFilter';//Active__c = true and
        }
        query += ' ORDER BY Section__r.Name)';

        query += ' FROM Student__c' +
                ' WHERE School__c = \'' + section.School__c + '\'';
        if (isActive) {
            query += ' AND Active__c = true';
        }
        System.debug('enabledStudentIAFilter ' + enabledStudentIAFilter);
        if (enabledStudentIAFilter) {
            query += ' AND ID IN: selectedStudentIDs';
        } else {
            query += ' AND ID NOT IN: enrolledStudentIDs' +
                    ' AND ID NOT IN: selectedStudentIDs';
        }

        if (String.isNotBlank(selectedGradeFilter) && selectedGradeFilter != 'all') {
            query += ' AND Grade__c =: selectedGradeFilter';
        }

        query += ' ORDER BY Student_First_Name__c, Student_Last_Name__c';
        system.debug(query);
        return query;
    }

    /*Enroll Students*/
    public void startEnrollStudents() {
        selectedGradeFilter = 'all';
        selectedSectionFilter = 'all';
        selectedIndicatorAreaFilter = 'all';
        selectedStudents = new List<StudentInfoWrapper>();
        selectedStudentIDs = new Set<ID>();
        studentSectionHolder = new Student_Section__c();//Enrollment_Start_Date__c = Datetime.now()
        ModalEnrollStudentController modalEnrollStudentController = new ModalEnrollStudentController();
        modalEnrollStudentController.startEnrollStudents();
    }

    public void enrollStudents() {
        List<Student_Section__c> toUpsert = new List<Student_Section__c>();
        //if its empty then
        if (selectedStudents.isEmpty()) {
            CYUtil.errorMessage('Please select at least one student to enroll.');
            return;
        }

        for (studentInfoWrapper s : selectedStudents) {
            toUpsert.add(new Student_Section__c(
                    Enrollment_Start_Date__c = studentSectionHolder.Enrollment_Start_Date__c,
                    //Intervention_Enrollment_Start_Date__c =	studentSectionHolder.Enrollment_Start_Date__c,
                    //Enrollment_End_Date__c = null,
                    //Section_Exit_Reason__c = null,
                    Active__c = true,
                    Student__c = s.student.ID,
                    Section__c = section.ID,
                    Reference_ID__c = s.student.Student_ID__c + '_' + section.Name + '_' + section.School__r.Name + '_' + section.Time__r.Name__c
            ));
        }

        try {
            upsert toUpsert Reference_ID__c;

            loadSectionData(section.ID);
            studentSectionHolder = new Student_Section__c();
            CyUtil.successMessage('Students enrolled successfully.');
        } catch (System.DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                CyUtil.errorMessage(e.getDMLMessage(i));
            }
        }
    }

    /*Withdraw Students*/
    public void startWithdrawStudents() {
        studentsToWithdraw = new List<StudentInfoWrapper>();
        studentSectionHolder = new Student_Section__c(Enrollment_End_Date__c = System.Now()); //system.today());
        for (StudentInfoWrapper sew : studentSections) {
            if (sew.selected) {
                studentsToWithdraw.add(sew);
            }
        }

        if (studentsToWithdraw.isEmpty()) {
            CyUtil.errorMessage('Please select a student to withdraw.');
        }
    }

    public void withdrawStudents() {
        List<Student_Section__c> toUpdate = new List<Student_Section__c>();
        Set<ID> withdrawStudentIDs = new Set<ID>();

        for (StudentInfoWrapper sew : studentsToWithdraw) {
            if((studentSectionHolder.Section_Exit_Reason__c == 'Accidental Enrollment') &&
                ((sew.studentSection.Dosage_to_Date__c < 1 && (studentSectionHolder.Enrollment_End_Date__c) == (sew.studentSection.Intervention_Enrollment_Start_Date__c)) ? false : true)){
                CyUtil.errorMessage('Exit Date should be equal to Enrollment Date.');
                break;
            } else {
                sew.studentSection.Enrollment_End_Date__c = studentSectionHolder.Enrollment_End_Date__c;
                sew.studentSection.Section_Exit_Reason__c = studentSectionHolder.Section_Exit_Reason__c;
                sew.studentSection.Active__c = false;
                toUpdate.add(sew.studentSection);
                withdrawStudentIDs.add(sew.studentSection.Student__c);
            }

        }

        if (toUpdate.size() > 0) {
            try {
                update toUpdate;
                loadSectionData(section.ID);
                CyUtil.successMessage('Students have been withdrawn successfully');
            } catch (System.DMLException e) {
                CyUtil.errorMessage('Unexpected exception while modifying student/sections.');
            }
        }
    }

    public void startEditTime() {
        selectedStaff = null;
        sessionFilter = new Intervention_Session__c();
        sessionLoader.updateResultSelection(false);
        sessionLoader.setAllSessions();
        sessionLoader.updateSessionSelection(section.ID, null, null, null, null);
        sessionLoader.loadSessionData();
        sessions = sessionLoader.getOrderedSessions();
        system.debug(sessions);
        if (sessions.isEmpty()) {
            CYUtil.errorMessage('There are no sessions for this section. Please create a new session.');
        }
    }

    public void filterSessions() {
        sessionLoader.setAllSessions();
        sessionLoader.updateSessionSelection(section.ID, null, sessionFilter.Date__c, null, sessionFilter.Session_Time_Completed_For__c);
        sessions = sessionLoader.getOrderedSessions();
        if (sessions.isEmpty()) {
            CYUtil.errorMessage('There are no sessions that match your criteria. Please create a new session.');
        }
    }

//=============================================Init skill functions==========================================================
    public PageReference getRecordPage() {
        String sessionRecordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sessionID ;
        PageReference sessionPage = new PageReference(sessionRecordUrl);
        return sessionPage;
    }

    public PageReference getSectionRecordPage() {
        String sectionRecordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sectionID ;
        PageReference sessionPage = new PageReference(sectionRecordUrl);
        return sessionPage;
    }
}
/**
 * Created by Yuriy Rudenko on 12/16/2020.
 */

public with sharing class ModalEnrollStudentController {

    public Section__c section { get; set; }
    public transient List<StudentInfoWrapper> studentSections { get; set; }
    public Boolean isCM { get; set; }
    public Student_Section__c studentSectionHolder { get; set; }
    public List<StudentInfoWrapper> availableStudents {
        get {
            if (availableStudents == null) {
                availableStudents = new List<StudentInfoWrapper>();
            }
            return availableStudents;
        }
        set;
    }
    public List<StudentInfoWrapper> selectedStudents { get; set; }
    public String selectedSectionFilter { get; set; }
    public String selectedIndicatorAreaFilter { get; set; }
    public String selectedGradeFilter { get; set; }
    public List<SelectOption> sectionFilters { get; set; }
    public List<SelectOption> indicatorAreaFilters { get; set; }
    public List<SelectOption> gradeFilters { get; set; }
    public Boolean enabledStudentIAFilter { get; set; }
    private ISTool sessionLoader;
    public Set<ID> enrolledStudentIDs { get; set; }
    private Set<ID> selectedStudentIDs;
    public Set<Id> selected { get; set; }
    public Map<Id, StudentInfoWrapper> addTo { get; set; }
    public AlphabeticPagination alphabeticPagination { get; set; }
    public String letter { get; set; }
    public ID sectionID { get; set; }

    //+++++++++++++++++++++++++++++++++++++++++++++

    public ModalEnrollStudentController() {
        letter = 'All';
        sectionID = ApexPages.currentPage().getParameters().get('sectionID');
        enabledStudentIAFilter = false;
        selectedIndicatorAreaFilter = 'all';
        selectedGradeFilter = 'all';
    }

    public void loadAvailableStudents() {
        availableStudents = new List<StudentInfoWrapper>();
        enrolledStudentIDs = new Set<ID>();

        for (Student_Section__c ss : section.Student_Section__r){
            if (ss.Active__c) {
                enrolledStudentIDs.add(ss.Student__c);
            }
        }


        String query = buildAvailableStudentQuery(true);
        System.debug('query = ' + query);

        if (selectedSectionFilter != 'all') {
            selectedIndicatorAreaFilter = 'all';
        }

        Set<String> gradeLevels = new Set<String>();
        Map<String, Set<ID>> indicatorAreaMap = new Map<String, Set<ID>>();
        Map<String, Set<ID>> sectionMap = new Map<String, Set<ID>>();
        for (Student__c student : Database.query(query)) {
            for (Indicator_Area_Student__c ias : student.Indicator_Area_Student__r) {
                if (selectedGradeFilter == 'all' && selectedSectionFilter == 'all' && selectedIndicatorAreaFilter == 'all') {
                    if (!indicatorAreaMap.containsKey(ias.Indicator_Area__r.Name)) {
                        indicatorAreaMap.put(ias.Indicator_Area__r.Name, new Set<Id>());
                    }
                    indicatorAreaMap.get(ias.Indicator_Area__r.Name).add(ias.Indicator_Area__c);
                }
            }
            if (selectedGradeFilter == 'all' && selectedSectionFilter == 'all' && selectedIndicatorAreaFilter == 'all') {
                gradeLevels.add(student.Grade__c);
                for (Student_Section__c studentSection : student.Student_Section__r) {
                    if (!sectionMap.containsKey(studentSection.Section__r.Name)) {
                        sectionMap.put(studentSection.Section__r.Name, new Set<ID>());
                    }
                    sectionMap.get(studentSection.Section__r.Name).add(studentSection.Section__c);
                }
            }

            if ((selectedSectionFilter != 'all' && student.Student_Section__r.isEmpty())
                    || (selectedIndicatorAreaFilter != 'all' && student.Indicator_Area_Student__r.isEmpty())) {
                continue;
            }

            Map<Id, Student_Section__c> mapSS = new Map<Id, Student_Section__c>();
            for (Student_Section__c ss : student.Student_Section__r) {
                mapSS.put(ss.Section__c, ss);
            }
            Student_Section__c ss = mapSS.containsKey(section.Id) ? mapSS.get(section.Id) : new Student_Section__c();
            availableStudents.add(new StudentInfoWrapper(student, ss, student.Indicator_Area_Student__r));
        }
        if (selectedGradeFilter == 'all' && selectedIndicatorAreaFilter == 'all' && selectedSectionFilter == 'all' && letter == 'All' ) {
            letter = 'All';
        }

        alphabeticPagination = new AlphabeticPagination(letter, availableStudents);
        availableStudents = alphabeticPagination.ShowStudent;

        loadSelectOptionLists(gradeLevels, indicatorAreaMap, sectionMap);
        if (availableStudents.size() == 0) {
            CYUtil.errorMessage('There are no students available using your filters.');
        }
    }

    private void loadSelectOptionLists(Set<String> studentGrades, Map<String, Set<ID>> indicatorAreaMap, Map<String, Set<ID>> sectionMap) {
        if (selectedSectionFilter == 'all' && selectedIndicatorAreaFilter == 'all' && selectedGradeFilter == 'all') {
            loadGradeLevels(studentGrades);
        }

        if (selectedSectionFilter == 'all' && selectedIndicatorAreaFilter == 'all' && (selectedGradeFilter == 'all' /*|| hasOver1000Students*/)) {
            indicatorAreaFilters = new List<SelectOption>();
            indicatorAreaFilters.add(new SelectOption('all', 'Filter by Ind. Area'));

            sectionFilters = new List<SelectOption>();
            sectionFilters.add(new SelectOption('all', 'Filter by Section'));

            List<String> labels = new List<String>(indicatorAreaMap.keySet());
            labels.sort();

            for (String label : labels) {
                for (ID iaID : indicatorAreaMap.get(label)) {
                    indicatorAreaFilters.add(new SelectOption(iaID, label));
                }
            }

            labels = new List<String>(sectionMap.keySet());
            labels.sort();

            for (String label : labels) {
                for (ID sectionID : sectionMap.get(label)) {
                    sectionFilters.add(new SelectOption(sectionID, label));
                }
            }
        }
    }

    private void loadGradeLevels(Set<String> studentGrades) {
        gradeFilters = new List<SelectOption>{
                new SelectOption('all', 'All Grade Levels')
        };

        Schema.DescribeFieldResult possibleGrades = Student__c.Grade__c.getDescribe();
        for (Schema.PicklistEntry pe : possibleGrades.getPicklistValues()) {
            if (studentGrades.contains(pe.getValue())) {
                gradeFilters.add(new SelectOption(pe.getValue(), pe.getLabel()));
            }
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

    public void addToSelected() {
        List<studentInfoWrapper> tempWrapper = new List<StudentInfoWrapper>();
        for (StudentInfoWrapper sw : availableStudents) {
            if (selectedStudents.size() + tempWrapper.size() >= 1000) {
                CyUtil.errorMessage('You have already selected 1000 students for addtion. Please finialize this addtion before adding more students.');
                break;
            } else if (sw.selected) {
                sw.selected = false;
                selectedStudents.add(sw);
                selectedStudentIds.add(sw.student.ID);
            } else {
                tempWrapper.add(sw);
            }
        }
        availableStudents = tempWrapper;
    }

    public void removeFromSelected() {
        List<studentInfoWrapper> tempWrapper = new List<StudentInfoWrapper>();
        for (StudentInfoWrapper sw : selectedStudents) {
            if (!sw.selected) {
                tempWrapper.add(sw);
            } else {
                selectedStudentIDs.remove(sw.student.ID);
            }
        }
        selectedStudents = tempWrapper;
        loadAvailableStudents();
    }

    /*Enroll Students*/
    public void startEnrollStudents() {
        selectedGradeFilter = 'all';
        selectedSectionFilter = 'all';
        selectedIndicatorAreaFilter = 'all';
        selectedStudents = new List<StudentInfoWrapper>();
        selectedStudentIDs = new Set<ID>();
        studentSectionHolder = new Student_Section__c();//Enrollment_Start_Date__c = Datetime.now()

        loadAvailableStudents();
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
                    //Intervention_Enrollment_Start_Date__c =  studentSectionHolder.Enrollment_Start_Date__c,
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

//            loadSectionData(section.ID);
            studentSectionHolder = new Student_Section__c();
            CyUtil.successMessage('Students enrolled successfully.');
        } catch (System.DMLException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                CyUtil.errorMessage(e.getDMLMessage(i));
            }
        }
    }

    public void displayStudent() {
        loadAvailableStudents();
    }

//    public String selectStudentParam { get; set; }
//
//    public void selectStudent() {
//        processSelectedStudents(selectStudentParam);
//        if (selected.IsEmpty()) {
//            ApexPages.addMessage(new ApexPages.Message(apexpages.severity.error, 'No students selected.'));
//            selectStudentParam = null;
//        }
//    }
//
//    public void processSelectedStudents(String selectStudentParam) {
//        for (StudentInfoWrapper studentWrapper : availableStudents) {
//            selected.remove(studentWrapper.student.ID);
//            addTo.remove(studentWrapper.student.ID);
//        }
//
//        if (String.isNotBlank(selectStudentParam)) {
//            List<String> ids = selectStudentParam.split(';');
//            Set<Id> selIds = new Set<Id>();
//            for (String i : ids) {
//                selIds.add(i.trim());
//            }
//            selected.addAll(selIds);
//
//            for (StudentInfoWrapper studentWrapper : availableStudents) {
//                if (selIds.contains(studentWrapper.student.ID)) {
//                    addTo.put(studentWrapper.student.Id, studentWrapper);
//                }
//            }
//        }
//    }


    public class AlphabeticPagination {
        public Integer resultSize { get; set; }
        public transient list<StudentInfoWrapper> listInner { get; set; }
        public List <String> SerchAlphabet { get; set; }
        public transient String SearchVar { get; set; }
        public transient list <StudentInfoWrapper> ShowStudent { get; set; }
        public integer sizee { get; set; }

        public AlphabeticPagination(String let, List<StudentInfoWrapper> lstWr) {
            listInner = new list<StudentInfoWrapper>(lstWr);
            resultSize = listInner.size();
            SerchAlphabet = new List<String>{
                    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'All'
            };
            SearchVar = let;
            ShowStudent = new List <StudentInfoWrapper> ();
            ShowStudent.clear();
            System.debug('lstWr ' + lstWr.size());

            for (StudentInfoWrapper a : lstWr) {
                if (SearchVar.equals('All')) {
                    if (ShowStudent.size() < 1000) {
                        ShowStudent.add(a);
                    }
                } else if (a.student.Student_First_Name__c.startsWith(SearchVar.toLowerCase()) || a.student.Student_First_Name__c.startsWith(SearchVar))
                    ShowStudent.add(a);
            }
            System.debug('ShowStudent ' + ShowStudent.size());


            if (ShowStudent.size() == 0) {
                ShowStudent = display('All');
            }
            sizee = ShowStudent.size();
        }

        public List<StudentInfoWrapper> display(String let) {
            ShowStudent.clear();
            SearchVar = let;
            System.debug('SearchVar ' + listInner.size());
            for (StudentInfoWrapper a : listInner) {
                if (SearchVar.equals('All')) {
                    if (ShowStudent.size() < 1000) {
                        ShowStudent.add(a);
                    }
                } else if (a.student.Student_First_Name__c.startsWith(SearchVar.toLowerCase()) || a.student.Student_First_Name__c.startsWith(SearchVar)) {
                    System.debug('a ' + a);
                    ShowStudent.add(a);
                }
            }
            sizee = ShowStudent.size();
            System.debug('ShowStudent ' + ShowStudent);
            return ShowStudent;
        }
    }
}
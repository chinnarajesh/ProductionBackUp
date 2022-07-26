public with sharing class Assessment_SoqlUtils {
    private static string studentSearchQuery = 'SELECT Name, Student_First_Name__c, Student_Last_Name__c,'+
                                                ' Grade__c, Active__c,Legacy_Id__c,' + 
                                                ' Student_Id__c, School__c' +// id, Date_of_Birth__c, Reference_ID__c, Setup__c, Individual__c, Individual__r.Name' +
                                                ' FROM Student__c'+
                                                ' WHERE Active__c=';
    private static string sectionSearchQuery = 'SELECT id, Name, Course__c, Course__r.Name'+
                                                ' FROM Section__c'+
                                                ' WHERE Name != null ';
                                                //' WHERE Reporting_Period__r.Parent_Time_Element__r.Parent_Time_Element__c=\'';
                                                // AND RecordType.Name=\'Published\'
//Added by Harsh Singh for T-493158
    public static List<Picklist_Value__c> getTypes(String typeID){
        return getTypes(typeID, '');
    }

    public static List<Picklist_Value__c> getTypes(String typeID, String typeIA){
        List<Picklist_Value__c> types = new List<Picklist_Value__c>();
        String query = 'SELECT id, Name, FieldSet__c, Show_On_Report_Card__c, show_On_Transcript__c, year_Over_Year__c ' +
                'FROM Picklist_Value__c ' +
                'WHERE RecordTypeId =: typeId';
        if(String.isNotBlank(typeIA) && typeIA!='--None--'){
            query += ' AND Indicator_Area__c = \''+String.escapeSingleQuotes(typeIA)+'\'';
        }
        types = DataBase.query(query);
//        types = [select id, Name, FieldSet__c, Show_On_Report_Card__c, show_On_Transcript__c, year_Over_Year__c
//                from Picklist_Value__c
//                where RecordTypeId =: typeId];
        
        return types;
    }
    
    public static List<Picklist_Value__c> getTypesById(Set<Id> ids){
        List<Picklist_Value__c> types = new List<Picklist_Value__c>();
        types = [SELECT Id, Name, FieldSet__c, Show_On_Report_Card__c, show_On_Transcript__c, year_Over_Year__c, Indicator_Area__c
                FROM Picklist_Value__c
                WHERE Id IN: ids];
        
        return types;
    }
    
    public static List<Time_Element__c> getYears(){
        List<Time_Element__c> years = new List<Time_Element__c>();
        years = [select id, Date_Start_Date__c, End_Date__c, Name__c
                from Time_Element__c 
                where Picklist_Value__r.Name = 'Year' order by EndTime__c DESC];
        
        return years;
    }
    
    public static List<Student__c> searchStudents(AssessmentWizardController.studentWrapper searchInfo, string yearid){
        System.debug('##@@'+searchInfo);
        String firstName = String.isNotBlank(searchInfo.student.Student_First_Name__c)? core_SoqlUtils.getSearchName(searchInfo.student.Student_First_Name__c): '';
        String lastName = String.isNotBlank(searchInfo.student.Student_Last_Name__c)? core_SoqlUtils.getSearchName(searchInfo.student.Student_Last_Name__c): '';
        String query = Assessment_SoqlUtils.studentSearchQuery;
        list<String> gradesSet=new list<String>();
        gradesSet=searchInfo.student.Grede_Multiselect__c!=null?searchInfo.student.Grede_Multiselect__c.split(';'):null;
        query += searchInfo.student.Active__c;
        query += String.isNotBlank(yearid)?(' AND Setup__r.Year__c =\'' + String.escapeSingleQuotes(yearid) + '\''): '';
        query += String.isNotBlank(firstName)? ' AND Student_First_Name__c LIKE \''+firstName+'\'': '';
        query += String.isNotBlank(lastName)? ' AND Student_Last_Name__c LIKE \''+lastName+'\'': '';
        if(searchInfo.student.Date_of_Birth__c!=null){
            //must reformat the date before it will search properly
            //date.format returns mm/dd/yyyy
            //queries need yyyy-mm-dd
            String[] vars = searchInfo.student.Date_of_Birth__c.format().split('/',3);
            if(vars[0].length()==1) vars[0] = '0'+vars[0];
            if(vars[1].length()==1) vars[1] = '0'+vars[1];
            query += ' AND Date_of_Birth__c='+vars[2]+'-'+vars[0]+'-'+vars[1];
        }
        query += (searchInfo.student.Date_of_Birth__c == null) ? '':' AND Date_of_Birth__c=' + String.valueOf(searchInfo.student.Date_of_Birth__c);
        query += (searchInfo.student.Gender__c == null) ? '':' AND Gender__c=\''+searchInfo.student.Gender__c+'\'';
        query += (searchInfo.student.Student_Id__c == null) ? '':' AND Student_Id__c=\'' + String.escapeSingleQuotes(searchInfo.student.Student_Id__c) + '\'';
        query += (searchInfo.student.Grade__c == null) ? '':' AND Grade__c =\''+searchInfo.student.Grade__c+'\'';
        query += (gradesSet==null || gradesSet.isEmpty()) ? '':' AND Grade__c in:gradesSet';
        query += (searchInfo.student.IEP__c)?' AND IEP__c=' + searchInfo.student.IEP__c:'';
        query += (searchInfo.student.ELL__c)?' AND ELL__c=' + searchInfo.student.ELL__c:'';
        query += (searchInfo.school == null || searchInfo.school == '--None--') ? '':' AND School__c=\''+String.escapeSingleQuotes(searchInfo.school)+'\'';
        query += (searchInfo.student.Local_Student_ID__c==null)?'' :' AND   Local_Student_ID__c=\''+ String.escapeSingleQuotes(String.valueOf(searchInfo.student.Local_Student_ID__c))+'\'';//Added for T-493156
        if(searchInfo.indicatorArea != null || searchInfo.indicatorArea != '--None--'){//Added for T-493156 begin
            List<Indicator_Area_Student__c > lstAre=[select Student__c FROM Indicator_Area_Student__c where Indicator_Area__r.Indicator_Area_Type__c =:searchInfo.indicatorArea];
            if(lstAre.isEmpty()==false){
                List<String> lstStIds = new List<String>();
                for(Indicator_Area_Student__c las: lstAre){
                    lstStIds.add(String.valueOf(las.Student__c));
                }
                query+= ' AND Id IN (\''+String.join(lstStIds, '\',\'')+'\') ';
            }
        }//Added for T-493156 end
        System.debug('query******'+query);
        query += '  AND School__r.RecordType.Name=\'School\' ORDER BY Student_Last_Name__c ASC LIMIT '+String.valueOf(Label.Record_Count_Search);
        
        List<Student__c> results = new List<Student__c>((List<Student__c>)Database.query(query));
        return results;
    }
    
    public static List<Section__c> searchSections(Section__c searchInfo,String recordTypeName, string courseName, string yearID){
        String name = String.isNotBlank(searchInfo.Name)? core_SoqlUtils.getSearchName(searchInfo.Name): '';
        courseName = String.isNotBlank(courseName)? core_SoqlUtils.getSearchName(courseName): '';
        
        String query = Assessment_SoqlUtils.sectionSearchQuery;
        //query += String.escapeSingleQuotes(yearid) + '\'';
        query += String.isNotBlank(name)? ' AND Name LIKE \'%'+name+'%\'': '';
        query += String.isNotBlank(courseName)? ' AND Course__r.Name LIKE \'%'+String.escapeSingleQuotes(courseName)+'%\'': '';
        query += (recordTypeName!='' && recordTypeName!='--None--')?' AND RecordType.Name=\''+recordTypeName+'\' ':'';// Added for T-493158 begin
        query += (searchInfo.Staff__c !=null)?' AND Intervention_Primary_Staff__c=\''+String.escapeSingleQuotes(searchInfo.Staff__c)+'\' ':'';
        query += (searchInfo.Program__c !=null)?' AND Program__c=\''+String.escapeSingleQuotes(searchInfo.Program__c)+'\' ':'';
        query += (searchInfo.Section_Nickname__c!=null)?' AND Section_Nickname__c LIKE \'%'+String.escapeSingleQuotes(searchInfo.Section_Nickname__c)+'%\' ':'';
        query += ' ORDER BY Name ASC limit '+String.valueOf(Label.Record_Count_Search);// Added for T-493158 end
        //query += ' AND School__r.RecordType.Name=\'School\' ORDER BY Name ASC limit 1001';
        System.debug('Query@@@@'+query);
        List<Section__c> results = new List<Section__c>((List<Section__c>)Database.query(query));
        return results;
    }
    
    public static List<Student__c> getStudentsInSections(Set<Id> sectionIds){
        List<Student_Section__c> ssList = [select Student__c from Student_Section__c where Section__c in: sectionIds AND Active__c = true];
        Set<Id> studentIds = new Set<Id>();
        for(Student_Section__c ss: ssList){
            studentIds.add(ss.Student__c);
        }
        
        List<Student__c> students = new List<Student__c>([SELECT id, Name, Student_First_Name__c, Student_Last_Name__c,
                                                            Grade__c, Active__c, Date_of_Birth__c, Legacy_Id__c,
                                                            Student_Id__c, School__c, Reference_ID__c, Individual__c
                                                        FROM Student__c
                                                        WHERE id IN: studentIds
                                                        AND Active__c = true]);
        return students;
    }
    
    public static List<Setup__c> getSetupsByYear(string year){
        List<Setup__c> setups = new List<Setup__c>();
        setups = [select id, School__c, School__r.Name
                    from Setup__c
                    where Year__c =: year
                    and School__c != null
                    and School__r.RecordType.Name = 'School'
                    order by School__r.Name ASC];
        return setups;
    }
    
    public static Set<String> FLDASSMENTS = new Set<String>{'Student__c','Student_Id__c','Type__c','Contact__c','Date__c',
        'External_Id__c','Time__c','Year_Over_Year__c','Show_On_Report_Card__c','Show_On_Transcript__c','Student__r.Student_First_Name__c',
        'Student__r.Student_Last_Name__c','Contact__r.Name','Date_Administered__c'
    };
    public static List<sObject> getAssessmentById(Set<Id> assessmentIds, String apiFieldSet){
        List<Assesment__c> assessments = new List<Assesment__c>();
        Set<String> flds = new Set<String>(FLDASSMENTS);
        flds.addAll(apiFieldSet.remove(' ').split(','));
        flds.remove('');
        String query = 'SELECT Id,'+String.join(new List<String>(flds), ',');
        query+= ' FROM Assesment__c WHERE ID in:assessmentIds';
        
        system.debug(query);
        assessments = (List<Assesment__c>) Database.query(query);
        return assessments;
    }
    
    public static List<Assesment__c> getExistingAssessments(Picklist_Value__c asmtType, Student__c searchInfo, Date startDate, Date endDate, String school, string grades, String indicator, Boolean nullDateCheck){
        List<Assesment__c> assessments = new List<Assesment__c>();
        String query = 'SELECT Date__c, Student_Name__c, Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c, Student__r.Legacy_Id__c, Student__r.Student_Id__c, '+string.escapeSingleQuotes(asmtType.fieldSet__c)+' FROM Assesment__c ';
        query += getFilterExistingAssessments(asmtType, searchInfo, startDate, endDate, school, grades, indicator, nullDateCheck);
        query +=' ORDER by Date__c Limit 10000';//added by harsh Singh

        system.debug('@@@ Query: '+query);
        assessments = (List<Assesment__c>) Database.query(query);
        
        return assessments;
    }

    //Added by Harsh Singh to get the count of the Assignment begin
    public static Integer getExistingAssessmentsCount(Picklist_Value__c asmtType, Student__c searchInfo, Date startDate, Date endDate, String school, string grades, String indicator ,Boolean nullDateCheck){
        List<Assesment__c> assessments = new List<Assesment__c>();
        String query = 'SELECT count(Id) FROM Assesment__c ';
        query += getFilterExistingAssessments(asmtType, searchInfo, startDate, endDate, school, grades, indicator, nullDateCheck);

        system.debug(query);
        Integer i;
        try{
            for(AggregateResult result : Database.query(query)){
                i=(Integer)result.get('expr0'); }
                System.debug('count***'+i);
        }catch(Exception e){
        }
        return i;
    }

    public static String getFilterExistingAssessments(Picklist_Value__c asmtType, Student__c searchInfo, Date startDate, Date endDate, String school, string grades, String indicator, Boolean nullDateCheck){
        String query = ' WHERE Student__c != null and Type__c=\''+String.escapeSingleQuotes(asmtType.Id)+'\' and Student__r.Active__c = '+String.escapeSingleQuotes(String.valueOf(searchInfo.Active__c));
        query += (searchInfo.IEP__c)?(' AND Student__r.IEP__c=' + String.escapeSingleQuotes(String.valueOf(searchInfo.IEP__c))):'';
        query += (searchInfo.ELL__c)?(' AND Student__r.ELL__c=' + String.escapeSingleQuotes(String.valueOf(searchInfo.ELL__c))):'';
        query += (String.isNotBlank(school) && school != '--None--')? (' AND Student__r.School__c =\''+String.escapeSingleQuotes(school)+'\''):'';
        //Added for T-493159 begin
        if(nullDateCheck==false){
            query += (startDate != null)?(' AND Date_Administered__c  >= :startDate'):'';
            query += (endDate != null)?(' AND Date_Administered__c  <= :endDate'):'';
            query += (startDate != null || endDate != null )?' AND Date_Administered__c  != null': '';
        }else if(nullDateCheck==true){
            query += ' AND Date_Administered__c  = null';
        }
        query +=(String.isNotBlank(searchInfo.Student_Id__c))? (' AND Student_Id__c = \''+String.escapeSingleQuotes(String.valueOf(searchInfo.Student_Id__c))+'\''):'';
        query +=(String.isNotBlank(searchInfo.Local_Student_ID__c))? (' AND Student__r.Local_Student_ID__c =\''+String.escapeSingleQuotes(String.valueOf(searchInfo.Local_Student_ID__c))+ '\''):'';

        if(String.isNotBlank(searchInfo.Section__c)){//search by section
            query += ' AND Student__c IN (SELECT Student__c FROM Student_Section__c WHERE Section__r.Name like \'%'+String.escapeSingleQuotes(searchInfo.Section__c)+'%\' )';
        }

        if(String.isNotBlank(indicator) && indicator!='--None--'){
            List<Indicator_Area_Student__c> indicatorAreas=[Select Student__c FROM Indicator_Area_Student__c Where Indicator_Area__r.Name=: indicator];
            System.debug('#####indicatorAreas'+indicatorAreas.size());
            Set<String> studentIds = new Set<String>();
            for(Indicator_Area_Student__c ida : indicatorAreas) {
                studentIds.add(ida.Student__c);
            }
            query +=(!studentIds.isEmpty())?' AND Student__r.ID IN (\''+String.join(new List<String>(studentIds), '\',\'')+'\')': '';
        }
        //Added for T-493159 end
        if(String.isNotBlank(grades)){
            Set<String> gradeSet = new Set<String>(StringUtils.splitAndTrim(grades, ';'));
            query += (!gradeSet.isEmpty())? (' AND Student__r.Grade__c IN (\''+String.join(new List<String>(gradeSet), '\',\'')+'\')'): '';
        }

        return query;
    }
}
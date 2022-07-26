public with sharing class testDataSetupUtil_v2 {

/*~~~~~~~~~~~~~~~~~~~~~~~START STATIC VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    public static Course_Catalog__c courseCatalogue;
    public static Account school;
    public static List<Course__c> coursesList;
    public static List<Course_Course_Catalog__c> ccCatalogueList;
    public static Grade_Scale_Catalog__c gradeScaleCat;
    public static Map<String, ID> scaleMap;
    public static Picklist_Value__c YearPickVal;
    public static Picklist_Value__c TermPickVal;
    public static Picklist_Value__c QPickVal;
    public static Picklist_Value__c SemPickVal;
    public static Picklist_Value__c PeriodPickVal;
    public static Time_Element__c masterYear;
    public static Time_Element__c term;
    public static Time_Element__c semester;
    public static Time_Element__c semester2;
    public static Time_Element__c semester3;
    public static Time_Element__c semester4;
    public static Setup__c activeSetUp;
    public static Standard__c strandStandard;
    public static List<Picklist_Value__c> assignmentTypeList;
    public static List<Program__c> programsList;
    public static List<Account_Program__c> accountProgramsList;
    public static List<Section__c> sectionsList;
    public static List<User> staffUsersList;
    public static List<Contact> staffContactsList;
    public static List<User> studUsersList;
    public static List<Contact> studContactsList;
    public static List<String> curriculumNameList;
    public static List<String> curriculumModulNameList;
    public static List<String> curriculumModuleAssignmentList;
    public static List<Curriculum__c> curriculumList;
    public static List<Staff__c> teachersList;
    public static List<Staff_Section__c> staffSectionsList;
    public static List<Student__c> studentsList;
    public static List<Student_Section__c> studSectionsList;
    public static List<Session__c> sessionsList;
    public static List<Intervention_Session__c> interventionSessionsList;
    public static List<Intervention_Session_Result__c> interventionSessionResultsList;
    public static List<Student_PG__c> studpgList;
    public static List<Room__c> roomList;
    public static List<Standard__c> testStandards;
    public static Assignment_Lib__c assignLib;
    public static UserRole portalRole;
    public static Profile portalProfile;
    public static List<Picklist_Value__c> pickListVals;
    public static List<Picklist_Value__c> behaviorPicklistVals;
    public static List<Grade_Normalization__c> gradeNormList;
    public static OverrideSettings__c os;
    public static SchoolForce_Settings__c sfs;
    public static S3_Credentials_Name__c s3n;
    public static List<Purged_Object__c> pos;
    public static boolean isGradebook = false;
    public static boolean isBehavior = false;
    public static boolean isAttendance = false;
    public static boolean is4Rp = false;

/*~~~~~~~~~~~~~~~~~~~~~~~END STATIC VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    /********************START OF MAIN METHODS ****************************/

    public static void setUPCoreData(integer courses) {
        setupCustomSettings(); //This should be genericized and not specific to report card; add in override
        //Ensure that the system admin user has crm content & assignments library
        createDefaultPicklistValues();
        school = getSchools(1)[0];
        setupTimeElements(30);
        if (isGradebook)
            setupPreGradebookData(); //Anything related to grades/gradebook
        setupCourses(courses);
        setupSetupRecord();

        if (isBehavior)
            behaviorPicklistVals = createBehaviorPicklistValues();
        //if (isGradebook) createScalesNormalizations();
    }
    /* 1.Insert k Users.
        2. Insert one contact for one User i.e k Contact records
        3. Insert one Staff Member for one contact i.e k Staff records
        4. Insert one staff section for one staff and one section.
    */
    public static void setUpStaffData(integer k) {
        staffUsersList = getUsers(k, 'Staff');
        staffContactsList = getContacts(k, 'Staff', staffUsersList);
        teachersList = getStaffMembers(k, 'Staff', staffContactsList);
        sectionsList = getSections(coursesList);
        if (isGradebook) setupStandards();
        staffSectionsList = getStaffSections(k, teachersList, sectionsList);
        roomList = getRooms(k);
    }

    /* 1.Insert k Users.
        2. Insert one contact for one User i.e k Contact records
        3. Insert one Student for one contact i.e k Student records
        4. Insert one Student section for one Student and one section.
    */
    public static void setUpStudentData(integer k) {
        studContactsList = getContacts(k, 'Student', null);
        studentsList = getStudents(k, 'Student', studContactsList);
        studpgList = getPGs();
        studSectionsList = getStudentSections(k, studentsList, sectionsList);
    }

    public static void setUpCurriculumData(Integer k) {
        curriculumNameList = getCurriculumNames(k, 'Curriculum__c', 'Curriculum_Name__c');
        curriculumModulNameList = getCurriculumModulNames(k, 'Curriculum__c', 'Module_Name__c');
        curriculumModuleAssignmentList = getCurriculumModuleAssignments(k, 'Curriculum__c', 'Module_Assignments__c');
        curriculumList = getCurriculums(k);
    }
    /********************END OF MAIN METHODS ****************************/


    /*********************START  SUMMARY METHODS******************************/
    public static void setupCustomSettings() {
        if (isGradebook) {
            getS3Settings();
            getDefaultGradeOverrideSettings();
        }
        getDefaultSchoolForceSettings();
        setUpPictureCustomSetting();
        getPurgedObjectCustomSettings();
        if (isAttendance) {
            processErrorMessageData();
        }
    }

    public static void setupTimeElements(integer yearsToAdd) {
        Integer month = system.today().month();
        Integer year = system.today().year() + yearsToAdd;
        String yearStart = '08/01/' + String.valueOf(year);
        String yearEnd = '07/31/' + String.valueOf(year + 1);
        String termStart = yearStart;
        String termEnd = yearEnd;

        //year
        masterYear = getTimeElements(1, 'Master Year', YearPickVal.Id, null, yearStart, yearEnd, false)[0]; //Time Element for the Master Year
        system.debug(LoggingLevel.info, 'masterYear ~~~~~~~~~~~~~~' + masterYear);

        //term
        term = getTimeElements_NoInsert(1, 'Term', TermPickVal.Id, masterYear.Id, termStart, termEnd, false)[0];
        term.Reporting_Period_Value__c = QPickVal.id; //Shouldn't we adapt the getTimeElements method for this
        insert term;

        system.debug(LoggingLevel.info, 'term ~~~~~~~~~~~~~~' + term);
        if (is4Rp) {
            semester = getTimeElements_NoInsert(1, 'Semester', QPickVal.Id, term.Id, term.date_start_date__c.format(), term.date_start_date__c.addDays(60).format(), true)[0];
            system.debug(LoggingLevel.info, 'semester ~~~~~~~~~~~~~~' + semester);
            semester2 = getTimeElements_NoInsert(1, 'Semester2', QPickVal.Id, term.Id, term.date_start_date__c.addDays(61).format(), term.end_Date__c.addDays(-10).format(), true)[0];
            system.debug(LoggingLevel.info, 'semester2 ~~~~~~~~~~~~~~' + semester2);
            semester3 = getTimeElements_NoInsert(1, 'Semester3', QPickVal.Id, term.Id, term.end_Date__c.addDays(-9).format(), term.end_Date__c.addDays(-8).format(), true)[0];
            semester4 = getTimeElements_NoInsert(1, 'Semester4', QPickVal.Id, term.Id, term.end_Date__c.addDays(-7).format(), term.end_Date__c.addDays(-6).format(), true)[0];

            List<Time_Element__c> timeElements = new List<Time_Element__c>{
                    semester, semester2, semester3, semester4
            };
            insert timeElements;
        } else {
            semester = getTimeElements_NoInsert(1, 'Semester', SemPickVal.Id, term.Id, term.date_start_date__c.format(), term.date_start_date__c.addDays(60).format(), true)[0];
            system.debug(LoggingLevel.info, 'semester ~~~~~~~~~~~~~~' + semester);
            semester2 = getTimeElements_NoInsert(1, 'Semester2', SemPickVal.Id, term.Id, term.date_start_date__c.addDays(61).format(), term.end_Date__c.addDays(-10).format(), true)[0];
            system.debug(LoggingLevel.info, 'semester2 ~~~~~~~~~~~~~~' + semester2);

            List<Time_Element__c> timeElements = new List<Time_Element__c>{
                    semester, semester2
            };
            insert timeElements;
        }
    }

    public static void setupCourses(integer k) {
        //Get Course catalog
        courseCatalogue = getCourseCatalogs(1)[0];
        system.debug(LoggingLevel.info, 'courseCatalogue ~~~~~~~~~~~~~~' + courseCatalogue);

        //Get Courses
        coursesList = getCourses(k);
        system.debug(LoggingLevel.info, 'coursesList ~~~~~~~~~~~~~~' + coursesList);

        if (!isGradebook) {//KC: this gets called twice
            assignmentTypeList = createDefaultAssignmentTypes();  //set up assignment type
            system.debug(LoggingLevel.info, 'assignmentTypeList ~~~~~~~~~~~~~~' + assignmentTypeList);
        }

        createDefaultAssignmentWeightings(coursesList, assignmentTypeList);

        //Get Course Course Catalog
        ccCatalogueList = getCourseCourseCatalogues(coursesList, courseCatalogue.Id);
        system.debug(LoggingLevel.info, 'ccCatalogueList ~~~~~~~~~~~~~~' + ccCatalogueList);
    }

    public static void createDefaultAssignmentWeightings(List<Course__c> courses, List<Picklist_Value__c> assignmentTypes) {
        List<Default_Assignment_Weighting__c> daws = new List<Default_Assignment_Weighting__c>();
        for (Course__c c : courses) {
            for (Picklist_Value__c plv : assignmentTypes) {
                daws.add(new Default_Assignment_Weighting__c(
                        Picklist_value__c = plv.id,
                        Course__c = c.id,
                        Default_Weighting__c = 1));
            }
        }
        upsert daws;
    }

    public static void setupPreGradebookData() {
        gradeScaleCat = getGradeScaleCatalogs(1)[0];    //Get GradeScale catalog
        createScalesNormalizations();                    //Get GradeScale Norms
    }

    public static void setupSetupRecord() {
        activeSetUp = [SELECT Course_Catalog__c, Grade_Scale_Catalog__c, School__c, School__r.Reference_Id__c, Year__c, Year__r.Name__c, Term__c, Active__c, Group_Based__c, Room_Dependent__c,Grade_Span__c, Points_Reset_Value__c, Points_Reset_Date__c, Points_Frequency__c, Show_Homework_in_Portal__c, Calculation_Type__c FROM Setup__c WHERE school__c = :school.id and active__c = true];
        activeSetup.Active__c = true;
        activeSetUp.term__c = term.id;
        if (ccCatalogueList != null)
            activeSetUp.course_catalog__c = courseCatalogue.Id;
        if (gradeScaleCat != null)
            activeSetUp.Grade_Scale_Catalog__c = gradeScaleCat.Id;

        activeSetup.group_based__c = false;
        activeSetup.Room_Dependent__c = true;
        activeSetup.Grade_Span__c = '1;2;3;4;5;';
        activeSetup.Points_Frequency__c = 'Monthy';
        activeSetup.Points_Reset_Date__c = system.today();
        activeSetup.Points_Reset_Value__c = 100;
        activeSetup.Show_Homework_in_Portal__c = true;
        activeSetup.Evaluation_Documents__c = 'Report Card - High School;Report Card - Elementary School;Progress Report - High School;Progress Report - Elementary School;Transcript';
        update activeSetup;
        system.debug(LoggingLevel.info, 'activeSetup~~~~' + activeSetup);
    }


    public static void createDefaultPicklistValues() {
        if (isGradebook) createDefaultAssignmentTypes();
        createDefaultTimeValues();
    }

    /*********************END	SUMMARY METHODS ************************/


    /********************* START CUSTOM SETTINGS METHODS******************************/
    /*	retrieve custom settings for Standards based Report Card*/
    public static void getS3Settings() {
        s3n = S3_Credentials_Name__c.getOrgDefaults();
        if (s3n.id == null) {
            s3n = new S3_Credentials_Name__c(server_Name__c = 'Report Card Server');
            upsert s3n;
        }
    }
    public static void getDefaultSchoolForceSettings() {
        sfs = SchoolForce_Settings__c.getOrgDefaults();
        if (sfs.id == null) {
            sfs = new SchoolForce_Settings__c(Purged_Setup__c = 1);
            upsert sfs;
        }
    }

    public static void getPurgedObjectCustomSettings() {
        testDataSetupUtil_v2.insertPurgedObjectsCustomSettings();
    }

    public static void getDefaultGradeOverrideSettings() {
        os = OverrideSettings__c.getOrgDefaults();
        if (os.id == null) {
            os = new OverrideSettings__c(Allowable_Grades__c = 'I,W,N', Grade_Override__c = true, Withdraw_Override__c = true);
            upsert os;
        }
    }

    public static void setUpPictureCustomSetting() {
        //This awesome code based on a blog at this address http://improveit360.blogspot.com/2010/09/how-to-use-static-resource-images-in.html
        pictureHelper__c ph = pictureHelper__c.getOrgDefaults();
        if (ph.id == null) {
            ph = new pictureHelper__c();
            upsert ph;
        }
        StaticResource pictureResource = [Select body, name, ID from StaticResource where Name = 'pictures' limit 1];
        if (pictureResource != null) {
            String imagesID = String.valueOf(pictureResource.id);
            PageReference pr = new PageReference('/' + imagesId);
            // Load the HTML of the page so we can parse out the link to the static resource
            if (!Test.isRunningTest()) {
                String pageContent = pr.getContent().toString();
                // Find the last instance of what we think is the link of the resource
                Integer startPC = pageContent.IndexOf('/resource/') + 10;

                // Chop off everything before the link that we care about.
                pageContent = pageContent.subString(startPC, pageContent.length());

                // Find where the link ends by assuming it is in a src="/ourURL/" type
                Integer endPC = pageContent.indexOf('/pictures');

                // Chop off everything after the link - we should be left with the link only.
                pageContent = pageContent.subString(0, endPC);
                // Put the URL of the resource into the custom setting for easy access
                ph.PictureURL__c = pageContent;
                update ph;
            }
        }
    }

    public static void createPointsSettings(boolean teacherISAdmin) {
        Points_Settings_v2__c pointsSetting = Points_Settings_v2__c.getOrgDefaults();
        if (pointsSetting.id == null) {
            if (teacherISAdmin) {
                pointsSetting = new Points_Settings_v2__c(Admin_Profile__c = 'System Administrator, SchoolForce Teacher');
            } else {
                pointsSetting = new Points_Settings_v2__c(Admin_Profile__c = 'Ha there are no admins now.');
            }
            insert pointsSetting;
        }
    }

    public static void insertPurgedObjectsCustomSettings() {
        pos = [SELECT Id FROM Purged_Object__c];
        if (pos != null)
            delete pos;
        pos = new List<Purged_Object__c>();
        String[] purgedObjects = core_SoqlUtils.processCSVFile('PurgedObjects');
        System.debug('Purgedobjects$$$' + purgedObjects);
        for (Integer i = 0; i < purgedObjects.size(); i++) {
            String[] inputvalues = purgedObjects[i].split(',');
            Purged_Object__c temp = new Purged_Object__c();
            temp.Name = String.valueOf(i + 1);
            temp.Name__c = inputvalues[0];
            System.debug('insertPurgedObjects$$$' + inputvalues[1]);
            if (inputvalues[1].contains('T') || inputvalues[1].contains('t'))
                temp.Purged_EOY__c = TRUE; else
                    temp.Purged_EOY__c = FALSE;
            pos.add(temp);
            System.debug('TEMP$$$' + temp);
        }
        System.debug('insertPurgedObjects$$$' + pos);
        insert pos;
    }

    public static void processErrorMessageData() {
        StaticResource errorMessages = [Select s.Name, s.Id, s.Body From StaticResource s where s.Name = 'errorMessages'];
        Map<String, ErrorMessages__c> emMap = new Map <String, ErrorMessages__c>();
        for (ErrorMessages__c em : [select id, id__c, name from ErrorMessages__c]) {
            emMap.put(em.id__c, em);
        }
        blob tempA = errorMessages.Body;
        //grab the body
        String messageString = tempA.toString();
        //turn it inot a string
        String[] filelinesMessages = messageString.split('\n');
        //split up the rows
        //clear the wrapper list
        List<ErrorMessages__c> defaultEms = new List<ErrorMessages__c>();
        for (Integer i = 0; i < filelinesMessages.size(); i++)//for each row
        {
            ErrorMessages__c temp = new ErrorMessages__c();
            String[] inputvalues = filelinesMessages[i].split(',');
            //split the rows by commas and populated the fields
            if (emMap.get(inputvalues[1]) == null) {
                temp.Name = inputValues[0];
                temp.Id__c = inputValues[1];
                temp.Message__c = inputValues[2];
                temp.Module__c = inputValues[3];
                defaultEms.add(temp);
            }
        }
        if (!defaultEms.isEmpty()) {
            insert defaultEms;
        }
    }
    /*********************END OF CUSTOM SETTINGS METHODS ************************/


    /*********************START  PICKLIST VALUE DETAIL METHODS******************************/

    /*Added for Chicago*/
    public static List <Picklist_Value__c> createDefaultAttendanceTypes(Setup__c setup) {
        Map<String, ID> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
        String recordType = rtMap.get('Attendance');
        List<Picklist_Value__c> tempPVs = new List<Picklist_Value__c>();
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Present', Category__c = 'Present', Name = 'Present', Display_Code__c = 'P', order__c = 1, Set_as_Default__c = TRUE));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Excused Absence', Category__c = 'Absent', Name = 'Excused Absence', Display_Code__c = 'EA', order__c = 2));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Unexcused Absence', Category__c = 'Absent', Name = 'Unexcused Absence', Display_Code__c = 'UA', order__c = 3, Is_Unexcused__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Excused Tardy', Category__c = 'Partial', Name = 'Excused Tardy', Display_Code__c = 'ET', order__c = 4, Is_tardy__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Unexcused Tardy', Category__c = 'Partial', Name = 'Unexcused Tardy', Display_Code__c = 'UT', order__c = 5, Is_tardy__c = true, Is_Unexcused__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Excused Early Departure', Category__c = 'Partial', Name = 'Excused Early Departure', Display_Code__c = 'ED', order__c = 6, Is_early_departure__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Unexcused Early Departure', Category__c = 'Partial', Name = 'Excused Early Departure', Display_Code__c = 'UD', order__c = 7, Is_early_departure__c = true, Is_Unexcused__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Out of School Suspension', Category__c = 'Out of School Suspension', Name = 'Out of School Suspension', Display_Code__c = 'OS', order__c = 8, Is_suspension__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Out of School Suspension', Category__c = 'In School Suspension', Name = 'In School Suspension', Display_Code__c = 'IS', order__c = 9, Is_suspension__c = true));
        tempPVs.add(new Picklist_Value__c(Setup__c = setup.id, recordTypeID = recordType, Long_Description__c = 'Tardy/Early Departure', Category__c = 'Partial', Name = 'Tardy/Early Departure', Display_Code__c = 'TED', order__c = 10, Is_early_departure__c = true, is_tardy__c = true, Is_Unexcused__c = true));

        insert tempPVs;
        return tempPvs;
    }

    public static List<Picklist_Value__c> createPointsCats(id setupId) {
        ID rtId = core_SoqlUtils.getRecordTypesBySObject('Picklist_Value__c').get('Points_Category');
        List<Picklist_Value__c> pvList = new List<Picklist_Value__c>();
        pvList.add(new Picklist_Value__c(Setup__c = setupID, Grade__c = '1;2;3;4;5;6;7;8;9;10;11;12', RecordTypeID = rtID, Name = 'Turning in Homeowork'));
        pvList.add(new Picklist_Value__c(Setup__c = setupID, Grade__c = '1;2;3;4;5;6;7;8;9;10;11;12', RecordTypeID = rtID, Name = 'Being Kind'));

        insert pvList;
        return pvList;
    }

    public static List<Picklist_Value__c> createDefaultAssignmentTypes() {
        Map<String, Id > rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
        List<Picklist_Value__c> defaultAssignmentTypes = new List<Picklist_Value__c>();
        String[] defaultAssignmentValues = core_SoqlUtils.processCSVFile('assignmentTypeDefaults');
        for (Integer i = 0; i < defaultAssignmentValues.size(); i++) {
            String[] inputvalues = defaultAssignmentValues[i].split(',');
            Picklist_Value__c temp = new Picklist_Value__c(Name = inputValues[0], RecordTypeId = rtMap.get('Assignment_Type'));
            defaultAssignmentTypes.add(temp);
        }
        defaultAssignmentTypes.add(new Picklist_Value__c(Name = 'Weighting', RecordTypeId = rtMap.get('Assignment_Type')));
        insert defaultAssignmentTypes;
        assignmentTypeList = defaultAssignmentTypes;
        system.debug(LoggingLevel.info, 'Default Assignment Types~~~~~~~~~~' + assignmentTypeList);
        return assignmentTypeList;
    }

    public static void createDefaultTimeValues() {
        Map<String, Id > rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
        List<Picklist_Value__c> defaultTimeVals = new List<Picklist_Value__c>();
        String[] defaultTimeValues = core_SoqlUtils.processCSVFile('timeDefaults');
        for (Integer i = 0; i < defaultTimeValues.size(); i++) {
            Picklist_Value__c temp = new Picklist_Value__c();
            String[] inputvalues = defaultTimeValues[i].split(',');
            temp.Name = inputValues[0];
            temp.Type__c = inputValues[1];
            if (inputValues.size() > 2) {
                temp.Category__c = inputValues[2];
                temp.Corresponding_Value__c = decimal.valueOf(inputValues[3].trim());
            }
            temp.RecordTypeId = rtMap.get('Time');
            defaultTimeVals.add(temp);
        }
        system.debug(defaultTimeVals);
        insert defaultTimeVals;

        Map<String, Picklist_Value__c > plVMap = new Map<String, Picklist_Value__c>();
        for (Picklist_Value__c plv : defaultTimeVals) {
            plVMap.put(plv.Name, plv);
        }

        system.debug(plvMap);

        YearPickVal = plVMap.get('Year');
        TermPickVal = plVMap.get('Term');
        SemPickVal = plVMap.get('Semester');
        QPickVal = plVMap.get('Quarter');
        PeriodPickVal = plVMap.get('Period');
    }

    public static List<Picklist_Value__c> createBehaviorPicklistValues() {
        if (behaviorPicklistVals == null) {
            List<Picklist_Value__c> BehaviorPickValuesList = new List<Picklist_Value__c>();
            Map<String, Id > rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
            String ConRecordID = String.valueOf(rtMap.get('Behavior_Consequence'));
            String typeRecordID = String.valueOf(rtMap.get('Behavior_Type'));
            string attRecordID = string.valueOf(rtMap.get('Attendance'));

            BehaviorPickValuesList.add(new Picklist_Value__c(Name = 'Other'
                    //,Type__c = 'Behavior_Consequence'
                    , recordTypeId = ConRecordID
                    , setup__c = activeSetUp.id
                    , set_as_default__c = true
                    , corresponding_value__c = 5
                    , notify_Admin__c = false
                    , order__c = 1));
            BehaviorPickValuesList.add(new Picklist_Value__c(Name = 'Suspension'
                    //,Type__c = 'Behavior_Consequence'
                    , recordTypeId = ConRecordID
                    , setup__c = activeSetUp.id
                    , set_as_default__c = false
                    , Is_Suspension__c = true
                    , corresponding_value__c = 900
                    , notify_Admin__c = false
                    , Category__c = 'In School Suspension'
                    , order__c = 2));
            BehaviorPickValuesList.add(new Picklist_Value__c(Name = 'T1 - Trouble Making'
                    , Type__c = 'Behavior_Type'
                    , recordTypeID = typeRecordID
                    , setup__c = activeSetUp.Id
                    , Behavior_Incident_Level__c = 'Negative'
                    , Behavior_Category__c = 'Disruptive / Disrespectful'));
            BehaviorPickValuesList.add(new Picklist_Value__c(Name = 'T5 - Assult'
                    , Type__c = 'Behavior_Type'
                    , recordTypeID = typeRecordID
                    , setup__c = activeSetUp.Id
                    , Behavior_Incident_Level__c = 'Negative'
                    , Behavior_Category__c = 'Having / Using Potential or Real Weapon'
                    , Incident_Involves_Weapon__c = true));
            BehaviorPickValuesList.add(new Picklist_Value__c(Name = 'Positive Behavior'
                    , Type__c = 'Behavior_Type'
                    , recordTypeID = typeRecordID
                    , setup__c = activeSetUp.Id
                    , Behavior_Incident_Level__c = 'Positive'
                    , Behavior_Category__c = 'Positive #1'));
            BehaviorPickValuesList.add(new Picklist_Value__c(Name = 'In School Suspension'
                    , Type__c = 'Attendance'
                    , recordTypeID = attRecordID
                    , setup__c = activeSetup.ID
                    , Category__c = 'In School Suspension'
                    , is_Suspension__c = true));
            insert behaviorPickValuesList;
            return behaviorPickValuesList;
        } else {
            return behaviorPicklistVals;
        }
    }

    public static List<Picklist_Value__c> createHomeworkPicklistValues() {
        List<Picklist_Value__c> homeworkPlValues = new List<Picklist_Value__c>();
        string recordType = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Homework');
        homeworkPlValues.add(new Picklist_Value__c(Setup__c = activeSetUp.id
                , RecordTypeId = recordType
                , Type__c = 'Homework'
                , Name = 'XXComplete'
                , Category__c = 'Complete'
                , order__c = 92
                , Set_as_Default__c = true));
        homeworkPlValues.add(new Picklist_Value__c(Setup__c = activeSetUp.id
                , RecordTypeId = recordType
                , Type__c = 'Homework'
                , Name = 'XXMissing'
                , Category__c = 'Incomplete'
                , order__c = 93));
        homeworkPlValues.add(new Picklist_Value__c(Setup__c = activeSetUp.id
                , RecordTypeId = recordType
                , Type__c = 'Homework'
                , Name = 'XXLate'
                , Category__c = 'Late'
                , order__c = 94));
        homeworkPlValues.add(new Picklist_Value__c(Setup__c = activeSetUp.id
                , RecordTypeId = recordType
                , Type__c = 'Homework'
                , Name = 'XXAbsent'
                , Category__c = 'Exempt'
                , order__c = 95));

        insert homeworkPlValues;
        return homeworkPlValues;
    }

    /*********************END OF PICKLIST VALUE DETAIL METHODS ************************/

    /*********************START CORE DETAIL METHODS******************************/


    public static List<Course_Catalog__c> getCourseCatalogs(Integer cnt) {
        List<Course_Catalog__c> courseCatalogs = new List<Course_Catalog__c>();

        for (Integer i = 0; i < cnt; i++) {
            Course_Catalog__c cc = new Course_Catalog__c();
            cc.Name = String.valueOf(System.Today().addyears(-i).year());
            cc.Course_Catalog_Description__c = 'Course Catalogue for ' + String.ValueOf(System.Today().addyears(-i).year());
            cc.Course_Catalog_Status__c = true;
            courseCatalogs.add(cc);
        }
        insert courseCatalogs;
        return courseCatalogs;
    }

    /* Input: Number of Courses
    */
    public static List<Course__c> getCourses(Integer cnt) {
        List<Course__c> courses = new List<Course__c>();
        Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Course__c');
        List <Picklist_Value__c> gsValueList = core_SoqlUtils.getPlValuesList('Grade Scale', null);
        Course__c subj = new Course__c (RecordTypeId = rtMap.get('Subject_Area'));
        insert subj;

        for (Integer i = 0; i < cnt; i++) {
            Course__c course =
                    new Course__c(
                            RecordTypeId = rtMap.get('Course'),
                            Subject_Area_Lookup__c = subj.id,
                            Name = 'Course' + ' - ' + i,
                            Course_Number__c = '100' + i,
                            Department__c = i + '-' + 'Course DEPT',
                            Credit_Hours__c = 4,
                            Number_of_Reporting_Periods__c = 2,
                            Grade_Scale_Lookup__c = (isGradebook) ? gsValueList[1].id : null,
                            has_final_grade__c = false
                    );
            courses.add(course);
        }

        insert courses;
        return courses;
    }


    /* Input: 1.Course_Catalogue Id
            2. List Of Courses
        Process:
    */
    public static List<Course_Course_Catalog__c> getCourseCourseCatalogues(List<Course__c> courseIds, Id ccatalogId) {
        List<Course_Course_Catalog__c> cccList = new List<Course_Course_Catalog__c>();
        for (Course__c c : courseIds) {
            Course_Course_Catalog__c cccatalog = new Course_Course_Catalog__c(Course__c = c.Id, Course_Catalog__c = ccatalogId);
            cccList.add(cccatalog);
        }
        insert cccList;
        return cccList;
    }

    public static List<Grade_Scale_Catalog__c> getGradeScaleCatalogs(Integer cnt) {
        List<Grade_Scale_Catalog__c> gradeScaleCatalogs = new List<Grade_Scale_Catalog__c>();

        for (Integer i = 0; i < cnt; i++) {
            Grade_Scale_Catalog__c gsc = new Grade_Scale_Catalog__c(Name = 'Current Scales' + '-' + i, Description__c = 'Current Scales', Active__c = true);
            gradeScaleCatalogs.add(gsc);
        }
        insert gradeScaleCatalogs;
        return gradeScaleCatalogs;
    }

    public static List<Account> getSchools(Integer cnt) {
        List<Account> schools = new List<Account>();

        for (Integer i = 0; i < cnt; i++) {
            Account acc =
                    new Account(
                            Legacy_ID__c = 'school'
                            , RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Account').get('School')
                            , Name = 'SC123' + i
                            , BillingStreet = '2412 New Hampshire Ave. NW' + '-' + i
                            , BillingState = 'Washington D.C' + '-' + i
                            , BillingPostalCode = '2003' + i
                            , BillingCountry = 'USA'
                            , BillingCity = 'D.C' + '-' + i
                            , Attendance_Goal__c = 96
                            , Behavior_Goal__c = 25
                            , Reference_Id__c = 'SC123' + i);
            schools.add(acc);
        }
        upsert schools Reference_Id__c;
        return schools;
    }

    public static List<Time_Element__c> getTimeElements(Integer cnt, String elementType, Id pickValType, Id parentId, String startDate, String endDate, Boolean repPeriod) {
        List<Time_Element__c> timeList = getTimeElements_NoInsert(cnt, elementType, pickValType, parentId, startDate, endDate, repPeriod);
        insert timeList;
        system.debug(LoggingLevel.info, 'New Time Elements~~~ Type: ' + elementType + ' && Details:  ' + timeList);
        return timeList;
    }

    public static List<Time_Element__c> getTimeElements_NoInsert(Integer cnt, String elementType, Id pickValType, Id parentId, String startDate, String endDate, Boolean repPeriod) {
        List<Time_Element__c> timeList = new List<Time_Element__c>();

        for (Integer i = 0; i < cnt; i++) {
            Time_Element__c t = new Time_Element__c();
            t.Type__c = elementType;
            t.Picklist_Value__c = pickValType;
            t.End_Date__c = date.parse(endDate);
            t.Date_Start_Date__c = date.parse(startDate);
            t.Name__c = t.Date_Start_Date__c.format() + '-' + t.End_Date__c.format();
            t.Parent_Time_Element__c = parentId;
            t.Reporting_Period__c = repPeriod;
            t.Days_of_Week__c = 'MTWHF';
            timeList.add(t);
        }
        system.debug(LoggingLevel.info, 'New Time Elements~~~ Type: ' + elementType + ' && Details:  ' + timeList);
        return timeList;
    }

    public static List<Section__c> getSections(List<Course__c> courses) {
        List<Section__c> secList = new List<Section__c>();
//      String numOfPeriods = String.valueOf(semester.Reporting_Period_Value__r.Corresponding_Value__c);
        Id rtId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Published');
        for (Course__c c : courses) {
            Section__c sec = getSection(rtId, c.Name, c.Id, masterYear.id, semester.Id);
            secList.add(sec);
        }
        insert secList;
        return secList;
    }

    public static Section__c getSection(Id rtId, String name, Id courseId, Id timeId, Id rpId) {
        return new Section__c(
                RecordTypeId = rtId,
                Name = 'Section' + name,
                School__c = school.Id,
                Course__c = courseId,
                Time__c = timeId,//masterYear.id,
                Reporting_Period__c = rpId,//semester.Id,
                Subject__c = name,
                Is_Section__c = true,
                Active__c = true,
                Has_Homework__c = true,
                Show_in_portal__c = true,
                Grade_Level__c = '5',
                All_Grades__c = '5',
                Number_of_Reporting_Periods__c = '2'
        );
    }

    public static List<User> getUsers(Integer cnt, String username) {
        List<User> usrList = new List<User>();
        String[] environment = Userinfo.getUserName().split('@');
        Profile p = [select id from profile where name = 'System Administrator'];

        for (integer i = 0; i < cnt; i++) {
            User u = new User(
                    alias = username.substring(0, 3) + i
                    , Email = username + i + '@testorg.com'
                    , LastName = username + i + 'LastName'
                    , FirstName = username + i + 'FirstName'
                    , LanguageLocaleKey = 'en_US'
                    , LocaleSidKey = 'en_US'
                    , ProfileID = p.Id
                    , TimeZoneSidKey = 'America/New_York'
                    , CompanyName = username + ' Company'
                    , UserName = username + i + 'FirstName' + 'x.' + username + i + 'LastName' + '@' + environment[1]
                    , Country = username + i + 'Country'
                    , IsActive = true
                    , EmailEncodingKey = 'UTF-8'
                    , School__c = school.Id);
            usrList.add(u);
        }
        insert usrList;
        return usrList;
    }

    public static List<User> getPortalUsers(Integer cnt, String username, List<Contact> studCons) {
        List<User> usrList = new List<User>();
        String[] environment = Userinfo.getUserName().split('@');
        Profile p = [select id from profile where name = 'SchoolForce Portal User'];
        PortalProfile = p;
        for (integer i = 0; i < cnt; i++) {
            User u = new User();
            u.alias = username.substring(0, 3) + i;
            u.Email = username + i + '@testorg.com';
            u.LastName = username + i + 'LastName';
            u.FirstName = username + i + 'FirstName';
            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.ProfileID = PortalProfile.id;
            u.TimeZoneSidKey = 'America/New_York';
            u.CompanyName = username + ' Company';
            u.UserName = u.FirstName + '.' + u.LastName + '@' + environment[1];
            u.Country = username + i + 'Country';
            u.IsActive = true;
            u.EmailEncodingKey = 'UTF-8';
            u.ContactId = studCons[i].id;
            usrList.add(u);
        }
        insert usrList;
        return usrList;
    }

    public static List<Contact> getContacts(Integer cnt, String contactName, List<User> usrs) {
        List<Contact> contList = new List<Contact>();
        Account acc = getSchools(1)[0];
        for (integer i = 0; i < cnt; i++) {
            Contact con = new Contact(
                    FirstName = contactName
                    , LastName = contactName + 'lastname' + i
                    , AccountId = acc.Id);
            if (usrs != null)
                con.User__c = usrs[i].Id;
            contList.add(con);
        }
        insert contList;
        return contList;
    }

    public static List<Student_PG__c> getPGs() {
        List<Contact> contList = new List<Contact>();
        List<Student_PG__c> pgList = new List<Student_PG__c>();
        Account acc = getSchools(1)[0];
        for (Student__c c : studentsList) {
            Contact con = new Contact();
            con.FirstName = c.Student_First_Name__c + 'Par';
            con.LastName = c.Student_Last_Name__c;
            con.AccountId = acc.Id;
            con.Wireless_Provider__c = 'Verizon';
            con.Email = 'TestEmail@acumensolutions.com';
            con.MobilePhone = '7035551212';
            con.Notify_via_SMS__c = true;
            con.Notify_via_EMAIL__c = true;
            contList.add(con);
        }
        insert contList;

        for (integer i = 0; i < contList.size(); i++) {
            Student_PG__c spg = new Student_PG__c(Parent_Guardian_c__c = contList[i].id, Primary_Contact__c = true, Student_c__c = studentsList[i].Individual__c, Student__c = studentsList[i].id);
            pgList.add(spg);
        }
        insert pgList;
        return pgList;
    }

    public static List<Staff__c> getStaffMembers(Integer cnt, String staffName, List<Contact> conts) {
        List<Staff__c> staffList = new List<Staff__c>();
        for (integer i = 0; i < cnt; i++) {
            Staff__c st = new Staff__c(ID__c = 'teststaff' + i
                    , External_Id__c = 'teststaff' + i);
            st.First_Name_Staff__c = staffName;
            st.Staff_Last_Name__c = staffName + 'lastName' + i;
            st.Reference_Id__c = 'teststaff' + i + '_' + testDataSetupUtil_v2.school.Reference_Id__c;
            st.Individual__c = conts[i].Id;
            st.Active__c = true;
            st.Organization__c = school.id;
            staffList.add(st);
        }

        insert staffList;
        return staffList;
    }


    public static List<Staff_Section__c> getStaffSections(Integer cnt, List<Staff__c> staffMembs, List<Section__c> sects) {
        List<Staff_Section__c> staffSections = new List<Staff_Section__c>();
        for (integer i = 0; i < sects.size(); i++) {
            Staff_Section__c ssec = new Staff_Section__c();
            ssec.Is_Active__c = true;
            ssec.Staff__c = staffMembs[i].Id;
            ssec.Section__c = sects[i].Id;
            staffSections.add(ssec);
        }

        insert staffSections;
        return staffSections;
    }


    public static List<Student__c> getStudents(Integer cnt, String studName, List<Contact> conts) {
        List<Student__c> students = new List<Student__c>();
        for (integer i = 0; i < cnt; i++) {
            Student__c stu = new Student__c();
            stu.Student_First_Name__c = studName;
            stu.Student_Last_Name__c = studName + 'lastName' + i;
            stu.Name = stu.Student_First_Name__c + ' ' + stu.Student_Last_Name__c;
            stu.Student_ID__c = testDataSetupUtil_v2.school.Reference_Id__c + '_Stu' + i;
            stu.State__c = 'NC';
            stu.Grade__c = '5';
            stu.Email__c = 'test' + i + '@123.com';
            stu.Individual__c = conts[i].Id;
            stu.School__c = school.Id;
            stu.Setup__c = activeSetup.id;
            stu.School_Year__c = masterYear.Id;
            stu.Active__c = true;
            stu.Reference_Id__c = testDataSetupUtil_v2.school.Reference_Id__c + '_Stu' + i;
            stu.External_Id__c = 'externID' + i;
            //stu.Local_Student_ID__c = 'testRRRqqq111';
            students.add(stu);
        }

        insert students;
        return students;
    }

    public static List<Student__c> getStudentsWithLocalId(String localId, Integer cnt, String studName, List<Contact> conts) {
        List<Student__c> students = new List<Student__c>();
        for (integer i = 0; i < cnt; i++) {
            Student__c stu = new Student__c();
            stu.Student_First_Name__c = studName;
            stu.Student_Last_Name__c = studName + 'lastName' + i;
            stu.Name = stu.Student_First_Name__c + ' ' + stu.Student_Last_Name__c;
            stu.Student_ID__c = testDataSetupUtil_v2.school.Reference_Id__c + '_Stu' + i;
            stu.State__c = 'NC';
            stu.Grade__c = '5';
            stu.Email__c = 'test' + i + '@123.com';
            stu.Individual__c = conts[i].Id;
            stu.School__c = school.Id;
            stu.Setup__c = activeSetup.id;
            stu.School_Year__c = masterYear.Id;
            stu.Active__c = true;
            stu.Reference_Id__c = testDataSetupUtil_v2.school.Reference_Id__c + '_Stu' + i;
            stu.External_Id__c = 'externID' + i;
            stu.Local_Student_ID__c = localId;
            students.add(stu);
        }
        insert students;
        return students;
    }

    public static List<Student_Section__c> getStudentSections(Integer cnt, List<Student__c> studs, List<Section__c> sects) {
        List<Student_Section__c> studSections = new List<Student_Section__c>();
        for (integer i = 0; i < sects.size(); i++) {
            if (i == 0 && sects.size() > 1) {
                Student_Section__c stuSec = new Student_Section__c();
                stuSec.Student__c = studs[0].Id;
                stuSec.Section__c = sects[0].Id;
                stuSec.Reference_ID__c = studs[0].Student_ID__c + '_' + sects[i].Name + '_' + school.Name + '_' + '2011-2012';
                stuSec.Active__c = true;
                studSections.add(stuSec);
                Student_Section__c stuSec1 = new Student_Section__c();
                stuSec1.Student__c = studs[1].Id;
                stuSec1.Section__c = sects[0].Id;
                stuSec1.Reference_ID__c = studs[1].Student_ID__c + '_' + sects[i].Name + '_' + school.Name + '_' + '2011-2012';
                stuSec1.Active__c = true;
                studSections.add(stuSec1);
            } else {
                Student_Section__c stuSec = new Student_Section__c();
                stuSec.Student__c = studs[i].Id;
                stuSec.Section__c = sects[i].Id;
                stuSec.Reference_ID__c = studs[i].Student_ID__c + '_' + sects[i].Name + '_' + school.Name + '_' + '2011-2012';
                stuSec.Active__c = true;
                studSections.add(stuSec);
            }
        }

        insert studSections;
        return studSections;
    }

    public static void setupSessiondata() {
        sessionsList = getSessions(1, semester, sectionsList[0].Id, 1);
        system.debug(LoggingLevel.info, 'Sessions List ~~~~~~~~~~~~~~' + sessionsList);
    }

    public static List<Session__c> getSessions(Integer cnt, Time_Element__c prd, Id secId, integer iPeriod) {
        List<Session__c> sessions = new List<Session__c>();
        DateTime dt = prd.Date_Start_Date__c;
        //EE 8/26
        //added 12 hours to start date due to Session_Date__c formula calculating incorrectly for user time zone
        //was 8/1/2043 00:00:00, now 8/1/2043 12:00:00
        //this ensures that the session date will calculate to 8/1/2043 (was calculating to 7/31/2043)
        dt = dt.addHours(12);
        if (iPeriod != null) dt.addHours(iPeriod);
        for (integer i = 0; i < cnt; i++) {
            Session__c sessn =
                    new Session__c(
                            Time__c = prd.Id,
                            Record_Attendance__c = true,
                            Start_DateTime__c = dt,
                            Section__c = secId,
                            Name = 'Session- ' + i,
                            End_DateTime__c = (iPeriod == null) ? dt.addHours(8) : dt.addHours(1)
                    );
            system.debug('Session~~~~~~' + sessn);
            sessions.add(sessn);
        }

        insert sessions;
        return sessions;
    }

    public static List<String> getCurriculumNames(Integer k, String objectAPIName, String fieldName) {
        List<String> curriculumNameList2 = new List<String>();
        for (integer i = 0; i < k; i++) {
            curriculumNameList2.add(CT_core_SoqlUtils.getPicklistValuesBySobject(objectAPIName, fieldName)[0]);
        }
        return curriculumNameList2;
    }

    public static List<String> getCurriculumModulNames(Integer k, String objectAPIName, String fieldName) {
        List<String> curriculumModulNameList2 = new List<String>();
        for (integer i = 0; i < k; i++) {
            curriculumModulNameList2.add(CT_core_SoqlUtils.getPicklistValuesBySobject(objectAPIName, fieldName)[0]);
        }
        return curriculumModulNameList2;
    }

    public static List<String> getCurriculumModuleAssignments(Integer k, String objectAPIName, String fieldName) {
        List<String> curriculumModuleAssignmentList2 = new List<String>();
        for (integer i = 0; i < k; i++) {
            curriculumModuleAssignmentList2.add(CT_core_SoqlUtils.getPicklistValuesBySobject(objectAPIName, fieldName)[0]);
        }
        return curriculumModuleAssignmentList2;
    }

    public static List<Curriculum__c> getCurriculums(Integer k) {
        List<Curriculum__c> curriculumList = new List<Curriculum__c>();
        for (integer i = 0; i < k; i++) {
            Curriculum__c newCurr = createCurriculum(i);
            curriculumList.add(newCurr);
        }
        insert curriculumList;
        return curriculumList;
    }
    public static Curriculum__c createCurriculum(Integer i) {
        Curriculum__c newCurr = new Curriculum__c(Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c, Section__c = testDataSetupUtil_v2.studSectionsList[0].Section__c,
                Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].Id, Date_of_Module__c = Date.today(), Curriculum_Name__c = curriculumNameList[i],
                Module_Name__c = curriculumModulNameList[i], Module_Assignments__c = curriculumModuleAssignmentList[i],
                Module_Score__c = 21.1, Comments__c = 'comm');

        return newCurr;
    }

    public static List <Room__c> getRooms(Integer cnt) {
        List <Room__c> rooms = new List <Room__c>();
        for (integer i = 0; i < cnt; i++) {
            Room__c r =
                    new Room__c(
                            Name = string.valueOf(i),
                            school__c = school.ID,
                            Number__c = i,
                            Size__c = 30,
                            Schedulable__c = true,
                            reference_Id__c = school.Reference_Id__c + '-' + string.valueOf(i)
                    );
            rooms.add(r);
        }
        insert rooms;
        return rooms;
    }

    /*********************END OF CORE DETAIL METHODS ************************/


    /********************* START ATTENDANCE DETAIL METHODS******************************/
    public static void createSessions(Integer cnt, Time_Element__c rptPd, Id secId) {
        sessionsList = new List<Session__c>();
        DateTime startDate = rptPd.Date_Start_Date__c;
        for (integer i = 0; i < cnt; i++) {
            Session__c sessn = new Session__c();
            sessn.Time__c = rptPd.Id;
            sessn.Start_DateTime__c = datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 8, 30, 0);
            sessn.Section__c = secId;
            sessn.Name = 'Session- ' + i;
            sessn.Record_Attendance__c = true;
            sessn.End_DateTime__c = datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 15, 30, 0);
            sessionsList.add(sessn);
            startDate = startDate.addDays(1);
        }

        insert sessionsList;
    }

    public static void createScalesNormalizations() {
        core_LoadCsvData loadCsv = new core_LoadCsvData();
        loadCsv.selectedLoadType = 'Grade Scales';
        loadCsv.changeLink();
        loadCsv.bUseDefault = true;
        loadCsv.loadData();
        loadCsv.insertList();

        Map<String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
        String[] filelinesNorms = core_SoqlUtils.processCSVFile('gradeNormDefaults');

        List<Grade_Normalization__c> defaultsNorms = new List<Grade_Normalization__c>();

        scaleMap = new Map<String, ID>();
        for (Picklist_value__c pv : [Select ID, Name from Picklist_Value__c where RecordTypeId = :rtMap.get('Grade_Scale')]) {
            scaleMap.put(pv.Name, pv.ID);
        }

        for (Integer i = 0; i < filelinesNorms.size(); i++) {
            Grade_Normalization__c temp = new Grade_Normalization__c();
            String[] inputvalues = filelinesNorms[i].split(',');

            //split the rows by commas and populated the fields
            temp.Name = inputValues[0];
            if (inputValues[1] != null && inputValues[1] != '') {
                temp.GP_Value__c = double.valueOf(inputValues[1]);
            }
            temp.Grade_value__c = double.valueOf(inputValues[2]);
            temp.Picklist_Value__c = scaleMap.get(inputValues[3]);

            if (inputValues[4] != null && inputValues[4] != '') {
                temp.Transformed_Grade__c = inputValues[4];
            }

            defaultsNorms.add(temp);
        }
        insert defaultsNorms;
    }

    public static void setUpStandards() {
        testStandards = new List<Standard__c>();
        List<Section_Standard__c> testSecStand = new List<Section_Standard__c>();
        Standard__c gradeStandard = new Standard__c(Name = 'Grade', Level__c = 0);
        insert gradeStandard;
        Standard__c subjectStandard = new Standard__c(Name = 'Subject', Level__c = 0, Grade_Level__c = gradeStandard.id);
        insert subjectStandard;
        strandStandard = new Standard__c(Name = 'Strand', Level__c = 0, Grade_Level__c = gradeStandard.id, Standard_Subject__c = subjectStandard.id);
        insert strandStandard;

        for (integer i = 0; i <= 3; i++) {
            Standard__c testStandard = new Standard__c(Standard_Subject__c = subjectStandard.id, Strand__c = strandStandard.id);
            testStandard.name = 'Test Standard ' + i;
            testStandard.Level__c = 3;
            testStandard.Course__c = testDataSetupUtil_v2.coursesList[0].id;
            testStandard.Identifier__c = string.valueof(i);
            testStandards.add(testStandard);
        }

        insert testStandards;

        for (Standard__c s : testStandards) {
            if (s.Course__c == testDataSetupUtil_v2.coursesList[1].id) {
                testSecStand.add(new Section_Standard__c(Section__c = testDataSetupUtil_v2.sectionsList[1].id, Standard__c = s.id, Reference_Id__c = testDataSetupUtil_v2.sectionsList[1].Name + '_' + s.id));
            } else {
                testSecStand.add(new Section_Standard__c(Section__c = testDataSetupUtil_v2.sectionsList[0].id, Standard__c = s.id, Reference_Id__c = testDataSetupUtil_v2.sectionsList[0].Name + '_' + s.id));
            }
        }
        insert testSecStand;
    }
    /* Input: Number of Course_Catalog__c
    */
    /**********************END OF DETAILED GRADEBOOK METHODS*****************/


    /**********************START OF DETAILED SCHEDULER METHODS*****************/
    public static List<Section__c> getScheduleGroups_Section() {
        testDataSetupUtil_v2.activeSetup.group_based__c = true;
        update testDataSetupUtil_v2.activeSetup; //need it to be a group based school
        List<Section__c> schedGrpsList = new List<Section__c>();
        Id groupRecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group');  //US1254; gets the Record Type ID for Schedule Group off Section object
        schedGrpsList.add(new Section__c(Name = '5A', All_Grades__c = '5', Description__c = 'test1', school__c = testDataSetupUtil_v2.school.id, time__c = testDataSetupUtil_v2.masterYear.id, RecordTypeId = groupRecordTypeId, Active__c = true));
        schedGrpsList.add(new Section__c(Name = '5B', All_Grades__c = '5', Description__c = 'test1', school__c = testDataSetupUtil_v2.school.id, time__c = testDataSetupUtil_v2.masteryear.id, RecordTypeId = groupRecordTypeId, Active__c = true));
        insert schedGrpsList;
        integer i = 0;

        for (Section__c sect : sectionsList) {
            if (i < 3) sect.schedule_group__c = schedGrpsList[0].id; else sect.schedule_group__c = schedGrpsList[1].id;
            i++;
            System.debug('~~~sect' + sect);
        }
        update sectionsList;

        return schedGrpsList;
    }

    public static List<Scheduled_Section__c> createScheduledSections(List<Section__c> groups) {
        List<Scheduled_Section__c> sections = new List<Scheduled_Section__c>();
        for (integer i = 0; i < 5; i++) {
            if (i >= 0 && i < 3) {
                Scheduled_Section__c ss =
                        new Scheduled_Section__c(
                                Name = 'test' + i,
                                Reference_Id__c = i + '',
                                Section_Reference_Id__c = 'testing' + i,
                                Schedule_Group_Section__c = groups[0].id,
                                Account__c = school.id
                        );
                sectionsList[i].Scheduler_Reference_Id__c = ss.Section_Reference_Id__c;
                sections.add(ss);
            } else {
                Scheduled_Section__c ss =
                        new Scheduled_Section__c(
                                Name = 'test' + i,
                                Reference_Id__c = i + '',
                                Section_Reference_Id__c = 'testing' + i,
                                Schedule_Group_Section__c = groups[1].id,
                                Account__c = school.id
                        );
                sectionsList[i].Scheduler_Reference_Id__c = ss.Section_Reference_Id__c;
                sections.add(ss);
            }
        }
        insert sections;
        update testDataSetupUtil_v2.sectionsList;
        return sections;
    }

    public static List<Section__c> getGroupsFromSelectOptions_Sections(List<SelectOption> so) {
        Set<ID> groupIDs = new Set<ID>();
        for (SelectOption s : so) groupIDs.add(s.getValue());
        List<Section__c> groups = [SELECT id,Name,All_Grades__c FROM Section__c WHERE id IN :groupIDs];
        return groups;
    }

    /**********************END OF DETAILED SCHEDULER METHODS*****************/


    /**********************START OF PROGRAM METHODS*****************/
    public static void setUPProgramData(List<Section__c> sectionsList, Account school) {
        Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
        insert ia;
        programsList = TestDataUtil.createPrograms(sectionsList.size(), true, ia);
        insert programsList;
        accountProgramsList = new List<Account_Program__c>();
        for (Program__c prog : programsList) {
            accountProgramsList.add(TestDataUtil.createAccountProgram(school, prog));
        }
        insert accountProgramsList;

        Integer i = 0;
        for (Section__c section : sectionsList) {
            section.Program__c = programsList[i].Id;
            section.Account_Program__c = accountProgramsList[i].Id;
            i++;
        }
        update sectionsList;
    }

    public static void setUPProgramData(List<String> progNameList, Account school) {
        Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
        insert ia;
        programsList = new List<Program__c>();
        for (String progName : progNameList) {
            programsList.add(testDataSetupUtil_v2.createProgram(progName, true, ia));
        }
        insert programsList;
        accountProgramsList = new List<Account_Program__c>();
        for (Program__c prog : programsList) {
            accountProgramsList.add(TestDataUtil.createAccountProgram(school, prog));
        }
        insert accountProgramsList;
    }

    public static Program__c createProgram(String progName, boolean isRequired, Indicator_Area__c ia) {
        return new Program__c(
                Name = progName,
                Required_Program__c = isRequired,
                Status__c = 'Approved',
                Indicator_Area__c = ia.Id,
                Active__c = true
        );
    }
    /**********************END OF PROGRAM METHODS*****************/

    /**********************START OF SESSION RESULTS METHODS*****************/
    public static void setUPExistingSessionResults(Integer amount) {
        interventionSessionsList = new List<Intervention_Session__c>();
        for (Section__c section : sectionsList) {
            interventionSessionsList.add(new Intervention_Session__c(
                    Section__c = section.ID,
                    Session_Time_Completed_For__c = teachersList[0].Id,
                    Date__c = Date.today(),
                    All_avenues__c = 'In-Person Service'
            ));
        }
        insert interventionSessionsList;
        Map<Id, Intervention_Session__c> mapId2Sesion = new Map<Id, Intervention_Session__c>();
        for (Intervention_Session__c s : interventionSessionsList) {
            mapId2Sesion.put(s.Section__c, s);
        }

        interventionSessionResultsList = new List<Intervention_Session_Result__c>();
        for (Student_Section__c s : studSectionsList) {
            interventionSessionResultsList.add(new Intervention_Session_Result__c(
                    Intervention_Session__c = mapId2Sesion.get(s.Section__c).Id,
                    Amount_of_Time__c = amount,
                    Student_Section__c = s.Id
            ));
        }
        insert interventionSessionResultsList;
    }
    /**********************START OF SESSION RESULTS METHODS*****************/

    /**********************START MISC METHODS**********************/
    public static void fixSectionAttendance() {
        List<Session__c> fixer = [Select Section__c, ID from Session__c where Record_Attendance__c = true];
        set<ID> sectionSet = new set<ID>();
        for (Session__c s : fixer) {
            sectionSet.add(s.Section__c);
        }
        list<Section__c> toFix = new List<Section__c>();
        for (Section__c s : [Select ID from Section__c where ID IN :sectionSet]) {
            s.Record_Attendance__c = true;
            toFix.add(s);
        }
        update toFix;
    }

    /**********************END MISC METHODS**********************/

    static testMethod void test_testDataSetupUtil() {
        testDataSetupUtil_v2.isAttendance = true;
        testDataSetupUtil_v2.isBehavior = true;
        testDataSetupUtil_v2.isGradebook = true;
        testDataSetupUtil_v2.setUPCoreData(5);
        system.assertNotEquals(testDataSetupUtil_v2.activeSetup.id, null);
        testDataSetupUtil_v2.setUPStaffData(5);
        system.assertEquals(testDataSetupUtil_v2.teachersList.size(), 5);
        testDataSetupUtil_v2.setUPStudentData(5);
        system.assertEquals(testDataSetupUtil_v2.studentsList.size(), 5);
		testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
		testDataSetupUtil_v2.setUPExistingSessionResults(10);
		testDataSetupUtil_v2.setUpCurriculumData(5);

        testDataSetupUtil_v2.getDefaultGradeOverrideSettings();
        testDataSetupUtil_v2.createHomeworkPicklistValues();

        StaticResource pictureResource = [Select body, name, ID from StaticResource where Name = 'pictures' limit 1];
        system.assert(pictureREsource != null);
    }
}
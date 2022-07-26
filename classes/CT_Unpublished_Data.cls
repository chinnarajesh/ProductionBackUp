public with sharing class CT_Unpublished_Data {

    private final String SETUP_SOQL_QUERY = 'SELECT Id, School__c, School__r.Id, School__r.Site__c, School__r.Reference_Id__c, Term__c, School__r.Name, Year__c, Year__r.Id, Year__r.Name__c, ' +
            'Verification_status__c, New_School_Year__c, Active__c, Group_Based__c, Published__c FROM Setup__c WHERE School__r.Id != \'\' AND Year__r.Id != \'\' ';

    private boolean bStatusChanged;
    private boolean bLocationChanged;
    private boolean bYearChanged;

    private String oldStatus;
    private String oldYear;
    private String oldLocation;

    private Set<String> locationsName;
    private Map<Id, String> schoolMap;
    private Map<Id, String> yearsMap;
    private Set<String> verificationStatusSet;

    private CT_BatchWrapper batch;                                   // holds data related to the running batch
    private CT_core_SetupWrapper    cSetup;                          // setup wrapper for the setup with id setupId
    private Id batchReportingPeriodId;                               //for startPropagator
    private Set<Id> termIds;
    private List<Setup__c> setupForPublish;
    private List<Time_Element__c> reportingPeriodsForPublish;

    public List<SelectOption> locations                             { get; set; }
    public String selectedLocation                                  { get; set; }

    public List<SelectOption> statuses                              { get; set; }
    public String selectedStatus                                    { get; set; }

    public List<SelectOption> schools                               { get; set; }
    public String selectedSchool                                    { get; set; }

    public List<SelectOption> years                                 { get; set; }
    public String selectedYear                                      { get; set; }

    public TreeBuilder treeBuilder                                  { get; set; }
    public String termIdString                                      { get; set; }
    public String reportingPeriodIdString                           { get; set; }
    public String periodIdString                                    { get; set; }
    public Boolean bOccupancyError                                  { get; set; } //disable Publish button


        /* ========================================================= */
        /*     Maps for Builder begin
        /* ========================================================= */
    public Set<String> schoolLocations                                 { get; set; }
    public Map<String, List<AccountSelector>> accountWithSetupMap      { get; set; }
    public Map<Id, List<Term__c>> termsMap                             { get; set; }
    public Map<Id, List<Time_Element__c>> reportingPeriodsMap          { get; set; }
    public Map<Id, List<Period__c>> periodsMap                         { get; set; }
        /* ========================================================= */
        /*     Maps for Builder end
        /* ========================================================= */
    public List<Id> setupIds { get; set; }
    public List<Id> scheduleTemplateIds { get; set; }
    public List<Setup__c> setupWithSchoolAndTime { get; set; }
    public String selectedLocationString { get; set; }
    public String selectedSetupId { get; set; }
    public String selectedTermId { get; set; }
    public String selectedScheduleTemplateId { get; set; }
    public String schoolForPublishId { get; set; }



    public CT_Unpublished_Data() {
        bOccupancyError = true;
        bStatusChanged = true;
        bLocationChanged = true;
        bYearChanged = true;
        schools = new List<SelectOption>();
        years = new List<SelectOption>();
        locations = new List<SelectOption>();
        statuses = new List<SelectOption>();
        yearsMap = new Map<Id, String>();
        schoolMap = new Map<Id, String>();
        locationsName = new Set<String>();
        verificationStatusSet = new Set<String>();


        schoolLocations = new Set<String>();
        accountWithSetupMap = new Map<String, List<AccountSelector>>();
        termsMap = new Map<Id, List<Term__c>>();
        reportingPeriodsMap = new Map<Id, List<Time_Element__c>>();
        periodsMap = new Map<Id, List<Period__c>>();
        setupIds = new List<Id>();
        scheduleTemplateIds = new List<Id>();
        termIds = new Set<Id>();
        termIdString = '';
        reportingPeriodIdString = '';
        periodIdString = '';

        fillCollectionsWithQueryData();

    }

    public void addStartValues() {
        years.add(new SelectOption('Choose Year', 'Choose Year'));
        locations.add(new SelectOption('Choose Location', 'Choose Location'));
//        selectedStatus = 'Verified';
        initSearchBoxes();
        oldStatus = this.selectedStatus;
        oldYear = this.selectedYear;
        oldLocation = this.selectedLocation;

    }



    public void fillCollectionsWithQueryData() {
        List<Setup__c> setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY);
//        querySObjectsForTree(setupWithSchoolAndTime);
        queryLocationsForTree(setupWithSchoolAndTime);
        for (Setup__c setupItem : setupWithSchoolAndTime) {
            verificationStatusSet.add(setupItem.Verification_status__c);
            yearsMap.put(setupItem.Year__r.Id, setupItem.Year__r.Name__c);
            schoolMap.put(setupItem.School__r.Id, setupItem.School__r.Name);
            locationsName.add(setupItem.School__r.Site__c);
        }
        initSearchBoxes();
        selectedStatus = 'Verified';
        selectedStatusPicklist();
        addStartValues();
    }

    public void queryLocationsForTree(List<Setup__c> setupList) {
        setupIds.clear();
//        schoolLocations.clear();
        accountWithSetupMap = new Map<String, List<AccountSelector>>();
        for(Setup__c setupItem : setupList) {

            setupIds.add(setupItem.Id);
//            schoolLocations.add(setupItem.School__r.Site__c);

            if (setupItem.School__r.Site__c != null) {
                accountWithSetupMap.put(setupItem.School__r.Site__c, new List<AccountSelector>());
            }
        }
//        treeBuilder = new TreeBuilder(schoolLocations);
        treeBuilder = new TreeBuilder(accountWithSetupMap.keySet(), accountWithSetupMap, termsMap, reportingPeriodsMap, periodsMap);
        System.debug('\n\n treeBuilder => ' + treeBuilder + '\n');
    }

    private void clearTreeMaps(){
        accountWithSetupMap = new Map<String, List<CT_Unpublished_Data.AccountSelector>>();
        termsMap = new Map<Id, List<Term__c>>();
        reportingPeriodsMap = new Map<Id, List<Time_Element__c>>();
        periodsMap = new Map<Id, List<Period__c>>();
    }


    public void querySchoolsForTree() {

        System.debug('\n\n selectedLocationString => ' + selectedLocationString + '\n');

        List<AccountSelector> accountsWithTheSameLocation = new List<AccountSelector>();

        System.debug('\n\n accountWithSetupMap.keySet() => ' + accountWithSetupMap.keySet() + '\n');
        System.debug('\n\n setupWithSchoolAndTime => ' + setupWithSchoolAndTime + '\n');

        for(Setup__c setupItem : this.setupWithSchoolAndTime) {
            if (setupItem.School__r.Site__c != null) {
                if(selectedLocationString.containsIgnoreCase(setupItem.School__r.Site__c)) {
                    accountsWithTheSameLocation.add(new AccountSelector(setupItem, false));
                }
            }
        }
        accountWithSetupMap.put(selectedLocationString, accountsWithTheSameLocation);

        System.debug('\n\n accountWithSetupMap.keySet() => ' + accountWithSetupMap.keySet() + '\n');
        System.debug('\n\n accountWithSetupMap => ' + accountWithSetupMap + '\n');

        treeBuilder = new TreeBuilder(accountWithSetupMap.keySet(), accountWithSetupMap, termsMap, reportingPeriodsMap, periodsMap);
        System.debug('\n\n treeBuilder => ' + treeBuilder + '\n');

    }
    public void deleteSchoolsFromTree(){
//        for (String locations : treeBuilder.accountWithSetupMap.keySet()) {
//            for (AccountSelector accountSelector : treeBuilder.accountWithSetupMap.get(locations)) {
//
//            }
//        }
        accountWithSetupMap.put(selectedLocationString, new List<AccountSelector>());
        System.debug('\n\n accountWithSetupMap => ' + accountWithSetupMap + '\n');
        System.debug('\n\n selectedLocationString => ' + selectedLocationString + '\n');
    }



    public void queryTermsForTree() {
        List<Term__c> terms = [SELECT Id, Time_Element__r.Id, Time_Element__r.Name__c, Setup__r.Id FROM Term__c WHERE Setup__c =: selectedSetupId];
        System.debug('\n\n selectedSetupId => ' + selectedSetupId + '\n');
        System.debug('\n\n terms => ' + terms + '\n');
//        for(Id setupId : setupIds) {
            List<Term__c> termsList = new List<Term__c>();
            for(Term__c term : terms) {
                if (term.Setup__r.Id == selectedSetupId) {
                    termsList.add(term);
                }
                termIds.add(term.Time_Element__r.Id);
            }
            if(!termsList.isEmpty()) {
                termsMap.put(selectedSetupId, termsList);
            }
//        }

        for(Term__c term : terms) {
            termIdString += term.Setup__r.Id + ',' ;
        }
        System.debug('\n\n termsMap => ' + termsMap + '\n');
        treeBuilder = new TreeBuilder(accountWithSetupMap.keySet(), accountWithSetupMap, termsMap, reportingPeriodsMap, periodsMap);
        System.debug('\n\n treeBuilder => ' + treeBuilder + '\n');

    }
    public void deleteTermsFromTree() {
        if(termsMap.keySet().contains(selectedSetupId)) {
            for(Term__c termObj : termsMap.get(selectedSetupId)) {
                if(termIds.contains(termObj.Time_Element__r.Id)) {
                    termIds.remove(termObj.Time_Element__r.Id);
                }
            }
            termsMap.put(selectedSetupId, new List<Term__c>());
        }
    }




    public void queryReportingPeriodsForTree() {
        //to-do get timeelement from termId
        List<Id> timeELementTermIds = new List<Id>();
        for(Id setupId : termsMap.keySet()) {
            if(termsMap.keySet().contains(setupId)) {
                for (Term__c termObj : termsMap.get(setupId)) {
                    if (termObj.Id == selectedTermId) {
                        timeELementTermIds.add(termObj.Time_Element__c);
                    }
                }
            }
        }
        List<Time_Element__c> reportingPeriodsWithChildren = [SELECT Id, Name__c, parent_time_element__c, parent_time_element__r.Name__c,
                                                                    (SELECT Section__r.Name, Staff__r.Name
                                                                    FROM Scheduled_Sections__r),
                                                                    (SELECT Id, Name
                                                                    FROM Schedule_Templates__r)
                                                                FROM Time_Element__c
                                                                WHERE parent_time_element__c IN : timeELementTermIds];

        for(Id termId : timeELementTermIds) {
            List<Time_Element__c> reportingPeriodForOneTerm = new List<Time_Element__c>();
            for(Time_Element__c reportingPeriod : reportingPeriodsWithChildren) {
                if(termId == reportingPeriod.parent_time_element__c) {
                    reportingPeriodForOneTerm.add(reportingPeriod);
                }
            }
            if (!reportingPeriodForOneTerm.isEmpty()) {
                reportingPeriodsMap.put(termId, reportingPeriodForOneTerm);
            }
        }
        for(Time_Element__c reportingPeriod : reportingPeriodsWithChildren) {
            reportingPeriodIdString += reportingPeriod.parent_time_element__c + ',' ;
        }

        if(reportingPeriodsMap.keySet().contains(timeELementTermIds[0])) {
            for(Time_Element__c repPeriod : reportingPeriodsMap.get(timeELementTermIds[0])) {
                for(Schedule_Template__c  schedTemplate : repPeriod.Schedule_Templates__r) {
                    scheduleTemplateIds.add(schedTemplate.Id);
                }
            }
        }


        List<Period__c> periods = [SELECT Id, Order__c, Key__c, Start_Time_Text__c, End_Time_Text__c, Schedule_Template__c
                                   FROM Period__c
                                   WHERE Schedule_Template__r.Id IN : scheduleTemplateIds];
        for(Id scheduleTemplateId : scheduleTemplateIds) {
            List<Period__c> tempPeriodList = new List<Period__c>();
            for(Period__c period : periods) {
                if(scheduleTemplateId == period.Schedule_Template__c) {
                    tempPeriodList.add(period);
                }
            }
            if(!tempPeriodList.isEmpty()) {
                periodsMap.put(scheduleTemplateId, tempPeriodList);
            }
        }
        for(Period__c period : periods) {
            periodIdString += period.Schedule_Template__c + ',';
        }

        treeBuilder = new TreeBuilder(accountWithSetupMap.keySet(), accountWithSetupMap, termsMap, reportingPeriodsMap, periodsMap);
        System.debug('\n\n treeBuilder => ' + treeBuilder + '\n');
    }
    public void deleteReportingPeriodFromTree() {
        List<Id> timeELementTermIds = new List<Id>();
        for(String setupId : termsMap.keySet()) {
            for (Term__c termObj : termsMap.get(setupId)) {
                if(termObj.Id == selectedTermId) {
                    timeELementTermIds.add(termObj.Time_Element__c);
                }
            }
        }
        for(Id termId : timeELementTermIds) {
            reportingPeriodsMap.put(termId, new List<Time_Element__c>());
        }
    }


    public void querySObjectsForTree(List<Setup__c> setupList) {
        /* ========================================================= */
        /*     Maps for Builder begin
        /* ========================================================= */
        Set<String> locations = new Set<String>();
        Map<String, List<AccountSelector>> accountWithSetupMap = new Map<String, List<AccountSelector>>();
        Map<Id, List<Term__c>> termsMap = new Map<Id, List<Term__c>>();
        Map<Id, List<Time_Element__c>> reportingPeriodsMap = new Map<Id, List<Time_Element__c>>();
        Map<Id, List<Period__c>> periodsMap = new Map<Id, List<Period__c>>();
        /* ========================================================= */
        /*     Maps for Builder end
        /* ========================================================= */

        List<Id> accountIds = new List<Id>();
        List<Id> setupIds = new List<Id>();
        List<Id> scheduleTemplateIds = new List<Id>();
        termIds = new Set<Id>();
        termIdString = '';
        reportingPeriodIdString = '';
        periodIdString = '';

        for(Setup__c setupItem : setupList) {

            setupIds.add(setupItem.Id);
            locations.add(setupItem.School__r.Site__c);
        }
        for(String loc : locations) {
            List<AccountSelector> accountsWithTheSameLocation = new List<AccountSelector>();
            for(Setup__c setupItem : setupList) {
                if(loc == setupItem.School__r.Site__c) {
                    accountsWithTheSameLocation.add(new AccountSelector(setupItem, false));
                }
            }
            accountWithSetupMap.put(loc, accountsWithTheSameLocation);
        }

        List<Term__c> terms = [SELECT Id, Time_Element__r.Id, Time_Element__r.Name__c, Setup__r.Id FROM Term__c WHERE Setup__c =: setupIds];
        for(Id setupId : setupIds) {
            List<Term__c> termsList = new List<Term__c>();
            for(Term__c term : terms) {
                if (term.Setup__r.Id == setupId) {
                    termsList.add(term);
                }
                termIds.add(term.Time_Element__r.Id);
            }
            if(!termsList.isEmpty()) {
                termsMap.put(setupId, termsList);
            }
        }
        for(Term__c term : terms) {
            termIdString += term.Setup__r.Id + ',' ;
        }

        List<Time_Element__c> reportingPeriodsWithChildren = [SELECT Id, Name__c, parent_time_element__c, parent_time_element__r.Name__c,
                                                                (SELECT Section__r.Name, Staff__r.Name
                                                                 FROM Scheduled_Sections__r),
                                                                (SELECT Id, Name
                                                                 FROM Schedule_Templates__r)
                                                             FROM Time_Element__c
                                                             WHERE parent_time_element__c IN : termIds];

        for(Id termId : termIds) {
            List<Time_Element__c> reportingPeriodForOneTerm = new List<Time_Element__c>();
            for(Time_Element__c reportingPeriod : reportingPeriodsWithChildren) {
                if(termId == reportingPeriod.parent_time_element__c) {
                    reportingPeriodForOneTerm.add(reportingPeriod);
                }
            }
            if (!reportingPeriodForOneTerm.isEmpty()) {
                reportingPeriodsMap.put(termId, reportingPeriodForOneTerm);
            }
        }
        for(Time_Element__c reportingPeriod : reportingPeriodsWithChildren) {
            reportingPeriodIdString += reportingPeriod.parent_time_element__c + ',' ;
        }

        for(Id reportingPeriodId : reportingPeriodsMap.keySet()) {
            for(Time_Element__c repPeriod : reportingPeriodsMap.get(reportingPeriodId)) {
                for(Schedule_Template__c  schedTemplate : repPeriod.Schedule_Templates__r) {
                    scheduleTemplateIds.add(schedTemplate.Id);
                }
            }
        }

        List<Period__c> periods = [SELECT Id, Order__c, Key__c, Start_Time_Text__c, End_Time_Text__c, Schedule_Template__c
                                   FROM Period__c
                                   WHERE Schedule_Template__r.Id IN : scheduleTemplateIds];
        for(Id scheduleTemplateId : scheduleTemplateIds) {
            List<Period__c> tempPeriodList = new List<Period__c>();
            for(Period__c period : periods) {
                if(scheduleTemplateId == period.Schedule_Template__c) {
                    tempPeriodList.add(period);
                }
            }
            if(!tempPeriodList.isEmpty()) {
                periodsMap.put(scheduleTemplateId, tempPeriodList);
            }
        }
        for(Period__c period : periods) {
            periodIdString += period.Schedule_Template__c + ',';
        }

        treeBuilder = new TreeBuilder(locations, accountWithSetupMap, termsMap, reportingPeriodsMap, periodsMap);
    }

    private void initSearchBoxes() {
        if (bStatusChanged) {
            initStatusBox();
        }
        if (bYearChanged) {
            initYearBox();
        }
        if (bLocationChanged) {
            initLocationBox();
        }
        initSchoolBox();
    }

    private void initStatusBox() {

        if (verificationStatusSet.size() != 0) {
            for (String status: verificationStatusSet) {
                if (status != null) {
                    statuses.add(new SelectOption(status, status));
                } else {
                    Boolean isNewStatusExists = false;
                    for (String st : verificationStatusSet) {
                        if (st == 'New') {
                            isNewStatusExists = true;
                            break;
                        }
                    }
                    if (isNewStatusExists == false) {
                        statuses.add(new SelectOption('new', 'New'));
                    }
                }
            }
            System.debug('\n\n statuses.size() => ' + statuses.size() + '\n');
        } else {
            statuses.add(new SelectOption('empty', 'No status'));
        }
    }

    private void initYearBox() {
        Integer numberOfDelete;
        Boolean foundWrongField = false;
        System.debug('\n\n numberOfDelete => ');

        if (yearsMap.size() != 0) {
            for (Id timeElementId: yearsMap.keySet()) {
                years.add(new SelectOption(yearsMap.get(timeElementId), yearsMap.get(timeElementId)));
            }
            System.debug('\n\n years.size() => ' + years.size() + '\n');
        } else {
            years.add(new SelectOption('empty', 'No years found'));
        }

//        for(Integer i = 0; i < years.size(); i++) {
//            if (years[i].getLabel() == 'Choose Year') {
//                numberOfDelete = i;
//                foundWrongField = true;
//            }
//        }
//        if(foundWrongField) {
//            years.remove(numberOfDelete);
//        }


    }

    private void initLocationBox() {
        if (locationsName.size() != 0) {
            for (String location: locationsName) {
                if(location != null) {
                    locations.add(new SelectOption(location, location));
                } else {
                    locations.add(new SelectOption('empty', 'No location'));
                }
            }
            System.debug('\n\n locations.size() => ' + locations.size() + '\n');
        } else {
            locations.add(new SelectOption('empty', 'No location'));
        }
    }

    private void initSchoolBox() {
        if (schoolMap.size() != 0) {
            for (Id schoolId: schoolMap.keySet()) {
                schools.add(new SelectOption(schoolId, schoolMap.get(schoolId)));
            }
            System.debug('\n\n schools.size() => ' + schools.size() + '\n');
        } else {
            schools.add(new SelectOption('empty', 'No schools'));
        }
    }

    private void clearCollections() {
        bStatusChanged = true;
        bLocationChanged = true;
        bYearChanged = true;
        schools.clear();
        schoolMap.clear();
    }

    // runs the search with parameters passed via picklists
    public PageReference runSearch() {

        System.debug('\n\n selectedStatus => ' + selectedStatus + '\n');
        System.debug('\n\n selectedYear => ' + selectedYear + '\n');
        System.debug('\n\n selectedLocation => ' + selectedLocation + '\n');

        clearCollections();
        clearTreeMaps();
        if (this.selectedStatus != oldStatus) {
            selectedStatusPicklist();
        } else if (this.selectedYear != oldYear) {
            selectedYearsPicklist();
        } else if (this.selectedLocation != oldLocation) {
            selectedLocationPicklist();
        }
        initSearchBoxes();
        oldStatus = this.selectedStatus;
        oldYear = this.selectedYear;
        oldLocation = this.selectedLocation;
        return null;
    }

    private void selectedStatusPicklist() {
        System.debug('\n\n selectedStatusPicklist \n');
        years.clear();
        yearsMap.clear();
        locations.clear();
        locationsName.clear();


        this.setupWithSchoolAndTime = new List<Setup__c>();
        if (this.selectedStatus.equalsIgnoreCase('New')) {
            this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                + 'AND (Verification_status__c = \'' + this.selectedStatus + '\' OR Verification_status__c = null)');
        } else {
            this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                + 'AND Verification_status__c = \'' + this.selectedStatus + '\'');
        }

//        querySObjectsForTree(setupWithSchoolAndTime);
        queryLocationsForTree(setupWithSchoolAndTime);
        for (Setup__c setupItem : setupWithSchoolAndTime) {
            yearsMap.put(setupItem.Year__r.Id, setupItem.Year__r.Name__c);
            locationsName.add(setupItem.School__r.Site__c);
            schoolMap.put(setupItem.School__r.Id, setupItem.School__r.Name);
        }
        bStatusChanged = false;
    }

    private void selectedYearsPicklist() {
        System.debug('\n\n selectedYearsPicklist \n');

        this.setupWithSchoolAndTime = new List<Setup__c>();
//        List<Setup__c> setupWithSchoolAndTime = null;
        locations.clear();
        locationsName.clear();
        if (this.selectedStatus.equalsIgnoreCase('New')) {
            this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                + 'AND (Verification_status__c = \'' + this.selectedStatus + '\' OR Verification_status__c = null)');
            this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                + 'AND (Verification_status__c = \'' + this.selectedStatus
                + '\' OR Verification_status__c = null) AND Year__r.Name__c = \'' + this.selectedYear + '\'');
        } else {
            this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                + 'AND Verification_status__c = \'' + this.selectedStatus
                + '\' AND Year__r.Name__c = \'' + this.selectedYear + '\'');
        }


        queryLocationsForTree(setupWithSchoolAndTime);
//        querySObjectsForTree(setupWithSchoolAndTime);
        for (Setup__c setupItem : setupWithSchoolAndTime) {
            locationsName.add(setupItem.School__r.Site__c);
            schoolMap.put(setupItem.School__r.Id, setupItem.School__r.Name);
        }
        bStatusChanged = false;
        bYearChanged = false;
    }

    private void selectedLocationPicklist() {
        System.debug('\n\n selectedLocationPicklist \n');
        this.setupWithSchoolAndTime = new List<Setup__c>();
//        List<Setup__c> setupWithSchoolAndTime = null;
        System.debug('\n\n selectedYear1 => ' + selectedYear + '\n');

        if(this.selectedYear != 'Choose Year') {
            if (this.selectedStatus.equalsIgnoreCase('New')) {
//                setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
//                    + 'AND (Verification_status__c = \'' + this.selectedStatus + '\' OR Verification_status__c = null)');

                this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                    + 'AND (Verification_status__c = \'' + this.selectedStatus
                    + '\'  OR Verification_status__c = null) AND Year__r.Name__c = \'' + this.selectedYear
                    + '\' AND School__r.Site__c = \'' + this.selectedLocation + '\'');
            } else {
                this.setupWithSchoolAndTime = Database.query(SETUP_SOQL_QUERY
                    + 'AND Verification_status__c = \'' + this.selectedStatus
                    + '\' AND Year__r.Name__c = \'' + this.selectedYear
                    + '\' AND School__r.Site__c = \'' + this.selectedLocation + '\'');
            }


        } else {
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,
                    'You should select the year!'));
            return;
        }
        queryLocationsForTree(setupWithSchoolAndTime);
//        querySObjectsForTree(setupWithSchoolAndTime);
        for (Setup__c setupItem : setupWithSchoolAndTime) {
            schoolMap.put(setupItem.School__r.Id, setupItem.School__r.Name);
        }
        bStatusChanged = false;
        bYearChanged = false;
        bLocationChanged  = false;
    }


    // sends the setup Id to the CT_core_PublishSetup page
    public PageReference goToSchoolSetup() {
//        String yearId;
//        for (Id timeElementId: yearsMap.keySet()) {
//            if (yearsMap.get(timeElementId) == selectedYear) {
//                yearId = timeElementId;
//            }
//        }
//        return CT_SetupWizard_Utils.getPublishSetup(selectedSchool, yearId);
        for(String key : treeBuilder.accountWithSetupMap.keySet()) {
            for(AccountSelector accSel : treeBuilder.accountWithSetupMap.get(key)) {
                System.debug('\n\n accSel.isSelected => ' + accSel.isSelected + ' ' + accSel.accountWithSetup.School__r.Name + '\n');

            }
        }
        return null;
    }
    private List<Setup__c> checkSelectedSchools() {
        System.debug('\n\n check school \n');
        List<Setup__c> setupForPublish = new List<Setup__c>();
        for (List<AccountSelector> accountsList : this.treeBuilder.accountWithSetupMap.values()) {
            for(AccountSelector wrapper : accountsList) {
                if(wrapper.isSelected == true) {
                    setupForPublish.add(wrapper.accountWithSetup);
                }
            }
        }
        return setupForPublish;
    }

    public void checkTermsOccupancy() {
        Map<Id, List<Time_Element__c>> reportingPeriodsMap = new Map<Id, List<Time_Element__c>>();
        List<Id> setupIds= new List<Id>();
        List<Id> termIds = new List<Id>();

        setupForPublish = checkSelectedSchools();
        if (setupForPublish.size() > 10) {
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,
                    'You can choose no more than 10 schools'));
            bOccupancyError = true;
            return;
        }
        for(Setup__c setup : setupForPublish){
            setupIds.add(setup.Id);
        }

        List<Term__c> terms = [SELECT Id, Name, Time_Element__r.Id, Time_Element__r.Name__c, Setup__r.Id FROM Term__c WHERE Setup__c IN : setupIds];
        List<Term__c> termsList = new List<Term__c>();
        for(Term__c term : terms) {
            termIds.add(term.Time_Element__r.Id);
        }

        reportingPeriodsForPublish = [SELECT Id, Name__c, parent_time_element__c, parent_time_element__r.Name__c,
                (SELECT Section__r.Name, Staff__r.Name FROM Scheduled_Sections__r),
                (SELECT Id, Name FROM Schedule_Templates__r)
            FROM Time_Element__c WHERE parent_time_element__c IN : termIds];
        for(Time_Element__c te: reportingPeriodsForPublish){
            if(!reportingPeriodsMap.containsKey(te.parent_time_element__c)){
                reportingPeriodsMap.put(te.parent_time_element__c, new List<Time_Element__c>());
            }
            reportingPeriodsMap.get(te.parent_time_element__c).add(te);
        }

        bOccupancyError = false;
        for(Term__c term: terms) {
            Integer countReportingPeriods = 0;
            if (reportingPeriodsMap.get(term.Time_Element__r.Id) != null) {
                for (Time_Element__c repPeriod : reportingPeriodsMap.get(term.Time_Element__r.Id)) {

                    if (repPeriod.Schedule_Templates__r.isEmpty() || repPeriod.Schedule_Templates__r == null) {
                        ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,
                                'There are no Scheduled Templates in  <a href="/' + repPeriod.parent_time_element__c + '">' + repPeriod.parent_time_element__r.Name__c + '</a>' +
                                        ' term. Please fill them in for publication opportunities. ' + repPeriod.Name__c));
                        bOccupancyError = true;
                    }

                    if (repPeriod.Scheduled_Sections__r.isEmpty() || repPeriod.Scheduled_Sections__r == null) {
                        ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,
                                'There are no Scheduled Sections in  <a href="/' +  repPeriod.parent_time_element__c + '">' + repPeriod.parent_time_element__r.Name__c + '</a>' +
                                        ' term. Please fill them in for publication opportunities. ' + repPeriod.Name__c));
                        bOccupancyError = true;
                    }
                }
            }

            if (String.isBlank(term.Time_Element__r.Id) || reportingPeriodsMap.get(term.Time_Element__r.Id)==null) {
                ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,
                        'There are no Reporting Periods in <a href="/' + (term.Time_Element__r.Id!=null? term.Time_Element__r.Id: term.Id) +
                                '">' + (term.Time_Element__r.Id!=null? term.Time_Element__r.Name__c: term.Name) + '</a>' +
                                ' term. Please fill them in for publication opportunities. Count terms are ' + terms.size()));
                bOccupancyError = true;
            }
        }

        System.debug('\n\n bOccupancyError => ' + bOccupancyError + '\n');
    }

    private List<Term__c> getTermsFromSetup() {
        System.debug('\n\n getTerm \n');
        List<Term__c> termsToPublish = new List<Term__c>();

        for(Setup__c setup : this.setupForPublish) {
            for (Id setupId : treeBuilder.termsMap.keySet()) {
                System.debug('\n\n setup.Id => ' + setup.Id );
                System.debug('setupId => ' + setupId + '\n');
                if(setup.Id == setupId) {
                    termsToPublish.addAll(this.treeBuilder.termsMap.get(setupId));
                }
            }
        }

        return termsToPublish;
    }

    private List<Time_Element__c> getReportingPeriodsFromTerm(List<Term__c> termsToPublish) {
        System.debug('\n\n getRepPeriod \n');
        List<Time_Element__c> reportingPeriodsForPublish = new List<Time_Element__c>();

        for(Term__c term : termsToPublish) {
            for(Id termId : this.treeBuilder.reportingPeriodsMap.keySet()) {
                if(term.Time_Element__r.Id == termId) {
                    reportingPeriodsForPublish.addAll(this.treeBuilder.reportingPeriodsMap.get(termId));
                }
            }
        }

        return reportingPeriodsForPublish;
    }

    public PageReference reloadPage() {
        return new PageReference(ApexPages.currentPage().getUrl());
    }

    public void publishSchools() {
        try {
            List<CT_core_SetupWrapper> cSetupList = new List<CT_core_SetupWrapper>();
            List<Id> reportingPeriodIdsList = new List<Id>();
            for (Time_Element__c reportingPeriod : this.reportingPeriodsForPublish) {
                reportingPeriodIdsList.add(reportingPeriod.Id);
            }
            System.debug('\n\n reportingPeriodIdsList => ' + reportingPeriodIdsList + '\n');
            
            for(Setup__c setup : setupForPublish) {
                cSetup= new CT_core_SetupWrapper(setup,'publish');
                cSetupList.add(cSetup);
              
                CT_Scheduler_UpsertHolding upho = new CT_Scheduler_UpsertHolding(cSetup);
                List<Scheduled_Section__c> scheduledSections = queryScheduleSections(reportingPeriodIdsList);
                
                System.debug('\n\n scheduledSections => ' + scheduledSections + '\n');
                if(upho.cSetup.setup.Group_Based__c) {
                    System.debug('\n\n goes to true \n');
                    upho.upsertHoldingRecordsForScheduledSec(scheduledSections);
                }
                else {
                    System.debug('\n\n goes to false \n');
                    upho.upsertHoldingRecordsForPeriods(scheduledSections);
                }
                cSetup.setup.Published__c = true;
                cSetup.setup.Verification_Status__c = 'Verified';

                System.debug('\n\n before update setup \n');
                update cSetup.setup;

                ApexPages.getMessages().clear();
//                bProcessing = true;
            }
            
            for (CT_core_SetupWrapper setup : cSetupList) {
                if(setup.reportingPeriodList!=null && !setup.reportingPeriodList.isEmpty()){
                    for (Time_Element__c setupReportingPeriod : setup.reportingPeriodList) {
                        for (Time_Element__c reportingPeriodWithChildren : reportingPeriodsForPublish) {
                            if (setupReportingPeriod.Id == reportingPeriodWithChildren.Id) {
                                this.batchReportingPeriodId = reportingPeriodWithChildren.Id;
                                start_Propagator('Staff', setup);
                            }
                        }
                    }
                }
            }
            activateData(setupForPublish);
        }
        catch (exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred'));
            System.debug('\n\n e.getLineNumber() => ' + e.getLineNumber() + '\n');
            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
            Global_Error__c ge = CT_Error_Handling.handleError('Scheduler_UpsertHoldingObject', 'Scheduler', 'Upserting to Holding Object for: '+cSetup.setup.Id, e);
            insert ge;
        }
    }

    private void start_Propagator(String mode, CT_core_SetupWrapper cSetup){
        CT_Scheduler_HoldingProcessor shp = new CT_Scheduler_HoldingProcessor();
        shp.continueBatch = true;
        shp.cSetup = cSetup.setup;
        shp.mode = mode;

        if (batchReportingPeriodId!=null) {
            shp.reportingPeriod = batchReportingPeriodId;
        }
        System.debug('\n\n shp.reportingPeriod  section=> ' + shp.reportingPeriod + '\n');
        Id batchId = database.executeBatch(shp);

        CT_SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Publish task was sent. Selected schools will be published in 10 minutes.');
    }


    private void activateData(List<Setup__c> setupForPublish){
        try{
            Set<Id> setupIds = new Set<Id>();
            for(Setup__c setup: setupForPublish) {
                setupIds.add(setup.Id);
                setup.New_School_Year__c = false;
                setup.Active__c = true;
            }
            update setupForPublish;

            CT_Batch_ProcessEOYData processEOYBatch = new CT_Batch_ProcessEOYData('Student__c', setupIds);
            processEOYBatch.bFlag = true;

            Id batchId = Database.executeBatch(processEOYBatch,10);
            batch = new CT_BatchWrapper(batchId,cSetup.setup.id);
            batch.needsStudents = true;
            //This method validates whether the batch has to be invoked again for another school or another mode(Student or Section)
            continueBatch();
        }
        catch(Exception e){
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred'));
        }
    }

    public PageReference continueBatch(){
        try{
            boolean failed = batch.continueBatch();
            System.debug('\n\n failed => ' + failed + '\n');
        }
        catch(Exception e){
            System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
            System.debug('\n\n e.getLineNumber() => ' + e.getLineNumber() + '\n');
            ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while checking the status of the batch.'));
        }
        return null;
    }



    private List<Scheduled_Section__c> queryScheduleSections(List<Id> reportingPeriodsIds) {

        List<Scheduled_Section__c> scheduleSectionsList =[Select account__r.reference_Id__c ,
                staff__r.reference_Id__c,
                Type__c,
                grade_level__c,schedule_group_name__c,
                Staff__c, Section__c,
                Schedule_Template__c,
                Schedule_Group_Section__c,
                Room__c,
                Reporting_Period__c,
                Reference_Id__c,
                Period_Key__c,
                Course__c,
                course_name__c,
                Account__c,
                reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c,
                staff__r.First_Name_Staff__c,
                staff__r.Staff_Last_Name__c,
                staff__r.Individual__r.Staff_Code__c,
                No_Meeting__c,
                Section__r.No_Meeting__c,
                section_ReportingPeriod__r.Time__c,
                staff__r.Individual__r.User_Name__c,
                staff__r.Individual__r.Email,
                staff__r.Individual__r.Phone,
                staff__r.Individual__r.MailingStreet,
                staff__r.Individual__r.MailingCity,
                staff__r.Individual__r.MailingState,
                staff__r.Individual__r.MailingPostalCode,
                staff__r.Individual__r.Gender__c,
                Section__r.Section_Number__c,
                section__r.Name,
                section__r.Grade_Level__c,
                section__r.All_Grades__c,
                section__r.Period__c,
                section__r.record_Attendance__c,
                section__r.daily_attendance__c,
                section__r.reporting_period__c,
                section__r.reference_Id__c,
                section__r.time__r.Name__c,
                record_attendance__c,
                Daily_Attendance__c,
                Grade_Levels__c,
                Room__r.name
        FROM Scheduled_Section__c WHERE Reporting_Period__c IN : reportingPeriodsIds
        AND Needs_Publish__c = true
        AND account__c =: cSetup.school.Id];

        return scheduleSectionsList;
    }

    public class AccountSelector {
        public Setup__c accountWithSetup                                                {get;set;}
        public Boolean isSelected                                                       {get;set;}

        public AccountSelector(Setup__c accountWithSetup, Boolean isSelected) {
            this.accountWithSetup = accountWithSetup;
            this.isSelected = isSelected;
        }
    }

    public class TreeBuilder {
        public Set<String> locations                                                    {get;set;}
        public Map<String, List<AccountSelector>> accountWithSetupMap                   {get;set;}
        public Map<Id, List<Term__c>> termsMap                                          {get;set;}
        public Map<Id, List<Time_Element__c>> reportingPeriodsMap                       {get;set;}
        public Map<Id, List<Period__c>> periodsMap                                      {get;set;}

        public TreeBuilder(Set<String> locations, Map<String, List<AccountSelector>> accountWithSetupMap, Map<Id, List<Term__c>> termsMap,
                Map<Id, List<Time_Element__c>> reportingPeriodsMap, Map<Id, List<Period__c>> periodsMap) {

            this.locations = locations;
            this.accountWithSetupMap = accountWithSetupMap;
            this.termsMap = termsMap;
            this.reportingPeriodsMap = reportingPeriodsMap;
            this.periodsMap = periodsMap;
        }

        public TreeBuilder(Set<String> locations) {
            this.locations = locations;
        }

        public TreeBuilder(Set<String> locations, Map<String, List<AccountSelector>> accountWithSetupMap) {
            this.locations = locations;
            this.accountWithSetupMap = accountWithSetupMap;
        }

        public TreeBuilder(Set<String> locations, Map<String, List<AccountSelector>> accountWithSetupMap, Map<Id, List<Term__c>> termsMap) {
            this.locations = locations;
            this.accountWithSetupMap = accountWithSetupMap;
            this.termsMap = termsMap;
        }
        public TreeBuilder(Set<String> locations, Map<String, List<AccountSelector>> accountWithSetupMap, Map<Id, List<Term__c>> termsMap,
                Map<Id, List<Time_Element__c>> reportingPeriodsMap) {

            this.locations = locations;
            this.accountWithSetupMap = accountWithSetupMap;
            this.termsMap = termsMap;
            this.reportingPeriodsMap = reportingPeriodsMap;
        }
    }

}
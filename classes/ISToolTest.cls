@isTest
public class ISToolTest {
	private static final Integer COUNT = 3;
	
	static testMethod void mainTest(){
		testDataSetupUtil_v2.setUPCoreData(COUNT);
		testDataSetupUtil_v2.setUPStaffData(COUNT);
		testDataSetupUtil_v2.setUPStudentData(COUNT);
		testDataSetupUtil_v2.setupTimeElements(COUNT);
		ISTool tool1 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id);
		ISTool tool2 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id, Date.today());
		ISTool tool3 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id, Date.today(), Date.today());
		ISTool tool4 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id, false);
		ISTool tool5 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id, Date.today(), false);
		ISTool tool6 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id);
		ISTool tool7 = new ISTool(testDataSetupUtil_v2.sectionsList[0].Id, false);
		tool1.updateSessionSelection(testDataSetupUtil_v2.sectionsList[0].Id);
		tool1.updateSessionSelection(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id, Date.today());
		tool1.updateSessionSelection(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id);
		tool1.updateSessionSelection(testDataSetupUtil_v2.sectionsList[0].Id, testDataSetupUtil_v2.studSectionsList[0].Id, Date.today(), Date.today() + 2, testDataSetupUtil_v2.staffUsersList[0].Id);
		tool1.updateResultSelection(false);

//		tool1.setSingleSession(testDataSetupUtil_v2.sessionsList[0].Id);
		tool1.setAllSessions();
		tool1.loadSessionData();
		tool1.getSessionsByDate(Date.today());
		tool1.getOrderedSessions();

//		ISTool.SessionWrapper sw = new ISTool.SessionWrapper(testDataSetupUtil_v2.interventionSessionsList[0]);
		//setSingleSession(ID sessionID)
		//List<SessionWrapper> sw = tool1.getSessionsByDate(Date.today());
		tool1.reformatDate(Date.today());

		ISTool.getAvaliableSkills('', new List<SelectOption>(), new List<SelectOption>());
		List<SelectOption> allAvenues = ISTool.getAllAvenues();
		ISTool.getSiteDetailsOptions();
		System.assert(!allAvenues.isEmpty());
	}

	static testMethod void secondTest(){

	}
}
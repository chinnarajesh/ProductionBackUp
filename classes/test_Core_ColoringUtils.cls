@isTest
private class test_Core_ColoringUtils {

	static void generateTest(String hex, string foreGroundText){
        string testText = core_ColoringUtils.getTextColor(hex);
        system.assertEquals(foreGroundText, testText);
        string anotherOptimizationMethod = core_ColoringUtils.optimizeHex(hex);
        string hexReturn = core_ColoringUtils.RGBToHex(25, 25, 25);
	}
	
    static testMethod void test_Util_Methods() {
    	generateTest('#4D4D4D', '#FFFFFF');//pass in grey, should get white
    	generateTest('#EEB4B4', '#000000'); //pass in pink, should get black
    }
}
public class CT_StringUtils {
	/**
	 * Joins specified array of string values using specified separator. Optionally, 
	 */
	public static String join(List<String> values, String separator, String enclosedBy) {
		// Handle null values
		if ((values == null) || (values.size() == 0)) {
			return '';
		}
		if (separator == null) {
			separator = '';
		}
		if (enclosedBy == null) {
			enclosedBy = '';
		}

		for(String s:values){
			s= enclosedBy+s+enclosedBy;
		}
		return String.join(values,separator);
	}
	
	/**
	 * Tests if specified value is null or an empty string.
	 */
	public static Boolean isBlank(String value) {
		return (value == null) || (value.trim().length() == 0);
	}
	
	public static String[] splitAndTrim(String value, String regExp) {
		List<String> result = new List<String>();
		for (String part : value.split(regExp)) {
			if (part != null) {
				result.add(part.trim());
			}
		}
		return result;
	}
	
	public static String capitalize(String value) {
		if (value == null) {
			return null;
		}
		value = value.trim();
		if (value.length() == 0) {
			return value;
		} else if (value.length() == 1) {
			return value.toUpperCase();
		}
		
		return value.substring(0,1).toUpperCase() + value.substring(1,value.length());
	}
	
	public static String blankNull(String value){
		return (value == null)?'':value;
	}
	
	public static String buildMutliSelectQuery(List<String> values){
		Set<String> setValues = values!=null? new Set<String>(values): new Set<String>();
		setValues.remove('');
		setValues.remove(null);
		String query=' INCLUDES ('+ (!setValues.isEmpty()? '\''+String.join(new List<String>(setValues), '\',\'')+'\'': '') +')';
		return query;
	}
	
	public static string getQueryDate(string s){
		String[] vars = s.split('/',3);
		if(vars.size() != 3)
			return null;
		if(vars[0].length()==1) vars[0] = '0'+vars[0];
		if(vars[1].length()==1) vars[1] = '0'+vars[1];
		return vars[2]+'-'+vars[0]+'-'+vars[1];
	}
	
	public static List<SelectOption> sortList(List<SelectOption> orig, boolean integerSortMode){
		if(orig.size() <= 1){
			return orig;
		}
		List<SelectOption> left = new List<SelectOption>();
		List<SelectOption> right = new List<SelectOption>();
		List<SelectOption> result = new List<SelectOption>();
		integer mid = orig.size()/2;

		for(integer i=0;i<mid;i++) {
			left.add(orig[i]);
		}
		for(integer i=mid;i<orig.size();i++) {
			right.add(orig[i]);
		}

		left = sortList(left, integerSortMode);
		right = sortList(right, integerSortMode);
		result = mergeSort(left, right, integerSortMode);
		return result;
	}

	private static List<SelectOption> mergeSort(List<SelectOption> left, List<SelectOption> right, boolean integerSortMode){
		List<SelectOption> result = new List<SelectOption>();
		while(left.size() > 0 || right.size() > 0){
			if(left.size() > 0 && right.size() > 0){
				if(integerSortMode && left[0].getLabel().length() < right[0].getLabel().length()){
					result.add(left.remove(0));
				} else if(integerSortMode && left[0].getLabel().length() > right[0].getLabel().length()){
					result.add(right.remove(0));
				} else {
					if(left[0].getLabel() < right[0].getLabel()){
						result.add(left.remove(0));
					} else {
						result.add(right.remove(0));
					}
				}
			} else if(left.size() > 0) {
				result.add(left.remove(0));
			} else if(right.size() > 0) {
				result.add(right.remove(0));
			}
		}
		return result;
	}
	
	static testMethod void  test_StringUtils(){
		string s = CT_StringUtils.capitalize('test');
		system.assertEquals(s,'Test');
		string [] sArray = CT_StringUtils.splitAndTrim( 'blah, test' ,',');
		system.assertEquals(sArray.size(),2);
		boolean b = CT_StringUtils.isBlank(s);
		system.assertEquals(b,false);
		string[] lString = new String[]{'blah','blah2','blah3'};
		string v= CT_StringUtils.join(lString, ',' ,'"');
	}

}
public with sharing class CT_core_UtilDays {
	public boolean Mon {get;set;}
	public boolean Tue{get;set;}
	public boolean Wed{get;set;}
	public boolean Thu{get;set;}
	public boolean Fri{get;set;}
	public boolean Sat{get;set;}
	public boolean Sun{get;set;}
	public  Set<Integer> intValueSet ;
	public static String validDOWCharacters = 'UMTWHFS';

	public CT_core_UtilDays() {
		Mon = Tue = Wed = Thu = Fri=true;
		Sat = Sun = false;
	}

	public CT_core_UtilDays(String days) {
		Mon = days.indexOf('M') > -1 ? true : false;

		Tue = days.indexOf('T') > -1 ? true : false;

		Wed = days.indexOf('W') > -1 ? true : false;

		Thu = days.indexOf('H') > -1 ? true : false;

		Fri = days.indexOf('F') > -1 ? true : false;
				
				Sat = days.indexOf('S') > -1 ? true : false;
				
				Sun = days.indexOf('U') > -1 ? true : false;
	}
	
	public static void processIntValues(CT_core_UtilDays c){
		c.intValueSet = new Set <Integer>();
		if (c.Sun) c.intValueSet.add(1);
		if (c.Mon) c.intValueSet.add(2);
		if (c.Tue) c.intValueSet.add(3);
		if (c.Wed) c.intValueSet.add(4);
		if (c.Thu) c.intValueSet.add(5);
		if (c.Fri) c.intValueSet.add(6);
		if (c.Sat) c.intValueSet.add(7);
	}

	public CT_core_UtilDays(boolean Mon, boolean Tue, boolean Wed, boolean Thu, boolean Fri, boolean Sat, boolean Sun) {
		this.Mon = Mon;
		this.Tue = Tue;
		this.Wed = Wed;
		this.Thu = Thu;
		this.Fri = Fri;
				this.Sat = Sat;
				this.Sun = Sun;                        
	}

	public String DaystoString() {
		String retVal = '';

		retVal += (Mon ? 'M' : '') + (Tue ? 'T' : '') + (Wed ? 'W' : '')
				+ (Thu ? 'H' : '') + (Fri ? 'F' : '') 
								+ (Sat ? 'S' : '') + (Sun ? 'U' : '');

		return retVal;
	}
	


	// Returns true if there is any overlap between days
	public boolean overlaps(CT_core_UtilDays d) {
		return ((Mon && d.Mon) || (Tue && d.Tue) || (Wed && d.Wed)
				|| (Thu && d.Thu) || (Fri && d.Fri)
								|| (Sat && d.Sat) || (Sun && d.Sun));
	}

	// Returns true if the days in 'd' are a subset of the days in
	// this object
	public boolean encompasses(CT_core_UtilDays d) {
		// Basically, what this equation does is, for each
		// day, if d does not contain that day, we get a 'true'.
		// if d DOES contain that day, we get a true iff this object
		// also contains that day. We then AND all of these together.
		// The only falses should come from days that are in d, but
		// not in this object. If there are any of those, then
		// this object does not encompass d, and we get a false
		// from the AND.
		return (d.Mon ? d.Mon == Mon : true) 
				&& (d.Tue ? d.Tue == Tue : true)
				&& (d.Wed ? d.Wed == Wed : true)
				&& (d.Thu ? d.Thu == Thu : true)
				&& (d.Fri ? d.Fri == Fri : true)
				&& (d.Sat ? d.Sat == Sat : true)
				&& (d.Sun ? d.Sun == Sun : true);
	}

		public static boolean isValid(String days) {
			// Returns true if this string contains only valid day characters
			String validCharacters = 'MTWHFSU';
			for (integer i = 0; i < days.length(); i++) {	
				if (!(validCharacters.contains(days.substring(i,i+1)))){
					return false;
				}

			}
			return true;
		}
		
		public boolean hasMon() {
			return this.Mon;
		}
		
		public boolean hasTue() {
			return this.Tue;
		}
		
		public boolean hasWed() {
			return this.Wed;
		}
		
		public boolean hasThu() {
			return this.Thu;
		}
		
		public boolean hasFri() {
			return this.Fri;
		}
		
		public boolean hasSat() {
			return this.Sat;
		}
		
		public boolean hasSun() {
			return this.Sun;
		}
}
global with sharing class CSVUtils {
	
	/* Helper class to parse CSV files into an import format.
	* This complies with the RCF 4180 standard on CSV files. */
	global class CSVParser{
		global string inputData;
		
		/* Parsed Data Containers */
		global List<String> headers;
		global List<List<String>> parsedData;
		private boolean containsHeaders;
		
		/* Error handeling */
		global boolean parseError;
		global string errorMessage;
		
		global CSVParser(string input, boolean hasHeaders){
			inputData = input;
			containsHeaders = hasHeaders;
			if(hasHeaders){
				headers = new List<String>();
			}
		}
		
		global void parse(){
			if(inputData == null || inputData == ''){
				parseError = true;
				errorMessage = 'Error: Malformed file. There is no contained data.';
				return;
			}
			List<String> csvList = inputData.split('\n');
			List<String> lineList = new List<String>();
			boolean inQuote = false;
			string quoteField = '';
			for(String s: csvList){
				system.debug(s);
				if(s.contains('"') || inQuote){
					//if there are an odd number of quotes, this will return true
					if(Math.mod(s.split('"',-1).size(), 2) == 0 && !inQuote){
						inQuote = true;
						quoteField = s + '\n';
						system.debug('Start Quote');
					//ending condition, where there are no escaped double quotes
					} else if(inQuote && !s.contains('""') && s.contains('"')){
						quoteField = quoteField + s;
						system.debug('Close without ""');
						//if we close and don't reopen, time for a new line
						string temp = s.substring(s.indexOf('"')+1);
						if(!temp.contains('"')){
							inQuote = false;
							lineList.add(quotefield);
							system.debug('Really closed.');
						} else if(Math.mod(temp.split('"',-1).size(), 2) == 1){
							inQuote = false;
							lineList.add(quotefield);
							system.debug('Really closed.');
						}
						if(inQuote){
							quoteField = quoteField + '\n';
						}
					//ending condition where there are escaped double quotes
					} else if(inQuote && s.contains('""')){
						quoteField = quoteField + s;
						string temp = s.replace('""', '');
						system.debug('Close with ""');
						//closed and not reopened no double quotes
						if(temp.contains('"') && !temp.substring(temp.indexOf('"')+1).contains('"')){
							inQuote = false;
							lineList.add(quotefield);
							system.debug('Close no more quotes');
						//same logic from above, detects if there is an open quote at the end of the line
						//now we're detecting even quotes
						} else if(Math.mod(temp.split('"',-1).size(), 2) == 0){
							inQuote = false;
							lineList.add(quotefield);
							system.debug('Close due to quote count.');
						}
						if(inQuote){
							quoteField = quoteField + '\n';
						}
					//keep going on open quote	
					} else if(inQuote){
						system.debug('Keep going');
						quoteField = quoteField + s + '\n';
					//standard open/close
					} else {
						lineList.add(s);
						system.debug('No multi-line');
					}
				} else {
					lineList.add(s);
				}
			}
			
			system.debug('Displaying first pass');
			for(string s:lineList){
				system.debug(s);
			}
			
			parsedData = new List<List<String>>();
			parseError = false;
			quoteField = '';
			inQuote = false;
			system.debug('Starting second pass.');
			for(String lineString: lineList){
				List<String> valueList = new List<String>();
				system.debug(lineString);
				for(String s: lineString.split(',',-1)){
					//s = s.trim();
					//missing base case of null
					if(s.startsWith('"') && s.replace('""', '') == '') {
						system.debug('string looks like: \'\'');
						valueList.add('');
					}
					else if(s.startsWith('"') && !s.replace('""', '').endsWith('"') && !inQuote){
						quoteField = s+ ',';
						inQuote = true;
						system.debug('starts quote');
					} else if (inQuote && !s.trim().endsWith('"')){
						quoteField += s + ',';
						system.debug('Keep going');
					} else if (inQuote){
						quoteField += s;
						//end quote
						if(!s.contains('""') || s.replace('""', '').contains('"')){
							quoteField = quoteField.trim();
							quoteField = quoteField.substring(1, quoteField.length()-1);
							quoteField = quoteField.replace('""', '"');
							valueList.add(quoteField);
							inQuote = false;
							system.debug('End Quote');
						}
						
					} else if(s.startsWith('"') && !inQuote){
						valueList.add(s.trim().substring(1, s.length()-1).replace('""', '"'));
						system.debug('Start and close in same');
					} else {
						valueList.add(s.trim().replace('""', '"'));
						system.debug('no quotes');
					}
				}
				parsedData.add(valueList);
			}
			Integer lineSize = 0;
			if(containsHeaders){
				headers = parsedData.remove(0);
				lineSize = headers.size();
			}
			system.debug('Start debug output.');
			system.debug(headers);
			integer lineCounter = 1;
			for(List<String> s:parsedData){
				if(lineSize == 0){
					lineSize = s.size();
				}
				if(lineSize != s.size()){
					errorMessage = 'Error: Malformed file. Line '+lineCounter+' has an unequal number of rows. Please check the file.';
				}
				lineCounter++;
				system.debug(s);
			}
		}
	}
	
	@istest
	private static void testParsing(){
		string teststring = '123,456,789\n' +
							'123,"""456""",789\n'+
							'123,"456 789",101\n'+
							'123,"456, 789",101\n'+
							'123,"456, \n789",101\n'+
							'123,"456\n"",""\n789","1,0,1"\n';
								
		CSVParser parser = new CSVParser(testString, false);
		parser.parse();
			
		List<List<String>> correctOutput = new List<List<String>>();
		correctOutput.add(new List<String>{'123', '456', '789'});
		correctOutput.add(new List<String>{'123', '"456"', '789'});
		correctOutput.add(new List<String>{'123', '456 789', '101'});
		correctOutput.add(new List<String>{'123', '456, 789', '101'});
		correctOutput.add(new List<String>{'123', '456, \n789', '101'});
		correctOutput.add(new List<String>{'123', '456\n","\n789', '1,0,1'});
		system.assertEquals(correctOutput.size(), parser.parsedData.size());
		for(integer i = 0; i<correctOutput.size(); i++){
			system.assertEquals(correctOutput[i], parser.parsedData[i], 'Parse error in test data line ' + i + '. Sizes:' + correctOutput[i].size() + ':' + parser.parsedData[i].size());
		}
		
	}
}
public with sharing class core_ColoringUtils {

	public static string getTextColor(string inputHex){
			decimal [] inputArray =HexToRGB(inputHex);
			decimal maxColorComponentVal = 255;
			inputArray[0]=maxColorComponentVal-inputArray[0];
			inputArray[1]=maxColorComponentVal-inputArray[1];
			inputArray[2]=maxColorComponentVal-inputArray[2];
			return PerceivedBrightness(inputArray[0], inputArray[1], inputArray[2]);
	}
			
	public static string optimizeHex(string inputHex){
			decimal [] inputArray =HexToRGB(inputHex);
			inputArray[0]=inputArray[0]*.2126;
			inputArray[1]=inputArray[1]*.7152;
			inputArray[2]=inputArray[2]*.0722;
			return RGBToHex(inputArray[0], inputArray[1], inputArray[2]);
	}

	public static decimal GiveDec(string Hex)
	{
			decimal value;
		 if(Hex == 'A')
				Value = 10;
		 else
		 if(Hex == 'B')
				Value = 11;
		 else
		 if(Hex == 'C')
				Value = 12;
		 else
		 if(Hex == 'D')
				Value = 13;
		 else
		 if(Hex == 'E')
				Value = 14;
		 else
		 if(Hex == 'F')
				Value = 15;
		 else
				Value = decimal.valueOf(Hex);
		 return Value;
	}
	public static string GiveHex(decimal Dec)
	{
			string value;
		 if(Dec == 10)
				Value = 'A';
		 else
		 if(Dec == 11)
				Value = 'B';
		 else
		 if(Dec == 12)
				Value = 'C';
		 else
		 if(Dec == 13)
				Value = 'D';
		 else
		 if(Dec == 14)
				Value = 'E';
		 else
		 if(Dec == 15)
				Value = 'F';
		 else
				Value = '' + Dec;
		 return Value;
	}
	public static decimal[] HexToRGB(string input)
	{

	 decimal[] rgbArrary = new decimal[]{};
	 if (input==null) input ='#FFFFFF';
	 input = input.replace('#', '');
		 decimal a = GiveDec(Input.substring(0, 1));
		 decimal b = GiveDec(Input.substring(1, 2));
		 decimal c = GiveDec(Input.substring(2, 3));
		 decimal d = GiveDec(Input.substring(3, 4));
		 decimal e = GiveDec(Input.substring(4, 5));
		 decimal f = GiveDec(Input.substring(5, 6));
	 
		rgbArrary.add( (a * 16) + b);
		rgbArrary.add( (c * 16) + d);
		 rgbArrary.add( (e * 16) + f);
	 return rgbArrary;

	}
	public static string RGBToHex(decimal red, decimal green, decimal blue)
	{
		 string a = GiveHex(Math.floor(Red / 16));
		 string b = GiveHex(math.mod(Integer.valueOf(Red) ,16));
		 string c = GiveHex(Math.floor(Green / 16));
		 string d =GiveHex(math.mod(Integer.valueOf(Green) ,16));
		string e = GiveHex(Math.floor(Blue / 16));
		string f =GiveHex(math.mod(Integer.valueOf(Blue) ,16));
			 string z ='#'+ a + b + c + d + e + f;
	 return z;
	 
	}
		
		public static string PerceivedBrightness(decimal red, decimal green, decimal blue)
	{
			decimal pbVal = (   red* 299 +    green * 587 +blue*114)/1000;
			return pbVal>128 ?  '#FFFFFF': '#000000'; 
	}
	
}
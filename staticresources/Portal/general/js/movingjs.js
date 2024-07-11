/*
   You can set timerlen and slideAniLen as ur wish.
*/
var timerlen =100;
var slideAniLen = 250;

var timerID = new Array();
var startTime = new Array();
var obj = new Array();
var endHeight = new Array();
var moving = new Array();
var dir = new Array();

function slidedown(did){
        
        if(moving[did])
                return;

        if(document.getElementById(did).style.display != "none")
                return; // cannot slide down something that is already visible
        moving[did] = true;
        dir[did] = "down";
        startslide(did);
        
}

function slideup(did){
        if(moving[did])
                return;

        if(document.getElementById(did).style.display == "none")
                return; // cannot slide up something that is already hidden

        moving[did] = true;
        dir[did] = "up";
        startslide(did);
}

function startslide(did){
              
        obj[did] = document.getElementById(did);
        endHeight[did] = parseInt(obj[did].style.height);
        startTime[did] = (new Date()).getTime();

        if(dir[did] == "down"){
               obj[did].style.height = "1px";
        }
        obj[did].style.display = "block";
        timerID[did] = setInterval('slidetick(\'' + did + '\');',timerlen);
  }

function slidetick(did){
        var elapsed = (new Date()).getTime() - startTime[did];
                
        if (elapsed > slideAniLen)
                endSlide(did)
        else {
                var d =Math.round(elapsed / slideAniLen * endHeight[did]);
                if(dir[did] == "up")
                        d = endHeight[did] - d;
                    
                obj[did].style.height = d + "px";
        }

        return;
}

function endSlide(did){
        clearInterval(timerID[did]);

        if(dir[did] == "up")
                obj[did].style.display = "none";
                

        obj[did].style.height = endHeight[did] + "px";

        delete(moving[did]);
        delete(timerID[did]);
        delete(startTime[did]);
        delete(endHeight[did]);
        delete(obj[did]);
        delete(dir[did]);

        return;
}


function toggleSlide(did,iid,image,size)
{
	if(document.getElementById(did).style.display == "none")
        {
		// Rotate the Arrow
		if (size == 1){
		document.getElementById(image).style.backgroundPosition="0px -14px";
		}
		else if (size == 2){
		document.getElementById(image).style.backgroundPosition="0px -28px";	
		}
		// div is hidden, so let's slide down
		slidedown(did);
                document.getElementById(iid).setAttribute('src','hexpander/remove.jpg');
               
	}
        else
         {
		// Make the arrow normal
		if (size == 1){
		document.getElementById(image).style.backgroundPosition="0px 0px";
		}
		else if (size == 2){
		document.getElementById(image).style.backgroundPosition="0px 0px";	
		}		// div is not hidden, so slide up
		slideup(did);
                document.getElementById(iid).setAttribute('src','hexpander/insert.jpg');
	}
}

// HACK HOME PAGE TOGGLE images

function toggle(obj,self) {
	var el = document.getElementById(obj);
	var sel = document.getElementById(self);
	if ( el.style.display != 'none' ) {
		el.style.display = 'none';
	
	}
	else {
		el.style.display = '';
		sel.style.display = 'none';
	}
}

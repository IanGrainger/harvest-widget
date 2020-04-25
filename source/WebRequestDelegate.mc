//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Communications;
using Toybox.WatchUi;
using Toybox.Time.Gregorian;

class WebRequestDelegate extends WatchUi.BehaviorDelegate {
    var notify;
    
    // Handle menu button press
//    function onMenu() {
//        makeRequest();
//        return true;
//    }
// NOT WORKING
//	function onMenu() {
//        var menu = new WatchUi.Menu2({:title=>"My Menu2"});
//        var delegate;
//        menu.addItem(
//            new MenuItem(
//                "Item 1 Label",
//                "Item 1 subLabel",
//                "itemOneId",
//                {}
//            )
//        );
//        menu.addItem(
//            new MenuItem(
//                "Item 2 Label",
//                "Item 2 subLabel",
//                "itemTwoId",
//                {}
//            )
//        );
//        delegate = new MyMenu2Delegate(); // a WatchUi.Menu2InputDelegate
//        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
//        return true;
//    }

    function onSelect() {
//        makeRequest();
//        return true;
		return onMenu();
    }
    
    function onMenu() {
    	if(!loaded) {
    		// special menu while loading!
    		var myMenu = new WatchUi.Menu();
    		myMenu.addItem("Queue start", :start);
    		myMenu.addItem("Queue stop", :stop);
	    	WatchUi.pushView(myMenu, new LoadingMenuDelegate(method(:loadingMenuUpdateCallback)), WatchUi.SLIDE_IMMEDIATE);
    	}
    	else {
	    	var myMenu = new WatchUi.Menu();
	    	if(isRunning) {
	    		myMenu.addItem("Stop", :stop);
	    	}
	    	else {
	    		myMenu.addItem("Start", :start);
	    	}
	    	WatchUi.pushView(myMenu, new MyMenuDelegate(timeEntryId, method(:updateCallback)), WatchUi.SLIDE_IMMEDIATE);
    	}
    }
    
    var actionOnLoaded = null;
    function loadingMenuUpdateCallback(startOrStopToken) {
    	System.println("loading menu callback" + startOrStopToken);
    	actionOnLoaded = startOrStopToken;
    	
    	makeRequest();
    }
    
    function updateCallback(responseCode, data) {
    	System.println("update callback!" + responseCode + ", data: " + data);
    	makeRequest();
    }

    function makeRequest() {
        notify.invoke("Getting data...");
        // this seems to break the app!?
		// Communications.cancelAllRequests();
        Communications.makeWebRequest(
            "https://api.harvestapp.com/v2/time_entries?per_page=5"+"&access_token=5034.pt.Zs6dN9lcB0QYSS0OQgtbuiDGJmU3LBp7mJRS1UvKo2Hxm_LD9gGGs8N-r0lPfhw3AeJMpQvpTSd7wgtdmIOcyQ&account_id=97677",
            {
            },
            {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:onReceive)
        );
    }

    // Set up the callback to the view
    function initialize(handler) {
        WatchUi.BehaviorDelegate.initialize();
        notify = handler;
        
        makeRequest();
    }

	var isRunning = false;
	var loaded = false;
	var timeEntryId = 0;

    // Receive the data from the web request
    function onReceive(responseCode, data) {
    	//latest response
    	var lastUpdatedEntry = getLastUpdatedEntry(data["time_entries"]);
    
        if (responseCode == 200 && data["time_entries"] != null && data["time_entries"].size() > 0) {
        	loaded = true;
        	// get first result's project and task
        	//var timeEntry1 = data["time_entries"][0];
        	var projectName = lastUpdatedEntry["project"]["name"];
        	var taskName = lastUpdatedEntry["task"]["name"];
        	var hours = lastUpdatedEntry["hours"];
        	isRunning = lastUpdatedEntry["is_running"];
        	timeEntryId = lastUpdatedEntry["id"];
        	var running = "Stopped";
        	if(isRunning) {
        		running = "Running";
        	}
        	
        	var h = hours.toNumber();
        	var bitHour = hours - h;
        	var m = (60 * (hours - h)).toNumber();
        	var minsMaybe = bitHour * 100;
			
			var timeStr = Lang.format("$1$:$2$", [h.format("%d"), m.format("%02d")]);
			System.println("p:" + projectName + ", t: " + taskName + ", hours: " + hours + ", bitHour: " + bitHour + ", h: " + timeStr + " minsMaybe: " + minsMaybe + " m: " + m);
			
			if(actionOnLoaded != null) {
				System.println("actionOnLoaded " + actionOnLoaded);
				if(actionOnLoaded == :start) {
					doHarvestTimeEntryPatch(timeEntryId, "restart");
				}
				else if(actionOnLoaded == :stop) {
					doHarvestTimeEntryPatch(timeEntryId, "stop");
				}
				actionOnLoaded = null;
			}
			else {
	        	var message = projectName + "\n" + taskName + "\n" + timeStr + " - " + running + "\n" + "Create: " + lastUpdatedEntry["created_at"] + "\nUpdate: " + lastUpdatedEntry["updated_at"];
	        	notify.invoke(message);
	            //notify.invoke(data);
            }
        } else {
            notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }
    
    function getLastUpdatedEntry(timeEntries) {
    	var lastUpdatedEntry = timeEntries[0];
    	var lastUpdateDate = parseISODate(lastUpdatedEntry["updated_at"]); 
    	for(var i=1; i<timeEntries.size(); i++) {
    		var checkingEntry = timeEntries[i];
    		if(parseISODate(checkingEntry["updated_at"]).greaterThan(lastUpdateDate)) {
    			lastUpdatedEntry = checkingEntry;
    		}
    	}
    	
    	return lastUpdatedEntry;
    }
    
    // todo: create parent type which has this available!
    function doHarvestTimeEntryPatch(timeEntryId, typeStr) {
    	System.println("patching after load " + typeStr + " time entry: " + timeEntryId);
    	Communications.makeWebRequest(
            "https://httpproxy.now.sh/api",
            {
            	"url" =>"https://api.harvestapp.com/v2/time_entries/"+timeEntryId+"/"+typeStr+"?"+"access_token=5034.pt.Zs6dN9lcB0QYSS0OQgtbuiDGJmU3LBp7mJRS1UvKo2Hxm_LD9gGGs8N-r0lPfhw3AeJMpQvpTSd7wgtdmIOcyQ&account_id=97677",
            	"method"=>"PATCH"
            },
            {
            	:method => Communications.HTTP_REQUEST_METHOD_POST,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:patchCallback)
        );
    }
    
    function patchCallback(responseCode, data) {
    	// this seems to give me an error message!?
    	System.println("patch response code: " + responseCode + " data: " + data);
		makeRequest();
    }
    
    // converts rfc3339 formatted timestamp to Time::Moment (null on error)
function parseISODate(date) {
// assert(date instanceOf String)

// 0123456789012345678901234
// 2011-10-17T13:00:00-07:00
// 2011-10-17T16:30:55.000Z
// 2011-10-17T16:30:55Z
if (date.length() < 20) {
return null;
}

var moment = Gregorian.moment({
:year => date.substring( 0, 4).toNumber(),
:month => date.substring( 5, 7).toNumber(),
:day => date.substring( 8, 10).toNumber(),
:hour => date.substring(11, 13).toNumber(),
:minute => date.substring(14, 16).toNumber(),
:second => date.substring(17, 19).toNumber()
});

var suffix = date.substring(19, date.length());
// skip over to time zone
var tz = 0;
if (suffix.substring(tz, tz + 1).equals(".")) {
while (tz < suffix.length()) {
var first = suffix.substring(tz, tz + 1);
if ("-+Z".find(first) != null) {
break;
}
tz++;
}
}

if (tz >= suffix.length()) {
// no timezone given
return null;
}
var tzOffset = 0;
if (!suffix.substring(tz, tz + 1).equals("Z")) {
// +HH:MM
if (suffix.length() - tz < 6) {
return null;
}
tzOffset = suffix.substring(tz + 1, tz + 3).toNumber() * Gregorian.SECONDS_PER_HOUR;
tzOffset += suffix.substring(tz + 4, tz + 6).toNumber() * Gregorian.SECONDS_PER_MINUTE;

var sign = suffix.substring(tz, tz + 1);
if (sign.equals("+")) {
tzOffset = -tzOffset;
} else if (sign.equals("-") && tzOffset == 0) {
// -00:00 denotes unknown timezone
return null;
}
}
var info = Gregorian.utcInfo(moment, Time.FORMAT_SHORT);
return moment.add(new Time.Duration(tzOffset));
}
}
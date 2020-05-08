//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Communications;
using Toybox.WatchUi;
using Toybox.Time.Gregorian;

class WebRequestDelegate extends WatchUi.BehaviorDelegate {
	var numToRequest = 5; 
    var notify;
    
	var isRunning = false;
	var loaded = false;
	var timeEntryId = 0;
	
	var recentTimeEntries = [0];
	var titleToTimeEntriesDict = {};
    
    var actionOnLoaded = null;
    
    // Set up the callback to the view
    function initialize(handler) {
        WatchUi.BehaviorDelegate.initialize();
        notify = handler;
        
        //makeRequest();
    }

    function makeRequest() {
        notify.invoke("Getting time entries.");
        // this seems to break the app!?
		// Communications.cancelAllRequests();
        Communications.makeWebRequest(
            "https://api.harvestapp.com/v2/time_entries?per_page="+numToRequest+"&access_token=5034.pt.Zs6dN9lcB0QYSS0OQgtbuiDGJmU3LBp7mJRS1UvKo2Hxm_LD9gGGs8N-r0lPfhw3AeJMpQvpTSd7wgtdmIOcyQ&account_id=97677",
            {
            },
            {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            method(:onReceive)
        );
    }

    // Receive the data from the web request
    function onReceive(responseCode, data) {
    	//latest response
    	
    	// todo: check today?
        if (responseCode == 200 && data["time_entries"] != null && data["time_entries"].size() > 0) {
        	loaded = true;
        	recentTimeEntries = data["time_entries"];
	    	var lastUpdatedEntry1 = getLastUpdatedEntry(recentTimeEntries);
	    	var lastUpdatedEntry =lastUpdatedEntry1; 
	    	titleToTimeEntriesDict = getTitleToTimeEntriesDict(recentTimeEntries);
	    
        	//var timeEntry1 = data["time_entries"][0];
        	var projectName = lastUpdatedEntry["project"]["name"];
        	var taskName = lastUpdatedEntry["task"]["name"];
        	isRunning = lastUpdatedEntry["is_running"];
        	timeEntryId = lastUpdatedEntry["id"];
        	var running = "Stopped";
        	if(isRunning) {
        		running = "Running";
        	}
        	
        	var timeStr = getTimeStrFromHourFraction(lastUpdatedEntry["hours"]);
			
			// todo: return early if actionOnLoaded?
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
				var timeToday = getTimeTodayStr(data["time_entries"]);
	        	var message = projectName + "\n" + taskName + "\n" + timeStr + " - " + running + "\nTotal: " + timeToday;
	        	notify.invoke(message);
            }
        } else {
            notify.invoke("Failed to load\nError: " + responseCode.toString() + "\n" + data);
        }
    }
    
    function onSelect() {
		return onMenu();
    }
    
    function onMenu() {
    	if(!loaded) {
    		// special menu while loading!
    		var myMenu = new WatchUi.Menu();
    		// todo: use timeEntryActionDict {action => start/stop}
    		myMenu.addItem("Queue start", :start);
    		// todo: use timeEntryActionDict {action => start/stop}
    		myMenu.addItem("Queue stop", :stop);
	    	WatchUi.pushView(myMenu, new LoadingMenuDelegate(method(:loadingMenuUpdateCallback)), WatchUi.SLIDE_IMMEDIATE);
    	}
    	else {
	    	var myMenu = new WatchUi.Menu();
	    	if(isRunning) {
	    		// todo: use timeEntryActionDict {action => start/stop}
	    		myMenu.addItem("Stop", {
	    			"action" => "stop",
	    			"timeEntry" => { "id" => timeEntryId }
	    		});
	    	}
	    	else {
	    		// todo: use timeEntryActionDict {action => start/stop}
	    		myMenu.addItem("Start", {
	    			"action" => "start",
	    			"timeEntry" => { "id" => timeEntryId }
	    		});
	    	}
	    	
	    	var keys = titleToTimeEntriesDict.keys();
	    	for(var i=0; i<keys.size(); i++) {
	    		// don't include if currently running!?
	    		var timeEntry = titleToTimeEntriesDict.get(keys[i]);
	    		
	    		// update_date takes a while to get set, unfortunately :(
	    		var entryToday = isToday(timeEntry); 
	    		var entryName = keys[i];
	    		var action = "start";
	    		
	    		if(!entryToday) {
	    			entryName = "(+) " + entryName;
	    			action = "create";
	    		}
	    		
	    		var vm = new TimeEntryViewModel();
	    		vm.init(timeEntry);
	    		
	    		var timeEntryActionDict = {
	    			"action" => action,
	    			//"timeEntry" => timeEntry // this might be way to large?
	    			// make sparse instead?
	    			"timeEntry" => {"id"=>timeEntry["id"], "projectId"=>timeEntry["project"]["id"], "taskId"=>timeEntry["task"]["id"]}
	    		};
	    		
	    		// exclude one which matches the timer on the main display
	    		if(timeEntry["id"] != timeEntryId) {
	    			myMenu.addItem(entryName, timeEntryActionDict);
	    		}
	    	}
	    	
	    	WatchUi.pushView(myMenu, new MyMenuDelegate(timeEntryId, method(:updateCallback)), WatchUi.SLIDE_IMMEDIATE);
    	}
    }
    
    function loadingMenuUpdateCallback(startOrStopToken) {
    	System.println("loading menu callback: " + startOrStopToken);
    	actionOnLoaded = startOrStopToken;
    	
    	makeRequest();
    }
    
    function updateCallback(responseCode, data) {
    	System.println("update callback!" + responseCode + ", data: " + data);
    	makeRequest();
    }

    function getTimeStrFromHourFraction(hours) {
		var h = hours.toNumber();
		var bitHour = hours - h;
		var m = (60 * (hours - h)).toNumber();
		
		return Lang.format("$1$:$2$", [h.format("%d"), m.format("%02d")]);
    }
    
    // todo: may need to return 'isRunning' entry instead if there is one!?
    function getLastUpdatedEntry(timeEntries) {
    	var lastUpdatedEntry = timeEntries[0];
    	
    	if(lastUpdatedEntry["is_running"]) {
    		return lastUpdatedEntry;
    	}
    	for(var i=1; i<timeEntries.size(); i++) {
    		var lastUpdateDate = parseISODate(lastUpdatedEntry["updated_at"]);
    		var checkingEntry = timeEntries[i];
    		if(checkingEntry["is_running"]) {
	    		return checkingEntry;
	    	}
    		var checkingDate = parseISODate(checkingEntry["updated_at"]);
    		
    		if(checkingDate.greaterThan(lastUpdateDate)) {
    			lastUpdatedEntry = checkingEntry;
    		}
    	}

    	return lastUpdatedEntry;
    }
    
    function getUtcStr(mo) {
	    var today = Gregorian.info(mo, Time.FORMAT_MEDIUM);
		var dateString = Lang.format(
		    "$1$:$2$:$3$ $4$ $5$ $6$ $7$",
		    [
		        today.hour,
		        today.min,
		        today.sec,
		        today.day_of_week,
		        today.day,
		        today.month,
		        today.year
		    ]
		);
		//System.println(dateString); // e.g. "16:28:32 Wed 1 Mar 2017"
		return dateString;
    }
    
    function getTitleToTimeEntriesDict(timeEntries) {
    	var entriesDict = {};
    	for(var i=0; i<timeEntries.size(); i++) {
    		var projectTitle = timeEntries[i]["project"]["name"] + " - " + timeEntries[i]["task"]["name"];
    		var existingEntry = entriesDict.get(projectTitle);
    		if(existingEntry == null) {
    			entriesDict.put(projectTitle, timeEntries[i]);
    		}
    		else if(parseISODate(existingEntry["updated_at"]).lessThan(parseISODate(timeEntries[i]["updated_at"]))) {
    			entriesDict.put(projectTitle, timeEntries[i]);
    		}
    	}
    	return entriesDict;
    }
    
    function getTimeTodayStr(timeEntries) {
    	var fractionalHours = getFractionalHoursToday(timeEntries);
    	return getTimeStrFromHourFraction(fractionalHours);
    }
    
    function getFractionalHoursToday(timeEntries) {
    	var totalTime = 0.0;
    	for(var i=0; i<timeEntries.size(); i++) {
    		var entry = timeEntries[i];
    		if(isToday(entry)) {
    			totalTime = totalTime + entry["hours"];
    		}
    	}
    	return totalTime;
    }
    
    function isToday(timeEntry) {
    	// today in 2020-05-02 format
    	var nowDateStr = getNowDateStr();
		//System.println("today: '" + nowDateStr + "' TE: '"+ timeEntry["spent_date"] + "' today? " + (nowDateStr.equals(timeEntry["spent_date"])));
		return nowDateStr.equals(timeEntry["spent_date"]);
    }
    
    function getNowDateStr() {
    	var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	return Lang.format(
		    "$1$-$2$-$3$",
		    [ now.year, now.month.format("%02d"), now.day.format("%02d")]
		);
    }
    
    // todo: create parent class which has this available!
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
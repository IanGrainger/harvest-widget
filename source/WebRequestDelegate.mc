//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Communications;
using Toybox.WatchUi;

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
    		return true;
    	}
    	var myMenu = new WatchUi.Menu();
    	if(isRunning) {
    		myMenu.addItem("Stop", :stop);
    	}
    	else {
    		myMenu.addItem("Start", :start);
    	}
    	WatchUi.pushView(myMenu, new MyMenuDelegate(timeEntryId, method(:updateCallback)), WatchUi.SLIDE_IMMEDIATE);
    }
    
    function updateCallback(responseCode, data) {
    	System.println("update callback!" + responseCode + ", data: " + data);
    	makeRequest();
    }

    function makeRequest() {
        notify.invoke("Getting data...");

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
        if (responseCode == 200 && data["time_entries"] != null && data["time_entries"].size() > 0) {
        	loaded = true;
        	// get first result's project and task
        	var timeEntry1 = data["time_entries"][0];
        	var projectName = timeEntry1["project"]["name"];
        	var taskName = timeEntry1["task"]["name"];
        	var hours = timeEntry1["hours"];
        	isRunning = timeEntry1["is_running"];
        	timeEntryId = timeEntry1["id"];
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
			
        	var message = projectName + "\n" + taskName + "\n" + timeStr + " - " + running;
        	notify.invoke(message);
            //notify.invoke(data);
        } else {
            notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }
}
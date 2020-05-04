using Toybox.WatchUi;
using Toybox.Communications;

class MyMenuDelegate extends WatchUi.MenuInputDelegate {
	var timeEntryId;
	var onUpdated;
	
    function initialize(inputTimeEntryId, updateCallback) {
        MenuInputDelegate.initialize();
        timeEntryId = inputTimeEntryId;
        onUpdated = updateCallback;
    }
    
    //item: {"action": "stop" | "start" | "create", "timeEntry": harvest_time_entry}
    function onMenuItem(item) {
    	if(item["action"].equals("stop")) {
    		stop(); 
    	}
		else if(item["action"].equals("start")) {
			startId(item["timeEntry"]["id"]);
		}
		else if(item["action"].equals("create")) {
		System.println("creating");
			createCopyOfTimeEntryTodayViaDuration(item["timeEntry"]);
		}
    }
    
    function stop() {
    	System.println("pausing id " + timeEntryId);
    	doHarvestTimeEntryPatch(timeEntryId, "stop");
    }
    
    function startId(specificTimeEntryId) {
    	System.println("starting specific time entry id " + specificTimeEntryId);
    	doHarvestTimeEntryPatch(specificTimeEntryId, "restart");
    }
    
    function createCopyOfTimeEntryTodayViaDuration(timeEntry) {
    	var projectId = timeEntry["projectId"];
    	var taskId = timeEntry["taskId"]; 
    	var nowDateStr = getNowDateStr();
    	System.println("proj"+projectId+",task"+taskId+",spent"+nowDateStr);
    	// don't set hours - so it'll start a timer with 0.0 hours
    	Communications.makeWebRequest(
            "https://api.harvestapp.com/v2/time_entries/?access_token=5034.pt.Zs6dN9lcB0QYSS0OQgtbuiDGJmU3LBp7mJRS1UvKo2Hxm_LD9gGGs8N-r0lPfhw3AeJMpQvpTSd7wgtdmIOcyQ&account_id=97677",
            {
            	"project_id" => projectId,
            	"task_id" => taskId,
            	"spent_date" => nowDateStr
            },
            {
            	:method => Communications.HTTP_REQUEST_METHOD_POST,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            onUpdated
        );
    }
    
    // todo: copypasta: refactor!
    function getNowDateStr() {
    	var now = Toybox.Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	return Lang.format(
		    "$1$-$2$-$3$",
		    [ now.year, now.month.format("%02d"), now.day.format("%02d")]
		);
    }
    
    // todo: refactor to base as used in two delegates!
    function doHarvestTimeEntryPatch(timeEntryId, typeStr) {
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
            onUpdated
        );
    }
}

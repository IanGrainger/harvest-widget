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
    
    function onMenuItem(item) {
    	System.println("menu item: " + item);
    	if(item == :stop) {
    		stop(); 
    	}
    	else if(item == :start) {
    		startId(timeEntryId);
		}
		else {
			startId(item);
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

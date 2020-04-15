using Toybox.WatchUi;
using Toybox.Communications;

class LoadingMenuDelegate extends WatchUi.MenuInputDelegate {
	var callback;
    function initialize(updateCallback) {
        MenuInputDelegate.initialize();
        callback = updateCallback;
    }
    
    function onMenuItem(item) {
    	if(item == :stop) {
    		stop(); 
    	}
    	if(item == :start) {
    		start();
		}
    }
    
    function stop() {
    	callback.invoke(:stop);
    }
    
    function start() {
    	callback.invoke(:start);
    }
}

class TimeEntryViewModel {
	var Id;
	var ProjectId;
	var TaskId;
	
	function init(timeEntry) {
		Id = timeEntry["id"];
		ProjectId = timeEntry["project"]["id"];
	    TaskId = timeEntry["task"]["id"];		
	}
}
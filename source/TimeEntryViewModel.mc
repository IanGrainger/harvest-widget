class TimeEntryViewModel {
	var Id;
	var ProjectId;
	var TaskId;
	var ProjectName;
	var TaskName;
	var Hours;
	var Name;
	var SpentDate;
	var UpdatedDtStr;
	var IsRunning;
	
	function initBaseFields(timeEntry) {
		Id = timeEntry["id"];
	    Hours = timeEntry["hours"];
	    SpentDate = timeEntry["spent_date"];
	    UpdatedDtStr = timeEntry["updated_at"];
		IsRunning = timeEntry["is_running"];
	    
	    Name = ProjectName + " - " + TaskName;
	}
	
	function init(timeEntry) {
		ProjectId = timeEntry["project"]["id"];
		ProjectName = timeEntry["project"]["name"];
	    TaskId = timeEntry["task"]["id"];
	    TaskName = timeEntry["task"]["name"];
	    
	    initBaseFields(timeEntry);		
	}
	
	function initFromProxy(timeEntry) {
		ProjectId = timeEntry["project.id"];
	    ProjectName = timeEntry["project.name"];
	    TaskId = timeEntry["task.id"];
	    TaskName = timeEntry["task.name"];
	    
	    initBaseFields(timeEntry);
	}
}

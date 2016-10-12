function gettime()
{
	AJAX("?action=gettime", function(response){
		$("#server_time1").text(response.now)
		$("#server_time2").val(response.now)
	})
}

$(document).ready(function() {
	$(".runsh").click(function() {
		AJAX("?action=runsh&argument="+ $(this).data("shell"), function(response){
			tip(response.output)
		})
		return false;
	});

	gettime();

	$("#settime").click(function() {
		AJAX("?action=settime&argument="+ $("#server_time2").val(), function(response){
			tip(response.output);
			gettime();
		})
		return false;
	});
	
	$("#update_chips").click(function() {
		AJAX("?action=update_chips&argument="+ $("#player_rid").val()+","+ $("#chips_count").val(), function(response){
			tip(response.output);
		})
		return false;
	});
});
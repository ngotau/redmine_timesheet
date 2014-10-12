/**
 * @author NGO TAU
 */

$(document).ready(function(){
 var manager_mode = $('#manager_mode').val();
 var simple_mode = $('#simple_mode').val();
 
 //check in
 if($('#checkIn').length){
  $('#checkIn').click(function() {
    var $this = $(this);
    var time = $('#work_on').val();
    $.ajax({
        url: '/timecards/autocomplete_work_on',
        type: 'post',
        data: {it: time,y:$('#y').val(),m:$('#m').val(),d:$('#d').val(),u:$('#u').val()},
        success: function(data){ 
        	var res_arr = data.split("|");
        	var res = res_arr[0];
        	var result = res_arr[1];
        	if (res!="OK"){
        	 alert_box("error",result);
        	}else {
        		if (simple_mode == "1") update_simple_view("On",result);
        		else update_view("On",result);
        		if (manager_mode == "0") disable_check_in();
        	}
        },
        beforeSend: function(){ $this.addClass('ajax-loading'); },
        complete: function(){ $this.removeClass('ajax-loading'); }
        });
   });
 }
 //check out
 if($('#checkOut').length){
   $('#checkOut').click(function() {
    var $this = $(this);
    var time = $('#work_off').val();
    $.ajax({
        url: '/timecards/autocomplete_work_off',
        type: 'post',
        data: {ot: time,y:$('#y').val(),m:$('#m').val(),d:$('#d').val(),u:$('#u').val()},
        success: function(data){ 
        	var res_arr = data.split("|");
        	var res = res_arr[0];
        	var result = res_arr[1];
        	if (res!="OK"){
        	 alert_box("error",result);
        	}else {
        		if (simple_mode == "1") update_simple_view("Off",result);
        		else update_view("Off",result);
        		if (manager_mode == "0") disable_check_out();
        	} 
        },
        beforeSend: function(){ $this.addClass('ajax-loading'); },
        complete: function(){ $this.removeClass('ajax-loading'); }
        });
   });
 }
 //break time
 if($('#breakTime').length){
   $('#breakTime').click(function() {
    var $this = $(this);
    var time = $('#work_break').val();
    $.ajax({
        url: '/timecards/autocomplete_work_break',
        type: 'post',
        data: {bt: time,y:$('#y').val(),m:$('#m').val(),d:$('#d').val(),u:$('#u').val()},
        success: function(data){ 
        	var res_arr = data.split("|");
        	var res = res_arr[0];
        	var result = res_arr[1];
        	if (res!="OK"){
        	 alert_box("error",result);
        	}else {
        		update_view("Break",result);
        	} 
        },
        beforeSend: function(){ $this.addClass('ajax-loading'); },
        complete: function(){ $this.removeClass('ajax-loading'); }
        });
   });
 }
 
 //check if time is input
 $(document).ready(function(){
	 if ($('#work_on').val() == "") {
	 	$("#work_on").focus();
	 	disable_check_out();
	 	alert_box("warning","Please check-in when you come office ");
	 }
	 else if ($('#work_off').val() == "") {
	 	$("#work_off").focus();
	 	alert_box("notice","Please check-out when you leave office ");
	 }
 })
 
 //check if not manager
 if (manager_mode=="0" && $('#work_on').val() != "") {
 	disable_check_in();
 }
 if (manager_mode=="0" && $('#work_off').val() != "") {
 	disable_check_out();
 }
});

function update_simple_view(type,result){
	$('#alert-box').hide();
	//display result
	var r1 = result.split(",");
	time = r1[0] || "";
	if (type == "On") {
		$('#work_on').val(time);
		alert_box("success","Have a nice working day !");
	}
	if (type == "Off") {
		$('#work_off').val(time);
		alert_box("success","Thank you for your hard-working !");
	}
}
//update date
function update_view(type,result) {
	$('#alert-box').hide();
	//display result
	var r1 = result.split(",");
	time = r1[0] || "";
	work_status = r1[1] || "";
	old_work_hours = r1[2] || 0;
	new_work_hours = r1[3] || 0;
	work_lunch = r1[4] || "";
	w_status = $('#this_date_id').val() + "_status";
	w_in = $('#this_date_id').val() + "_in";
	w_out = $('#this_date_id').val() + "_out";
	w_lunch = $('#this_date_id').val() + "_lunch";
	w_break = $('#this_date_id').val() + "_break";
	w_hours = $('#this_date_id').val() + "_hours";
	$('#'+w_hours).text(new_work_hours);
	$('#'+w_lunch).text(work_lunch);
	total_hours = parseFloat($('#total_hours').text());
	if (new_work_hours !="") total_hours = total_hours - parseFloat(old_work_hours) + parseFloat(new_work_hours);
	$('#total_hours').text(total_hours);
	$('#this_work_status').text(work_status);
	if (type == "On") {
		$('#work_on').val(time);
		$('#'+w_in).text(time);
		change_col_status("On",w_status);
		alert_box("success","Have a nice working day !");
	}
	if (type == "Off") {
		$('#work_off').val(time);
		$('#'+w_out).text(time); 
		change_col_status("On",w_status);
		alert_box("success","Thank you for your hard-working !");
	}
	if (type == "Break") { $('#'+w_break).text(time); alert_box("success","Thank you !");}
}

function change_col_status(type,w_status) {
	if (type == "On") type_vs = "Off" ;
	else type_vs = "On";
	var classes = $('#'+w_status).attr('class').split(' ');
	for(var i = 0; i < classes.length; i++) {
  		new_class = classes[i].replace(type_vs, type);
  		$('#'+w_status).removeClass(classes[i]).addClass(new_class);
	}
}

//disable user click 
function disable_check_in(){
	$('#work_on').prop( "disabled", true );
	$("#checkIn").prop('disabled',true);
	$("#checkIn").attr('disabled','disabled');
	$("#checkIn").children().prop('disabled',true);
	$("#checkIn").unbind("click");
}
function disable_check_out(){
	$('#work_off').prop( "disabled", true );
	$("#checkOut").prop('disabled',true);
	$("#checkOut").attr('disabled','disabled');
	$("#checkOut").children().prop('disabled',true);
	$("#checkOut").unbind("click");
}

//initilize page
function init_status(mode,in_time,out_time){
	if (!mode) {
		if (in_time.trim() != "") disable_check_in();
		if (out_time.trim() != "") disable_check_out();
	}
}

//change date function
function changeDate(y,m,d) {
	$('#y').val(y);
	$('#m').val(m);
	$('#d').val(d);
	$("#targetForm" ).submit();
}

//default time
function make_default(target) {
	c_time = $('#current_time').val();
	s = $('#'+target).val();
	if (s.trim() =="") $('#'+target).val(c_time);
}

//display alert box
function alert_box(type,message){
	//remove class first
	$('#alert-box').removeClass("error success warning notice");
	$('#alert-box').addClass(type);
	$('#alert-box-title').text(type);
	$('#alert-box-message').text(message);
	$('#alert-box').show();
}

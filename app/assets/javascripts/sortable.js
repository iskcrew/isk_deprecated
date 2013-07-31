$(document).ready(function() { 
	$("[data-sortable]").sortable({ 
    handle : '.handle', 
    update : function () { 
      var order = $('[data-sortable]').sortable('serialize'); 
      $.ajax({
			        type: "POST",
			        url: $('[data-sortable]').attr('data-sortable'),
			        data: order,
					error:function (xhr, ajaxOptions, thrownError){
						alert("Error updating order, try reloading the page");
					}
			});
			 
    } 
  }); 
});

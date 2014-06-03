$(document).ready(function() { 
	$("[data-sortable]").sortable({ 
	handle : '.handle', 
	update : function (e, ui) { 
		var data = {
			element_id: ui.item.attr('id').split('_').pop(),
			element_position: ui.item.index()
		}
		$.ajax({
					type: "POST",
					url: $('[data-sortable]').attr('data-sortable'),
					data: data,
					error:function (xhr, ajaxOptions, thrownError){
						alert("Error updating order, try reloading the page");
					}
			});
			 
	} 
  }); 
});

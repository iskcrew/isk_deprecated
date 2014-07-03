module MonitorHelper
	def monitor_check_box(obj, name = nil)
		check_box_tag "monitor_#{obj.class.base_class.name.downcase}_#{obj.id}"
	end
end

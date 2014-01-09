#Luodaan mysql-triggereitä timestampeille
warnings;

delimiter //

DROP PROCEDURE IF EXISTS slide_timestamps//
CREATE PROCEDURE slide_timestamps(in mg_id INT)
BEGIN
	update master_groups set master_groups.updated_at = UTC_TIMESTAMP() where master_groups.id = mg_id;
END//

DROP PROCEDURE IF EXISTS master_group_timestamps//
CREATE PROCEDURE master_group_timestamps(in mg_id INT)
BEGIN
	update groups set groups.updated_at = UTC_TIMESTAMP() where groups.master_group_id = mg_id;
END//

DROP PROCEDURE IF EXISTS group_timestamps//
CREATE PROCEDURE group_timestamps(in p_id INT)
BEGIN
	update presentations set presentations.updated_at = UTC_TIMESTAMP() where presentations.id = p_id;
END//

DROP PROCEDURE IF EXISTS presentation_timestamps//
CREATE PROCEDURE presentation_timestamps(in presentation_id INT)
BEGIN
	update displays set displays.updated_at = UTC_TIMESTAMP() where displays.presentation_id = presentation_id;
END//

DROP PROCEDURE IF EXISTS override_queue_timestamps//
CREATE PROCEDURE override_queue_timestamps(in display_id INT)
BEGIN
	update displays set displays.updated_at = UTC_TIMESTAMP() where displays.id = display_id;
END//

DROP TRIGGER IF EXISTS update_slides//
CREATE TRIGGER update_slides BEFORE UPDATE on slides
	FOR EACH ROW BEGIN
		CALL slide_timestamps(OLD.master_group_id);
		CALL slide_timestamps(NEW.master_group_id);
	END;
//

DROP TRIGGER IF EXISTS insert_slides//
CREATE TRIGGER insert_slides AFTER INSERT on slides
	FOR EACH ROW BEGIN
		CALL slide_timestamps(NEW.master_group_id);
	END;
//

DROP TRIGGER IF EXISTS update_master_groups//
CREATE TRIGGER update_master_groups BEFORE UPDATE on master_groups
	FOR EACH ROW BEGIN
		CALL master_group_timestamps(NEW.id);
		CALL master_group_timestamps(OLD.id);
	END;
//

DROP TRIGGER IF EXISTS insert_master_groups//
CREATE TRIGGER insert_master_groups AFTER INSERT on master_groups
	FOR EACH ROW BEGIN
		CALL master_group_timestamps(NEW.id);
	END
//

DROP TRIGGER IF EXISTS update_groups//
CREATE TRIGGER update_groups BEFORE UPDATE on groups
	FOR EACH ROW BEGIN
		CALL group_timestamps(NEW.presentation_id);
		CALL group_timestamps(OLD.presentation_id);
	END;
//

DROP TRIGGER IF EXISTS insert_groups//
CREATE TRIGGER insert_groups AFTER INSERT on groups
	FOR EACH ROW BEGIN
		CALL group_timestamps(NEW.presentation_id);
	END;
//

DROP TRIGGER IF EXISTS update_presentations//
CREATE TRIGGER update_presentations BEFORE UPDATE on presentations
	FOR EACH ROW BEGIN
		CALL presentation_timestamps(OLD.id);
		CALL presentation_timestamps(NEW.id);
	END;
//

DROP TRIGGER IF EXISTS insert_presentations//
CREATE TRIGGER insert_presentations AFTER INSERT on presentations
	FOR EACH ROW BEGIN
		CALL presentation_timestamps(NEW.id);
	END;
//

DROP TRIGGER IF EXISTS update_override_queues//
CREATE TRIGGER update_override_queues BEFORE UPDATE on override_queues
	FOR EACH ROW BEGIN
		CALL override_queue_timestamps(OLD.display_id);
		CALL override_queue_timestamps(NEW.display_id);
	END;
//

DROP TRIGGER IF EXISTS insert_override_queues//
CREATE TRIGGER insert_override_queues AFTER INSERT on override_queues
	FOR EACH ROW BEGIN
		CALL override_queue_timestamps(NEW.display_id);
	END;
//

DROP TRIGGER IF EXISTS delete_override_queues//
CREATE TRIGGER delete_override_queues AFTER DELETE on override_queues
	FOR EACH ROW BEGIN
		CALL override_queue_timestamps(OLD.display_id);
	END;
//
delimiter ;

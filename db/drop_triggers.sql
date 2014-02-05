#Luodaan mysql-triggereitä timestampeille
warnings;

delimiter //

DROP PROCEDURE IF EXISTS slide_timestamps//
DROP PROCEDURE IF EXISTS master_group_timestamps//
DROP PROCEDURE IF EXISTS group_timestamps//
DROP PROCEDURE IF EXISTS presentation_timestamps//
DROP PROCEDURE IF EXISTS override_queue_timestamps//
DROP TRIGGER IF EXISTS update_slides//
DROP TRIGGER IF EXISTS insert_slides//
DROP TRIGGER IF EXISTS update_master_groups//
DROP TRIGGER IF EXISTS insert_master_groups//
DROP TRIGGER IF EXISTS update_groups//
DROP TRIGGER IF EXISTS insert_groups//
DROP TRIGGER IF EXISTS update_presentations//
DROP TRIGGER IF EXISTS insert_presentations//
DROP TRIGGER IF EXISTS update_override_queues//
DROP TRIGGER IF EXISTS insert_override_queues//
DROP TRIGGER IF EXISTS delete_override_queues//
delimiter ;

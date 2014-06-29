# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Effects for using with displays, the id's are part of the communication protocol.

effects = [
	[1, 'Normal', 'Default transition effect'],
	[2, 'Subtle', 'Subtle transiton effect'],
	[3, 'Alert',	'Attention seeking effect for alerts']
]

effects.each do |e|
	eff = Effect.where(id: e.first).first_or_initialize
	eff.name = e[1]
	eff.description = e.last
	eff.save!
	puts "Created effect #{e[1]} with id #{eff.id}"
end

# Roles

roles = [
	['slide-hide', 'Can hide any slide.'],
	['display-override', 'Can add slides to override queue on any display.']
]

models = [
	Slide,
	MasterGroup,
	Presentation,
	Display,
	User,
	Ticket
].each do |m|
	roles << [
		"#{m.base_class.name.downcase}-admin",
		"Full control for #{m.base_class.name.downcase.pluralize}"
	]
	roles << [
		"#{m.base_class.name.downcase}-create",
		"Can create new #{m.base_class.name.downcase.pluralize}"
	]
end

roles.each do |r|
	role = Role.where(role: r.first).first_or_initialize
	role.description = r.last
	role.save
	puts "Created role #{r.first} (#{r.last}) with id #{role.id}"	
end

# Create default event if needed
if Event.where(current: true).count != 1
	e = Event.new
	e.name = "Default ISK event"
	e.current = true
	e.save!
	puts "Created new default event #{e.name} id #{e.id}"
end

# Create admin account
if User.where(username: 'admin').count != 1
	u = User.new
	u.username = 'admin'
	u.password = 'admin'
	u.save!
	puts "Created admin user (username: admin, password: admin)"
end
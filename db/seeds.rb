# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

MasterGroup.create(:name => "Ungrouped slides", :id => 1)
Effect.create(:name => "Random", :description => "Chooses random effect for each transition", :id => 1)
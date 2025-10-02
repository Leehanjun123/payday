#!/usr/bin/env ruby
# Script to add GoogleService-Info.plist to Xcode project

require 'xcodeproj'

# Open the project
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Runner' }

# Find the Runner group
runner_group = project.main_group.groups.find { |g| g.name == 'Runner' }

# Check if GoogleService-Info.plist already exists in project
existing_file = runner_group.files.find { |f| f.name == 'GoogleService-Info.plist' }

if existing_file
  puts "GoogleService-Info.plist already exists in project"
else
  # Add the file reference
  file_ref = runner_group.new_reference('GoogleService-Info.plist')

  # Add to all build phases
  target.resources_build_phase.add_file_reference(file_ref)

  puts "Successfully added GoogleService-Info.plist to Xcode project"
end

# Save the project
project.save

puts "Project saved successfully!"
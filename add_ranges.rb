require 'xcodeproj'

project_path = 'Cutoff.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Find the group
ranges_group = project.main_group.find_subpath(File.join('Cutoff', 'Resources', 'Ranges'), true)
ranges_group.set_source_tree('<group>')

# Get all json files
dir_path = 'Cutoff/Resources/Ranges'
files = Dir.glob("#{dir_path}/*.json")

files.each do |file|
  basename = File.basename(file)
  # Check if file is already in group
  unless ranges_group.files.any? { |f| f.path == basename }
    file_ref = ranges_group.new_file(basename)
    target.resources_build_phase.add_file_reference(file_ref)
  end
end

project.save
puts "Added files to Xcode project."

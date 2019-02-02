# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"
has_app_changes = !git.modified_files.grep(/Classes/).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

# Changelog entries are required for changes to library files.
no_changelog_entry = !git.modified_files.include?("CHANGELOG.md")
if has_app_changes && no_changelog_entry && !declared_trivial
  warn("Any changes to library code should be reflected in the CHANGELOG. Please consider adding a note there about your change.")
end

# Added (or removed) library files need to be added (or removed) from the
# Carthage Xcode project to avoid breaking things for our Carthage users.
added_library_files = !(git.added_files.grep(/Classes.*\.{h,m,swift}/).empty?)
deleted_library_files = !(git.deleted_files.grep(/Classes.*\.{h,m,swift}/).empty?)
modified_carthage_xcode_project = !(git.modified_files.grep(/Lumberjack\.xcodeproj/).empty?)
if (added_library_files || deleted_library_files) && !modified_carthage_xcode_project
  fail("Added or removed library files require the Carthage Xcode project to be updated.")
end

# Warn when library files has been updated but not tests.
tests_updated = !git.modified_files.grep(/Tests/).empty?
if has_app_changes && !tests_updated
  warn("The library files were changed, but the tests remained unmodified. Consider updating or adding to the tests to match the library changes.")
end

# Run SwiftLint
swiftlint.lint_files "Classes/*.swift"

# Check if Carthage modified and CocoaPods didn't or vice-versa
modified_cocoapods = !(git.modified_files.grep(/CocoaLumberjack\.podspec/).empty?)
if modified_carthage_xcode_project && !modified_cocoapods
  warn("The Carthage project was modified but CocoaPods podspec wasn't. Did you forget to update the podspec?")
end
if !modified_carthage_xcode_project && modified_cocoapods
  warn("The CocoaPods podspec was modified but the Carthage project wasn't. Did you forget to update the xcodeproj?")
end

# Check xcodeproj settings are not changed
# Check to see if any of our project files contains a line with "SOURCE_ROOT" which indicates that the file isn't in sync with Finder.
accepted_settings = [
"APPLICATION_EXTENSION_API_ONLY",
"ASSETCATALOG_COMPILER_APPICON_NAME",
"ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME",
"ATTRIBUTES",
"CODE_SIGN_IDENTITY",
"COMBINE_HIDPI_IMAGES",
"FRAMEWORK_VERSION",
"GCC_PRECOMPILE_PREFIX_HEADER",
"GCC_PREFIX_HEADER",
"IBSC_MODULE",
"INFOPLIST_FILE",
"MODULEMAP_FILE",
"PRIVATE_HEADERS_FOLDER_PATH",
"PRODUCT_BUNDLE_IDENTIFIER",
"PRODUCT_NAME",
"PUBLIC_HEADERS_FOLDER_PATH",
"SDKROOT",
"SUPPORTED_PLATFORMS",
"TARGETED_DEVICE_FAMILY",
"WRAPPER_EXTENSION"
]

if modified_carthage_xcode_project
  ["Lumberjack.xcodeproj/project.pbxproj"].each do |project_file|
    next unless File.file?(project_file)
    File.readlines(project_file).each_with_index do |line, index|
	  if line.include?("sourceTree = SOURCE_ROOT;") and line.include?("PBXFileReference")
        warn("Files should be in sync with project structure", file: project_file, line: index+1)
	  end
	  line_containing_setting = line.match(/[A-Z_]+ = .*;/)
	  if line_containing_setting
	    setting = line_containing_setting[0].split(' = ')[0]
	    if !accepted_settings.include?(setting)
	      warn("Xcode settings need to remain in Configs/*.xcconfig. Please move " + setting + " to the xcconfig file")
	    end
	  end
	end
  end
end


# Check Copyright
source_copyright_lines = [
"// Software License Agreement (BSD License)",
"//",
"// Copyright (c) 2010-2019, Deusty, LLC",
"// All rights reserved.",
"//",
"// Redistribution and use of this software in source and binary forms,",
"// with or without modification, are permitted provided that the following conditions are met:",
"//",
"// * Redistributions of source code must retain the above copyright notice,",
"//   this list of conditions and the following disclaimer.",
"//",
"// * Neither the name of Deusty nor the names of its contributors may be used",
"//   to endorse or promote products derived from this software without specific",
"//   prior written permission of Deusty, LLC."
]

demos_copyright_lines = [
"//",
"//  ",
"//  ",
"//",
"//  CocoaLumberjack Demos",
"//"
]

benchmarking_copyright_lines = [
"//",
"//  ",
"//  ",
"//",
"//  CocoaLumberjack Benchmarking",
"//"
]

# sourcefiles_to_check = Dir.glob("*/*/*") # uncomment when we want to test all the files (locally)

sourcefiles_to_check = (git.modified_files + git.added_files).uniq
invalid_copyright = false
sourcefiles_to_check.each do |sourcefile|
  fileExtension = File.extname(sourcefile)
  next unless (fileExtension===".swift" or fileExtension===".h" or fileExtension===".m")
  next unless File.file?(sourcefile)

  # Use correct copyright lines depending on source file location
  copyright_lines = source_copyright_lines
  if sourcefile.start_with?("Demos/") and not sourcefile.include?("/Vendor/") and not sourcefile.include?("/FMDB/")
    copyright_lines = demos_copyright_lines
  elsif sourcefile.start_with?("Benchmarking/")
    copyright_lines = benchmarking_copyright_lines
  end
  File.readlines(sourcefile)[0..copyright_lines.count-1].each_with_index do |line, index|
    if !line.include?(copyright_lines[index])
      invalid_copyright = true
      markdown("Invalid copyright: " + sourcefile)
      break
    end
  end
end
if invalid_copyright === true
  warn("Copyright is not valid. See our default copyright in all of our files (Classes, Demos and Benchmarking use different formats).")
end
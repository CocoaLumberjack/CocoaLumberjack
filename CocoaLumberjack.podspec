class Sources
  def self.name
    ''
  end

  def self.root
    "Sources/#{self.name}"
  end

  def self.implementation_files
    [self.root]
  end

  def self.public_headers
    ["#{self.root}/include/*.{h}", "#{self.root}/Supporting Files/*.{h}"]
  end

  def self.private_headers
    []
  end

  def self.source_files
    self.implementation_files + self.public_headers + self.private_headers
  end

  def self.inspection
    return {
      "name" => self.name,
      "root" => self.root,
      "implementation_files" => self.implementation_files,
      "public_headers" => self.public_headers,
      "private_headers" => self.private_headers,
      "source_files" => self.source_files,
    }
  end

  class Core < Sources
    def self.name
      'CocoaLumberjack'
    end

    def self.implementation_files
      ['DD*.{m}', 'Extensions/*.{m}', 'CLI/*.{m}'].map {|x| "#{self.root}/#{x}"}
    end

    def self.private_headers
      ['DD*Internal.{h}'].map {|x| "#{self.root}/#{x}"}
    end
  end

  class Swift < Sources
    def self.name
      'CocoaLumberjackSwift'
    end

    def self.implementation_files
      super.map {|x| "#{x}/*.swift"}
    end

    def self.public_headers
      ["#{self.root}/Supporting Files/*.{h}", 'Sources/CocoaLumberjackSwiftSupport/include/SwiftLogLevel.{h}']
    end
  end
end

require 'pp'

pp Sources::Core.inspection
pp Sources::Swift.inspection

Pod::Spec.new do |s|

  s.name     = 'CocoaLumberjack'
  s.version  = '3.5.3'
  s.license  = 'BSD'
  s.summary  = 'A fast & simple, yet powerful & flexible logging framework for Mac and iOS.'
  s.homepage = 'https://github.com/CocoaLumberjack/CocoaLumberjack'
  s.author   = { 'Robbie Hanson' => 'robbiehanson@deusty.com' }
  s.source   = { :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git',
                 :tag => "#{s.version}" }

  s.description = 'It is similar in concept to other popular logging frameworks such as log4j, '   \
                  'yet is designed specifically for objective-c, and takes advantage of features ' \
                  'such as multi-threading, grand central dispatch (if available), lockless '      \
                  'atomic operations, and the dynamic nature of the objective-c runtime.'

  s.requires_arc   = true

  s.preserve_paths = 'README.md'

  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.10'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target    = '9.0'
  s.swift_version = '5.0'

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files         = Sources::Core.source_files#'Sources/CocoaLumberjack/DD*.{m}', 'Sources/CocoaLumberjack/Extensions/*.{m}', 'Sources/CocoaLumberjack/CLI/*.{m}', 'Sources/CocoaLumberjack/DD*Internal.{h}', 'Sources/CocoaLumberjack/include/*.{h}', 'Sources/CocoaLumberjack/Supporting Files/*.{h}'
    ss.private_header_files = Sources::Core.private_headers#'Sources/CocoaLumberjack/DD*Internal.{h}'
    ss.public_header_files  = Sources::Core.public_headers#'Sources/CocoaLumberjack/include/*.{h}', 'Sources/CocoaLumberjack/Supporting Files/*.{h}'
  end

  s.subspec 'Swift' do |ss|
    ss.dependency 'CocoaLumberjack/Core'
    ss.source_files        = Sources::Swift.source_files#'Sources/CocoaLumberjackSwift/*.swift', 'Sources/CocoaLumberjackSwift/Supporting Files/*.{h}', 'Sources/CocoaLumberjackSwiftSupport/include/*.{h}',
    ss.public_header_files = Sources::Swift.public_headers#'Sources/CocoaLumberjackSwift/Supporting Files/*.{h}', 'Sources/CocoaLumberjackSwiftSupport/include/*.{h}'
  end

end

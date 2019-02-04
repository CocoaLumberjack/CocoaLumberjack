
Pod::Spec.new do |s|

  s.name     = 'CocoaLumberjack'
  s.version  = '3.5.1'
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
  s.swift_version = '4.2'

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files         = 'Classes/CocoaLumberjack.h', 'Classes/DD*.{h,m}', 'Classes/Extensions/*.{h,m}', 'Classes/CLI/*.{h,m}'
    ss.private_header_files = 'Classes/DD*Internal.{h}'
  end

  s.subspec 'Swift' do |ss|
    ss.dependency 'CocoaLumberjack/Core'
    ss.source_files        = 'Classes/CocoaLumberjack.swift', 'Classes/DDAssert.swift', 'Classes/SwiftLogLevel.h'
  end

end

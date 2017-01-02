
Pod::Spec.new do |s|

  s.name     = 'CocoaLumberjack'
  s.version  = '3.0.0'
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

  s.preserve_paths = 'README.md', 'Classes/CocoaLumberjack.swift', 'Framework/Lumberjack/CocoaLumberjack.modulemap'
  
  s.ios.deployment_target     = '5.0'
  s.osx.deployment_target     = '10.7'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'

  s.default_subspecs = 'Default', 'Extensions'

  s.subspec 'Default' do |ss|
    ss.source_files         = 'Classes/CocoaLumberjack.h', 'Classes/DD*.{h,m}'
    ss.public_header_files  = 'Classes/CocoaLumberjack.h', 'Classes/DD*.h'
  end

  s.subspec 'Core' do |ss|
    ss.source_files         = 'Classes/DD*.{h,m}'
    ss.public_header_files  = 'Classes/DD*.h'
  end

  s.subspec 'Extensions' do |ss|
    ss.dependency 'CocoaLumberjack/Default'
    ss.source_files         = 'Classes/Extensions/*.{h,m}'
    ss.public_header_files  = 'Classes/Extensions/*.h'
  end
  
  s.subspec 'CLI' do |ss|
    ss.osx.deployment_target    = '10.7'
    ss.osx.dependency 'CocoaLumberjack/Default'
    ss.osx.source_files         = 'Classes/CLI/*.{h,m}'
    ss.osx.public_header_files  = 'Classes/CLI/*.h'
  end

  s.subspec 'Swift' do |ss|
    ss.ios.deployment_target      = '8.0'
    ss.osx.deployment_target      = '10.10'
    ss.watchos.deployment_target  = '2.0'
    ss.tvos.deployment_target     = '9.0'
    ss.dependency 'CocoaLumberjack/Default'
    ss.source_files               = 'Classes/CocoaLumberjack.swift'
  end
  
end

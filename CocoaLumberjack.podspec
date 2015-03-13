
Pod::Spec.new do |s|

  s.name     = 'CocoaLumberjack'
  s.version  = '2.0.0'
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

  s.preserve_paths = 'README.md', 'Classes/CocoaLumberjack.{swift,modulemap}'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  
  s.public_header_files = 'Classes/*.h'
  
  s.default_subspecs = 'Default', 'Extensions'

  s.subspec 'Default' do |ss|
    ss.source_files = 'Classes/CocoaLumberjack.{h,m}'
    ss.dependency 'CocoaLumberjack/Core'
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'Classes/DD*.{h,m}'
  end

  s.subspec 'Extensions' do |ss|
    ss.source_files = 'Classes/Extensions/*.{h,m}'
    ss.dependency 'CocoaLumberjack/Default'
  end
  
  s.subspec 'CLI' do |ss|
      ss.source_files = 'Classes/CLI/*.{h,m}'
      ss.dependency 'CocoaLumberjack/Default'
  end
  
end


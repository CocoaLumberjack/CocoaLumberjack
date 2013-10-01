Pod::Spec.new do |s|
  s.name     = 'CocoaLumberjack'
  s.version  = '1.6.2'
  s.license  = 'BSD'
  s.summary  = 'A fast & simple, yet powerful & flexible logging framework for Mac and iOS.'
  s.homepage = 'https://github.com/robbiehanson/CocoaLumberjack'
  s.author   = { 'Robbie Hanson' => 'robbiehanson@deusty.com' }
  s.source   = { :git => 'https://github.com/robbiehanson/CocoaLumberjack.git',
                 :tag => "#{s.version}" }

  s.description = 'It is similar in concept to other popular logging frameworks such as log4j, '   \
                  'yet is designed specifically for objective-c, and takes advantage of features ' \
                  'such as multi-threading, grand central dispatch (if available), lockless '      \
                  'atomic operations, and the dynamic nature of the objective-c runtime.'

  s.requires_arc   = true
  s.ios.platform   = :ios, '5.0'
  s.osx.platform   = :osx, '10.7'
  s.source_files   = 'Lumberjack/**/*.{h,m}'
  s.preserve_paths = 'Lumberjack/**/README*'
end

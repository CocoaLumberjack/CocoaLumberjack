Pod::Spec.new do |s|
  s.name     = 'CocoaLumberjack'
  s.version  = '3.8.0'
  s.license  = 'BSD'
  s.summary  = 'A fast & simple, yet powerful & flexible logging framework for macOS, iOS, tvOS and watchOS.'
  s.authors  = { 'Robbie Hanson' => 'robbiehanson@deusty.com' }
  s.homepage = 'https://github.com/CocoaLumberjack/CocoaLumberjack'
  s.source   = { :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git',
                 :tag => "#{s.version}" }

  s.description = 'It is similar in concept to other popular logging frameworks such as log4j, '   \
                  'yet is designed specifically for objective-c, and takes advantage of features ' \
                  'such as multi-threading, grand central dispatch (if available), lockless '      \
                  'atomic operations, and the dynamic nature of the objective-c runtime.'

  s.cocoapods_version = '>= 1.7.0'
  s.swift_versions = ['5.5', '5.6', '5.7']

  s.osx.deployment_target     = '10.13'
  s.ios.deployment_target     = '11.0'
  s.tvos.deployment_target    = '11.0'
  s.watchos.deployment_target = '4.0'

  s.preserve_paths = 'README.md', 'LICENSE', 'CHANGELOG.md'

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files         = 'Sources/CocoaLumberjack/**/*.{h,m}'
    ss.private_header_files = 'Sources/CocoaLumberjack/DD*Internal.{h}'
  end

  s.subspec 'Swift' do |ss|
    ss.dependency 'CocoaLumberjack/Core'
    ss.source_files = 'Sources/CocoaLumberjackSwift/**/*.swift', 'Sources/CocoaLumberjackSwiftSupport/include/**/*.{h}'
  end
end

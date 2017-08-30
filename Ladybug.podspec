Pod::Spec.new do |spec|
    spec.name             = 'Ladybug'
    spec.version          = '2.0.0'
    spec.license          = { :type => 'MIT' }
    spec.homepage         = 'https://github.com/jhurray/Ladybug'
    spec.authors          = { 'Jeff Hurray' => 'jhurray33@gmail.com' }
    spec.summary          = 'A powerful model framework for Swift 4'
    spec.source           = { :git => 'https://github.com/jhurray/Ladybug.git', :tag => spec.version.to_s }
    spec.source_files     = 'Source/**/*.swift', 'Frameworks/Ladybug.h'
    spec.social_media_url = 'https://twitter.com/jeffhurray'
    spec.platform     = :ios, '8.0'
    spec.requires_arc = true
    spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
    spec.requires_arc     = true
end

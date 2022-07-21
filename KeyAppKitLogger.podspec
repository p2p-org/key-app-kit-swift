Pod::Spec.new do |s|
  s.name             = 'KeyAppKitLogger'
  s.version          = '1.0.7'
  s.summary          = 'Logger for p2p wallet.'

  s.description      = <<-DESC
  LoggerService for p2p wallet.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/key-app-kit-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chung Tran' => 'chung.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/key-app-kit-swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/KeyAppKitLogger/**/*'
  s.swift_version = '5.5'

  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
end

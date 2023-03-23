Pod::Spec.new do |s|
  s.name             = 'Onboarding'
  s.version          = '1.0.0'
  s.summary          = 'A bridge between swift and js'

  s.description      = <<-DESC
  A magic client for Solana.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/key-app-kit-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tran Giang Long' => 'gianglong.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/key-app-kit-swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/Onboarding/**/*'
  s.swift_version = '5.5'
  s.resources = "Sources/Onboarding/Resource/**/*"
  s.dependency 'JSBridge'
  s.dependency 'SolanaSwift', '~> 3'
  s.dependency 'CryptoSwift', '~> 1.6.0'
  s.dependency "KeyAppKitCore"
  s.dependency "AnalyticsManager"
  
  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
end

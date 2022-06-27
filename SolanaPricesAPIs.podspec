Pod::Spec.new do |s|
  s.name             = 'SolanaPricesAPIs'
  s.version          = '1.0.0'
  s.summary          = 'Prices api client for Solana.'

  s.description      = <<-DESC
 Prices api client for Solana.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/key-app-kit-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tran Giang Long' => 'gianglong.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/key-app-kit-swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/SolanaPricesAPIs/**/*'
  s.swift_version = '5.5'
  s.dependency 'Cache'
  s.dependency 'SolanaSwift', '~> 2'

  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
end

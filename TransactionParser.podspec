Pod::Spec.new do |s|
  s.name             = 'TransactionParser'
  s.version          = '1.0.0'
  s.summary          = 'A magic client for Solana.'

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

  s.source_files = 'Sources/TransactionParser/**/*'
  s.swift_version = '5.5'

  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }

  s.dependency 'SolanaSwift', '~> 2'
  s.dependency 'Cache'
end

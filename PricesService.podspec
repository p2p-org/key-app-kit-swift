Pod::Spec.new do |s|
  s.name             = 'PricesService'
  s.version          = '1.0.0'
  s.summary          = 'PricesService for p2p wallet.'

  s.description      = <<-DESC
      PricesService for p2p wallet.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/solana-swift-magic'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chung Tran' => 'chung.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/solana-swift-magic.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/PricesService/**/*'
  s.swift_version = '5.5'

  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
end

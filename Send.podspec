Pod::Spec.new do |s|
  s.name             = 'Send'
  s.version          = '1.0.0'
  s.summary          = 'KeyApp Send kit'

  s.description      = <<-DESC
  A magic client for Solana.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/key-app-kit-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tran Giang Long' => 'gianglong.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/key-app-kit-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/Send/**/*'
  s.dependency 'NameService'
  s.dependency 'SolanaSwift', '~> 3'
  s.dependency 'SolanaPricesAPIs'
  s.dependency 'History'
  s.dependency 'TransactionParser'
  s.dependency 'FeeRelayerSwift'

  s.swift_version = '5.5'

  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
end

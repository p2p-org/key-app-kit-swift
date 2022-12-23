Pod::Spec.new do |s|
  s.name             = 'Sell'
  s.version          = '1.0.0'
  s.summary          = 'KeyApp Sell kit'

  s.description      = <<-DESC
  A magic client for Solana.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/key-app-kit-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chung tran' => 'chung.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/key-app-kit-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/Sell/**/*'

  s.swift_version = '5.5'

  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
end

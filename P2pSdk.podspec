Pod::Spec.new do |s|
  s.name             = 'P2pSdk'
  s.version          = '1.0.0'
  s.summary          = 'A library in rust'

  s.description      = <<-DESC
  A magic client for Solana.
                       DESC

  s.homepage         = 'https://github.com/p2p-org/key-app-kit-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tran Giang Long' => 'gianglong.t@p2p.org' }
  s.source           = { :git => 'https://github.com/p2p-org/key-app-kit-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = "Frameworks/p2p.xcframework/**/*"
  s.vendored_frameworks = "p2p.xcframework"
  s.swift_version = '5.5'
end

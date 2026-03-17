Pod::Spec.new do |s|
  s.name             = 'meta_dat'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin wrapping the Meta Wearables DAT iOS SDK.'
  s.description      = <<-DESC
A Flutter plugin that wraps the Meta Wearables Device Access Toolkit (DAT) iOS SDK,
enabling Flutter apps to build hands-free wearable experiences with Meta AI glasses.
                       DESC
  s.homepage         = 'https://github.com/chrisstayte/dart-meta-dat'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chris Stayte' => 'chris@stayte.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.0'
  s.swift_version    = '5.0'
end

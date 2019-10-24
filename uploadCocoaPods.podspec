Pod::Spec.new do |s|
  s.name                = 'uploadCocoaPods'
  s.version             = '1.0.2'
  s.summary             = 'uplodCocoaPods'
  s.homepage            = 'https://github.com/fanshengle/uploadCocoaPods'
  s.license             = 'MIT'
  s.author              = { 'fanshengle' => '1316838962@qq.com' }
  s.platform            = :ios, '7.0'
  s.source              = { :git => 'https://github.com/fanshengle/uploadCocoaPods.git', :tag => '1.0.2' }
  s.source_files  	= 'uploadCocoaPods/**/*'
  s.requires_arc        = true
end

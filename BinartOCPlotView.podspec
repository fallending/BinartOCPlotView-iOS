Pod::Spec.new do |s|
  s.name         = "BinartOCPlotView"
  s.version      = "0.1.0"
  s.summary      = "A hardware-accelerated audio visualization view using EZAudio, inspired by ZLHistogramAudioPlot."
  s.description  = <<-DESC
  A hardware-accelerated audio visualization view using EZAudio, inspired by ZLHistogramAudioPlot.
    DESC
  s.homepage     = "https://github.com/fallending/BinartOCPlotView-iOS"
  s.screenshots  = "https://raw.githubusercontent.com/zhxnlai/ZLHistogramAudioPlot/master/Previews/ZLHistogramAudioPlotBuffer.gif"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "fallen ink" => "fengzilijie@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/fallending/BinartOCPlotView-iOS.git", :tag => "0.0.1" }
  s.source_files = "BinartOCPlotView/*.{h,m}"
  s.frameworks   = "UIKit", "Accelerate"
  s.requires_arc = true
end

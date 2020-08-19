//
//  MRBarChartAudioPlot.h
//  MurmurReborn
//
//  Created by Zhixuan Lai on 8/2/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

#import "BAAudioPlot.h"

typedef enum : NSUInteger {
    BABarAudioPlotAlignmentBottom,
    BABarAudioPlotAlignmentCenter,
} BABarAudioPlotAlignment;

@interface BABarAudioPlot : BAAudioPlot

@property (nonatomic) BABarAudioPlotAlignment alignment;
@property (nonatomic) BOOL displayWaving; // rolling 的第二种模式
@property (nonatomic) CGFloat barMinHeight;

/// The upper bound of the frequency range the audio plot will display. Default:
/// 10000Hz
@property (nonatomic) float maxFrequency;

/// The lower bound of the frequency range the audio plot will display. Default:
/// 1200Hz
@property (nonatomic) float minFrequency;

/// The number of bins in the audio plot. Default: 30
@property (nonatomic) NSUInteger numOfBins;

/// The padding of each bin in percent width. Default: 0.1
@property (nonatomic) CGFloat padding;

/// The gain applied to the height of each bin. Default: 10
@property (nonatomic) CGFloat gain;

/// A float that specifies the vertical gravitational acceleration applied to
/// each bin. Default: 10 pixel/sec^2
@property (nonatomic) float gravity;

/// The color of all bins in the audio plot.
@property (strong, nonatomic) UIColor *color;

/// An array of color objects defining the color of each bin in the audio plot.
/// If not set, the color attribute will be used instead. Currently only
/// supported by plot type EZPlotTypeBuffer.
@property (strong, nonatomic) NSArray *colors;

@end

//
//  MRBarChartAudioPlot.m
//  MurmurReborn
//
//  Created by Zhixuan Lai on 8/2/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

#import "BABarAudioPlot.h"
#import <Accelerate/Accelerate.h>
//#import "EZAudio.h"

const UInt32 kMaxFrames = 2048;
const Float32 kAdjust0DB = 1.5849e-13;
const NSInteger kFrameInterval = 1; // Alter this to draw more or less often

@interface BABarAudioPlot () {
    // ftt setup
    FFTSetup fftSetup;
    COMPLEX_SPLIT A;
    int log2n, n, nOver2;
    float sampleRate, *dataBuffer;
    size_t bufferCapacity, index;

    // buffers
    float *heightsByFrequency, *speeds, *times, *tSqrts, *vts, *deltaHeights;
}

@property (strong, nonatomic) NSMutableArray *heightsByTime;
@property (strong, nonatomic) CADisplayLink *displaylink;

@end

@implementation BABarAudioPlot

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup:frame];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self layoutIfNeeded];
    [self setup:self.frame];
}

- (void)setup:(CGRect)frame {
    // default attributes
    self.maxFrequency = 10000;
    self.minFrequency = 2000;
    self.barMinHeight = 4;
    self.numOfBins = 15;
    self.padding = 1 / 10.0;
    self.gain = 4;
    self.gravity = 10;
    self.color = [UIColor lightGrayColor];
    self.colors = @[
        [UIColor lightGrayColor],
        [UIColor lightGrayColor],
        [UIColor lightGrayColor],
        [UIColor lightGrayColor],
        [UIColor lightGrayColor],
        [UIColor lightGrayColor],
        [UIColor lightGrayColor],
    ];

    // ftt setup
    dataBuffer = (float *)malloc(kMaxFrames * sizeof(float));
    log2n = log2f(kMaxFrames);
    n = 1 << log2n;
    assert(n == kMaxFrames);
    nOver2 = kMaxFrames / 2;
    bufferCapacity = kMaxFrames;
    index = 0;
    A.realp = (float *)malloc(nOver2 * sizeof(float));
    A.imagp = (float *)malloc(nOver2 * sizeof(float));
    fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);

    // inherited properties
    self.plotType = BAPlotTypeRolling;
    self.alignment = BABarAudioPlotAlignmentCenter;
    self.displayWaving = YES;

    // configure audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    sampleRate = session.sampleRate;

    // start timer
    self.displaylink =
        [CADisplayLink displayLinkWithTarget:self
                                    selector:@selector(updateHeights)];
    self.displaylink.frameInterval = kFrameInterval;
    [self.displaylink addToRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSRunLoopCommonModes];
}

- (void)dealloc {
    [self.displaylink invalidate];
    self.displaylink = nil;
    if (plotData) {
        free(plotData);
    }
    [self freeBuffersIfNeeded];
}

#pragma mark - Properties
- (void)setNumOfBins:(NSUInteger)someNumOfBins {
    _numOfBins = MAX(1, someNumOfBins);

    // reset buffers
    [self freeBuffersIfNeeded];

    // create buffers
    heightsByFrequency = (float *)calloc(sizeof(float), _numOfBins);
    speeds = (float *)calloc(sizeof(float), _numOfBins);
    times = (float *)calloc(sizeof(float), _numOfBins);
    tSqrts = (float *)calloc(sizeof(float), _numOfBins);
    vts = (float *)calloc(sizeof(float), _numOfBins);
    deltaHeights = (float *)calloc(sizeof(float), _numOfBins);
    self.heightsByTime = [NSMutableArray arrayWithCapacity:_numOfBins];
    for (int i = 0; i < _numOfBins; i++) {
        self.heightsByTime[i] = [NSNumber numberWithFloat:self.barMinHeight];
    }
}

#pragma mark - Timer Callback
- (void)updateHeights {
    
    // 随机序列发生器
    if (kBAPlotEnableMockMode) {
        // 振幅 amplitude
        const double amplitude = ((float)rand() / RAND_MAX) * 0.8; // 0~2
        static double theta = 0.0;
        double thetaIncrement = 2.0 * M_PI * 880.0 / 44100.0;
        NSUInteger inNumberFrames = 512;
        float *buffer = malloc(sizeof(float)*inNumberFrames);
        
        // Generate the samples
        for (UInt32 frame = 0; frame < inNumberFrames; frame ++) {
            buffer[frame] = sin(theta) * amplitude;

            theta += thetaIncrement;

            if (theta >= 2.0 * M_PI) {
                theta -= 2.0 * M_PI;
            }
        }

        [self updateBuffer:buffer withBufferSize:(UInt32)inNumberFrames];
        
        free(buffer);
        buffer = nil;

    }
    // delay from last frame
    float delay = self.displaylink.duration * self.displaylink.frameInterval;

    // increment time
    vDSP_vsadd(times, 1, &delay, times, 1, _numOfBins);

    // clamp time
    static const float timeMin = 1.5, timeMax = 10;
    vDSP_vclip(times, 1, &timeMin, &timeMax, times, 1, _numOfBins);

    // increment speed
    float g = self.gravity * delay;
    vDSP_vsma(times, 1, &g, speeds, 1, speeds, 1, _numOfBins);

    // increment height
    vDSP_vsq(times, 1, tSqrts, 1, _numOfBins);
    vDSP_vmul(speeds, 1, times, 1, vts, 1, _numOfBins);
    float aOver2 = g / 2;
    vDSP_vsma(tSqrts, 1, &aOver2, vts, 1, deltaHeights, 1, _numOfBins);
    vDSP_vneg(deltaHeights, 1, deltaHeights, 1, _numOfBins);
    vDSP_vadd(heightsByFrequency, 1, deltaHeights, 1, heightsByFrequency, 1,
              _numOfBins);

    [self _refreshDisplay];
}

#pragma mark - Update Buffers
- (void)setSampleData:(float *)data length:(int)length {
    // fill the buffer with our sampled data. If we fill our buffer, run the
    // fft.
    int inNumberFrames = length;
    int read = (int)(bufferCapacity - index);
    if (read > inNumberFrames) {
        memcpy((float *)dataBuffer + index, data,
               inNumberFrames * sizeof(float));
        index += inNumberFrames;
    } else {
        // if we enter this conditional, our buffer will be filled and we should
        // perform the FFT.
        memcpy((float *)dataBuffer + index, data, read * sizeof(float));

        // reset the index.
        index = 0;

        // fft
        vDSP_ctoz((COMPLEX *)dataBuffer, 2, &A, 1, nOver2);
        vDSP_fft_zrip(fftSetup, &A, 1, log2n, FFT_FORWARD);
        vDSP_ztoc(&A, 1, (COMPLEX *)dataBuffer, 2, nOver2);

        // convert to dB
        Float32 one = 1, zero = 0;
        vDSP_vsq(dataBuffer, 1, dataBuffer, 1, inNumberFrames);
        vDSP_vsadd(dataBuffer, 1, &kAdjust0DB, dataBuffer, 1, inNumberFrames);
        vDSP_vdbcon(dataBuffer, 1, &one, dataBuffer, 1, inNumberFrames, 0);
        vDSP_vthr(dataBuffer, 1, &zero, dataBuffer, 1, inNumberFrames);

        // aux
        float mul = (sampleRate / bufferCapacity) / 2;
        int minFrequencyIndex = self.minFrequency / mul;
        int maxFrequencyIndex = self.maxFrequency / mul;
        int numDataPointsPerColumn =
            (maxFrequencyIndex - minFrequencyIndex) / _numOfBins;
        float maxHeight = 0;

        for (NSUInteger i = 0; i < _numOfBins; i++) {
            // calculate new column height
            float avg = 0;
            vDSP_meanv(dataBuffer + minFrequencyIndex +
                           i * numDataPointsPerColumn,
                       1, &avg, numDataPointsPerColumn);
            CGFloat columnHeight =
                MIN(avg * self.gain, CGRectGetHeight(self.bounds));
            
//            NSLog(@"%@, %@", @(avg), @(columnHeight));
            
            maxHeight = MAX(maxHeight, columnHeight);

            // set column height, speed and time if needed
            if (columnHeight > heightsByFrequency[i]) {
                heightsByFrequency[i] = columnHeight;
                speeds[i] = 0;
                times[i] = 0;
            }
        }

        [self.heightsByTime addObject:[NSNumber numberWithFloat:maxHeight]];
        if (self.heightsByTime.count > _numOfBins) {
            [self.heightsByTime removeObjectAtIndex:0];
        }
    }
}

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    [self setSampleData:buffer length:bufferSize];
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGRect frame = self.bounds;

    // set the background color
    [(UIColor *)self.plotBackgroundColor set];
    UIRectFill(frame);

    CGFloat columnWidth =
        rect.size.width / (self.plotType == BAPlotTypeBuffer ? _numOfBins : _numOfBins - 1);
    CGFloat actualWidth = MAX(1, columnWidth * (1 - 2 * self.padding));
    CGFloat actualPadding = (columnWidth - actualWidth) / 2;
    // TODO: warning: padding is larger than width

    for (NSUInteger i = 0; i < _numOfBins; i++) {
        CGFloat columnHeight = self.plotType == BAPlotTypeBuffer
                                   ? heightsByFrequency[i]
                                   : [self.heightsByTime[i] floatValue];
        
        columnHeight = MAX(self.barMinHeight, columnHeight);
        
        if (columnHeight <= 0)
            continue;
        
        CGFloat columnX =
        i * columnWidth - (self.plotType == BAPlotTypeBuffer || self.displayWaving
                                   ? 0
                                   : columnWidth * [self rollingOffset]);
    
        CGFloat columnY = (CGRectGetHeight(frame) - columnHeight)/(self.alignment == BABarAudioPlotAlignmentCenter ? 2 : 1);
        
        UIBezierPath *rectanglePath = [UIBezierPath
            bezierPathWithRect:CGRectMake(columnX + actualPadding,
                                          columnY,
                                          actualWidth,
                                          columnHeight)];
        
        
        UIColor *color = (self.plotType == BAPlotTypeBuffer && self.colors)
                             ? [self.colors objectAtIndex:i % self.colors.count]
                             : self.color;
        [color setFill];
        [rectanglePath fill];
    }

    CGContextRestoreGState(ctx);
}

- (void)_refreshDisplay {
    [self setNeedsDisplay];
}

#pragma mark - ()
void printFloatArray(float *array, int length, NSString *prefix) {
    NSMutableString *str = [NSMutableString string];
    for (int i = 0; i < length; i++) {
        [str appendFormat:@"%f ", array[i]];
    }
    NSLog(@"%@ %@", prefix, str);
}

/// Return rolling offset for rolling plot in percent
- (CGFloat)rollingOffset {
    return (CGFloat)index / bufferCapacity;
}

- (void)freeBuffersIfNeeded {
    if (heightsByFrequency) {
        free(heightsByFrequency);
    }
    if (speeds) {
        free(speeds);
    }
    if (times) {
        free(times);
    }
    if (tSqrts) {
        free(tSqrts);
    }
    if (vts) {
        free(vts);
    }
    if (deltaHeights) {
        free(deltaHeights);
    }
}

@end

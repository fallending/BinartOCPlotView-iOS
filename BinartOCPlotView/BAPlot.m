
#import "BAPlot.h"

BOOL kBAPlotEnableMockMode = NO;

@interface BAPlot ()

@end

@implementation BAPlot

- (void)clear {
  // Override in subclass
}

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
  // Override in subclass
}

- (void)setPlotBackgroundColor:(UIColor *)plotBackgroundColor{
    _plotBackgroundColor = plotBackgroundColor;
    [self refreshDisplay];
}
  
- (void)setPlotColor:(UIColor *)plotColor {
    _plotColor = plotColor;
    [self refreshDisplay];
}
  
- (void)setGain:(float)gain {
    _gain = gain;
    [self refreshDisplay];
}

- (void)setPlotType:(BAPlotType)plotType {
    _plotType = plotType;
    [self refreshDisplay];
}

- (void)setShouldFill:(BOOL)shouldFill {
    _shouldFill = shouldFill;
    [self refreshDisplay];
}

- (void)setShouldMirror:(BOOL)shouldMirror {
    _shouldMirror = shouldMirror;
    [self refreshDisplay];
}
  
- (void)refreshDisplay {
    [self setNeedsDisplay];
}

@end

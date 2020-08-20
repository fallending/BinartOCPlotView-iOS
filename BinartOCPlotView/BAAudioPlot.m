
#import "BAAudioPlot.h"

// 如果需要BAAudioPlot好好工作，需要 EZAudio，目前只能支持柱状波形图
//#import "EZAudio.h"

@interface BAAudioPlot () {

  BOOL    _setMaxLength;
  float   *_scrollHistory;
  int     _scrollHistoryIndex;
  UInt32  _scrollHistoryLength;
  BOOL    _changingHistorySize;
}

@end

@implementation BAAudioPlot
@synthesize backgroundColor = _backgroundColor;
@synthesize color           = _color;
@synthesize gain            = _gain;
@synthesize plotType        = _plotType;
@synthesize shouldFill      = _shouldFill;
@synthesize shouldMirror    = _shouldMirror;

- (id)init {
  self = [super init];
  if(self){
    [self initPlot];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self){
    [self initPlot];
  }
  return self;
}

- (id)initWithFrame:(CGRect)frameRect {
  self = [super initWithFrame:frameRect];
  if(self){
    [self initPlot];
  }
  return self;
}
  
- (void)initPlot {
  self.backgroundColor = [UIColor blackColor];
  self.color           = [UIColor colorWithHue:0 saturation:1.0 brightness:1.0 alpha:1.0];
  self.gain            = 1.0;
  self.plotType        = BAPlotTypeRolling;
  self.shouldMirror    = NO;
  self.shouldFill      = NO;
  plotData             = NULL;
  _scrollHistory       = NULL;
  _scrollHistoryLength = kEZAudioPlotDefaultHistoryBufferLength;
}

- (void)setBackgroundColor:(id)backgroundColor {
    _backgroundColor = backgroundColor;
    [self _refreshDisplay];
}
  
- (void)setColor:(id)color {
    _color = color;
    [self _refreshDisplay];
}
  
- (void)setGain:(float)gain {
    _gain = gain;
    [self _refreshDisplay];
}

- (void)setPlotType:(BAPlotType)plotType {
    _plotType = plotType;
    [self _refreshDisplay];
}

- (void)setShouldFill:(BOOL)shouldFill {
    _shouldFill = shouldFill;
    [self _refreshDisplay];
}

- (void)setShouldMirror:(BOOL)shouldMirror {
    _shouldMirror = shouldMirror;
    [self _refreshDisplay];
}
  
- (void)_refreshDisplay {
    [self setNeedsDisplay];
}
  
- (void)setSampleData:(float *)data
              length:(int)length {
    if( plotData != nil ) {
        free(plotData);
    }
  
    plotData   = (CGPoint *)calloc(sizeof(CGPoint),length);
    plotLength = length;
  
    for (int i = 0; i < length; i++) {
        data[i]     = i == 0 ? 0 : data[i];
        plotData[i] = CGPointMake(i,data[i] * _gain);
    }
    
    [self _refreshDisplay];
}
  
- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    if( _plotType == BAPlotTypeRolling ) {
    
    // Update the scroll history datasource
      // 如果需要BAAudioPlot好好工作，需要 EZAudio，目前只能支持柱状波形图
//    [EZAudio updateScrollHistory:&_scrollHistory
//                      withLength:_scrollHistoryLength
//                         atIndex:&_scrollHistoryIndex
//                      withBuffer:buffer
//                  withBufferSize:bufferSize
//            isResolutionChanging:&_changingHistorySize];

    // 
        [self setSampleData:_scrollHistory
                     length:(!_setMaxLength?kEZAudioPlotMaxHistoryBufferLength:_scrollHistoryLength)];
        _setMaxLength = YES;
    
    }
    else if( _plotType == BAPlotTypeBuffer ){
    
        [self setSampleData:buffer
                     length:bufferSize];
    }
    else {
    // Unknown plot type
    
    }
}

- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  CGRect frame = self.bounds;
    
    // Set the background color
    [(UIColor*)self.backgroundColor set];
    UIRectFill(frame);
    // Set the waveform line color
    [(UIColor*)self.color set];

    if (plotLength > 0) {
      
      plotData[plotLength-1] = CGPointMake(plotLength-1,0.0f);
      
      CGMutablePathRef halfPath = CGPathCreateMutable();
      CGPathAddLines(halfPath,
                     NULL,
                     plotData,
                     plotLength);
      CGMutablePathRef path = CGPathCreateMutable();
      
      double xscale = (frame.size.width) / (float)plotLength;
      double halfHeight = floor( frame.size.height / 2.0 );
      
      // iOS drawing origin is flipped by default so make sure we account for that
      int deviceOriginFlipped = 1;

      deviceOriginFlipped = -1;
      
      CGAffineTransform xf = CGAffineTransformIdentity;
      xf = CGAffineTransformTranslate( xf, frame.origin.x , halfHeight + frame.origin.y );
      xf = CGAffineTransformScale( xf, xscale, deviceOriginFlipped*halfHeight );
      CGPathAddPath( path, &xf, halfPath );
      
      if( self.shouldMirror ){
        xf = CGAffineTransformIdentity;
        xf = CGAffineTransformTranslate( xf, frame.origin.x , halfHeight + frame.origin.y);
        xf = CGAffineTransformScale( xf, xscale, -deviceOriginFlipped*(halfHeight));
        CGPathAddPath( path, &xf, halfPath );
      }
      CGPathRelease( halfPath );
      
      // Now, path contains the full waveform path.
      CGContextAddPath(ctx, path);
      
      // Make this color customizable
      if( self.shouldFill ){
        CGContextFillPath(ctx);
      }
      else {
        CGContextStrokePath(ctx);
      }
      CGPathRelease(path);
    }
    
    CGContextRestoreGState(ctx);
}
  
// MARK: - Adjust Resolution

- (int)setRollingHistoryLength:(int)historyLength {
      historyLength = MIN(historyLength,kEZAudioPlotMaxHistoryBufferLength);
      size_t floatByteSize = sizeof(float);
      _changingHistorySize = YES;
    
      if ( _scrollHistoryLength != historyLength ) {
          _scrollHistoryLength = historyLength;
      }
    
      _scrollHistory = realloc(_scrollHistory,_scrollHistoryLength * floatByteSize);
    
      if ( _scrollHistoryIndex < _scrollHistoryLength ) {
          memset(&_scrollHistory[_scrollHistoryIndex],
               0,
               (_scrollHistoryLength-_scrollHistoryIndex)*floatByteSize);
      } else {
          _scrollHistoryIndex = _scrollHistoryLength;
      }
      _changingHistorySize = NO;
      return historyLength;
}

- (int)rollingHistoryLength {
  return _scrollHistoryLength;
}
    
- (void)dealloc {
      if ( plotData ) {
          free(plotData);
      }
}

@end

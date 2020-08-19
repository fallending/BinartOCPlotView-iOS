#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    BAPlotTypeBuffer = 1 << 0,
    BAPlotTypeRolling = 1 << 1,
} BAPlotType;

@interface BAPlot : UIView

@property (nonatomic, strong) id backgroundColor;
@property (nonatomic, strong) id color;

/**
 The plot's gain value, which controls the scale of the y-axis values. The default value of the gain is 1.0f and should always be greater than 0.0f.
 */
@property (nonatomic, assign, setter=setGain:) float gain;

/**
 The type of plot as specified by the `EZPlotType` enumeration (i.e. a buffer or rolling plot type).
 */
@property (nonatomic, assign, setter=setPlotType:) BAPlotType plotType;

/**
 A boolean indicating whether or not to fill in the graph. A value of YES will make a filled graph (filling in the space between the x-axis and the y-value), while a value of NO will create a stroked graph (connecting the points along the y-axis).
 */
@property (nonatomic, assign, setter=setShouldFill:) BOOL shouldFill;

/**
 A boolean indicating whether the graph should be rotated along the x-axis to give a mirrored reflection. This is typical for audio plots to produce the classic waveform look. A value of YES will produce a mirrored reflection of the y-values about the x-axis, while a value of NO will only plot the y-values.
 */
@property (nonatomic, assign, setter=setShouldMirror:) BOOL shouldMirror;

// MARK: = Clearing

///-----------------------------------------------------------
/// @name Clearing The Plot
///-----------------------------------------------------------

/**
 Clears all data from the audio plot (includes both EZPlotTypeBuffer and EZPlotTypeRolling)
 */
- (void)clear;

// MARK: = Get Samples

///-----------------------------------------------------------
/// @name Updating The Plot
///-----------------------------------------------------------

/**
 Updates the plot with the new buffer data and tells the view to redraw itself. Caller will provide a float array with the values they expect to see on the y-axis. The plot will internally handle mapping the x-axis and y-axis to the current view port, any interpolation for fills effects, and mirroring.
 @param buffer     A float array of values to map to the y-axis.
 @param bufferSize The size of the float array that will be mapped to the y-axis.
 @warning The bufferSize is expected to be the same, constant value once initial triggered. For plots using OpenGL a vertex buffer object will be allocated with a maximum buffersize of (2 * the initial given buffer size) to account for any interpolation necessary for filling in the graph. Updates use the glBufferSubData(...) function, which will crash if the buffersize exceeds the initial maximum allocated size.
 */
- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize;

@end

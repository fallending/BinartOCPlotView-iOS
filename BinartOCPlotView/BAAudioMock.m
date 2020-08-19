//
//  BAAudioMock.m
//  EZAudioRecordExample
//
//  Created by Seven on 2020/8/19.
//  Copyright © 2020 Syed Haris Ali. All rights reserved.
//

#import "BAAudioMock.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreServices/CoreServices.h>

@interface BAAudioMock ()

@end

@implementation BAAudioMock

- (instancetype)init {
    if (self = [super init]) {
        [self setupDefault];
    }
    
    return self;
}

- (void)setupDefault {
    // 延时100毫秒启动
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self start];
    });
}

- (void)start {
    AudioComponentDescription mixerDesc;
    mixerDesc.componentType = kAudioUnitType_Generator;
    mixerDesc.componentSubType = kAudioUnitSubType_ScheduledSoundPlayer;
    mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerDesc.componentFlags = 0;
    mixerDesc.componentFlagsMask = 0;
    
    [AVAudioUnitGenerator instantiateWithComponentDescription:mixerDesc
                                             options:kAudioComponentInstantiation_LoadOutOfProcess
                                   completionHandler:^(__kindof AVAudioUnit * _Nullable audioUnit, NSError * _Nullable error) {
        if ([audioUnit.AUAudioUnit respondsToSelector:@selector(setOutputProvider:)]) {
            audioUnit.AUAudioUnit.outputProvider = ^AUAudioUnitStatus(AudioUnitRenderActionFlags * _Nonnull actionFlags, const AudioTimeStamp * _Nonnull timestamp, AUAudioFrameCount frameCount, NSInteger inputBusNumber, AudioBufferList * _Nonnull inputData) {
                
                ///
                const double amplitude = 0.2;
                static double theta = 0.0;
                double thetaIncrement = 2.0 * M_PI * 880.0 / 44100.0;
                
                const int channel = 0;
                Float32 *buffer = (Float32 *)inputData->mBuffers[channel].mData;
                
                memset(inputData->mBuffers[channel].mData, 0, inputData->mBuffers[channel].mDataByteSize);
                memset(inputData->mBuffers[1].mData, 0, inputData->mBuffers[1].mDataByteSize);
                
                // Generate the samples
                for (UInt32 frame = 0; frame < inputBusNumber; frame ++) {
                    buffer[frame] = sin(theta) * amplitude;
                    
                    theta += thetaIncrement;
                    
                    if (theta >= 2.0 * M_PI) {
                        theta -= 2.0 * M_PI;
                    }
                }
                
                if ([self.delegate respondsToSelector:@selector(updateBuffer:withBufferSize:)]) {
                    [self.delegate updateBuffer:buffer withBufferSize:(UInt32)inputBusNumber];
                }
                
                 return noErr;
            };
        }
    }];
}

@end

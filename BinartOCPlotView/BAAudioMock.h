//
//  BAAudioMock.h
//  EZAudioRecordExample
//
//  Created by Seven on 2020/8/19.
//  Copyright © 2020 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BAAudioMockDelegate <NSObject>

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize;

@end

@interface BAAudioMock : NSObject

@property (nonatomic, weak) id<BAAudioMockDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

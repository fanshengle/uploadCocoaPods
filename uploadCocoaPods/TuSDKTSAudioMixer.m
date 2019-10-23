//
//  TuSDKTSAudioMixer.m
//  TuSDKVideo
//
//  Created by wen on 22/06/2017.
//  Copyright © 2017 TuSDK. All rights reserved.
//

#import "TuSDKTSAudioMixer.h"
#import "TuSDKVideoImport.h"
#import "TuSDKVideoStatistics.h"

@interface TuSDKTSAudioMixer () {
    // 音轨混合数组
    NSMutableArray *_audioMixParams;
    // 输出的 session
    AVAssetExportSession *_exporter;
    // 混合音频结果路径
    NSString *_resultAudioPath;
}
@end

@implementation TuSDKTSAudioMixer
#pragma mark - setter getter

- (void)setMixAudios:(NSArray<TuSDKTSAudio *> *)mixAudios;
{
    _mixAudios = mixAudios;
    [self resetMixOperation];
}

- (void)setMainAudio:(TuSDKTSAudio *)mainAudio;
{
    _mainAudio = mainAudio;
    [self resetMixOperation];
}

#pragma mark - init

- (instancetype)init;
{
    if (self = [super init]) {
        _status = lsqAudioMixStatusUnknown;
    }
    return self;
}

#pragma mark - mix method

- (void)startMixingAudio;
{
    [self startMixingAudioWithCompletion:nil];
}

- (void)startMixingAudioWithCompletion:(void (^)(NSURL*, lsqAudioMixStatus))handler;
{
    if (!_audioMixParams) {
        _audioMixParams = [[NSMutableArray alloc]init];
    }
    
    if (!_mainAudio) {
        lsqLError(@"have not set a valid main track");
        [self notifyStatus:lsqAudioMixStatusCancelled];
        return;
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];


    TuSDKTimeRange *mainAudioTrackTimeRange;
    if (_mainAudio.audioTrack) {
        
        // 处理主音轨
        mainAudioTrackTimeRange = [TuSDKTimeRange makeTimeRangeWithStart:kCMTimeZero duration:_mainAudio.audioTrack.timeRange.duration];
        CMTimeRangeShow(_mainAudio.audioTrack.timeRange);
        
        [self addAudioTrack:_mainAudio toComposition:composition atTimeRange:mainAudioTrackTimeRange mainTimeRange:mainAudioTrackTimeRange];
    } else {
        mainAudioTrackTimeRange = _mainAudio.audioTimeRange;
    }
    
    
    // 处理混合音轨
    if (_mixAudios && _mixAudios.count > 0) {
        for (TuSDKTSAudio *audio in _mixAudios) {
            if (audio.audioTrack) {
                TuSDKTimeRange *audioTimeRange = audio.atTimeRange;
                if (CMTIME_COMPARE_INLINE(audioTimeRange.duration, >, _mainAudio.atTimeRange.duration)) {
                    audioTimeRange.duration = _mainAudio.atTimeRange.duration;
                }
                [self addAudioTrack:audio toComposition:composition atTimeRange:audioTimeRange mainTimeRange:_mainAudio.atTimeRange];
            }
        }
    }
    
    // 创建一个可变的音频混合对象
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:_audioMixParams];
    
    // 创建一个输出对象
    if (!_exporter) {
        _exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    }
    _exporter.audioMix = audioMix;
    _exporter.outputFileType = AVFileTypeAppleM4A;
    
    _resultAudioPath = [self generateTempFile];
    _exporter.outputURL = [NSURL fileURLWithPath:_resultAudioPath];
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _mainAudio.atTimeRange.duration);
    
    [self notifyStatus:lsqAudioMixStatusMixing];

    __weak typeof(self) weakSelf = self;
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        lsqAudioMixStatus exportStatus = lsqAudioMixStatusUnknown;
        switch (self->_exporter.status) {
            case AVAssetExportSessionStatusFailed: {
                exportStatus = lsqAudioMixStatusFailed;
            }
                break;
            case AVAssetExportSessionStatusCompleted: {
                exportStatus = lsqAudioMixStatusCompleted;
            }
                break;
            case AVAssetExportSessionStatusUnknown: {
                exportStatus = lsqAudioMixStatusFailed;
            }
                break;
            case AVAssetExportSessionStatusExporting: {
                exportStatus = lsqAudioMixStatusMixing;
            }
                break;
            case AVAssetExportSessionStatusCancelled: {
                exportStatus = lsqAudioMixStatusCancelled;
            }
                break;
                
            default:{
                exportStatus = lsqAudioMixStatusFailed;
            }
                break;
        }
        if (self->_exporter.error) {
            lsqLError(@"exporter audio error : %@",self->_exporter.error);
        }
        
        [weakSelf notifyStatus:exportStatus];
        if (handler) {
            handler(self->_exporter.outputURL, exportStatus);
        }
        
        [weakSelf resetMixOperation];
    }];
    
}

// 处理音频轨道
- (void)addAudioTrack:(TuSDKTSAudio *)audioData toComposition:(AVMutableComposition *)composition atTimeRange:(TuSDKTimeRange *)timeRange mainTimeRange:(TuSDKTimeRange *)mainTimeRange;
{
    AVAssetTrack *audioTrack = audioData.audioTrack;
    
    
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    BOOL insertResult = NO;
  
    // 音效播放区间
    CMTimeRange atTimeRange = CMTimeRangeMake(timeRange.start, CMTIME_COMPARE_INLINE(timeRange.duration, >, mainTimeRange.duration) ? mainTimeRange.duration : timeRange.duration);
    
    // 设置音量
    AVMutableAudioMixInputParameters *mixInputPara = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionTrack];
    [mixInputPara setVolume:audioData.audioVolume atTime:mainTimeRange.start];
    [_audioMixParams addObject:mixInputPara];
    
    if (!_enableCycleAdd || CMTIME_COMPARE_INLINE(atTimeRange.duration, >, mainTimeRange.duration) ) {
        // 不需要循环
        
        insertResult = [compositionTrack insertTimeRange: (audioData.catTimeRange ? audioData.catTimeRange.CMTimeRange : atTimeRange) ofTrack:audioTrack atTime:mainTimeRange.start error:&error];
        if (!insertResult) {
            lsqLError(@"mix insert error 1: %@",error);
        }
    }else
    {
        // 音效裁剪时间范围
        CMTimeRange contentTimeRange =  audioData.catTimeRange ? audioData.catTimeRange.CMTimeRange :(  CMTimeRangeMake(CMTimeMakeWithSeconds(0, USEC_PER_SEC), CMTIME_COMPARE_INLINE(audioTrack.timeRange.duration, >,atTimeRange.duration) ? atTimeRange.duration : audioTrack.timeRange.duration));

        CMTime nextAtTime = atTimeRange.start;
        CMTime audioDurationTime = contentTimeRange.duration;
        CMTime insertDurationTime = kCMTimeZero;
        
        while (CMTIME_COMPARE_INLINE(nextAtTime, <, CMTimeRangeGetEnd(atTimeRange))) {
            
            /** 剩余时间 */
            CMTime remainingTime = CMTimeSubtract(atTimeRange.duration, insertDurationTime);
            
            if (CMTIME_COMPARE_INLINE(remainingTime, <, audioDurationTime))
                contentTimeRange.duration = remainingTime;
            
            insertResult = [compositionTrack insertTimeRange:contentTimeRange ofTrack:audioTrack atTime:nextAtTime error:&error];
            if (!insertResult) {
                lsqLError(@"mix insert error 1: %@",error);
                break;
            }
        
            nextAtTime = CMTimeAdd(nextAtTime, contentTimeRange.duration);
            insertDurationTime = CMTimeAdd(insertDurationTime, contentTimeRange.duration);
 
        }
    }

}

// 取消混合操作
- (void)cancelMixing;
{
    if (_exporter) {
        if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
            [_exporter cancelExport];
            [self notifyStatus:lsqAudioMixStatusCancelled];
        }
    }
}

#pragma mark - helper method

/**
 *  生成临时文件路径
 *TuSDKTSMovieSplicer
 *  @return 文件路径
 */
- (NSString *)generateTempFile;
{
    NSString *path = [TuSDKTSFileManager createDir:[TuSDKTSFileManager pathInCacheWithDirPath:lsqTempDir filePath:@""]];
    path = [NSString stringWithFormat:@"%@%f.m4a", path, [[NSDate date]timeIntervalSince1970]];
    
    unlink([path UTF8String]);
    return path;
}

- (void)notifyStatus:(lsqAudioMixStatus) status;
{
    _status = status;
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.mixDelegate respondsToSelector:@selector(onAudioMix:statusChanged:)]) {
                [self.mixDelegate onAudioMix:self statusChanged:status];
            }
        });
    }else{
        if ([self.mixDelegate respondsToSelector:@selector(onAudioMix:statusChanged:)]) {
            [self.mixDelegate onAudioMix:self statusChanged:status];
        }
    }
    if (status == lsqAudioMixStatusCompleted) {
        [self notifyResult];
    }
}

- (void)notifyResult;
{
    TuSDKAudioResult *result = [[TuSDKAudioResult alloc]init];
    result.audioPath = _resultAudioPath;
    result.duration = CMTimeGetSeconds(_mainAudio.audioTrack.timeRange.duration);
    
    
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.mixDelegate respondsToSelector:@selector(onAudioMix:result:)]) {
                [self.mixDelegate onAudioMix:self result:result];
            }
        });
    }else{
        if ([self.mixDelegate respondsToSelector:@selector(onAudioMix:result:)]) {
            [self.mixDelegate onAudioMix:self result:result];
        }
    }

    
    // sdk统计信息
    [TuSDKTKStatistics appendWithComponentIdt: tkc_video_api_mix_audio];
}

// 重置混合状态
- (void)resetMixOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        lsqLError(@"Conditions cannot be reset during operation.");
    }else{
        if (_audioMixParams) {
            [_audioMixParams removeAllObjects];
        }
        _exporter = nil;
    }
}

@end

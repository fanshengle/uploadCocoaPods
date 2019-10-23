# 七牛直播外部滤镜 TuSDK API调用

## 1.七牛TuSDK外部滤镜处理API

### 1.TuSDKFilterProcessor 初始化

TuSDKFilterProcessor 是视频滤镜处理 API 的接口，处理的是视频 帧buffer 或 纹理texture 数据

1. 在文件中引入 `#import <TuSDKVideo/TuSDKVideo.h>`
2. 遵守协议TuSDKFilterProcessorMediaEffectDelegate
3. 创建对象

```objective-c

 @property (nonatomic,strong) TuSDKFilterProcessor *filterProcessor;

```

4. 初始化对象

```objective-c

// 初始化 TuSDKFilterProcessor
- (void)initFilterProcessor;
{
    // 传入图像的方向是否为原始朝向(相机采集的原始朝向)，SDK 将依据该属性来调整人脸检测时图片的角度。如果没有对图片进行旋转，则为 YES
    BOOL isOriginalOrientation = NO;
    
    // 初始化，输入的数据类型支持 BGRA 和 YUV 数据
    self.filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:isOriginalOrientation];
    
    // 遵守代理 TuSDKFilterProcessorDelegate
    self.filterProcessor.delegate = self;
    
    // 是否开启了镜像
    self.filterProcessor.horizontallyMirrorFrontFacingCamera = NO;
    // 告知摄像头默认位置
    self.filterProcessor.cameraPosition = AVCaptureDevicePositionFront;
    // 输出是否按照原始朝向
    self.filterProcessor.adjustOutputRotation = NO;
    // 开启动态贴纸服务（需要大眼瘦脸特效和动态贴纸的功能需要开启该选项）
    [self.filterProcessor setEnableLiveSticker:YES];
    
    // 切换滤镜（在 TuSDKFilterProcessor 初始化前需要提前配置滤镜代号，即 filterCode 的数组）
    // 默认选中的滤镜代号，这个要与 filterView 默认选择的滤镜顺序保持一致
    [self.filterProcessor addMediaEffect:[[TuSDKMediaFilterEffect alloc] initWithEffectCode:_videoFilters[1]]];
}

```

### 2.普通滤镜特效

1. 添加普通滤镜特效

```objective-c
    
    //普通滤镜特效初始化，滤镜特效不能叠加处理，切换滤镜时，需要重新创建对应滤镜code的滤镜特效，并addMediaEffect；
    //SkinNatural_2：滤镜code，在lsq_tusdk_configs.json中可查询到
    TuSDKMediaFilterEffect *effect = [[TuSDKMediaFilterEffect alloc] initWithEffectCode:@"SkinNatural_2"];
    //TuSDK滤镜处理器添加滤镜特效
    [self.filterProcessor addMediaEffect:effect];

```

2. 普通滤镜的参数默认配置

普通滤镜的参数默认配置参数值，lsq_tusdk_configs.json中已经做了每款滤镜mixied参数值的设置，可忽略。

3. 手动调整普通滤镜参数值

```objective-c
    
    //从TuSDKFilterProcessor滤镜处理器中取到当前的滤镜对象
    TuSDKMediaFilterEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
    //通过index索引取到滤镜特效的对应滤镜，提交滤镜特效的滤镜效果参数值
    [effect submitParameter:index argPrecent:percentValue];
```
4. **FilterPanelView** 普通滤镜UI层，可参考

### 3.漫画滤镜特效

1. 添加漫画滤镜特效
```objective-c
    
    //滤镜特效初始化，滤镜特效不能叠加处理，切换滤镜时，需要重新创建对应滤镜code的滤镜特效，并addMediaEffect；
    //CHComics_Live：滤镜code，在lsq_tusdk_configs.json中可查询到
    TuSDKMediaComicEffect *effect = [[TuSDKMediaComicEffect alloc] initWithEffectCode:@"CHComics_Live"];
    //TuSDK滤镜处理器添加滤镜特效
    [self.filterProcessor addMediaEffect:effect];
```

2. 漫画滤镜没有参数调节

3. **CartoonPanelView** 漫画滤镜UI层，可参考

### 4.动态贴纸特效

动态贴纸的资源需要配置贴纸资源item，内容较多，这里给出demo中的参考类。

1. **customStickerCategories.json** 这个是动态贴纸的名称、id、缩略图等数据的json，动态贴纸的数据是从json中读取的，可对该json进行修改成贵公司名下的动态贴纸资源。可参考目录3.FAQ-2.贴纸替换使用贴纸。

2. **PropsItemCategory**、**PropsItemStickerCategory** 这两个类是动态贴纸的数据配置类，可以拿到所有动态贴纸数组的dataSource。

3. **PropsPanelView** 动态贴纸UI层，可参考

### 5.美颜特效

美颜分为：精准美颜与极度美颜，他们是分别独立的，需要独立初始化创建。

1. 添加美颜（精准美颜、极度美颜）特效
```objective-c
    
    //初始化美颜特效
    //useSkinNatural 是否开启精准美颜 YES：精准美颜 NO: 极致美颜
    TuSDKMediaSkinFaceEffect *skinFaceEffect = [[TuSDKMediaSkinFaceEffect alloc] initUseSkinNatural:YES];
    //TuSDK滤镜处理器添加美颜特效
    [self.filterProcessor addMediaEffect:skinFaceEffect];
```

2. 修改美颜默认参数配置，以下是修改美颜默认参数代码，根据贵公司需求自行修改；当然可以不调用该方法块，直接是TuSDK的默认参数

```objective-c
/**
 重置美颜参数默认值
 */
- (void)updateSkinFaceDefaultParameters;
{
    TuSDKMediaSkinFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].firstObject;
    NSArray<TuSDKFilterArg *> *args = effect.filterArgs;
    BOOL needSubmitParameter = NO;
    
    for (TuSDKFilterArg *arg in args) {
        NSString *parameterName = arg.key;
        // NSLog(@"调节的滤镜参数名称 parameterName: %@",parameterName)
        // 应用保存的参数默认值、最大值
        NSDictionary *savedDefaultDic = _filterParameterDefaultDic[parameterName];
        if (savedDefaultDic) {
            if (savedDefaultDic[kFilterParameterDefaultKey])
                arg.defaultValue = [savedDefaultDic[kFilterParameterDefaultKey] doubleValue];
            
            if (savedDefaultDic[kFilterParameterMaxKey])
                arg.maxFloatValue = [savedDefaultDic[kFilterParameterMaxKey] doubleValue];
            
            // 把当前值重置为默认值
            [arg reset];
            needSubmitParameter = YES;
            continue;
        }
        
        // TUSDK 开放了滤镜等特效的参数调节，用户可根据实际使用场景情况调节效果强度大小
        // Attention ！！
        // 特效的参数并非越大越好，请根据实际效果进行调节
        
        // 是否需要更新参数值
        BOOL updateValue = NO;
        // 默认值的百分比，用于指定滤镜初始的效果（参数默认值 = 最小值 + (最大值 - 最小值) * defaultValueFactor）
        CGFloat defaultValueFactor = 1;
        // 最大值的百分比，用于限制滤镜参数变化的幅度（参数最大值 = 最小值 + (最大值 - 最小值) * maxValueFactor）
        CGFloat maxValueFactor = 1;
        
        if ([parameterName isEqualToString:@"smoothing"]) {
            // 润滑
            maxValueFactor = 0.7;
            defaultValueFactor = 0.6;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"whitening"]) {
            // 白皙
            maxValueFactor = 0.4;
            defaultValueFactor = 0.3;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"ruddy"]) {
            // 红润
            maxValueFactor = 0.4;
            defaultValueFactor = 0.3;
            updateValue = YES;
        }
        
        if (updateValue) {
            if (defaultValueFactor != 1)
                arg.defaultValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * defaultValueFactor * maxValueFactor;
            
            if (maxValueFactor != 1)
                arg.maxFloatValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * maxValueFactor;
            // 把当前值重置为默认值
            [arg reset];
            
            // 存储值
            _filterParameterDefaultDic[parameterName] = @{kFilterParameterDefaultKey: @(arg.defaultValue), kFilterParameterMaxKey: @(arg.maxFloatValue)};
            needSubmitParameter = YES;
        }
    }
    
    // 提交修改结果
    if (needSubmitParameter)
        [effect submitParameters];
    //将配置好的默认参数，同步到视图层显示
    //[_facePanelView reloadFilterParamters];
}
```

3. 手动调整美颜功能参数特效参数值

```objective-c
    
    //从TuSDKFilterProcessor滤镜处理器中取到当前的美颜特效对象
     TuSDKMediaSkinFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].firstObject;
    //通过index索引取到美颜特效的对应功能参数，提交美颜参数功能特效的美颜参数值
    //[effect submitParameter:index argPrecent:percentValue];
    //通过美颜对应功能参数key取到美颜特效的对应功能参数，提交美颜参数功能特效的美颜参数值
    [effect submitParameterWithKey:@"smoothing" argPrecent:percentValue];
    //两种提交方式二选一
```

4. **CameraBeautyPanelView** 美颜UI层，可参考

### 6.微整形特效

1. 添加微整形特效
```objective-c
    
    //初始化微整形特效
    TuSDKMediaPlasticFaceEffect *plasticFaceEffect = [[TuSDKMediaPlasticFaceEffect alloc] init];
    //TuSDK滤镜处理器添加美颜特效
    [self.filterProcessor addMediaEffect:plasticFaceEffect];
```

2. 修改微整形默认参数配置，以下是修改微整形默认参数代码，根据贵公司需求自行修改；当然可以不调用该方法块，直接是TuSDK的默认参数

```objective-c
/**
 重置微整形参数默认值
 */
- (void)updatePlasticFaceDefaultParameters {
    
    TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
    NSArray<TuSDKFilterArg *> *args = effect.filterArgs;
    BOOL needSubmitParameter = NO;
    
    for (TuSDKFilterArg *arg in args) {
        NSString *parameterName = arg.key;
        
        // 是否需要更新参数值
        BOOL updateValue = NO;
        // 默认值的百分比，用于指定滤镜初始的效果（参数默认值 = 最小值 + (最大值 - 最小值) * defaultValueFactor）
        CGFloat defaultValueFactor = 1;
        // 最大值的百分比，用于限制滤镜参数变化的幅度（参数最大值 = 最小值 + (最大值 - 最小值) * maxValueFactor）
        CGFloat maxValueFactor = 1;
        if ([parameterName isEqualToString:@"eyeSize"]) {
            // 大眼
            defaultValueFactor = 0.3;
            maxValueFactor = 0.85;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"chinSize"]) {
            // 瘦脸
            defaultValueFactor = 0.2;
            maxValueFactor = 0.8;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"noseSize"]) {
            // 瘦鼻
            defaultValueFactor = 0.2;
            maxValueFactor = 0.6;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"mouthWidth"]) {
            // 嘴型
        } else if ([parameterName isEqualToString:@"archEyebrow"]) {
            // 细眉
        } else if ([parameterName isEqualToString:@"jawSize"]) {
            // 下巴
        } else if ([parameterName isEqualToString:@"eyeAngle"]) {
            // 眼角
        } else if ([parameterName isEqualToString:@"eyeDis"]) {
            // 眼距
        }
        
        if (updateValue) {
            if (defaultValueFactor != 1)
                arg.defaultValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * defaultValueFactor * maxValueFactor;
            
            if (maxValueFactor != 1)
                arg.maxFloatValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * maxValueFactor;
            // 把当前值重置为默认值
            [arg reset];
            
            needSubmitParameter = YES;
        }
    }
    
    // 提交修改结果
    if (needSubmitParameter)
        [effect submitParameters];
     //将配置好的默认参数，同步到视图层显示
    //[_facePanelView reloadFilterParamters];
}

```

3. 手动调整微整形功能参数特效参数值

```objective-c
    
    //从TuSDKFilterProcessor滤镜处理器中取到当前的微整形特效对象
    TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
    //通过index索引取到微整形特效的对应功能参数，提交微整形参数功能特效的微整形参数值
    [effect submitParameter:index argPrecent:percentValue];
    //通过微整形对应功能参数key取到微整形特效的对应功能参数，提交微整形参数功能特效的微整形参数值
    //[effect submitParameterWithKey:@"eyeSize" argPrecent:percentValue];
    //两种提交方式二选一
```

## 2.七牛直播自定义渲染：（详见七牛链接：https://developer.qiniu.com/pili/sdk/3781/PLMediaStreamingKit-function-using)

* TuSDK通过修改七牛开放的视频帧数据pixelBuffer，来完成外部滤镜的渲染。
* 具体使用方式请参考demo中的**PLMainViewController**
* 方法调用：

```objective-c

- (CVPixelBufferRef)mediaStreamingSession:(PLMediaStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    // TuSDK mark 处理数据 添加美颜和贴纸
    if (!_filterProcessor) {
        return pixelBuffer;
    }
    //七牛外部渲染处理：_filterProcessor处理七牛抛出的pixelBuffer数据，送给七牛
    CVPixelBufferRef newPixelBuffer  = [_filterProcessor syncProcessPixelBuffer:pixelBuffer];
    
    return newPixelBuffer;
}

```

## 3.FAQ

### 1.滤镜替换使用的滤镜的代号

* 替换资源文件后，查看资源文件（TuSDK.bundle/others/lsq_config.json）filterGroups中滤镜的 filerCode（filters/name），替换到项目中对应的位置。
* 替换滤镜资源后，需要根据新的 filterCode 更改对应滤镜效果缩略图文件的名称。
* 举例："name":"lsq_filter_VideoFair"，`VideoFair ` 就是该滤镜的filterCode ，在`_videoFilters = @[@"VideoFair"]`;可以进行选择使用滤镜的设置。

### 2.贴纸替换使用贴纸

* 替换资源文件后，查看资源文件（TuSDK.bundle/others/lsq_config.json） stickerGroups中贴纸的id、name，新增/替换到项目中customStickerCategories.json对应的位置。
* Assets/customStickerCategories.json/categoryName，修改/新增类别名称。
* Assets/customStickerCategories.json/categoryName/stickers，对应类别名称下的组员groups。
* Assets/customStickerCategories.json/categoryName/stickers/name，修改/新增使用贴纸的名称。
* Assets/customStickerCategories.json/categoryName/stickers/id，修改/新增使用贴纸的id。
* Assets/customStickerCategories.json/categoryName/stickers/previewImage，修改/新增使用贴纸的缩略图，只需将最后的一串数字改成id值即可。

### 3.多包名发布

* 参考[多包名发布](https://tutucloud.com/docs/ios-faq/masterkey)

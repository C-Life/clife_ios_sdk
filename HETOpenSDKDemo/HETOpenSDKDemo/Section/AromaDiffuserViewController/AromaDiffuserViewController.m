//
//  AromaDiffuserViewController.m
//  HETOpenSDKDemo
//
//  Created by mr.cao on 16/4/14.
//  Copyright © 2016年 mr.cao. All rights reserved.
//

#import "AromaDiffuserViewController.h"
#import "ColorButton.h"
#import <HETOpenSDK/HETOpenSDK.h>
#import "HETWIFIAromaDiffuserDevice.h"
#import "HETDeviceInfoViewController.h"


#define MENU_HEIGHT 36
#define MENU_BUTTON_WIDTH  60

#define MIN_MENU_FONT  13.f
#define MAX_MENU_FONT  18.f

@interface AromaDiffuserViewController ()<UIScrollViewDelegate>
{
    UIView *_navView;
    UIView *_topNaviV;
    UIScrollView *_scrollV;
    
    UIScrollView *_navScrollV;
    
    float _startPointX;
    float _btnW;
    UIView *_selectTabV;
    ColorButton *_lastSelectedColorBtn;
    HETWIFIAromaDiffuserDevice *_device;
    

    
    

}
@property(nonatomic,assign) NSUInteger mist;//MIST键设置
@property(nonatomic,assign) NSUInteger light;//LIGHT键设置

@property(nonatomic,assign) NSUInteger timeClose;//定时关机(单位分钟)

@property(nonatomic,assign) NSUInteger presetStartupTime;//预约开机(单位分钟)

@property(nonatomic,assign) NSUInteger presetShutdownTime;//预约关机(单位分钟)
@property(nonatomic,assign) NSUInteger color;//颜色
@property(nonatomic,assign) NSUInteger updateFlag;//用户行为

//忽略次数
@property (nonatomic, assign) NSInteger  ignoreCount;
@property (strong,nonatomic)UIButton    *deviceControlButton;
@property (strong, nonatomic) UITextView *logTextView;

@end

@implementation AromaDiffuserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.updateFlag=0;
    self.mist=0;
    self.timeClose=0;
    self.presetShutdownTime=0;
    self.presetStartupTime=0;
    self.color=0;
    self.ignoreCount=0;
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.view addSubview:self.deviceControlButton];
    
    self.view.backgroundColor=[UIColor whiteColor];
    
    
    //右边添加按钮
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 100, 40);
    // [addButton setImage: [UIImage imageNamed:@"deviceShare_shareManage_addShareIcon"] forState:UIControlStateNormal];
    [rightButton setTitle:@"设备升级和历史数据" forState:UIControlStateNormal];
    rightButton.titleLabel.font=[UIFont systemFontOfSize:11];
    [rightButton addTarget:self action:@selector(rightBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:rightButton] animated:NO];
    
    NSArray *arT = @[@"灯光", @"喷雾", @"颜色"];
    _btnW = self.view.frame.size.width/arT.count;
    for (int i = 0; i < [arT count]; i++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(_btnW * i, 0, _btnW, MENU_HEIGHT)];
        [btn setTitle:[arT objectAtIndex:i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.tag = i + 1;
        if(i==0)
        {
             [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
             btn.titleLabel.font = [UIFont systemFontOfSize:MAX_MENU_FONT];
        }else
        {
             btn.titleLabel.font = [UIFont systemFontOfSize:MAX_MENU_FONT];
             [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
        [btn addTarget:self action:@selector(actionbtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
   UIView *line=[[UIView alloc]initWithFrame:CGRectMake(0,MENU_HEIGHT,self.view.frame.size.width, 0.5)];
   line.backgroundColor=[UIColor lightGrayColor];
   [self.view addSubview:line];
    
    _selectTabV.backgroundColor=[UIColor redColor];
    [self.view addSubview:_selectTabV];
    _selectTabV=[[UIView alloc]initWithFrame:CGRectMake(0, MENU_HEIGHT, _btnW, 0.5)];
    _selectTabV.backgroundColor=[UIColor redColor];
    [self.view addSubview:_selectTabV];
    _scrollV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, MENU_HEIGHT+1, self.view.frame.size.width, self.view.frame.size.height*0.3)];
    [_scrollV setPagingEnabled:YES];
    [_scrollV setBounces:NO];
    [_scrollV setShowsHorizontalScrollIndicator:NO];
    _scrollV.delegate = self;
    [_scrollV.panGestureRecognizer addTarget:self action:@selector(scrollHandlePan:)];
    [self.view addSubview:_scrollV];
    
    [self addView2Page:_scrollV count:[arT count] frame:CGRectZero];
    
    [self.view addSubview:self.logTextView];
    
//    NSString *deviceId=[self.deviceDic objectForKey:@"deviceId"];
//    
//    NSString *deviceBindType=[self.deviceDic objectForKey:@"bindType"];
//    NSString *deviceTypeId=[self.deviceDic objectForKey:@"deviceTypeId"];
//    
//    NSString *userKey=[self.deviceDic objectForKey:@"userKey"];
//    NSString *macAddress=[self.deviceDic objectForKey:@"macAddress"];
//    NSString *deviceSubtypeId=[self.deviceDic objectForKey:@"deviceSubtypeId"];
//     NSString *productId=[self.deviceDic objectForKey:@"productId"];
    
    
       

}
-(void)viewWillAppear:(BOOL)animated
{
    _device=[[HETWIFIAromaDiffuserDevice alloc]initWithHetDeviceModel:self.hetDeviceModel deviceRunDataSuccess:^(AromaDiffuserDeviceRunModel *model) {
        NSLog(@"%@",model);
        NSDictionary *responseObject=[model convertModelToDic];
        NSString *jsonString=[self DataTOjsonString:responseObject];
        [self addText:jsonString];
        self.ignoreCount--;
        if(self.ignoreCount<0)
        {
            NSString *mist=model.mist;
            NSString *light=model.light;
            NSString *color=model.color;
//            self.mist=mist.integerValue;
//            self.light=light.integerValue;
//            self.color=color.integerValue;
            for(int j=0;j<3;j++)
            {
                UIButton *btn = (UIButton *)[self.view viewWithTag:1000+j+1];
                UIButton *btn1 = (UIButton *)[self.view viewWithTag:2000+j+1];
                btn.backgroundColor=[UIColor whiteColor];
                btn1.backgroundColor=[UIColor whiteColor];
            }
            
            
            
            UIButton *lightBtn=(UIButton *)[self.view viewWithTag:1000+light.integerValue];
            lightBtn.backgroundColor=[UIColor blueColor];
            UIButton *mistBtn=(UIButton *)[self.view viewWithTag:2000+mist.integerValue];
            mistBtn.backgroundColor=[UIColor blueColor];
            ColorButton *colorBtn=(ColorButton *)[self.view viewWithTag:3000+color.integerValue];
            colorBtn.selected=YES;
            [colorBtn setNeedsDisplay];
            _lastSelectedColorBtn=colorBtn;
        }
        
        
        
    } deviceRunDataFail:^(NSError *error) {
        
    } deviceCfgDataSuccess:^(AromaDiffuserDeviceConfigModel *model) {
        NSLog(@"%@",model);
        NSDictionary *responseObject=[model convertModelToDic];
        NSString *jsonString=[self DataTOjsonString:responseObject];
        [self addText:jsonString];
        self.ignoreCount--;
        if(self.ignoreCount<0)
        {
            
            NSString *mist=model.mist;
            NSString *light=model.light;
            NSString *color=model.color;
//            self.mist=mist.integerValue;
//            self.light=light.integerValue;
//            self.color=color.integerValue;
            
            for(int j=0;j<3;j++)
            {
                UIButton *btn = (UIButton *)[self.view viewWithTag:1000+j+1];
                UIButton *btn1 = (UIButton *)[self.view viewWithTag:2000+j+1];
                btn.backgroundColor=[UIColor whiteColor];
                btn1.backgroundColor=[UIColor whiteColor];
            }
            
            
            
            
            UIButton *lightBtn=(UIButton *)[self.view viewWithTag:1000+light.integerValue];
            lightBtn.backgroundColor=[UIColor blueColor];
            UIButton *mistBtn=(UIButton *)[self.view viewWithTag:2000+mist.integerValue];
            mistBtn.backgroundColor=[UIColor blueColor];
            ColorButton *colorBtn=(ColorButton *)[self.view viewWithTag:3000+color.integerValue];
            colorBtn.selected=YES;
            [colorBtn setNeedsDisplay];
            _lastSelectedColorBtn=colorBtn;
        }
        
        
        
    } deviceCfgDataFail:^(NSError *error) {
        
    }];
    [_device  start];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_device stop];
    _device=nil;
}

- (void)addView2Page:(UIScrollView *)scrollV count:(NSUInteger)pageCount frame:(CGRect)frame
{
    for (int i = 0; i < pageCount; i++)
    {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(scrollV.frame.size.width * i, 0, scrollV.frame.size.width, scrollV.frame.size.height)];
        
        view.tag = i + 1;
        view.userInteractionEnabled = YES;
  
    
       // [self initPageView:view];
        if(i==0)
        {
            float gap=30;
            NSArray *btnTitleArray=@[@"高亮",@"暗亮",@"熄灭"];
            float btnW=(self.view.frame.size.width-gap*(btnTitleArray.count+1))/(btnTitleArray.count);
            
            for(int j=0;j<[btnTitleArray count];j++)
            {
              UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
              [btn setFrame:CGRectMake(btnW * j+gap*(j+1), view.center.y-btnW/2, btnW, btnW)];
              [btn setTitle:[btnTitleArray objectAtIndex:j] forState:UIControlStateNormal];
              [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
              btn.tag = j + 1000+1;
              btn.titleLabel.font = [UIFont systemFontOfSize:MAX_MENU_FONT];
              [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
             
              [btn addTarget:self action:@selector(actionbtnlight:) forControlEvents:UIControlEventTouchUpInside];
               btn.layer.cornerRadius=btnW/2;
               btn.layer.borderWidth=1;
               btn.layer.borderColor=[UIColor lightGrayColor].CGColor;
              [view addSubview:btn];
            }
        }
        else if(i==1)
        {
            float gap=30;
            NSArray *btnTitleArray=@[@"全功率",@"半功率",@"停止"];
            float btnW=(self.view.frame.size.width-gap*(btnTitleArray.count+1))/(btnTitleArray.count);
            
            for(int j=0;j<[btnTitleArray count];j++)
            {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                [btn setFrame:CGRectMake(btnW * j+gap*(j+1), view.center.y-btnW/2, btnW, btnW)];
                [btn setTitle:[btnTitleArray objectAtIndex:j] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                btn.tag = j + 2000+1;
                btn.titleLabel.font = [UIFont systemFontOfSize:MAX_MENU_FONT];
                [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [btn addTarget:self action:@selector(actionbtnmist:) forControlEvents:UIControlEventTouchUpInside];
                btn.layer.cornerRadius=btnW/2;
                btn.layer.borderWidth=1;
                btn.layer.borderColor=[UIColor lightGrayColor].CGColor;
                [view addSubview:btn];
            }
            
            
        }
        else if(i==2)
        {
            
            float gap=10;
         
            float btnW=(self.view.frame.size.width-gap*(8))/(7);

            for(int j=0;j<7;j++)
            {
                //UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                ColorButton *btn=[[ColorButton alloc]initWithFrame:CGRectMake(btnW * j+gap*(j+1), view.center.y-btnW/2, btnW, btnW)];
                //[btn setTitle:[btnTitleArray objectAtIndex:j] forState:UIControlStateNormal];
                //[btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                btn.tag = j + 3000+1;
               // btn.titleLabel.font = [UIFont systemFontOfSize:MAX_MENU_FONT];
                //[btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [btn addTarget:self action:@selector(actionbtncolor:) forControlEvents:UIControlEventTouchUpInside];
                btn.layer.cornerRadius=btnW/2;
                btn.layer.borderWidth=1;
                btn.layer.borderColor=[UIColor lightGrayColor].CGColor;
                btn.layer.masksToBounds=YES;
                if(j==0)
                {
                   btn.backgroundColor=[UIColor colorWithRed:247/255.0 green:96/255.0 blue:98/255.0 alpha:1.0];
                }
                else  if(j==1)
                {
                    btn.backgroundColor=[UIColor colorWithRed:252/255.0 green:142/255.0 blue:51/255.0 alpha:1.0];
                }
                else  if(j==2)
                {
                    btn.backgroundColor=[UIColor colorWithRed:235/255.0 green:227/255.0 blue:111/255.0 alpha:1.0];
                }
                else  if(j==3)
                {
                    btn.backgroundColor=[UIColor colorWithRed:129/255.0 green:227/255.0 blue:129/255.0 alpha:1.0];
                }
                else  if(j==4)
                {
                    btn.backgroundColor=[UIColor colorWithRed:125/255.0 green:231/255.0 blue:239/255.0 alpha:1.0];
                }
                else  if(j==5)
                {
                    btn.backgroundColor=[UIColor colorWithRed:111/255.0 green:152/255.0 blue:235/255.0 alpha:1.0];
                }
                else  if(j==6)
                {
                    btn.backgroundColor=[UIColor colorWithRed:250/255.0 green:123/255.0 blue:243/255.0 alpha:1.0];
                }
               [view addSubview:btn];
              
                
            }
            
        }

        
        [scrollV addSubview:view];
    }
    [scrollV setContentSize:CGSizeMake(scrollV.frame.size.width * pageCount, scrollV.frame.size.height)];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)addText:(NSString *)str
{
    self.logTextView.text = [self.logTextView.text stringByAppendingFormat:@"%@\n",str];
    [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length, 1)];
}

#pragma mark - action
-(void)rightBtnClick
{
    
    HETDeviceInfoViewController *vc=[[HETDeviceInfoViewController alloc]init];
    vc.hetDeviceModel=self.hetDeviceModel;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)actionbtn:(UIButton *)btn
{
    [_scrollV scrollRectToVisible:CGRectMake(_scrollV.frame.size.width * (btn.tag - 1), _scrollV.frame.origin.y, _scrollV.frame.size.width, _scrollV.frame.size.height) animated:YES];
    
}
- (void)actionbtnlight:(UIButton *)btn
{
    
    
    self.updateFlag=1<<7;
    self.updateFlag=htonl(self.updateFlag);
    NSString *updateFlagStr=[NSString stringWithFormat:@"%08x",self.updateFlag];//800000
    int test=(4-(7/8)-1)*8+7%8;
    self.updateFlag=1<<test;
     updateFlagStr=[NSString stringWithFormat:@"%08x",self.updateFlag];
    self.light=btn.tag-1000;
    for(int j=0;j<3;j++)
    {
        UIButton *btn = (UIButton *)[self.view viewWithTag:1000+j+1];
   
        btn.backgroundColor=[UIColor whiteColor];
   
    }
    
   btn.backgroundColor=[UIColor blueColor];
  
  
    
}
- (void)actionbtnmist:(UIButton *)btn
{
    self.mist=btn.tag-2000;
    int test=(4-(6/8)-1)*8+6%8;
    self.updateFlag=1<<test;
     NSString *updateFlagStr=[NSString stringWithFormat:@"%08x",self.updateFlag];//800000
    for(int j=0;j<3;j++)
    {
        UIButton *btn = (UIButton *)[self.view viewWithTag:2000+j+1];
        
        btn.backgroundColor=[UIColor whiteColor];
        
    }
    
    btn.backgroundColor=[UIColor blueColor];
    
   
    
}
- (void)actionbtncolor:(ColorButton *)btn
{
  
    
    int test=(4-(19/8)-1)*8+19%8;
    self.updateFlag=1<<test;
    self.color=btn.tag-3000;
    self.updateFlag=1<<(31-19-1);//00000800
     NSString *updateFlagStr=[NSString stringWithFormat:@"%08x",self.updateFlag];//800000
    if(_lastSelectedColorBtn)
    {
        _lastSelectedColorBtn.selected=!_lastSelectedColorBtn.selected;
        [_lastSelectedColorBtn setNeedsDisplay];
    }
    btn.selected=!btn.selected;
  
    _lastSelectedColorBtn=btn;

    [btn setNeedsDisplay];
   
  

    
}
-(void)sendData
{
    
    self.ignoreCount=2;
    
      NSDictionary *dic=@{@"color":[NSString stringWithFormat:@"%lu",(unsigned long)self.color],@"light":[NSString stringWithFormat:@"%lu",(unsigned long)self.light],@"mist":[NSString stringWithFormat:@"%d",self.mist],@"presetShutdownTime":@"0",@"presetStartupTime":@"0",@"timeClose":@"0",@"updateFlag":[NSString stringWithFormat:@"%x",self.updateFlag]};
    AromaDiffuserDeviceConfigModel *model=[[AromaDiffuserDeviceConfigModel alloc]initWithDic:dic];
 
    [_device deviceControlRequestWithModel:model withSuccessBlock:^(id responseObject) {
        NSLog(@"发送成功:%@",responseObject);
    } withFailBlock:^(NSError *error) {
        NSLog(@"发送失败:%@",error);
    }];

}
-(void)scrollHandlePan:(UIPanGestureRecognizer*) panParam
{
    BOOL isPaning = NO;
    if(_scrollV.contentOffset.x < 0)
    {
        isPaning = YES;
        //        isLeftDragging = YES;
        //        [self showMask];
    }
    else if(_scrollV.contentOffset.x > (_scrollV.contentSize.width - _scrollV.frame.size.width))
    {
        isPaning = YES;
        //        isRightDragging = YES;
        //        [self showMask];
    }
    if(isPaning)
    {
       // [[QHSliderViewController sharedSliderController] moveViewWithGesture:panParam];
    }
}
- (void)changeView:(float)x
{
    //float xx = x * (self.view.frame.size.width/3 / self.view.frame.size.width);
    
    //    float endX = xx + MENU_BUTTON_WIDTH;
    //int sT =floor(x/_scrollV.frame.size.width);
    // 得到每页宽度
    CGFloat pageWidth = _scrollV.frame.size.width;
    // 根据当前的x坐标和页宽度计算出当前页数
    int currentPage = floor((x - pageWidth / 2) / pageWidth) + 1;

   // NSLog(@"当前页数:%d,坐标:%f,%f",currentPage,x,_scrollV.frame.size.width);
    if (currentPage <= 0)
    {
        //return;
    }
    for(int i=0;i<3;i++)
    {
        UIButton *btn2 = (UIButton *)[self.view viewWithTag:i + 1];
        
        [btn2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
  
    }
    UIButton *btn = (UIButton *)[self.view viewWithTag:currentPage+1];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _selectTabV.frame=CGRectMake(_btnW*(currentPage), MENU_HEIGHT, _btnW, 1);
    
   
  
}
-(NSString*)DataTOjsonString:(id)object
{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    
    return jsonString;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _startPointX = scrollView.contentOffset.x;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self changeView:scrollView.contentOffset.x];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{

    
}
//注意该方法常用在当用户滚动完屏幕时加载图片，HTTP请求加载，这样会提高效率
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSLog(@"%f,%f",(*targetContentOffset).x,(*targetContentOffset).y);
   
}


#pragma mark-----设备控制按钮
-(UIButton *)deviceControlButton
{
    if(!_deviceControlButton)
    {
        UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
          nextBtn.frame =  CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds)-64-44, CGRectGetWidth([UIScreen mainScreen].bounds), 44);
        [nextBtn setTitle:@"设备控制" forState:UIControlStateNormal];
        [nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [nextBtn addTarget:self action:@selector(sendData) forControlEvents:UIControlEventTouchUpInside];
         nextBtn.backgroundColor=[self colorFromHexRGB:@"2E7BD3"];
        _deviceControlButton=nextBtn;
        
    }
    return _deviceControlButton;
    
}


-(UITextView *)logTextView
{
    if(!_logTextView)
    {
        UITextView *textView=[[UITextView alloc]initWithFrame:CGRectZero];
        textView.backgroundColor=[UIColor lightGrayColor];
        textView.layoutManager.allowsNonContiguousLayout = NO;
        _logTextView=textView;
    }
    return _logTextView;
}
@end

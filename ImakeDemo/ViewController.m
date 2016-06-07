//
//  ViewController.m
//  ImakeDemo
//
//  Created by 俊王 on 16/4/14.
//  Copyright © 2016年 EB. All rights reserved.
//

#import "ViewController.h"
#import "JYParameterAlterView.h"
#import "JYParameterObject.h"
#import "YJTransmitAlterView.h"
#import "DXPopover.h"
#import "RealReachability.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "PeripheralInfo.h"
#import "SVProgressHUD.h"
#import "WXApi.h"

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif

#define channelOnPeropheralView @"peripheralView"

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

#define readwriteCharacteristicUUID  @"0000FFF1-0000-1000-8000-00805F9B34FB"
#define readwrite6CharacteristicUUID @"0000FFF6-0000-1000-8000-00805F9B34FB"
#define readCharacteristicUUID       @"0000FFF7-0000-1000-8000-00805F9B34FB"


@interface ViewController ()<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource,WXApiDelegate>
{
    CGFloat _popoverWidth;
    CGSize _popoverArrowSize;
    CGFloat _popoverCornerRadius;
    CGFloat _animationIn;
    CGFloat _animationOut;
    BOOL _animationSpring;
    
    
    NSMutableArray *peripherals;
    NSMutableArray *peripheralsAD;
    BabyBluetooth *baby;
}

@property (weak, nonatomic) IBOutlet UILabel *netwokeLable;

@property (weak, nonatomic) IBOutlet UILabel *deviceLabel;

@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;//昵称

@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;//连接目标

@property (weak, nonatomic) IBOutlet UIView *nickNameView;

@property (weak, nonatomic) IBOutlet UIView *connectionView;

@property (weak, nonatomic) IBOutlet UIButton *selectBtn;

@property (weak, nonatomic) IBOutlet UIButton *chooseBluetoothBtn;

@property (weak, nonatomic) IBOutlet UITextField *nickTextField;
@property (weak, nonatomic) IBOutlet UITextField *connectionTextField;

@property (nonatomic, strong) NSArray *configs;

@property (nonatomic, strong) NSMutableArray *sendMessageArray;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UITableView *bluetoothTableView;

@property (nonatomic, strong) DXPopover *popover;

@property (weak, nonatomic) IBOutlet UILabel *acceptDataLabel;// 连接数据

@property (nonatomic, strong) NSMutableArray *objectArray;

@property (nonatomic, strong) JYParameterObject *parameterObject;

@property __block NSMutableArray *services;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIView *sendView;

/// 蓝牙
@property (nonatomic,strong)CBCharacteristic *characteristic1;
@property (nonatomic,strong)CBCharacteristic *characteristic6;

- (IBAction)sureButtonClick:(id)sender;

- (IBAction)parameterButtonClick:(id)sender;

- (IBAction)firmwareButtonClick:(id)sender;

- (IBAction)authLogin:(id)sender;

@property(strong,nonatomic) CBPeripheral *currPeripheral;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.services = [[NSMutableArray alloc]init];
    self.sendMessageArray = [[NSMutableArray alloc] init];

    self.nickTextField.delegate = self;
    self.connectionTextField.delegate = self;
    
    JYParameterObject *object = [[JYParameterObject alloc] init];
    object.minPiston = @"3d09";
    object.maxPiston = @"ffff";
    object.minMotor  = @"1a";
    object.maxMotor  = @"c8";
    object.threshold = @"a";
    
    UITableView *blueView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, _popoverWidth, 120) style:UITableViewStyleGrouped];
    self.tableView = blueView;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    UITableView *bluetoothView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 260, 300) style:UITableViewStyleGrouped];
    self.bluetoothTableView = bluetoothView;
    self.bluetoothTableView.dataSource = self;
    self.bluetoothTableView.delegate = self;
    
    self.parameterObject = object;
    [self resetPopover];
    
    self.configs = @[
                     @"男",
                     @"女"];

    // RealReachability
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    if (status == RealStatusNotReachable)
    {
        self.netwokeLable.text = @"网络：未连接";
    }
    
    if (status == RealStatusViaWiFi)
    {
        self.netwokeLable.text = @"网络：连接成功";
    }
    
    if (status == RealStatusViaWWAN)
    {
        self.netwokeLable.text = @"网络：连接成功";
    }
    
    
    // BabyBlueTooth
    [SVProgressHUD showInfoWithStatus:@"准备打开设备"];
    
    //初始化其他数据 init other
    peripherals = [[NSMutableArray alloc]init];
    peripheralsAD = [[NSMutableArray alloc]init];
    
    //初始化BabyBluetooth 蓝牙库
    baby = [BabyBluetooth shareBabyBluetooth];
    //设置蓝牙委托
    [self babyDelegate];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    //停止之前的连接
    [baby cancelAllPeripheralsConnection];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
    //    baby.scanForPeripherals().begin();
    baby.scanForPeripherals().begin().stop(10);
    
    if (self.sendView == nil) {
        
        self.sendView = [[UIView alloc] initWithFrame:CGRectMake(0, 320, kWidth, kHeight - 320)];
        NSLog(@"%f",kHeight);
        [self.view addSubview:self.sendView];
    }
}

#pragma mark -蓝牙配置和操作

//蓝牙网关初始化和委托方法设置
-(void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {

            
        }
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        
        if (peripheral.name != nil) {
            
            [weakSelf insertTableView:peripheral advertisementData:advertisementData];
        }
    }];
    
    //设置发现设备的Services的委托
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
//        for (CBService *service in peripheral.services) {
//            NSLog(@"搜索到服务:%@",service.UUID.UUIDString);
//        }
        
        
        for (int i=0;i<peripherals.count;i++) {
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell.textLabel.text == peripheral.name) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu个service",(unsigned long)peripheral.services.count];
            }
        }
    }];
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
//        NSLog(@"===service name:%@",service.UUID);
//        for (CBCharacteristic *c in service.characteristics) {
//            NSLog(@"charateristic name is :%@",c.UUID);
//        }
    }];
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
//        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
//        for (CBDescriptor *d in characteristic.descriptors) {
//            NSLog(@"CBDescriptor name is :%@",d.UUID);
//        }
    }];
    
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
    }];
    
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelScanBlock");
    }];
    
    
    /*设置babyOptions
     
     参数分别使用在下面这几个地方，若不使用参数则传nil
     - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
     - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
     - [peripheral discoverServices:discoverWithServices];
     - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
     
     该方法支持channel版本:
     [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}


-(void)loadData{
    [SVProgressHUD showInfoWithStatus:@"开始连接设备"];
    baby.having(self.currPeripheral).and.channel(channelOnPeropheralView).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
    //    baby.connectToPeripheral(self.currPeripheral).begin();
}

//babyDelegate
-(void)babyConnectDelegate{
    
    __weak typeof(self) weakSelf = self;
    BabyRhythm *rhythm = [[BabyRhythm alloc] init];
    
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [baby setBlockOnConnectedAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral) {
//        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接成功",peripheral.name]];
        
        weakSelf.deviceLabel.text = @"设备：连接成功";
        
    }];
    
    //设置设备连接失败的委托
    [baby setBlockOnFailToConnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        weakSelf.deviceLabel.text = @"设备：未成功";

//        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--连接失败",peripheral.name]];
    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnectAtChannel:channelOnPeropheralView block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        weakSelf.deviceLabel.text = @"设备：未成功";

//        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--断开失败",peripheral.name]];
    }];
    
    //设置发现设备的Services的委托
    [baby setBlockOnDiscoverServicesAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, NSError *error) {
//        for (CBService *s in peripheral.services) {
//            NSLog(@"搜索到的%@",s);
//            ///插入section到tableview
//            [weakSelf insertSectionToTableView:s];
//        }
        
        [rhythm beats];
    }];
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristicsAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===service name:%@",service.UUID);
        for (CBCharacteristic *c in service.characteristics)
        {
//            NSLog(@"------%@",c);
            NSLog(@"c.properties:%@",c.UUID);
            
            NSString *uuidString = [NSString stringWithFormat:@"%@",c.UUID];
            //Subscribing to a Characteristic’s Value 订阅
            [peripheral setNotifyValue:YES forCharacteristic:c];
            
            // read the characteristic’s value，回调didUpdateValueForCharacteristi
            [peripheral readValueForCharacteristic:c];
            
            if ([uuidString isEqualToString:readwriteCharacteristicUUID]) {
                
                weakSelf.characteristic1 = c;
            }
            else if([uuidString isEqualToString:readwrite6CharacteristicUUID]){
                
                weakSelf.characteristic6 = c;
            }
        }

        //插入row到tableview
//        [weakSelf insertRowToTableView:service];
        
    }];
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristicAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
//        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    
    [baby setBlockOnDidWriteValueForCharacteristicAtChannel:channelOnPeropheralView block:^(CBCharacteristic *characteristic, NSError *error) {
        
//        NSLog(@"--- name:%@ value is:%@",characteristic.UUID,characteristic.value);

    }];
    
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
//        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
//        for (CBDescriptor *d in characteristic.descriptors) {
//            NSLog(@"CBDescriptor name is :%@",d.UUID);
//        }
    }];
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptorsAtChannel:channelOnPeropheralView block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
//        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //读取rssi的委托
    [baby setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
//        NSLog(@"setBlockOnDidReadRSSI:RSSI:%@",RSSI);
    }];
    
    
    //设置beats break委托
    [rhythm setBlockOnBeatsBreak:^(BabyRhythm *bry) {
//        NSLog(@"setBlockOnBeatsBreak call");
        
        //如果完成任务，即可停止beat,返回bry可以省去使用weak rhythm的麻烦
        //        if (<#condition#>) {
        //            [bry beatsOver];
        //        }
        
    }];
    
    //设置beats over委托
    [rhythm setBlockOnBeatsOver:^(BabyRhythm *bry) {
//        NSLog(@"setBlockOnBeatsOver call");
    }];
    
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    [baby setBabyOptionsAtChannel:channelOnPeropheralView scanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    
}

#pragma mark -UIViewController 方法
//插入table数据
-(void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData{
    if(![peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        [peripherals addObject:peripheral];
        [peripheralsAD addObject:advertisementData];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (void)resetPopover {
    self.popover = [DXPopover new];
    _popoverWidth = 100;
}

- (void)showPopover {
    [self updateTableViewFrame];
    
    CGPoint startPoint =
    CGPointMake(CGRectGetMidX(self.selectBtn.frame), CGRectGetMaxY(self.selectBtn.frame) + 5);
    [self.popover showAtPoint:startPoint
               popoverPostion:DXPopoverPositionDown
              withContentView:self.tableView
                       inView:self.navigationController.view];
    
    __weak typeof(self) weakSelf = self;
    self.popover.didDismissHandler = ^{
        [weakSelf bounceTargetView:weakSelf.selectBtn];
    };
}

-(void)showBluetoothPopover{
    
    [self updateTableViewFrame];
    
    [self babyConnectDelegate];

    CGPoint startPoint =
    CGPointMake(CGRectGetMidX(self.chooseBluetoothBtn.frame), CGRectGetMaxY(self.chooseBluetoothBtn.frame) + 5);
    [self.popover showAtPoint:startPoint
               popoverPostion:DXPopoverPositionDown
              withContentView:self.bluetoothTableView
                       inView:self.navigationController.view];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(reloadTableViewData:) userInfo:nil repeats:YES];
    
    __weak typeof(self) weakSelf = self;
    self.popover.didDismissHandler = ^{
        [weakSelf bounceTargetView:weakSelf.chooseBluetoothBtn];
    };
}

-(void)reloadTableViewData:(id)sender{
    
    [self.bluetoothTableView reloadData];
}

- (void)updateTableViewFrame {
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.width = _popoverWidth;
    self.tableView.frame = tableViewFrame;
    self.popover.contentInset = UIEdgeInsetsZero;
    self.popover.backgroundColor = [UIColor whiteColor];
}

- (void)bounceTargetView:(UIView *)targetView {
    targetView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         targetView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

#pragma mark 
#pragma mark TableViewDataSource and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.bluetoothTableView) {
        
        NSLog(@"%ld",(unsigned long)peripherals.count);
        
        return peripherals.count;
    }
    return self.configs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellId];
    }
    
    if (tableView == self.tableView) {
        
        cell.textLabel.text = self.configs[indexPath.row];

    }
    else{
        
        CBPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
//        NSDictionary *ad = [peripheralsAD objectAtIndex:indexPath.row];
        NSString *localName;
        localName = peripheral.name;
        cell.textLabel.text = localName;
        NSLog(@"----%@",peripheral.RSSI);
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",peripheral.RSSI];

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.bluetoothTableView) {
        
        self.currPeripheral = peripherals[indexPath.row];
        
        [self loadData];
        
        [self.timer invalidate];
        self.timer = nil;
    }
    else{
        
        [self.selectBtn setTitle:self.configs[indexPath.row] forState:UIControlStateNormal];

    }
    
    [self.popover dismiss];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark
#pragma mark NetworkingNotification

- (void)networkChanged:(NSNotification *)notification
{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    ReachabilityStatus previousStatus = [reachability previousReachabilityStatus];
    NSLog(@"networkChanged, currentStatus:%@, previousStatus:%@", @(status), @(previousStatus));
    
    if (status == RealStatusNotReachable)
    {
        self.netwokeLable.text = @"网络：未连接";
    }
    
    if (status == RealStatusViaWiFi)
    {
        self.netwokeLable.text = @"网络：连接成功";
    }
    
    if (status == RealStatusViaWWAN)
    {
        self.netwokeLable.text = @"网络：连接成功";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)parameterButtonClick:(id)sender {

    
    [self sendAuthRequest];

    
//    NSArray *array = @[@"最小活塞周期",@"最大活塞周期",@"最小马达占空比",@"最大马达占空比",@"毛刺阈值"];
//    JYParameterAlterView *paramererView = [[JYParameterAlterView alloc] initwithTypeArray:array dismissBlock:^(NSInteger count) {
//        if (count == 10) {
//            
//            [paramererView updateUI];
//        }
//    }];
//    
//    paramererView.parameterObject = self.parameterObject;
//    [paramererView show];
}

#pragma mark 
#pragma mark firmwareButton

- (IBAction)firmwareButtonClick:(id)sender {
   
    __weak typeof(self) weakself = self;
    
    UIButton *btn = (UIButton *)sender;
    
    if (btn.tag == 100) {
       
        NSArray *array = @[@"最小活塞周期",@"最大活塞周期"];
        YJTransmitAlterView *paramererView = [[YJTransmitAlterView alloc] initwithTypeArray:array
                                                                               dismissBlock:^(NSInteger count,NSInteger index,NSString *textString) {
                                                                                   
                                                                                   if (count == 10000) {
                                                                                       
                                                                                       [weakself writeValueWith:index andString:textString];
                                                                                       NSLog(@"发送数据了");
                                                                                   }
                                                                               }];
        [paramererView show];
    }
    else if (btn.tag == 102){
    
        [self showPopover];
    }
    else if (btn.tag == 101){
        
        [self showBluetoothPopover];
    }
}

- (IBAction)authLogin:(id)sender {
    
    [self sendAuthRequest];

    
}

-(void)sendAuthRequest
{
    SendAuthReq* req =[[SendAuthReq alloc ] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"0744" ;
    [WXApi sendReq:req];
}

#pragma mark
#pragma mark makeSure
- (IBAction)sureButtonClick:(id)sender {

    UIButton *btn = (UIButton *)sender;
    [self.view endEditing:YES];
    
    if (btn.tag == 1000) {
        
        if (![_nickTextField.text isEqualToString:@""] && _nickTextField.text != nil) {
           
            self.nickNameView.hidden = YES;
            self.nicknameLabel.text = [NSString stringWithFormat:@"昵称：%@",_nickTextField.text];
        }
    }
    else{
        if (![_connectionTextField.text isEqualToString:@""] && _connectionTextField.text != nil) {
            
            self.connectionView.hidden = YES;
            self.connectionLabel.text = [NSString stringWithFormat:@"连接目标：%@",_connectionTextField.text];
        }
    }
}

#pragma mark 
#pragma mark UITextFieldDelegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.nickTextField) {
        
        self.nickTextField.text = textField.text;
    }
    else if(textField == self.connectionTextField){
        
        self.connectionTextField.text = textField.text;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

//写一个值
-(void)writeValueWith:(NSInteger)integer andString:(NSString *)textString{
    
    NSData *fnameStr = [self hexStringFromString:textString];
    
    NSLog(@"fnameStr:%@",fnameStr);
    
//    fnameStr = [self stringFromHexString:fnameStr];
//    
//    NSLog(@"fnameStr:%@",fnameStr);

    if (integer == 0) {
        
        [self.sendMessageArray addObject:[NSString stringWithFormat:@"char1发了数据：%@",textString]];

//        Byte b = 0X02;
//        NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
        
        NSData *data =[textString dataUsingEncoding:NSUTF8StringEncoding];

        [self.currPeripheral writeValue:data forCharacteristic:self.characteristic1 type:CBCharacteristicWriteWithResponse];
        
    }
    else{
        
        [self.sendMessageArray addObject:[NSString stringWithFormat:@"char6发了数据：%@",textString]];
        
//        Byte ACkValue[3] = {0};
//        ACkValue[0] = 0xe0; ACkValue[1] = 0x00; ACkValue[2] = ACkValue[0] + ACkValue[1];
//        NSData *data1 = [NSData dataWithBytes:&ACkValue length:sizeof(ACkValue)];

//        Byte b = 0X08;
//        NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
        
        NSData *data =[textString dataUsingEncoding:NSUTF8StringEncoding];

        [self.currPeripheral writeValue:data forCharacteristic:self.characteristic6 type:CBCharacteristicWriteWithResponse];
    }
    [self creatSendMessageLable];

}



-(NSData *)hexStringFromString:(NSString *)string{
    NSString *hexString = string; //16进制字符串
    Byte bytes[4];  ///3ds key的Byte 数组， 128位
    for(int i = 0; i < [hexString length];i++)
    {
        bytes[i] = [[hexString substringWithRange:NSMakeRange(0, 2)] integerValue];
    }
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    NSLog(@"newData=%@",newData);
    
    return newData;
}


-(void)creatSendMessageLable{

    for (UILabel *labelView in self.sendView.subviews) {
        
        [labelView removeFromSuperview];
    }

    for (NSInteger i = 0; i < self.sendMessageArray.count; i++) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 16*i, 200, 12)];
        label.font = [UIFont systemFontOfSize:10.0f];
        label.textColor = [UIColor brownColor];
        label.text = self.sendMessageArray[i];
        [self.sendView addSubview:label];
    }
}



@end

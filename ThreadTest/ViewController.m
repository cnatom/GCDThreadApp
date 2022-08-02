//
//  ViewController.m
//  ThreadTest
//
//  Created by atom on 2022/8/1.
//
#import <Masonry.h>
#import "ViewController.h"

@interface ViewController ()
@property(nonatomic, strong) UIButton *afterButton;
@property(nonatomic, strong) UIButton *groupButton;
@property(nonatomic, strong) UIButton *groupWaitButton;
@property(nonatomic, strong) UIButton *applyButton;
@property(nonatomic, strong) UIButton *onceButton;

@property(nonatomic, assign) UIEdgeInsets buttonMargins;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setConstraintsParam];
    [self setConstraints];
}

#pragma mark - 约束

- (void)setConstraints {
    [self.afterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        [make centerX];
    }];
    [self.groupButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.afterButton.mas_bottom).offset(self.buttonMargins.top);
        [make centerX];
    }];
    [self.groupWaitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.groupButton.mas_bottom).offset(self.buttonMargins.top);
        [make centerX];
    }];
    [self.applyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.groupWaitButton.mas_bottom).offset(self.buttonMargins.top);
        [make centerX];
    }];
    [self.onceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.applyButton.mas_bottom).offset(self.buttonMargins.top);
        [make centerX];
    }];

}

#pragma mark 约束 - 参数

- (void)setConstraintsParam {
    self.buttonMargins = UIEdgeInsetsMake(15, 0, 0, 0);
}

#pragma mark - 函数

/**
 * 使用 dispatch_after可以实现延时执行任务的效果，需要注意的是任务会在指定延时后提交到队列，
 * 而任务真正的执行的时间点是未知的。在需要大致延时的情况下 dispatch_after 还是比较有效的
 */
- (IBAction)after_func:(UIButton *)sender {
    NSLog(@"开始执行after_func:%@", NSThread.currentThread);
    NSLog(@"2s后打印HelloWorld:");
    dispatch_time_t time1 = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);//延时2s
    dispatch_queue_t serialQueue = dispatch_get_main_queue(); // 串行队列
    dispatch_after(time1, serialQueue, ^{
        NSLog(@"HelloWorld! :%@", NSThread.currentThread);
    });
}

/**
 * 如果希望在一个 Dispatch Queue 中所有任务执行完或者多个 Dispatch Queue 中的所有任务执行完后再执行某任务，
 * 可以通过dispatch_group、dispatch_group_notify 实现
 */
- (IBAction)group_func:(id)sender {
    NSLog(@"开始执行group_func:%@", NSThread.currentThread);
    dispatch_group_t group = dispatch_group_create();//创建group

    dispatch_queue_t concurrentQueue = dispatch_queue_create("group_func.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    // 添加任务到group(异步并行执行)
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"block0 = %@", NSThread.currentThread);
    });
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"block1 = %@", NSThread.currentThread);
    });
    //group中所有的任务都执行完之后再回主线程执行
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"group执行完毕，执行notify:%@", NSThread.currentThread);
    });
}

/**
 * 使用 dispatch_group_wait 可以设置等待 group 执行的时间上限，
 * 当 group 中全部任务执行完或者满足 timeout 条件 dispatch_group_wait 才返回，
 * 可通过返回值区分两种返回类型
 */
- (IBAction)group_wait_func:(id)sender {
    NSLog(@"开始执行group_wait_func:%@", NSThread.currentThread);
    dispatch_group_t group = dispatch_group_create();//创建group
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //追加任务到group
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"block0 = %@", NSThread.currentThread);
    });
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"block1 = %@", NSThread.currentThread);
    });
    //设置延时时间
    int64_t delay1 = NSEC_PER_USEC; // 每微秒纳秒，group中的任务完不成，dispatch_group_wait()不为0
    int64_t delay2 = NSEC_PER_SEC; // 秒，保证group内所有任务都能完成，dispatch_group_wait()返回0
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1 * delay1);
    // 如果返回0，说明group所有任务都执行完了。否则，未执行完
    long result = dispatch_group_wait(group, time);
    if (result == 0) {
        NSLog(@"group中所有任务都执行完毕!:%@", NSThread.currentThread);
    } else {
        NSLog(@"超过等待时间，group中任务没有执行完(还在执行）:%@", NSThread.currentThread);
    }
}

/**
 * GCD 提供了 dispatch_apply 接口用于实现快速迭代，
 * dispatch_apply 将按照指定的次数将指定的任务追加到派发队列，
 * 并等待队列中全部任务执行结束 \n\n
 * dispatch_apply 和 dispatch_sync 函数类似，会等待队列中的任务执行结束，
 * 在主线程中使用可能引起卡顿问题或者发生死锁，尽量在 dispatch_async 函数中非同步地执行 dispatch_apply
 */
- (IBAction)apply_func:(id)sender {
    NSLog(@"开始执行apply_func:%@", NSThread.currentThread);
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(10, concurrentQueue, ^(size_t iter) {
        NSLog(@"%@ : %@", @(iter), NSThread.currentThread);
    });
}

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (IBAction)once_func:(id)sender {
    NSLog(@"开始执行once_func:%@", NSThread.currentThread);

}

#pragma mark - 组件
#pragma mark Getter

- (UIButton *)afterButton {
    if (_afterButton == NULL) {
        _afterButton = [self createButtonWithTitle:@"DispatchAfter" action:@selector(after_func:)];
    }
    return _afterButton;
}

- (UIButton *)groupButton {
    if (_groupButton == NULL) {
        _groupButton = [self createButtonWithTitle:@"DispatchGroup" action:@selector(group_func:)];
    }
    return _groupButton;
}

- (UIButton *)groupWaitButton {
    if (_groupWaitButton == NULL) {
        _groupWaitButton = [self createButtonWithTitle:@"DispatchWaitGroup" action:@selector(group_wait_func:)];
    }
    return _groupWaitButton;
}

- (UIButton *)applyButton {
    if (_applyButton == NULL) {
        _applyButton = [self createButtonWithTitle:@"DispatchApply" action:@selector(apply_func:)];
    }
    return _applyButton;
}


#pragma mark Creater

/**
 * 创建统一外观的UIButton
 * @param title 按钮文字
 * @param action 执行的函数
 * @return UIButton
 */
- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *newButton = [UIButton new];
    UIButtonConfiguration *uiConfig = UIButtonConfiguration.borderedProminentButtonConfiguration;
    uiConfig.title = title;
    uiConfig.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    newButton.configuration = uiConfig;
    [newButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:newButton];
    return newButton;
}


@end

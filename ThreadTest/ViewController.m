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

@property(nonatomic, assign) UIEdgeInsets buttonMargins;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setConstrainsParam];
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

}

#pragma mark 参数

- (void)setConstrainsParam {
    self.buttonMargins = UIEdgeInsetsMake(15, 0, 0, 0);
}

#pragma mark - 函数

- (IBAction)after_func:(UIButton *)sender {
    NSLog(@"dispatch_after  2s后打印HelloWorld:");
    dispatch_time_t time1 = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);//延时2s
    dispatch_queue_t queue1 = dispatch_get_main_queue(); // 串行队列
    dispatch_after(time1, queue1, ^{
        NSLog(@"HelloWorld!");
    });
}

- (IBAction)group_func:(id)sender {
    NSLog(@"开始执行group:");
    //创建group
    dispatch_group_t group = dispatch_group_create();
    // 添加任务到group
    dispatch_queue_t concurrentQueue = dispatch_queue_create("group_func.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t serialQueue = dispatch_queue_create("group_func.serialQueue", DISPATCH_QUEUE_SERIAL);

    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"block0 = %@", NSThread.currentThread);
        NSLog(@"block0");
    });
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"block1 = %@", NSThread.currentThread);
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC);
        dispatch_sync(serialQueue, ^{
            NSLog(@"block2 = %@", NSThread.currentThread);
            dispatch_after(delay, serialQueue, ^(){
                NSLog(@"block1:我是延时任务");
            });
        });
    });
    //group中所有的任务都执行完之后再执行
    dispatch_group_notify(group, serialQueue, ^{
        NSLog(@"group执行完毕，执行notify");
    });
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


#pragma mark Creater

/**
 * 创建统一外观的UIButton
 * @param title 按钮文字
 * @param action 执行的函数
 * @return UIButton
 */
- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *newButton = [UIButton new];
    [newButton setTitle:title forState:UIControlStateNormal];
    [newButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [newButton setBackgroundColor:[UIColor systemBlueColor]];
    [newButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:newButton];
    return newButton;
}


@end

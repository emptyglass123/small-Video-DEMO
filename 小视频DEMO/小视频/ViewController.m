//
//  ViewController.m
//  小视频
//
//  Created by 朱辉 on 16/4/18.
//  Copyright © 2016年 JXX. All rights reserved.
//

#import "ViewController.h"
#import "WDSmallVideoViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor =[UIColor whiteColor];
    button.frame = CGRectMake(100, 100, 100, 40);
    button.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [self.view addSubview:button];
    [button addTarget:self action:@selector(gotoVideo) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"小视频" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:20.0f/255.0f green:107.0f/255.0f blue:254.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    button.layer.cornerRadius = 2.f;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:20.0f/255.0f green:107.0f/255.0f blue:254.0f/255.0f alpha:1.0].CGColor;
    button.clipsToBounds = YES;
    
}

-(void)gotoVideo{
    WDSmallVideoViewController *video = [[WDSmallVideoViewController alloc] init];
    [self.navigationController pushViewController:video animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

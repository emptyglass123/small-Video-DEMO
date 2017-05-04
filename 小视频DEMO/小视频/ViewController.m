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


    self.view.backgroundColor = [UIColor  lightGrayColor];
    

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor =[UIColor blackColor];
    button.frame = CGRectMake(100, 100, 50, 20);
    button.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [self.view addSubview:button];
    [button addTarget:self action:@selector(gotoVideo) forControlEvents:UIControlEventTouchUpInside];
    


}

-(void)gotoVideo
{
    WDSmallVideoViewController *video = [[WDSmallVideoViewController alloc] init];
    [self.navigationController pushViewController:video animated:YES];
    

    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  ViewController.m
//  webview嵌套tableview
//
//  Created by delinshe on 2019/5/6.
//  Copyright © 2019 tl.com.666. All rights reserved.
//

#import "NewsDetailController.h"
#import <MJRefresh/MJRefresh.h>
//屏幕宽度
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
//屏幕高度
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
//view高度
#define VIEW_HEIGHT_WEB [UIScreen mainScreen].bounds.size.height-64

@interface NewsDetailController ()<UIScrollViewDelegate,UIWebViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong)UIScrollView *containerScrollView;
@property (nonatomic,strong)UIWebView *webView;
@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *topView;

@property (nonatomic,assign)CGFloat lastWebViewContentHeight;
@property (nonatomic,assign)CGFloat lastTableViewContentHeight;

@end

@implementation NewsDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"webview嵌套tableview";
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.lastWebViewContentHeight = 0;
    self.lastTableViewContentHeight = 0;
    
    
    //背景容器滚动视图
    self.containerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, VIEW_HEIGHT_WEB)];
    self.containerScrollView.delegate = self;
    self.containerScrollView.backgroundColor = [UIColor yellowColor];
    self.containerScrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.containerScrollView];
    
    self.containerScrollView.mj_footer = [MJRefreshFooter footerWithRefreshingBlock:^{
        [self.containerScrollView.mj_footer endRefreshing];
    }];
    
    
    [self.contentView addSubview:self.topView];
    [self.contentView addSubview:self.webView];
    [self.contentView addSubview:self.tableView];
    [self.view addSubview:self.containerScrollView];
    [self.containerScrollView addSubview:self.contentView];
    
    self.contentView.frame = CGRectMake(0, 0, SCREEN_WIDTH, VIEW_HEIGHT_WEB * 2);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.topView.frame), SCREEN_WIDTH, 1);
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.webView.frame), SCREEN_WIDTH, 1);
    
    [self.webView addObserver:self forKeyPath:@"scrollView.contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    
//    NSString *path = @"https://www.jianshu.com/p/f31e39d3ce41";
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]];
//    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
//    [self.webView loadRequest:request];
    
    NSMutableString *mstr = [NSMutableString string];
    for (int i=0; i<100; i++) {
        [mstr appendString:@"<p>这是一段话</p>"];
    }
    [self.webView loadHTMLString:mstr baseURL:nil];
}

- (void)loadData {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == _webView) {
        if ([keyPath isEqualToString:@"scrollView.contentSize"]) {
            [self updateContainerScrollViewContentSize:0 webViewContentHeight:0];
        }
    }else if(object == _tableView) {
        if ([keyPath isEqualToString:@"contentSize"]) {
            [self updateContainerScrollViewContentSize:0 webViewContentHeight:0];
        }
    }
}

- (void)updateContainerScrollViewContentSize:(NSInteger)flag webViewContentHeight:(CGFloat)inWebViewContentHeight{
    
    CGFloat webViewContentHeight = flag==1 ?inWebViewContentHeight :self.webView.scrollView.contentSize.height;
    CGFloat tableViewContentHeight = self.tableView.contentSize.height;
    
    if (webViewContentHeight == _lastWebViewContentHeight && tableViewContentHeight == _lastTableViewContentHeight) {
        return;
    }
    
    _lastWebViewContentHeight = webViewContentHeight;
    _lastTableViewContentHeight = tableViewContentHeight;
    
    self.containerScrollView.contentSize = CGSizeMake(self.view.mj_x, self.webView.mj_y + webViewContentHeight + tableViewContentHeight);
    
    CGFloat webViewHeight = (webViewContentHeight < self.view.mj_h ?webViewContentHeight :self.view.mj_h);
    CGFloat tableViewHeight = tableViewContentHeight < self.view.mj_h ?tableViewContentHeight :self.view.mj_h;
    self.webView.mj_h = webViewHeight <= 0.1 ?0.1 :webViewHeight;
    self.contentView.mj_h = self.webView.mj_y + webViewHeight + tableViewHeight;
    self.tableView.mj_h = tableViewHeight;
                             CGFloat jk_bottom = self.webView.mj_y+ self.webView.mj_h;
    self.tableView.mj_y = jk_bottom;
    
    //Fix:contentSize变化时需要更新各个控件的位置
    [self scrollViewDidScroll:self.containerScrollView];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (_containerScrollView != scrollView) {
        return;
    }
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    CGFloat webViewHeight = self.webView.mj_h;
    CGFloat tableViewHeight = self.tableView.mj_h;
    
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height;
    CGFloat tableViewContentHeight = self.tableView.contentSize.height;
    //CGFloat topViewHeight = self.topView.height;
    CGFloat webViewTop = self.webView.mj_y;
    
    CGFloat netOffsetY = offsetY - webViewTop;
    
    if (netOffsetY <= 0) {
        self.contentView.mj_y = 0;
        self.webView.scrollView.contentOffset = CGPointZero;
        self.tableView.contentOffset = CGPointZero;
    }else if(netOffsetY  < webViewContentHeight - webViewHeight){
        self.contentView.mj_y = netOffsetY;
        self.webView.scrollView.contentOffset = CGPointMake(0, netOffsetY);
        self.tableView.contentOffset = CGPointZero;
    }else if(netOffsetY < webViewContentHeight){
        self.contentView.mj_y = webViewContentHeight - webViewHeight;
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointZero;
    }else if(netOffsetY < webViewContentHeight + tableViewContentHeight - tableViewHeight){
        self.contentView.mj_y = offsetY - webViewHeight - webViewTop;
        self.tableView.contentOffset = CGPointMake(0, offsetY - webViewContentHeight - webViewTop);
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
    }else if(netOffsetY <= webViewContentHeight + tableViewContentHeight ){
        self.contentView.mj_y = self.containerScrollView.contentSize.height - self.contentView.mj_h;
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointMake(0, tableViewContentHeight - tableViewHeight);
    }else {
        //do nothing
        NSLog(@"do nothing");
    }
}

#pragma mark - UITableViewDataSouce
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.backgroundColor = [UIColor redColor];
    }
    
    cell.textLabel.text = @(indexPath.row).stringValue;
    return cell;
}



#pragma mark - private
- (UIWebView *)webView{
    if (_webView == nil) {
        _webView = [[UIWebView alloc] init];
        _webView.scrollView.scrollEnabled = NO;
    }
    return _webView;
}

- (UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        _tableView.scrollEnabled = NO;
        
        
    }
    return _tableView;
}

- (UIView *)contentView{
    if (_contentView == nil) {
        _contentView = [[UIView alloc] init];
    }
    
    return _contentView;
}

- (UIView *)topView{
    if (_topView == nil) {
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];
        _topView.backgroundColor = [UIColor yellowColor];
    }
    
    return _topView;
}

@end

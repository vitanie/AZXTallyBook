//
//  AZXAccountViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

// 1.Fetch也许需要一个predicate来限制其只fetch今天的日期 ~
// 2.说到日期又要实现页面上方显示日期 ~
// 3.接下来就处理另一个界面添加Account到CoreData了
// 4.这边应该能用了吧。。。

#import "AZXAccountViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "AZXAccountTableViewCell.h"
#import "AZXNewAccountTableViewController.h"
#import "AZXAccountMO.h"

@interface AZXAccountViewController () <NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, PassingDateDelegate>

@property (weak, nonatomic) IBOutlet UITableView *accountTableView;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSString *passedDate; // 从新建账单处传来的date值，用做Predicate筛选Fetch的ManagedObject

@end

@implementation AZXAccountViewController

// navigation控制时从下一界面返回时不会再次调用viewDidLoad，应用viewWillAppear
- (void)viewDidLoad {
    [super viewDidLoad];
    self.accountTableView.delegate = self;
    self.accountTableView.dataSource = self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.passedDate) { // 将控制器的标题设为当前日期
        self.title = self.passedDate;
    }

    [self initializeFetchedResultsController];

}

- (void)initializeFetchedResultsController {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
 
    [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.passedDate]];  // 根据传来的date筛选需要的结果
    
    NSSortDescriptor *date = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];  // 事实上同一界面account的date都是一样的，此处只是因为NSFetchRequeset必须要一个sort才加的
    
    [request setSortDescriptors:@[date]];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = appDelegate.managedObjectContext;
    
    [self setFetchedResultsController:[[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil]];
    
    [[self fetchedResultsController] setDelegate:self];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Failed to initiialize FetchedResultsController: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    //NSArray *hehe = [moc executeFetchRequest:request error:&error];
    //NSLog(@"%@", [[self fetchedResultsController] objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
    id object = [[self fetchedResultsController] fetchedObjects];
    NSLog(@"hehe:%@", object);
}

#pragma mark - UITableViewDataSource

- (void)configureCell:(AZXAccountTableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath {
    AZXAccountMO *account = [[self fetchedResultsController] fetchedObjects][indexPath.row];
    id object = [[self fetchedResultsController] fetchedObjects];
    NSLog(@"object: %@ account: %@", object, account);
    cell.typeName.text = account.type;
    cell.money.text = account.money;
    //cell.typeImage.image = [UIImage imageNamed:cell.typeName.text]; !!!!!!!!!!!!
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cellForRowAtIndexPath");
    AZXAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"numberOfSectionsInTableView: %lu", [[[self fetchedResultsController] sections] count]);
    return [[[self fetchedResultsController] sections] count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id< NSFetchedResultsSectionInfo> sectionInfo = [[self fetchedResultsController] sections][section];
    NSLog(@"numberOfRowsInSection: %lu", [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self accountTableView] beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSLog(@"type:%lu", (unsigned long)type);
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self accountTableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self accountTableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[[self accountTableView] cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [[self accountTableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[self accountTableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self accountTableView] endUpdates];
}


#pragma mark - PassingDateDelegate

-(void)viewController:(AZXNewAccountTableViewController *)controller didPassDate:(NSString *)date {
    self.passedDate = date;  // 接收从AZXNewAccountTableViewController传来的date值，用做Predicate来筛选Fetch的ManagedObject
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[AZXNewAccountTableViewController class]]) {  // segue时将self设为AZXNewAccountTableViewController的代理
        AZXNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.delegate = self;
    }
}


@end

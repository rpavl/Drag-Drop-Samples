
8#import "DragAndDrop.h"
#include <AVFoundation/AVFoundation.h>

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

@interface DragAndDrop () < UITableViewDelegate, UITableViewDelegate, UITableViewDataSource>{
    MyAppDelegate *appDelegate{
    bool dragOnce;//Make sure gesture is initialised only once
    CGPoint oldCord; //Dragged icons initial location
    CGPoint locationPoint; //Dragged icons location durgin gesture
    NSMutableArray *expanded;//Bools for which sections are expanded
    bool begin; //Initialise
    NSString *draggedName;//name of dragged icon
     //Get index Row and Section of icon being handeled
    int draggedInnerIndex;
    int draggedOutterIndex;
    float tempSize;//Gets icon size and increase temporarily to create gesture feedback
    float dragOffset;//Compensate for drag offset
    int lastButton;//Last button you hovered over
    vector < string > splitPath; //Array of stringd to host sample path segments
    UIVisualEffectView *blurEffectView; //Background Style

}


@property (nonatomic, retain) UICollectionView *collectionView;
@property (nonatomic, retain) UISegmentedControl *seg; //Segmented Control for switching between hands
@property (nonatomic, retain) UIView *segView;//Segmented Control Container
@property float iconSize;

@end


@implementation DragAndDrop


- (void)viewDidLoad {
    
    appDelegate=(MyAppDelegate *)[[UIApplication sharedApplication]delegate]

    [self createCollectionView];

    [super viewDidLoad];
}

//Initialise collection view
-(void)createCollectionView{
    
    //Hide other menu
    _mainTableView.hidden = true;
    
    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0, 17, 0, 17);
    _collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*0.775) collectionViewLayout:layout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.contentMode = UIViewContentModeCenter;
    _collectionView.clipsToBounds = YES;
    _collectionView.backgroundColor = [UIColor colorWithRed:0 green:1.0 blue:1.0 alpha:0.0];
    
    //Populate array that determines whether section is expanded
    expanded =  [[NSMutableArray alloc] init];
    for(int i = 0; i < [appDelegate.sectionNames count]; i++)
        [expanded addObject: @YES];
    
    //Add section insets for layout
    layout.headerReferenceSize = CGSizeMake(0.0, SCREEN_HEIGHT*0.12);
    
    //Register the collectionView cell
    [_collectionView registerClass: [UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    
    //Register UICollectionHeaderView
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"collectionHeaderView"];
    
    [_collectionView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]];
    [self.view addSubview:_collectionView];
    
    
    
    //Constrain the position of collection view to left
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint
                                                 constraintWithItem:self.collectionView attribute:NSLayoutAttributeLeft
                                                 relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.view attribute:
                                                 NSLayoutAttributeLeft multiplier:1.0 constant:0];
    //Constrain the position of collection view to top
    NSLayoutConstraint *yConstraint = [NSLayoutConstraint
                                                 constraintWithItem:self.collectionView attribute:NSLayoutAttributeBottom
                                                 relatedBy:NSLayoutRelationEqual toItem:self.view attribute:
                                                 NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
    
    //Constrain collection view width to half of screen
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:SCREEN_WIDTH*0.5];
    //Constrain collection view height to full screen
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:SCREEN_HEIGHT*0.77];
    
    // Add constraints to superview
    [self.view addConstraints:@[ xConstraint, yConstraint, widthConstraint, heightConstraint]];
    
    //Initialise segmented control for selection between hands
    _segView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH*0.5, SCREEN_HEIGHT*0.11)];
    _segView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
    _segView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_segView];
    
    //Constrain the position of segmented control to left
    xConstraint = [NSLayoutConstraint
                   constraintWithItem:_segView attribute:NSLayoutAttributeLeft
                   relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.view attribute:
                   NSLayoutAttributeLeft multiplier:1.0 constant:0.0f];
    //Constrain the position of segmented control to top
    yConstraint = [NSLayoutConstraint
                   constraintWithItem:_segView attribute:NSLayoutAttributeBottom
                   relatedBy:NSLayoutRelationEqual toItem:self.collectionView attribute:
                   NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
    //Constrain segmented control width to half of screen
    widthConstraint = [NSLayoutConstraint constraintWithItem:_segView
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:1.0
                                                    constant:SCREEN_WIDTH*0.5];
    //Constrain segmented control height to 1/10 of screen
    heightConstraint = [NSLayoutConstraint constraintWithItem:_segView
                                                    attribute:NSLayoutAttributeHeight
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:nil
                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                   multiplier:1.0
                                                     constant:SCREEN_HEIGHT*0.11];
    // Add constraints to superview
    [self.view addConstraints:@[ xConstraint, yConstraint, widthConstraint, heightConstraint]];
    
    //Define segment control content
    _seg = [[UISegmentedControl alloc] initWithItems:[[NSArray alloc] initWithObjects:@"Left", @"Right", nil]];
    _seg.selectedSegmentIndex = 0;
    [_seg addTarget:self
             action:@selector(SegPressed)
   forControlEvents:UIControlEventValueChanged];
    _seg.tag = 17;
    _seg.translatesAutoresizingMaskIntoConstraints = NO;
    _seg.layer.cornerRadius = 0.0;
    _seg.layer.borderColor = [UIColor clearColor].CGColor;
    _seg.layer.borderWidth = 1.0f;
    _seg.layer.masksToBounds = YES;
    _seg.tintColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    _seg.segmentedControlStyle = UISegmentedControlStyleBar;
    
    UIFont *font = [UIFont systemFontOfSize:18];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                           forKey:NSFontAttributeName];
    [_seg setTitleTextAttributes:attributes
                        forState:UIControlStateNormal];
    [_segView addSubview:_seg];
    
    
    
    //Constrain segment control within it's container
    xConstraint = [NSLayoutConstraint
                             constraintWithItem:_seg attribute:NSLayoutAttributeLeft
                             relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:_segView attribute:
                             NSLayoutAttributeLeft multiplier:1.0 constant:0.0f];
    yConstraint = [NSLayoutConstraint
                             constraintWithItem:_seg attribute:NSLayoutAttributeBottom
                             relatedBy:NSLayoutRelationEqual toItem:_segView attribute:
                             NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
    
    widthConstraint = [NSLayoutConstraint constraintWithItem:_seg
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:1.0
                                                    constant:SCREEN_WIDTH*0.5];
    heightConstraint = [NSLayoutConstraint constraintWithItem:_seg
                                                    attribute:NSLayoutAttributeHeight
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:nil
                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                   multiplier:1.0
                                                     constant:SCREEN_HEIGHT*0.11];
    [self.view addConstraints:@[ xConstraint, yConstraint, widthConstraint, heightConstraint]];
    
}

//Segmented control action
-(void)SegPressed{
    [appDelegate switchHands];
    
    if(_seg.selectedSegmentIndex == 1)
        [self moveButtons:false];
    else [self moveButtons:true];
    
}

//Collection View Layout
//Icons Size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int rounded = roundf(([appDelegate.dragPathsFull[indexPath.section] count] - 1) / 4);
    int floor = rounded * 4;
    
    if(indexPath.row < 4)
        return CGSizeMake(_iconSize, _iconSize+17);
    else if(indexPath.row >= floor)
        return CGSizeMake(_iconSize + 7
                          , _iconSize+17);
    else return CGSizeMake(_iconSize, _iconSize);
    
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    
    if(begin)
        return [[appDelegate.dragPathsTemp objectAtIndex:section] count];
    else return 0;
    
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return [appDelegate.dragPathsTemp count];
    
}



//Section Header Setup
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"viewForSupplementaryElementOfKind: %@",kind);
    
    //Check if header or footer
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *headerView = nil;
        headerView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"collectionHeaderView" forIndexPath:indexPath];
        
        //Clear headers on page reload if they are out of sight
        NSArray *viewsToRemove = [headerView subviews];
        for (UIView *v in viewsToRemove) {
            [v removeFromSuperview];
        }
        
        headerView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0 blue:1 alpha:0.0];
        headerView.tag = indexPath.section;
        
        //Container for header content
        UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH*0.5, 50)];
        view.tag = indexPath.section;
        view.contentMode = UIViewContentModeCenter;
        view.clipsToBounds = YES;
        
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        headerView.contentMode = UIViewContentModeCenter;
        headerView.clipsToBounds = YES;
        
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.contentMode = UIViewContentModeScaleToFill;
        view.clipsToBounds = YES;
        
        //Title header
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*0.025, 0, SCREEN_WIDTH*0.5, 50)];
        label.text = [NSString stringWithFormat: @"%@(%li)", [appDelegate.sectionNames objectAtIndex:indexPath.section], [[appDelegate.dragPaths objectAtIndex:indexPath.section] count]];
        label.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
        label.adjustsFontSizeToFitWidth = YES;
        label.adjustsLetterSpacingToFitWidth = YES;
        label.minimumScaleFactor = 10.0f/12.0f;
        label.clipsToBounds = YES;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
    
        label.contentMode = UIViewContentModeCenter;
        label.clipsToBounds = YES;
        
        [view addSubview:label];
        
        
        //Button for expanding header section
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(expandSection:) forControlEvents:UIControlEventTouchUpInside];
        
        if([expanded objectAtIndex:indexPath.section] == @YES)
            button.selected = NO;
        else button.selected = YES;
        view.backgroundColor = [UIColor colorWithRed:0/255.0 green:1 blue:0 alpha:0.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"+" forState:UIControlStateNormal];
        [button setTitle:@"-" forState:UIControlStateSelected];
        button.frame = CGRectMake(0, 0, SCREEN_WIDTH*0.5, SCREEN_HEIGHT*0.13);
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, SCREEN_WIDTH*0.05);
        button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:28];
        [button.layer setBackgroundColor:[[UIColor colorWithRed:255/255.0 green:0/255.0 blue:0/255.0 alpha:0.0] CGColor]];
        button.tag = indexPath.section;
        
        [headerView addSubview:view];
        [headerView addSubview:button];

        return headerView;
    }
    
    return nil;
    
}



//Expand or minimise section below header
- (void)expandSection:(id)sender  {
    
    if(!begin){
        for(int i = 0; i < [appDelegate.sectionNames count]; i++)
            [appDelegate.dragPathsTemp replaceObjectAtIndex:i withObject:[[NSArray alloc] initWithObjects:nil]];
    }
    
    begin = true;
    
    UIButton *myButton = (UIButton*)sender;
    
    if([expanded objectAtIndex:myButton.tag] == @YES){
        [expanded replaceObjectAtIndex:myButton.tag withObject:@NO];
        [appDelegate.dragPathsTemp replaceObjectAtIndex:myButton.tag withObject:appDelegate.dragPaths[myButton.tag]];
        myButton.selected = NO;
    }else{
        [expanded replaceObjectAtIndex:myButton.tag withObject:@YES];
        [appDelegate.dragPathsTemp replaceObjectAtIndex:myButton.tag withObject:[[NSArray alloc] initWithObjects:nil]];
        myButton.selected = YES;
    }
    
    [self refreshDrag];
    
}

//Refresh Drag & Drop status
- (void) refreshDrag{
    [_collectionView reloadData];
    [_myTimer invalidate];
    _myTimer = nil;
}


//Handle drag icon movement and outcome
-(void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    //Get index Row and Section of icon being handeled
    draggedInnerIndex = [longPress.name intValue];
    draggedOutterIndex = longPress.view.tag;
    //Get name of icon
    draggedName = [appDelegate.dragPathsFull[draggedInnerIndex] objectAtIndex:draggedOutterIndex];
    //Get icon size and increase temporarily by %25 to create gesture feedback
    tempSize = longPress.view.frame.size.width * 1.25;
    
    //If handeling has just begun
    if(longPress.state == UIGestureRecognizerStateBegan)
    {
        //Get initial icons location for reference
        locationPoint = [longPress locationInView:longPress.view];
        locationPoint.y = locationPoint.y;
        [self.view bringSubviewToFront:longPress.view];
        //Compensate for drag offset
        dragOffset = -SCREEN_HEIGHT*0.19;
        
        //Get icon cell that is being handeled and scale up to signify gesture
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:draggedOutterIndex inSection:draggedInnerIndex]];
        for (UILabel *i in cell.subviews){
            if([i isKindOfClass:[UILabel class]]){
                UILabel *newLbl = (UILabel *)i;
                newLbl.frame = CGRectMake(0,0,tempSize,tempSize);
                newLbl.font=[newLbl.font fontWithSize:SCREEN_WIDTH*0.03];
                
                newLbl.layer.cornerRadius = newLbl.bounds.size.height / 2;
            }
        }
    }
    
    
    CGPoint newCoord = [longPress locationInView:longPress.view];
    float dX = newCoord.x-locationPoint.x;
    float dY = newCoord.y-locationPoint.y;
    longPress.view.frame = CGRectMake(longPress.view.frame.origin.x+dX,
                                      longPress.view.frame.origin.y+dY,
                                      tempSize,
                                      tempSize);
    
    
    
    [self.view addSubview:longPress.view];
    
    
    
    
    //Highlight buttons on hoover
    for(int i = 0; i < 16; i++){
        
        UIButton *temp = [self getLabelFromArrayAtIndex:i];
        if(longPress.view.frame.origin.x > temp.frame.origin.x - _iconSize/2 + xOffset + SCREEN_WIDTH*0.5 && longPress.view.frame.origin.x < temp.frame.origin.x + _iconSize/1.25 + xOffset + SCREEN_WIDTH*0.5
           
           && longPress.view.frame.origin.y > temp.frame.origin.y - _iconSize/2 + yOffset && longPress.view.frame.origin.y < temp.frame.origin.y + _iconSize/1.25 + yOffset){
            
            [appDelegate overButton: temp.tag: true];
            lastButton = temp.tag;
            
        }else{
            [appDelegate overButton: temp.tag : false];
            
        }
    }
    
    
    
    
    
    if (longPress.state == UIGestureRecognizerStateEnded){
        
        
        
        for(int i = 0; i < 16; i++){
            
            UIButton *temp = [self getLabelFromArrayAtIndex:i];
            
            if(longPress.view.frame.origin.x > temp.frame.origin.x - _iconSize/2 + xOffset + SCREEN_WIDTH*0.5 && longPress.view.frame.origin.x < temp.frame.origin.x + _iconSize/1.25 + xOffset + SCREEN_WIDTH*0.5
               
               && longPress.view.frame.origin.y > temp.frame.origin.y - _iconSize/2 + yOffset && longPress.view.frame.origin.y < temp.frame.origin.y + _iconSize/1.25 + yOffset){
                
                [appDelegate stopSamples];
                [appDelegate setTempPath  :[appDelegate.dragPathsFull[draggedInnerIndex] objectAtIndex:draggedOutterIndex]:  temp.tag  ];
            }
        }
        
        [_collectionView reloadData];
        for(int i = 0; i < 16; i++)
            [appDelegate overButton: i  : false];
    }
    
}

-(UIButton *)getLabelFromArrayAtIndex:(NSInteger)index{
    int i = 0;
    if(!appDelegate.bDrag)
        i = 1;
    else i = 0;
    
    UIView * temp;
    //Here, we are accessing the current view's subviews and looping through them
    for (UIView *v in btnView[i].subviews){
        //We are asking if the loop's current view (v) is a UILabel
        if ([v isKindOfClass:[UIButton class]]){
            //We know it's a label, now see if it has the correct tag (index)
            if (v.tag ==  index){
                //if so, return the UIView, cast as a UILabel
                return (UIButton *)v;
            }
            temp = (UIButton *)v;
        }
    }
    return temp;
}




#pragma mark - CollectionView Delegates

//Populate Collection View with cells
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0];
    cell.tag = indexPath.row;
    //cell.layer.masksToBounds = YES;

    //Clear subView in cell when reloading, in case they need to be refreshed
    for (UIView *view in cell.subviews){
        [view removeFromSuperview];
    }
    
    UILabel *sampleName;

    int rounded = roundf(([appDelegate.dragPathsFull[indexPath.section] count] - 1) / 4);
    int btmIndex = indexPath.row - rounded * 4;
    if(indexPath.row < 4)
        sampleName = [[UILabel alloc] initWithFrame:CGRectMake(0, 9, _iconSize, _iconSize)];
    else if(btmIndex == 1)
        sampleName = [[UILabel alloc] initWithFrame:CGRectMake(4, 0, _iconSize, _iconSize)];
    else if(btmIndex == 2)
        sampleName = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, _iconSize, _iconSize)];
    else if(btmIndex == 3)
        sampleName = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, _iconSize, _iconSize)];
    else sampleName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _iconSize, _iconSize)];
    
    sampleName.font=[sampleName.font fontWithSize:SCREEN_WIDTH*0.02];
    sampleName.textAlignment = NSTextAlignmentCenter;
    
    //Get sample path
    NSString * temp = [appDelegate.dragPathsFull[indexPath.section] objectAtIndex:indexPath.row];
    
    //Derive sample name from file path
    splitPath = ofSplitString([temp UTF8String], "/");
    splitPath = ofSplitString(splitPath[splitPath.size()-1], " ");
    splitPath = ofSplitString(splitPath[0],".");
    sampleName.text = [NSString stringWithCString:splitPath[0].c_str()
                                         encoding:[NSString defaultCStringEncoding]];
    
    sampleName.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
    //Apply blue color scheme to sound samples, and red to sound filters.
    if(indexPath.section != 7)
        sampleName.backgroundColor = [UIColor colorWithRed:0/255.0 green:51/255.0 blue:255/255.0 alpha:0.5];
    else sampleName.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.4 alpha:0.5];
    
    //Turn UILabel content box into a circle
    sampleName.layer.masksToBounds = YES;
    sampleName.layer.cornerRadius = sampleName.bounds.size.height / 2;
    
    [cell addSubview: sampleName];

    //Trigger handle press method after pressing sample for a minimum of 0.075 seconds
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.075 ; //seconds
    lpgr.name = [NSString stringWithFormat: @"%ld", (long)indexPath.section];;
    [cell addGestureRecognizer:lpgr];
    
    return cell;
    
}

//Press collectionView cell to preview sample sound
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
    
    if(indexPath.section != 7){
        [appDelegate setAmp:@(1.0)];
        [appDelegate soundPreview:std::string([[appDelegate.dragPathsFull[indexPath.section] objectAtIndex:indexPath.row] UTF8String])];
    }else{
        NSLog(@"Sound filters, no preview ");
    }
    
}



@end



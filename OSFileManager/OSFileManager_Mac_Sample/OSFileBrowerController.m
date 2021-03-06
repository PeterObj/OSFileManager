//
//  OSFileBrowerController.m
//  OSFileManager
//
//  Created by alpface on 2017/7/21.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "OSFileBrowerController.h"
#import "FileAttributedItem.h"
#import "OSFileManager.h"

@interface OSFileBrowerController ()

/** 正在拖拽的文件 */
@property (nonatomic, strong) NSArray<FileAttributedItem *> *draggingItems;
/** 当前拖拽松开文件 */
@property (nonatomic, strong) FileAttributedItem *currentDropItem;

@end

@implementation OSFileBrowerController

{
    id<OSFileOperation> _fileOperation;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // 对leftOutlineView进行注册拖放事件的监听
    [self.leftOutlineView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
    [self.leftOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    
    [self.rightOutlineView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
    [self.rightOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    
    [self.progressIndicator setUsesThreadedAnimation:YES];
    [self.progressIndicator startAnimation:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSOutlineViewDataSource
////////////////////////////////////////////////////////////////////////

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(nonnull NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(nonnull NSArray *)draggedItems {
    // 正在拖动的items
    _draggingItems = [draggedItems mutableCopy];
    
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    
    // 拖拽结束后 将拖拽的文件copy到目标文件夹中
    [_draggingItems enumerateObjectsUsingBlock:^(FileAttributedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 使用OSFileManager 操作文件
        
       _fileOperation = [[OSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:obj.fullPath] toURL:[NSURL fileURLWithPath:[_currentDropItem.fullPath stringByAppendingPathComponent:obj.fullPath.lastPathComponent]] progress:^(NSProgress *progress) {
            self.progressIndicator.doubleValue = progress.fractionCompleted;
            self.progressTextLabel.stringValue = [self progressStringWithProgress:progress];
            self.fileNameLabel.stringValue = obj.fullPath.lastPathComponent;
            if(progress.fractionCompleted >= 1) {
                [self.progressIndicator stopAnimation:nil];
            }
        } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
            
        }];
        
        
        // 使用OSFileOperationQueue 操作文件
//        [_fileOperationQueue copyItemAtURL:[NSURL fileURLWithPath:obj.fullPath] toURL:[NSURL fileURLWithPath:[_currentDropItem.fullPath stringByAppendingPathComponent:obj.fullPath.lastPathComponent]] progress:^(NSProgress *progress) {
//            NSLog(@"progress:(%f)", progress.fractionCompleted);
//        } completionHandler:^(id<OSFileOperation> fileOperation, NSError *error) {
//            NSLog(@"%ld", fileOperation.writeState);
//        }];
    }];
    
    [_fileOperationQueue performQueue];
    [OSFileManager defaultManager].totalProgressBlock = ^(NSProgress *progress) {
        self.progressIndicator.doubleValue = progress.fractionCompleted;
        if(progress.fractionCompleted >= 1) {
            [self.progressIndicator stopAnimation:nil];
        }
    };
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    _currentDropItem = item;
    return index == -1 ? NSDragOperationNone : NSDragOperationCopy;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    
    NSMutableArray *urls = [NSMutableArray array];
    
    [items enumerateObjectsUsingBlock:^(FileAttributedItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [urls addObject:[NSURL fileURLWithPath:obj.fullPath]];
    }];
    [pasteboard writeObjects:urls];
    return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return !item ? 1 : [[item childrenItems] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [[item childrenItems] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return !item ? [FileAttributedItem rootItem] : [[item childrenItems] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
}

- (NSString *)progressStringWithProgress:(NSProgress *)progress {
    NSString *receivedCopiedBytesStr = [NSByteCountFormatter stringFromByteCount:progress.completedUnitCount
                                                                      countStyle:NSByteCountFormatterCountStyleFile];
    NSString *totalBytesStr = [NSByteCountFormatter stringFromByteCount:progress.totalUnitCount countStyle:NSByteCountFormatterCountStyleFile];
    return [NSString stringWithFormat:@"[%@ of %@] -- [progress: %f]", receivedCopiedBytesStr, totalBytesStr, progress.fractionCompleted];
}
- (IBAction)cancel:(id)sender {
    
    if (_fileOperation) {
        [_fileOperation cancel];
        _fileOperation = nil;
    }
}


@end

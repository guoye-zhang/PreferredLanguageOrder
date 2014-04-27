#import "Tweak.h"

NSMutableArray *cellOrder;
NSMutableDictionary *preferences;

%hook PSInternationalLanguageController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    self.table.editing = YES;
    NSInteger numItems = [self tableView:self.table numberOfRowsInSection:0];
    cellOrder = [NSMutableArray arrayWithCapacity:numItems];
    for (NSInteger i = 0 ; i < numItems ; i ++)
        [cellOrder addObject:@(i)];
}

%new
- (NSInteger)tableView:(id)view editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

%new
- (BOOL)tableView:(id)view shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

%new
- (BOOL)tableView:(id)view canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

%new
- (void)tableView:(id)view moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    id temp = cellOrder[fromIndexPath.row];
    [cellOrder removeObjectAtIndex:fromIndexPath.row];
    [cellOrder insertObject:temp atIndex:toIndexPath.row];
    temp = self.cellCache[fromIndexPath];
    if (fromIndexPath.row < toIndexPath.row)
        for (NSInteger i = fromIndexPath.row; i < toIndexPath.row; i++)
            [self.cellCache setObject:self.cellCache[[NSIndexPath indexPathForRow:i + 1 inSection:0]] forKey:[NSIndexPath indexPathForRow:i inSection:0]];
    else
        for (NSInteger i = fromIndexPath.row; i > toIndexPath.row; i--)
            [self.cellCache setObject:self.cellCache[[NSIndexPath indexPathForRow:i - 1 inSection:0]] forKey:[NSIndexPath indexPathForRow:i inSection:0]];
    [self.cellCache setObject:temp forKey:toIndexPath];
}

- (void)doneButtonTapped {
    BOOL changed = NO;
    for (NSInteger i = 0; i < [cellOrder count]; i++)
        if ([cellOrder[i] integerValue] != i) {
            changed = YES;
            break;
        }
    if (changed) {
        preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/.GlobalPreferences.plist"];
        NSArray *languageList = [preferences objectForKey:@"AppleLanguages"];
        NSMutableArray *newLanguageList = [NSMutableArray arrayWithCapacity:[cellOrder count]];
        for (NSInteger i = 0; i < [cellOrder count]; i++)
            [newLanguageList addObject:languageList[[cellOrder[i] integerValue]]];
        [preferences setObject:newLanguageList forKey:@"AppleLanguages"];
        if ([cellOrder[0] integerValue] == 0) {
            [preferences writeToFile:@"/var/mobile/Library/Preferences/.GlobalPreferences.plist" atomically:YES];
            system("killall -HUP SpringBoard");
        } else
            [self tableView:self.table didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:[cellOrder[0] integerValue] inSection:0]];
    }
    %orig;
    cellOrder = nil;
}

- (void)cancelButtonTapped {
    %orig;
    cellOrder = nil;
}

%end

%hook PSLanguageSelector

- (void)setLanguage:(id)arg1 {
    %orig(arg1);
    [preferences writeToFile:@"/var/mobile/Library/Preferences/.GlobalPreferences.plist" atomically:YES];
    preferences = nil;
}

%end

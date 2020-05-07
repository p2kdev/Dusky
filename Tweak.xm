@interface CALayer (Undocumented)
	@property (assign) BOOL continuousCorners;
@end

@interface MTMaterialLayer : CALayer
	@property (assign,getter=isReduceTransparencyEnabled,nonatomic) BOOL reduceTransparencyEnabled;
	@property (assign,getter=isBlurEnabled,nonatomic) BOOL blurEnabled;
@end

@interface MTMaterialView : UIView
	-(id)_materialLayer;
	@property (assign,nonatomic) BOOL ignoresScreenClip;
@end

@interface PLShadowView : UIImageView

@end

@interface FBSystemService : NSObject
  +(id)sharedInstance;
  -(void)exitAndRelaunch:(BOOL)arg1;
@end

@interface NCNotificationViewControllerView : UIView

@end

static BOOL wantsCorners = YES;
static int cornerRadius = 20;
static BOOL lessTransparentDock = YES;
static BOOL lessTransparentNotif = YES;
static BOOL lessTransparentPlayer = YES;
static BOOL lessTransparentWidget = YES;
static BOOL lessTransparentFolder = YES;
static BOOL lessTransparentSpotlight = YES;
static BOOL lessTransparentHomeScreen = NO;
static BOOL wantsRestrictedLines = YES;
static int maxNumberOfLines = 2;

%hook MTMaterialView
	//-(id)_materialLayer
	- (void)layoutSubviews
	{
		%orig;
		MTMaterialLayer *orig = [self _materialLayer];

		bool shouldChangeCornerRadius = NO;

		//Player
		if (([self.superview class] == objc_getClass("PLPlatterView")) && lessTransparentPlayer)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}

		//Notifications
		if (([self.superview class] == objc_getClass("NCNotificationShortLookView")) && lessTransparentNotif)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}

		if (([self.superview class] == objc_getClass("NCNotificationShortLookView")) && lessTransparentNotif)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}

		if (([self.superview class] == objc_getClass("NCNotificationListCellActionButton")) && lessTransparentNotif)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}

		//Folder Background
		if (([self.superview class] == objc_getClass("SBFolderBackgroundView")) && lessTransparentFolder)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}

		//HomeScreen Folder Background
		if (([self.superview class] == objc_getClass("SBHomeScreenBackdropView")) && lessTransparentHomeScreen)
			orig.reduceTransparencyEnabled = YES;

		//Spotlight
		if (([self.superview class] == objc_getClass("SBSearchBackdropView")) && lessTransparentSpotlight)
			orig.reduceTransparencyEnabled = YES;

		//Widgets
		if (([self.superview class] == objc_getClass("WGWidgetPlatterView")) && lessTransparentWidget)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}

		//Dock
		if ((([self.superview class] == objc_getClass("SBDockView")) || ([self.superview class] == objc_getClass("SBFloatingDockView"))) && lessTransparentDock)
		{
			orig.reduceTransparencyEnabled = YES;
			shouldChangeCornerRadius = YES;
		}


		//Corner Radius, setting corner radius on folders causes respring
		if (wantsCorners && shouldChangeCornerRadius)
		{
			orig.cornerRadius = cornerRadius;
			//Thanks @bengiannis
			if (@available(iOS 13.0, *))
			    orig.cornerCurve = kCACornerCurveContinuous;
			else
				orig.continuousCorners = YES;

			orig.masksToBounds = YES;
		}

		//return orig;

	}
%end

//Fixes blurry corners for stacked notifications
%hook NCNotificationViewControllerView

	-(void)layoutSubviews
	{
		%orig;

		if (wantsCorners && lessTransparentNotif)
		{
			//MSHookIvar<UIView*>(self,"_stackDimmingView").alpha = 1;
			MSHookIvar<UIView*>(self,"_stackDimmingView").layer.cornerRadius = cornerRadius;
		}
	}
%end

//Fixes blurry corners on Banners
%hook PLShadowView

	-(void)layoutSubviews
	{
		%orig;

		if (([self.superview class] == objc_getClass("NCNotificationShortLookView")) && lessTransparentNotif && wantsCorners)
			self.hidden = YES;
	}
%end

//Restrict Max Notification Lines
%hook NCNotificationShortLookView

	-(void)setMaximumNumberOfPrimaryLargeTextLines:(unsigned long long)arg1
	{
		%orig(wantsRestrictedLines ? maxNumberOfLines : arg1);
	}

	-(void)setMaximumNumberOfSecondaryTextLines:(unsigned long long)arg1
	{
		%orig(wantsRestrictedLines ? maxNumberOfLines : arg1);
	}

	-(void)setMaximumNumberOfSecondaryLargeTextLines:(unsigned long long)arg1
	{
		%orig(wantsRestrictedLines ? maxNumberOfLines : arg1);
	}
%end

static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void reloadSettings() {

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.p2kdev.dusky.plist"];
	if(prefs)
	{

		wantsRestrictedLines = [prefs objectForKey:@"wantsRestrictedLines"] ? [[prefs objectForKey:@"wantsRestrictedLines"] boolValue] : wantsRestrictedLines;
		maxNumberOfLines = [prefs objectForKey:@"maxNumberOfLines"] ? [[prefs objectForKey:@"maxNumberOfLines"] intValue] : maxNumberOfLines;
    wantsCorners = [prefs objectForKey:@"wantsCorners"] ? [[prefs objectForKey:@"wantsCorners"] boolValue] : wantsCorners;
		cornerRadius = [prefs objectForKey:@"cornerRadius"] ? [[prefs objectForKey:@"cornerRadius"] intValue] : cornerRadius;
		lessTransparentWidget = [prefs objectForKey:@"lessTransparentWidget"] ? [[prefs objectForKey:@"lessTransparentWidget"] boolValue] : lessTransparentWidget;
		lessTransparentNotif = [prefs objectForKey:@"lessTransparentNotif"] ? [[prefs objectForKey:@"lessTransparentNotif"] boolValue] : lessTransparentNotif;
		lessTransparentPlayer = [prefs objectForKey:@"lessTransparentPlayer"] ? [[prefs objectForKey:@"lessTransparentPlayer"] boolValue] : lessTransparentPlayer;
		lessTransparentDock = [prefs objectForKey:@"lessTransparentDock"] ? [[prefs objectForKey:@"lessTransparentDock"] boolValue] : lessTransparentDock;
		lessTransparentFolder = [prefs objectForKey:@"lessTransparentFolder"] ? [[prefs objectForKey:@"lessTransparentFolder"] boolValue] : lessTransparentFolder;
		lessTransparentSpotlight = [prefs objectForKey:@"lessTransparentSpotlight"] ? [[prefs objectForKey:@"lessTransparentSpotlight"] boolValue] : lessTransparentSpotlight;
		lessTransparentHomeScreen = [prefs objectForKey:@"lessTransparentHomeScreen"] ? [[prefs objectForKey:@"lessTransparentHomeScreen"] boolValue] : lessTransparentHomeScreen;
	}
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.p2kdev.dusky.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring, CFSTR("com.p2kdev.dusky.respring"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

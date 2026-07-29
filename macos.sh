#!/usr/bin/env bash

# ~/.macos — https://mths.be/macos
# Modernized for macOS Sequoia (15.x)
# Last Sequoia sync: 2026-07

# Strict mode: exit on error, undefined vars are bugs, pipelines propagate failures
set -euo pipefail

# Warn (don't abort) if running on a macOS other than Sequoia
MACOS_VER="$(sw_vers -productVersion)"
if [[ "${MACOS_VER}" != 15.* ]]; then
	echo "Warning: this script is tuned for macOS 15 (Sequoia), detected ${MACOS_VER}." >&2
	echo "Some keys may differ on other releases. Continuing anyway..." >&2
fi

# Close any open System Settings panes to prevent override conflicts
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo time stamp until .macos has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Disable the sound effects on boot
# [MODIFIED: Apple Silicon uses StartupMute; SystemAudioVolume is Intel-era.
#  Try both — the non-applicable one is a harmless no-op.]
sudo nvram SystemAudioVolume=" " 2>/dev/null || true
sudo nvram StartupMute=%01 2>/dev/null || true

# Set sidebar icon size to medium (1=small, 2=medium, 3=large)
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Always show scrollbars (WhenScrolling/Automatic/Always)
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Disable the over-the-top focus ring animation
# Reduces visual distraction when text fields have focus
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

# Increase window resize speed for Cocoa applications
# Lower value = faster resize (0.001 is nearly instant)
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default (both old and new API)
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default (both old and new API)
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
# Disables quarantine warnings for downloaded applications
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Reset Launch Services to clear duplicate "Open With" entries
# [FIXED: was `systemextensionsctl reset`, which resets SYSTEM EXTENSIONS
#  (security/endpoint tools) — not Launch Services. Restored lsregister.]
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "${LSREGISTER}" ]]; then
	"${LSREGISTER}" -kill -r -domain local -domain system -domain user 2>/dev/null || true
fi

# Display ASCII control characters using caret notation in standard text views
# e.g. Control+C shows as ^C instead of non-printable character
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

# Disable Resume system-wide (don't restore windows on relaunch)
# [MODIFIED: System Preferences → System Settings path changed in Sequoia]
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Don't restore windows at login either ("Reopen windows when logging back in")
# [NEW: complements NSQuitAlwaysKeepsWindows; default unchecked]
defaults write com.apple.loginwindow TALLogoutSavesState -bool false

# Disable automatic termination of inactive apps
# Keeps apps in memory rather than suspending them
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Disable the crash reporter dialog
# Set to 'prompt' to restore normal crash reporting
defaults write com.apple.CrashReporter DialogType -string "none"

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Reveal IP address, hostname, OS version when clicking clock in login window
# [NOTE: May require Full Disk Access on modern macOS]
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName 2>/dev/null || true

# Auto-hide menu bar (true=enable autohide, false=don't autohide)
# [MODIFIED: Original commented version was inverted logic]
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Disable automatic capitalization (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Privacy: Apple Intelligence, Siri & ads (Sequoia 15+)                       #
###############################################################################

# Apple Intelligence
# [FIXED: removed bogus `com.apple.AppleIntelligence CoreSettings` key — there
#  is no stable documented defaults key for Apple Intelligence. The reliable
#  opt-out is System Settings → Apple Intelligence & Siri, or Screen Time →
#  Intelligence & Siri restrictions. The Siri keys below ARE documented.]

# Disable Siri
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true

# Disable personalized Apple advertising
# [NEW: System Settings → Privacy & Security → Apple Advertising]
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input              #
###############################################################################

# Enable tap to click for this user and for the login screen
# [MODIFIED: added com.apple.AppleMultitouchTrackpad — the Bluetooth domain
#  only covers external trackpads; the built-in one uses its own domain]
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable "natural" (Lion-style) scrolling - use traditional direction
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Increase sound quality for Bluetooth headphones/headsets
# Forces a higher minimum bitpool for A2DP audio
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
# Mode 3 = Full keyboard access with Tab and arrows
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Use scroll gesture with Ctrl modifier key to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set blazingly fast keyboard repeat rate (1=fastest, 2=default)
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Set language and text formats
defaults write NSGlobalDomain AppleLanguages -array "en-US" "es"
defaults write NSGlobalDomain AppleLocale -string "en_US"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
defaults write NSGlobalDomain AppleMetricUnits -bool true

# Show language menu in top right corner of boot screen
# [NOTE: May require Full Disk Access on modern macOS]
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true 2>/dev/null || true

# Set timezone (see sudo systemsetup -listtimezones for other values)
# [FIXED: Added error suppression - systemsetup may fail with -99 on modern macOS]
sudo systemsetup -settimezone "America/La_Paz" > /dev/null 2>&1 || true

###############################################################################
# Energy saving                                                               #
###############################################################################

# Enable lid wakeup (wake when opening MacBook)
sudo pmset -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
# [FIXED: Added error suppression - may fail with -99 on modern macOS]
sudo systemsetup -setrestartfreeze on > /dev/null 2>&1 || true

# Sleep the display after 15 minutes
sudo pmset -a displaysleep 15

# Disable machine sleep while charging (0=never sleep on AC)
sudo pmset -c sleep 0

# Set machine sleep to 5 minutes on battery
sudo pmset -b sleep 5

# Set standby delay to 24 hours (default is 1 hour)
# Delay before system goes into standby mode
sudo pmset -a standbydelay 86400

# Never go into computer sleep mode
# [FIXED: Added error suppression - may fail with -99 on modern macOS]
sudo systemsetup -setcomputersleep Off > /dev/null 2>&1 || true

# Hibernation mode: 0=disable hibernation (faster sleep), 3=copy RAM to disk
# [MODIFIED: Removed sleepimage cleanup - can cause issues on APFS volumes]
# [NOTE: May require Full Disk Access]
sudo pmset -a hibernatemode 0 2>/dev/null || true

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (BMP/GIF/JPG/PDF/TIFF also available)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots (for cleaner captures)
defaults write com.apple.screencapture disable-shadow -bool true

# Skip the floating thumbnail after taking a screenshot
# [NEW: saves the ~5s wait before the file lands on disk]
defaults write com.apple.screencapture show-thumbnail -bool false

# Enable subpixel font rendering on non-Apple LCDs
# [MODIFIED: Simplified - removed duplicate CGFontRenderingFontSmoothingDisabled]
defaults write NSGlobalDomain AppleFontSmoothing -int 1

###############################################################################
# Window Manager & Stage Manager (Sequoia 15+)                               #
###############################################################################

# Disable Stage Manager (default is already off; set explicitly for reproducibility)
defaults write com.apple.WindowManager GloballyEnabled -bool false

# Don't hide all windows when clicking on the wallpaper
# [NEW: Sonoma+ default is "Always"; false = only in Stage Manager]
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# Remove the gaps around tiled windows (Sequoia window tiling)
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# Sequoia window tiling gestures — uncomment to disable:
# defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false       # drag window to screen edge
# defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false    # drag window to menu bar to fill
# defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false # hold Option while dragging

###############################################################################
# Control Center & menu bar                                                   #
###############################################################################

# Show battery percentage in the menu bar
# [NEW: -currentHost required; 18=show icon, 24=hide icon]
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
defaults -currentHost write com.apple.controlcenter "NSStatusItem Visible Sound" -int 18

# Tighten menu bar item spacing (useful on notched Macs) — uncomment to enable:
# defaults -currentHost write -globalDomain NSStatusItemSpacing -int 6
# defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6

###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: allow quitting via Cmd+Q (also hides desktop icons)
defaults write com.apple.finder QuitMenuItem -bool true

# Set Desktop as default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Show icons for hard drives, servers, and removable media on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar (breadcrumb navigation at bottom)
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
# [MODIFIED: Use defaults delete instead of commented false - ensures clean state]
defaults delete com.apple.finder "_FXSortFoldersFirst" 2>/dev/null || true

# Finder keyboard shortcuts for tab navigation and window merging
defaults write com.apple.Finder NSUserKeyEquivalents -dict-add "Show Next Tab"       "@~\U2192"
defaults write com.apple.Finder NSUserKeyEquivalents -dict-add "Show Previous Tab"   "@~\U2190"
# [MODIFIED: Fixed duplicate and moved here from line ~460]
defaults write com.apple.Finder NSUserKeyEquivalents -dict-add "Merge All Windows" "@\$M"

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Auto-remove items from the Trash after 30 days — uncomment to enable:
# defaults write com.apple.finder FXRemoveOldTrashItems -bool true

# Enable spring loading for directories (reveal contents on drag)
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Automatically open new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Show item info near icons on desktop and icon views
# [MODIFIED: Added error suppression for PlistBuddy commands]
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Show item info to the right of the icons (not below)
/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Enable snap-to-grid for icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Increase grid spacing for icons (100 is larger spacing)
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Increase the size of icons on desktop and icon views (80=pixels)
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Use list view in all Finder windows (Nlsv=list, icnv=icon, clmv=column, glyv=grid)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Enable AirDrop over Ethernet and on unsupported Macs
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Show the ~/Library folder (hidden by default since Lion)
# [NEW: chflags alone can fail if FinderInfo xattr carries the hidden bit]
chflags nohidden ~/Library 2>/dev/null || true
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# Show the /Volumes folder in Finder
# [NOTE: May fail on modern macOS with SIP]
sudo chflags nohidden /Volumes 2>/dev/null || true

# Expand File Info panes: General, Open with, and Sharing & Permissions
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

# Enable highlight hover effect for grid view of stacks
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set icon size of Dock items to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Change minimize/maximize window effect (scale/genie)
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in Dock
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications from Dock
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations (lower=faster)
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't group windows by application in Mission Control
defaults write com.apple.dock expose-group-by-app -bool false

# Don't show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.4

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Reset Launchpad database
# [MODIFIED: ResetLaunchPad is the documented modern mechanism; replaces
#  deleting *-*.db (which also had -maxdepth after -name, invalid order).
#  Applied on next Dock restart — see killall at the end of this script.]
defaults write com.apple.dock ResetLaunchPad -bool true

# Disable system-wide symbolichotkeys that conflict with custom shortcuts
# [MODIFIED: Consolidated all hotkey disables into one section]
# Disable Ctrl+Space for "Select the previous input source"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><false/></dict>'
# Disable Ctrl+Option+Space for "Select next source in input menu"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '<dict><key>enabled</key><false/></dict>'
# Disable Cmd+Space for "Show Spotlight search"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'
# Disable Option+Cmd+Space for "Show Finder search window"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '<dict><key>enabled</key><false/></dict>'
# Disable Ctrl+Up for "Mission Control"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 '<dict><key>enabled</key><false/></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 34 '<dict><key>enabled</key><false/></dict>'
# Disable Ctrl+Left for "Mission Control: Move left a space"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '<dict><key>enabled</key><false/></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 '<dict><key>enabled</key><false/></dict>'
# Disable Ctrl+Right for "Mission Control: Move right a space"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '<dict><key>enabled</key><false/></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 '<dict><key>enabled</key><false/></dict>'

# Enable Text to Speech and set Option+Space as hotkey (2097=Option+Space)
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyFlag -bool true
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyCombo -int 2097

# Hot corners (0=no-op, 2=Mission Control, 3=App Windows, 4=Desktop, 5=Screen Saver, 6=Disable SD, 7=Dashboard, 10=Sleep, 11=Launchpad, 12=Notification Center, 13=Lock Screen)
# Top left → Desktop
defaults write com.apple.dock wvous-tl-corner -int 4
defaults write com.apple.dock wvous-tl-modifier -int 0
# Top right → Mission Control
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
# Bottom left → Notification Center
defaults write com.apple.dock wvous-bl-corner -int 12
defaults write com.apple.dock wvous-bl-modifier -int 0
# Bottom right → Show application windows
defaults write com.apple.dock wvous-br-corner -int 3
defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

# Privacy: don't send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Press Tab to highlight each item on a web page
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Show the full URL in the address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari's home page to about:blank for faster loading
defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from opening 'safe' files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Allow hitting Backspace to go to previous page in history
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

# Hide Safari's bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Hide Safari's sidebar in Top Sites
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# Disable Safari's thumbnail cache for History and Top Sites
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

# Enable Safari's debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Make Safari's search banners default to Contains instead of Starts With
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# Remove useless icons from Safari's bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

# Enable the Develop menu and Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add Web Inspector to context menu for all apps
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Enable continuous spellchecking in Safari
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
# Disable auto-correct in Safari
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

# Disable Safari AutoFill
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Enable "Do Not Track"
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Update Safari extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Mail                                                                        #
###############################################################################

# Disable send and reply animations in Mail.app
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true

# Copy email addresses as foo@example.com instead of Foo Bar <foo@example.com>
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Add Cmd+Enter to send an email in Mail.app
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

# Display emails in threaded mode, sorted by date (oldest at top)
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

# Disable inline attachments (just show the icons)
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# Disable automatic spell checking
defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

###############################################################################
# Spotlight                                                                   #
###############################################################################

# Disable Spotlight indexing for any volume that gets mounted
# [FIXED: Changed path from /.Spotlight-V100 to /Volumes/.Spotlight-V100]
# [NOTE: This may fail on modern macOS due to SIP - Full Disk Access required]
sudo defaults write /Volumes/.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes" 2>/dev/null || true

# Change indexing order and disable some search results for privacy
defaults write com.apple.spotlight orderedItems -array \
	'{"enabled" = 1;"name" = "APPLICATIONS";}' \
	'{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
	'{"enabled" = 1;"name" = "DIRECTORIES";}' \
	'{"enabled" = 1;"name" = "PDF";}' \
	'{"enabled" = 1;"name" = "FONTS";}' \
	'{"enabled" = 0;"name" = "DOCUMENTS";}' \
	'{"enabled" = 0;"name" = "MESSAGES";}' \
	'{"enabled" = 0;"name" = "CONTACT";}' \
	'{"enabled" = 0;"name" = "EVENT_TODO";}' \
	'{"enabled" = 0;"name" = "IMAGES";}' \
	'{"enabled" = 0;"name" = "BOOKMARKS";}' \
	'{"enabled" = 0;"name" = "MUSIC";}' \
	'{"enabled" = 0;"name" = "MOVIES";}' \
	'{"enabled" = 0;"name" = "PRESENTATIONS";}' \
	'{"enabled" = 0;"name" = "SPREADSHEETS";}' \
	'{"enabled" = 0;"name" = "SOURCE";}' \
	'{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
	'{"enabled" = 0;"name" = "MENU_OTHER";}' \
	'{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
	'{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
	'{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
	'{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

# Keep Spotlight indexing OFF on the boot volume (user preference: minimal
# mds uptime; apps remain searchable via Launch Services).
# [FIXED: previous version ended with `mdutil -i on` + `-E` (full erase &
# rebuild), leaving the indexer permanently ON — opposite of the intent.]
# To index newly installed apps on demand WITHOUT the background indexer:
#   sudo mdimport -r /Applications
# To do a full one-shot rebuild:
#   sudo mdutil -i on / && sudo mdutil -E / && sudo mdutil -i off /
sudo mdutil -i off / 2>/dev/null || true
killall mds > /dev/null 2>&1 || true

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################

# Only use UTF-8 in Terminal.app (4=UTF-8)
defaults write com.apple.terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
# Prevents other apps from intercepting keystrokes
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# Disable the annoying line marks (decorative marks at line ends)
defaults write com.apple.Terminal ShowLineMarks -int 0

# Don't display prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

###############################################################################
# Time Machine                                                                #
###############################################################################

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable local Time Machine snapshots
# [NOTE: disablelocal verb removed in modern macOS (Monterey+). No equivalent command exists.
# Local APFS snapshots are now system-managed and cannot be disabled via tmutil.
# The DoNotOfferNewDisksForBackup preference above handles the UI behavior instead.]
# Keeping this commented as a reminder:
# hash tmutil &> /dev/null && sudo tmutil disablelocal 2>/dev/null || true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 0

# Show all processes in Activity Monitor (not just user processes)
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
defaults write com.apple.ActivityMonitor UpdatePeriod -int 8

###############################################################################
# TextEdit, Disk Utility, QuickTime                                           #
###############################################################################

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0
# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable Disk Utility debug menu and advanced imaging options
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Auto-play videos when opened with QuickTime Player
defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

###############################################################################
# Mac App Store                                                               #
###############################################################################

# Enable WebKit Developer Tools in Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Enable Debug Menu in Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Enable automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily (not just weekly)
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files and security updates automatically
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Automatically download apps purchased on other Macs
defaults write com.apple.SoftwareUpdate ConfigDataInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Allow the App Store to reboot machine on macOS updates
defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

###############################################################################
# Photos                                                                      #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

# Disable automatic emoji substitution in messages
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

# Disable smart quotes in messages (annoying for code sharing)
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

# Disable continuous spell checking in messages
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

###############################################################################
# Google Chrome & Google Chrome Canary                                        #
###############################################################################

# Disable the sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the sensitive backswipe on Magic Mouse
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true
defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Opera & Opera Developer                                                     #
###############################################################################

# Expand the print dialog by default
defaults write com.operasoftware.Opera PMPrintingExpandedStateForPrint2 -bool true
defaults write com.operasoftware.OperaDeveloper PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Optional: Touch ID for sudo (survives macOS updates)                        #
###############################################################################

# Sonoma+ supports /etc/pam.d/sudo_local, which /etc/pam.d/sudo includes and
# which macOS updates do NOT overwrite (unlike editing /etc/pam.d/sudo).
# Uncomment to enable Touch ID authentication for sudo:
# if ! grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null; then
# 	echo "auth       sufficient     pam_tid.so" | sudo tee /etc/pam.d/sudo_local > /dev/null
# fi

###############################################################################
# Kill affected applications                                                  #
###############################################################################

# Restart affected applications to apply changes
# [MODIFIED: Removed deprecated apps (Twitter, Tweetbot, GPGMail, SizeUp, Spectacle, Transmission)]
# [MODIFIED: Added error suppression with || true for each killall]
# [MODIFIED: Added ControlCenter for menu bar changes]
for app in "Activity Monitor" \
	"Calendar" \
	"cfprefsd" \
	"Contacts" \
	"ControlCenter" \
	"Dock" \
	"Finder" \
	"Google Chrome Canary" \
	"Google Chrome" \
	"Mail" \
	"Messages" \
	"Opera" \
	"Photos" \
	"Safari" \
	"SystemUIServer" \
	"Terminal" \
	"TextEdit"; do
	killall "${app}" &> /dev/null || true
done

echo "Done. Note that some of these changes require a logout/restart to take effect."

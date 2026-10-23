#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

################################################################################
# Pre-execution                                                                #
################################################################################

# Close any open System Settings windows, to prevent them from overriding
# settings
osascript <<'EOF'
tell application "System Settings"
  if it is running then
    quit
    repeat while it is running
      delay 0.01
    end repeat
  end if
end tell
EOF

################################################################################
# Dock                                                                         #
################################################################################

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

################################################################################
# Keyboard Shortcuts                                                           #
################################################################################

defaults write -g ApplePressAndHoldEnabled -bool false

# Symbolic hotkeys 118–126 select Desktop 1–9; virtual keycodes are not in digit order.
readonly -a DESKTOP_KEY_CODES=(18 19 20 21 23 22 26 28 25)
readonly OPTION_MODIFIER=524288

for desktop in {1..9}; do
	defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$((117 + desktop))" \
		"<dict>
			<key>enabled</key><true/>
			<key>value</key><dict>
				<key>type</key><string>standard</string>
				<key>parameters</key><array>
					<integer>$((48 + desktop))</integer>
					<integer>${DESKTOP_KEY_CODES[desktop]}</integer>
					<integer>$OPTION_MODIFIER</integer>
				</array>
			</dict>
		</dict>"
done

# 64 = Show Spotlight search
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist

################################################################################
# Menu Bar                                                                     #
###############################################################################

# defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false
defaults write NSGlobalDomain SLSMenuBarUseBlurredAppearance -bool false

################################################################################
# Privacy & Security                                                           #
################################################################################

# 2 = opted out, 1 = opted in, 0 = not yet asked
defaults \
	write \
	com.apple.assistant.support \
	"Search Queries Data Sharing Status" \
	-int 2
defaults \
	write \
	com.apple.assistant.support \
	"Siri Data Sharing Opt-In Status" \
	-int 2

################################################################################
# Screenshot                                                                   #
################################################################################

defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture target -string "file"

################################################################################
# Siri                                                                         #
################################################################################

defaults write com.apple.assistant.backedup "Cloud Sync Enabled" -bool false
defaults write com.apple.assistant.support "Assistant Enabled" -bool false

################################################################################
# Spotlight                                                                    #
################################################################################

# defaults delete com.apple.Spotlight EnabledPreferenceRules
# defaults write com.apple.Spotlight PasteboardHistoryEnabled -bool false

################################################################################
# Post-Execution                                                               #
################################################################################

# Force restart system UI
killall Dock
killall Spotlight
killall SystemUIServer # manages menu bar items
# Force restart preferences daemon, forcing recache of plist settings
killall cfprefsd
# Force system services to reload plist settings
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings \
	-u

echo "==> System settings successfully applied."

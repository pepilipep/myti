SCHEME = myti
BUILD_DIR = .build
APP_NAME = myti.app
INSTALL_DIR = /Applications

.PHONY: build run clean install uninstall

build:
	swift build -c release

run: bundle
	@open $(BUILD_DIR)/$(APP_NAME)

dev:
	swift build
	@rm -rf $(BUILD_DIR)/$(APP_NAME)
	@mkdir -p $(BUILD_DIR)/$(APP_NAME)/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(APP_NAME)/Contents/Resources
	@cp $(BUILD_DIR)/debug/myti $(BUILD_DIR)/$(APP_NAME)/Contents/MacOS/myti
	@cp Info.plist $(BUILD_DIR)/$(APP_NAME)/Contents/Info.plist
	@cp Resources/Assets.xcassets/TrayIcon.imageset/trayTemplate.png $(BUILD_DIR)/$(APP_NAME)/Contents/Resources/
	@cp Resources/Assets.xcassets/TrayIcon.imageset/trayTemplate@2x.png $(BUILD_DIR)/$(APP_NAME)/Contents/Resources/
	@open $(BUILD_DIR)/$(APP_NAME)

clean:
	swift package clean

# Create .app bundle from SPM build
bundle: build
	@rm -rf $(BUILD_DIR)/$(APP_NAME)
	@mkdir -p $(BUILD_DIR)/$(APP_NAME)/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(APP_NAME)/Contents/Resources
	@cp $(BUILD_DIR)/release/myti $(BUILD_DIR)/$(APP_NAME)/Contents/MacOS/myti
	@cp Info.plist $(BUILD_DIR)/$(APP_NAME)/Contents/Info.plist
	@# Copy tray icon into Resources
	@cp Resources/Assets.xcassets/TrayIcon.imageset/trayTemplate.png $(BUILD_DIR)/$(APP_NAME)/Contents/Resources/
	@cp Resources/Assets.xcassets/TrayIcon.imageset/trayTemplate@2x.png $(BUILD_DIR)/$(APP_NAME)/Contents/Resources/
	@echo "Built $(BUILD_DIR)/$(APP_NAME)"

install: bundle
	@rm -rf $(INSTALL_DIR)/$(APP_NAME)
	@cp -R $(BUILD_DIR)/$(APP_NAME) $(INSTALL_DIR)/$(APP_NAME)
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME)"
	@# Add to Login Items
	@osascript -e 'tell application "System Events" to make login item at end with properties {path:"$(INSTALL_DIR)/$(APP_NAME)", hidden:false}' 2>/dev/null || true
	@echo "Added to Login Items"

uninstall:
	@rm -rf $(INSTALL_DIR)/$(APP_NAME)
	@echo "Removed from $(INSTALL_DIR)"
	@osascript -e 'tell application "System Events" to delete login item "myti"' 2>/dev/null || true
	@echo "Removed from Login Items"

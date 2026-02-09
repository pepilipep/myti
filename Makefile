.PHONY: dev build pack install uninstall clean

# Run in development mode with hot reload
dev:
	npm run dev

# Build the renderer and main process
build:
	npm run build

# Package as macOS .app
pack:
	npm run pack

# Package, copy to /Applications, and add to Login Items
install: pack
	@echo "Installing myti.app..."
	cp -R dist/mac-arm64/myti.app /Applications/myti.app
	osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/myti.app", hidden:true}' 2>/dev/null || true
	@echo "Installed to /Applications and added to Login Items"

# Remove from /Applications and Login Items
uninstall:
	@echo "Uninstalling myti..."
	osascript -e 'tell application "System Events" to delete login item "myti"' 2>/dev/null || true
	rm -rf /Applications/myti.app
	@echo "Removed from /Applications and Login Items"

# Remove build artifacts
clean:
	rm -rf out dist

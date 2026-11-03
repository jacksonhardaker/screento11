APP = dist/ScreenTo11.app
CONTENTS = $(APP)/Contents

.PHONY: app run test clean

app:
	SWIFT_MODULECACHE_PATH=/private/tmp/screento11-swift-cache CLANG_MODULE_CACHE_PATH=/private/tmp/screento11-clang-cache XDG_CACHE_HOME=/private/tmp/screento11-cache swift build --disable-sandbox -c release
	mkdir -p $(CONTENTS)/MacOS
	cp .build/release/ScreenTo11 $(CONTENTS)/MacOS/ScreenTo11
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	codesign --force --sign - $(APP)

run: app
	open $(APP)

test:
	SWIFT_MODULECACHE_PATH=/private/tmp/screento11-swift-cache CLANG_MODULE_CACHE_PATH=/private/tmp/screento11-clang-cache XDG_CACHE_HOME=/private/tmp/screento11-cache swift test --disable-sandbox

clean:
	rm -rf .build dist

framework 'Cocoa'

require 'time'

require 'exts'

require 'ClocksController'


class AppDelegate
    attr_accessor :background_alpha_slider, :face_alpha_slider, :hands_alpha_slider
    attr_accessor :window
    attr_accessor :defaults
    attr_accessor :status_item, :status_item_menu, :toggle_clocks_menu_item, :toggle_clocks_button

    attr_accessor :clocks_controller

    include CocoaCompatibility


    def applicationDidFinishLaunching(a_notification)
        init_defaults

        self.clocks_controller = ClocksController.new(NSScreen.screens.drop(1))

        ["background_alpha", "face_alpha", "hands_alpha"].each do |attribute|
            path = "values." + attribute
            clocks_controller.bind(attribute, toObject:NSUserDefaultsController.sharedUserDefaultsController, withKeyPath:path, options:nil)
        end
        
        clocks_controller.addObserver(self, forKeyPath:"visible", options:NSKeyValueObservingOptionNew, context:nil)


        NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector:'workspaceChanged:', name:NSWorkspaceActiveSpaceDidChangeNotification, object:nil)


        window.releasedWhenClosed = false

        # only show when explicitly requested
        # applicationShouldHandleReopen:hasVisibleWindows: handles that
        window.close

        # show above clock
        window.level = NSFloatingWindowLevel

        show_menu_bar_icon if defaults.boolForKey("show_menu_bar_icon")
    end
    
    
    def observeValueForKeyPath(keyPath, ofObject:object, change:change, context:context)
        if object == clocks_controller && keyPath == "visible"
            is_visible = change[NSKeyValueChangeNewKey]
            title = if is_visible then "Hide Clocks" else "Show Clocks" end
            self.toggle_clocks_menu_item.title = NSLocalizedString(title)
            self.toggle_clocks_button.title = NSLocalizedString(title)
        
            # float command window above the clock windows
            window.orderFront(self) if window.isKeyWindow
        end
    end

    def workspaceChanged(trigger)
        clocks_controller.hide_immediately
    end

    def applicationShouldHandleReopen(app, hasVisibleWindows:flag)
        window.makeKeyAndOrderFront(self)
    end

    def applicationDidChangeScreenParameters(notification)
        clocks_controller.screens = NSScreen.screens.drop(1)
    end

    def showAboutPanel(sender)
        NSApp.orderFrontStandardAboutPanel(sender)
        NSApp.activateIgnoringOtherApps(true) # or won't show if called via status bar menu
    end

    def showPreferencesWindow(sender)
        window.makeKeyAndOrderFront(sender)
        NSApp.activateIgnoringOtherApps(true) # or won't be focused if called via status bar menu
    end

    def changeMenuBarIconVisibility(sender)
        if sender.state == 0
            hide_menu_bar_icon


            title = NSLocalizedString("Info")
            message = NSLocalizedString("You can still go to this preferences window by double-clicking the application icon.")

            NSRunInformationalAlertPanel(title, message, nil, nil, nil, nil)
        else
            show_menu_bar_icon
        end
    end

    def toggle_clocks(sender)
        if clocks_controller.visible?
            clocks_controller.hide
        else
            clocks_controller.show
        end
    end



    #################
    # MENU BAR ICON #
    #################


    def show_menu_bar_icon
        self.status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSSquareStatusItemLength)
        self.status_item.menu = status_item_menu
        self.status_item.highlightMode = true
        self.status_item.toolTip = NSRunningApplication.currentApplication.localizedName
        self.status_item.image = ClockView.alloc.initWithFrame([[0, 0], [16, 16]], time:Time.parse("06:50")).to_image
    end

    def hide_menu_bar_icon
        NSStatusBar.systemStatusBar.removeStatusItem(status_item)
        self.status_item = nil
    end



    ############
    # DEFAULTS #
    ############


    private


    def default_values()
        path = NSBundle.mainBundle.pathForResource("UserDefaults", ofType:"plist")
        dict = NSDictionary.dictionaryWithContentsOfFile(path)
    end

    def init_defaults()
        self.defaults = NSUserDefaults.standardUserDefaults

        dict = default_values
        defaults.registerDefaults(dict)
    end

    def restore_defaults(sender)
        dict = default_values

        defaults.setFloat(dict["background_alpha"], forKey:"background_alpha")
        defaults.setFloat(dict["face_alpha"], forKey:"face_alpha")
        defaults.setFloat(dict["hands_alpha"], forKey:"hands_alpha")
    end
end

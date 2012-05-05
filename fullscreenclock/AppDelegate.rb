framework 'Cocoa'

require 'Date'

require 'exts'


class AppDelegate
    attr_accessor :background_alpha_slider, :face_alpha_slider, :hands_alpha_slider
    attr_accessor :window, :minute_timer, :clock_windows
    attr_accessor :fading_timer, :fading_step, :fading_interval
    attr_accessor :background_alpha, :hands_alpha, :face_alpha
    attr_accessor :fullscreen_notifier, :defaults
    
    include CocoaCompatibility
    
        
    def applicationDidFinishLaunching(a_notification)
        self.clock_windows = [];

        self.fading_step     = 0.02
        self.fading_interval = 0.05
        
        self.fullscreen_notifier = FullscreenNotifier.new
        fullscreen_notifier.setFullscreenCallbackTarget(self, enterSelector:'on_fullscreen_enter',
                                                              exitSelector:'on_fullscreen_exit')
        
        
        # set alpha values
        init_defaults
        
        
        window.releasedWhenClosed = false
        
        # only show when explicitly requested
        # applicationShouldHandleReopen:hasVisibleWindows: handles that
        window.close
        
        
        # show above clock
        window.level = NSFloatingWindowLevel
    end
    
    
    def applicationShouldHandleReopen(app, hasVisibleWindows:flag)
        window.makeKeyAndOrderFront(self)
    end
    
    
    
    ############
    # DEFAULTS #
    ############
    
    
    private
    
    
    def default_values()
        path = NSBundle.mainBundle.pathForResource("UserDefaults", ofType:"plist")
        dict = NSDictionary.dictionaryWithContentsOfFile(path);
    end
    
    def init_defaults()
        self.defaults = NSUserDefaults.standardUserDefaults
        
        dict = default_values
        defaults.registerDefaults(dict)
        
        self.background_alpha = defaults.floatForKey('background_alpha')
        self.face_alpha       = defaults.floatForKey('face_alpha')
        self.hands_alpha      = defaults.floatForKey('hands_alpha')
    end
    
    def restore_defaults(sender)
        dict = default_values
        
        self.background_alpha = dict['background_alpha']
        self.face_alpha       = dict['face_alpha']
        self.hands_alpha      = dict['hands_alpha']
    end
    
    
    
    ####################
    # CLOCK MANAGEMENT #
    ####################
    
    
    private
    
        
    def toggle_clocks(sender)
        if minute_timer.nil? or not minute_timer.valid?
            setup_clocks
        else
            teardown_clocks
        end
    end
    
    def setup_clocks()
        clean_up
        
        t = Time.now + 60 # +1 minute
        fire_date = Time.mktime(t.year, t.month, t.day, t.hour, t.min)
        self.minute_timer = NSTimer.alloc.initWithFireDate(fire_date,
                                                           interval:60,
                                                           target:self,
                                                           selector:'update_clock_view:',
                                                           userInfo:nil,
                                                           repeats:true)
        NSRunLoop.currentRunLoop.addTimer(self.minute_timer, forMode:NSDefaultRunLoopMode)
        
        # draw clocks on secondary screens
        # screens.first is the the mainScreen - remove it
        # (we can't use delete() because its destructive)
        screens = NSScreen.screens.drop(1)
        
        t = Time.now
        screens.each { |scr| setup_screen(scr, t) }
        
        # float command window above the clock windows
        window.orderFront(self) if window.isKeyWindow
        
        fade_in
    end
    
    def update_clock_view(timer)
        t = Time.now
        self.clock_windows.each do |win|
            win.contentView.subviews.first.time = t
        end
    end
    
    def setup_screen(screen, time)
        screenBounds = [NSZeroPoint, screen.frame.size]
        
        window = NSWindow.alloc.initWithContentRect(screenBounds,
                                                    styleMask:NSBorderlessWindowMask,
                                                    backing:NSBackingStoreBuffered,
                                                    defer:false,
                                                    screen:screen)     
        
        window.opaque          = false
        window.level           = NSFloatingWindowLevel
        window.alphaValue      = 0.0    # don't draw immediately
        window.backgroundColor = NSColor.colorWithCalibratedWhite(0, alpha:background_alpha)
        window.hasShadow       = false
        
        window.delegate = self
        def window.mouseDown(notification)
            close
        end
        
        view = ClockView.alloc.initWithFrame(screenBounds, time:time)
        view.face_alpha  = face_alpha
        view.hands_alpha = hands_alpha
        window.contentView.addSubview(view)
        window.orderFront(self)
        
        self.clock_windows << window
    end
    
    def teardown_clocks()
        minute_timer.invalidate
        fade_out
    end
    
    def clean_up()
        # close windows here because timer doesn't always take the same time
        # (when windows were not completely opaque when fading out began)
        clock_windows.each &:close
        self.clock_windows = []
    end
    
    def windowWillClose(notification)
        clock_windows.delete(notification.object)
    end
    
    
    
    ##########
    # FADING #
    ##########
    
    
    private
    
    
    def fade(starting_alpha, fading_selector)
        alpha = starting_alpha
        
        unless fading_timer.nil? or not fading_timer.valid?
            alpha = fading_timer.userInfo[:alpha]
            fading_timer.invalidate
        end
        
        self.fading_timer =
            NSTimer.timerWithTimeInterval(fading_interval,
                                          target:self,
                                          selector:fading_selector,
                                          userInfo:{ :alpha => alpha },
                                          repeats:true)
        
        # don't use NSDefaultRunloopMode because Mac OS X Lion pauses timers
        # in that mode whenever the user drags NSSliders around
        NSRunLoop.currentRunLoop.addTimer(self.fading_timer, forMode:NSRunLoopCommonModes)
    end
    
    
    def fade_in()
        fade(0.0, 'fade_in_do:')
    end
    
    def fade_out()
        fade(1.0, 'fade_out_do:')
    end
    
    
    def fade_step_do(timer, step)
        timer.userInfo[:alpha] += step
        clock_windows.each { |w| w.alphaValue = timer.userInfo[:alpha] }
    end
    
    
    def fade_in_do(timer)
        fade_step_do(timer, +fading_step)
        timer.invalidate if timer.userInfo[:alpha] >= 1.0
    end

    def fade_out_do(timer)
        fade_step_do(timer, -fading_step)
        
        if timer.userInfo[:alpha] <= 0.0
            timer.invalidate
            clean_up
        end
    end
    
    
    
    ##############
    # PROPERTIES #
    ##############
    
    
    public
    

    def background_alpha=(alpha)
        set_ivar(:background_alpha, alpha) do
            defaults.setFloat(alpha, forKey:'background_alpha')
            
            self.clock_windows.each do |win|
                win.backgroundColor = NSColor.colorWithCalibratedWhite(0, alpha:alpha)
            end
        end
    end
    
    def face_alpha=(alpha)
        set_ivar(:face_alpha, alpha) do
            defaults.setFloat(alpha, forKey:'face_alpha')
            
            self.clock_windows.each do |win|
                win.contentView.subviews.first.face_alpha = alpha
            end
        end
    end
    
    def hands_alpha=(alpha)
        set_ivar(:hands_alpha, alpha) do
            defaults.setFloat(alpha, forKey:'hands_alpha')
            
            self.clock_windows.each do |win|
                win.contentView.subviews.first.hands_alpha = alpha
            end
        end
    end
    
    
    
    ###########
    # ALIASES #
    ###########
    
    
    public
    
    
    alias_method :on_fullscreen_enter, :setup_clocks
    alias_method :on_fullscreen_exit,  :teardown_clocks
end

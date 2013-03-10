require 'exts'

class ClocksController
public
    include CocoaCompatibility

    attr_reader :visible
    alias_method :visible?, :visible

    attr_accessor :screens, :background_alpha, :hands_alpha, :face_alpha


#private # can't make these private or macruby can't access these anymore if method is called via the ui
    attr_accessor :windows, :minute_timer, :fullscreen_observer #, :visible must be defined manually - for KVO compliance
    attr_accessor :fading_timer, :fading_step, :fading_interval, :current_alpha


public
    def initialize(screens)
        self.windows = []

        self.fading_step     = 0.02
        self.fading_interval = 0.05
        self.current_alpha   = 0.0

        self.background_alpha = 0.5
        self.hands_alpha      = 1.0
        self.face_alpha       = 1.0

        self.visible = false

        self.fullscreen_observer = FullscreenObserver.sharedFullscreenObserver
        fullscreen_observer.addObserver(self, forKeyPath:"fullscreenMode", options:NSKeyValueObservingOptionNew, context:nil)

        self.screens = screens
    end

    def show
        setup_clocks unless visible?
    end

    def hide
        teardown_clocks if visible?
    end

    def hide_immediately
        clean_up
    end

    def screens=(allowed_screens)
        # remove clocks from removed screens and (maybe new) primary screen

        old_clock_windows = windows
        self.windows = []

        old_clock_windows.each do |window|
            if !allowed_screens.include?(window.screen)
                window.delegate = nil
                window.releasedWhenClosed = true
                window.close
            else
                windows << window
            end
        end

        # MacRuby returns fullscreen_observer.isFullscreenMode as int instead of bool
        # therefore we have to check for 0 or 1

        # add clocks to new screens
        if fullscreen_observer.isFullscreenMode == true || fullscreen_observer.isFullscreenMode == 1
            now = Time.now
            used_screens = windows.map(&:screen)
            unused_screens = allowed_screens - used_screens
            unused_screens.each do |screen|
                window = setup_screen(screen, now)
                window.alphaValue = 1.0 # no fading
            end
        end


        # stop timer etc. if no clocks are left
        clean_up if windows.empty?
    end

    def background_alpha=(alpha)
        set_ivar(:background_alpha, alpha) do
            windows.each do |window|
                window.backgroundColor = NSColor.colorWithCalibratedWhite(0, alpha:alpha)
            end
        end
    end

    def face_alpha=(alpha)
        set_ivar(:face_alpha, alpha) do
            windows.each do |window|
                window.contentView.subviews.first.face_alpha = alpha
            end
        end
    end

    def hands_alpha=(alpha)
        set_ivar(:hands_alpha, alpha) do
            windows.each do |window|
                window.contentView.subviews.first.hands_alpha = alpha
            end
        end
    end


public
    def observeValueForKeyPath(keyPath, ofObject:object, change:change, context:context)
        if object == fullscreen_observer && keyPath == "fullscreenMode"
            if change[NSKeyValueChangeNewKey].boolValue
                show
            else
                hide
            end
        end
    end


private



    ####################
    # CLOCK MANAGEMENT #
    ####################


    def setup_clocks()
        if windows.empty?
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
        else
            # no need to create new clocks because the old ones are still fading out
        end

        self.visible = true
        fade_in
    end

    def update_clock_view(timer)
        t = Time.now
        self.windows.each do |win|
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
        
        #["face_alpha", "hands_alpha"].each do |attribute|
        #    viewProxy.bind(attribute, toObject:self, withKeyPath:attribute, options:nil)
        #end
        
        #window.bind("background_alpha", toObject:self, withKeyPath:"background_alpha", options:nil)

        windows << window

        window
    end

    def teardown_clocks()
        self.visible = false
        fade_out
    end

    def clean_up()
        minute_timer.invalidate unless minute_timer.nil?
        fading_timer.invalidate unless fading_timer.nil?

        # close windows here because timer doesn't always take the same time
        # (when windows were not completely opaque when fading out began)
        windows.each &:close
        self.windows = []
        self.current_alpha = 0.0
        self.visible = false
    end

    def windowWillClose(notification)
        windows.delete(notification.object)

        if windows.empty?
            self.visible = false
            clean_up
        end
    end



    ##########
    # FADING #
    ##########


    def fade(fading_selector)
        fading_timer.invalidate unless fading_timer.nil?

        self.fading_timer =
            NSTimer.timerWithTimeInterval(fading_interval,
                                          target:self,
                                          selector:fading_selector,
                                          userInfo:nil,
                                          repeats:true)

        # don't use NSDefaultRunloopMode because Mac OS X Lion pauses timers
        # in that mode whenever the user drags NSSliders around
        NSRunLoop.currentRunLoop.addTimer(self.fading_timer, forMode:NSRunLoopCommonModes)
    end


    def fade_in()
        fade('fade_in_do:')
    end

    def fade_out()
        fade('fade_out_do:')
    end


    def fade_step_do(timer, step)
        self.current_alpha += step
        windows.each { |w| w.alphaValue = current_alpha }
    end


    def fade_in_do(timer)
        fade_step_do(timer, +fading_step)
        timer.invalidate if current_alpha >= 1.0
    end

    def fade_out_do(timer)
        fade_step_do(timer, -fading_step)

        if current_alpha <= 0.0
            timer.invalidate
            clean_up
        end
    end
    
    
    
    ##############
    # PROPERTIES #
    ##############
    
    
    # MacRuby doesn't seem to always generate KVO-compliant setters
    def setVisible(is_visible)
        set_ivar(:visible, is_visible)
    end
    
    alias_method :"visible=", :setVisible
end
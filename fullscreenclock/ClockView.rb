require 'exts'

class ClockView < NSView
    attr_accessor :time, :hands_alpha, :face_alpha
    
    def initWithFrame(frame, time:time)
        if super
            self.time = time
            self.hands_alpha = 0.4
            self.face_alpha = 0.4
            self
        end
    end
    
    def drawRect(dirty_rect)
        draw_face                
        draw_hour_hand
        draw_minute_hand
    end
    
    def time=(new_time)
        @time = new_time
        self.needsDisplay = true
    end
    
    def hands_alpha=(alpha)
        @hands_alpha = alpha
        self.needsDisplay = true
    end
    
    def face_alpha=(alpha)
        @face_alpha = alpha
        self.needsDisplay = true
    end
    
    def to_image
        representation = bitmapImageRepForCachingDisplayInRect(bounds)
        cacheDisplayInRect(bounds, toBitmapImageRep:representation)
        
        image = NSImage.alloc.initWithSize(bounds.size)
        image.addRepresentation(representation)
        
        image
    end
    
    
    private
    
    def draw_face()
        # draw a rectangle in the center of the screen
        rect = bounds
        if rect.size.width > rect.size.height then
            rect.origin.x += (rect.size.width - rect.size.height) / 2
            rect.size.width = rect.size.height
            else 
            rect.origin.y += (rect.size.height - rect.size.width) / 2
            rect.size.height = rect.size.width
        end
        path = NSBezierPath.bezierPathWithOvalInRect(rect)
        NSColor.colorWithCalibratedWhite(0.0, alpha:face_alpha).set
        path.fill 
    end
    
    def draw_hour_hand()
        polygon    = [[100, 158], [107, 101], [100, 86], [93, 101]]
        num_units  = units_for_time(time.hour, :h)
        num_units += units_for_time(1, :h) / units_for_time(60, :m) * units_for_time(time.min, :m)
        draw_hand(polygon, num_units)
    end
    
    def draw_minute_hand()
        polygon   = [[100, 190], [105, 101], [100, 86], [95, 101]]
        num_units = time.min
        draw_hand(polygon, num_units)
    end
    
    def draw_hand(polygon, num_units)
        polygon.map!(&method(:scale_point))
        
        path = NSBezierPath.bezierPath
        path.appendBezierPathWithPoints(polygon, count:polygon.size)
        
        transform = NSAffineTransform.transformRotatingAroundPoint([NSMidX(bounds), NSMidY(bounds)],
                                                                   byDegrees:degrees_for_units(num_units))
        path.transformUsingAffineTransform(transform)
        
        NSColor.colorWithCalibratedWhite(1, alpha:hands_alpha).set
        path.fill
    end
    
    def scale_point(p)
        mul_x = bounds.size.width / max_point_size[0]
        mul_y = bounds.size.height / max_point_size[1]
        
        [mul_x * p[0], mul_y * p[1]]
    end
    
    
    def max_point_size()
        [200, 200]
    end
    
    def degrees_for_units(num_units)
        -(360/60) * num_units
    end
    
    def units_for_time(time, unit)
        muls = { :h => 5.0, :m => 1.0 }
        
        raise "invalid time unit" unless muls.include?(unit)
        
        time * muls[unit]
    end
    
end
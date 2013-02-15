module CocoaCompatibility
    def self.included(receiver)
        # class methods are not included by default
        receiver.extend(ClassMethods)
    end

    module ClassMethods
        def method_added(name)
            # sync cocoa and ruby setters
            # do it here because macruby doesn't do it properly
            if name[-1] == '='
                cocoa_name = 'set' + name[0].upcase + name[1, name.length-2]

                alias_method cocoa_name, name
            end

            super
        end
    end

    # set ivar and send out notifications
    # pass a block to do non-atomic operations
    def set_ivar(name, value)
        name = name.to_s
        willChangeValueForKey(name)
        instance_variable_set(('@'+name).to_sym, value)
        yield if block_given?
        didChangeValueForKey(name)
    end

    def NSLocalizedString(key, value = nil)
        NSBundle.mainBundle.localizedStringForKey(key, value:value, table:nil)
    end
end



class NSAffineTransform
    def self.transformRotatingAroundPoint(p, byDegrees:deg)
        if p.is_a?(NSPoint)
            p = [p.x, p.y]
        end

        transform = NSAffineTransform.transform
        transform.translateXBy(p[0], yBy:p[1])
        transform.rotateByDegrees(deg)
        transform.translateXBy(-p[0], yBy:-p[1])
        transform
    end
end

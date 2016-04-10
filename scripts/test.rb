require 'orocos'
include Orocos
require 'utilrb'
require 'vizkit'

## Initialize orocos ##
Orocos.initialize

Orocos.run 'motion_controller::Task' => 'motion_controller', :valgrind => false, :gdb => false do
    motion_controller = Orocos.name_service.get 'motion_controller'
    motion_controller.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/eo2/config/orogen/motion_controller::Task.yml", ['default'])
    #motion_controller.apply_conf_file("../config/spacebot-motion_controller::Task.yml", ['default'])
      
    motion_controller.configure
    motion_controller.start
        
    Vizkit.display motion_controller
    Vizkit.display motion_controller.wheel_debug
    Vizkit.display motion_controller.ackermann_turning_center
    Vizkit.exec
end
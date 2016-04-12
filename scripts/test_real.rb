require 'orocos'
include Orocos
require 'utilrb'
require 'vizkit'

## Initialize orocos ##
Orocos.initialize

Orocos.run 	'motion_controller::Task' => 'motion_controller',
			'ndlcom_wheelmodules::WheelModuleTask' => 'bogie_front_task',
			'ndlcom_wheelmodules::WheelModuleTask' => 'bogie_left_task',
			'ndlcom_wheelmodules::WheelModuleTask' => 'bogie_right_task',
			'serial_ndlcom::Task' => 'serial_bogie_front_task',
			'serial_ndlcom::Task' => 'serial_bogie_left_task',
			'serial_ndlcom::Task' => 'serial_bogie_right_task',
			'joint_dispatcher::Task' => 'bogie_dispatcher',
			'imu_xsens::Task' => 'xsens',
			:valgrind => false, :gdb => false do

	serialBogieFront = Orocos.name_service.get 'serial_bogie_front_task'
    serialBogieLeft = Orocos.name_service.get 'serial_bogie_left_task'
    serialBogieRight = Orocos.name_service.get 'serial_bogie_right_task'

    serialBogieFront.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/serial_ndlcom::Task.yml", ['default', 'front'])
    serialBogieLeft.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/serial_ndlcom::Task.yml", ['default', 'left'])
    serialBogieRight.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/serial_ndlcom::Task.yml", ['default', 'right'])

    puts "serialBogieFront.configure.."
    serialBogieFront.configure
    puts "serialBogieLeft.configure.."
    serialBogieLeft.configure
    puts "serialBogieRight.configure.."
    serialBogieRight.configure


    bogieFront = Orocos.name_service.get 'bogie_front_task'
    bogieLeft = Orocos.name_service.get 'bogie_left_task'
    bogieRight = Orocos.name_service.get 'bogie_right_task'

    bogieFront.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/ndlcom_wheelmodules::WheelModuleTask.yml", ['default', 'front'])
    bogieLeft.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/ndlcom_wheelmodules::WheelModuleTask.yml", ['default', 'left'])
    bogieRight.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/ndlcom_wheelmodules::WheelModuleTask.yml", ['default', 'right'])

	puts "bogieFront.configure.."
    bogieFront.configure
    puts "bogieLeft.configure.."
    bogieLeft.configure
    puts "bogieRight.configure.."
    bogieRight.configure


    bogieDispatcher = Orocos.name_service.get 'bogie_dispatcher'
    bogieFront.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/joint_dispatcher::Task.yml", ['default', 'bogies'])
    puts "bogieDispatcher.configure.."
    bogieDispatcher.configure


    motion_controller = Orocos.name_service.get 'motion_controller'
	motion_controller.apply_conf_file("../config/spacebot-motion_controller::Task.yml", ['default'])
	puts "motion_controller.configure.."
	motion_controller.configure


    xsens = Orocos.name_service.get 'xsens'
    xsens.apply_conf_file("#{ENV['AUTOPROJ_CURRENT_ROOT']}/bundles/spacebot/config/orogen/imu_xsens::Task.yml", ['default'])
    puts "xsens.configure.."
    xsens.configure


    puts "connect all ports.."
    serialBogieFront.ndlcom_message_out.connect_to bogieFront.ndlcom_message_in, :type => :buffer, :size => 40
    bogieFront.ndlcom_message_out.connect_to serialBogieFront.ndlcom_message_in, :type => :buffer, :size => 40
    serialBogieLeft.ndlcom_message_out.connect_to bogieLeft.ndlcom_message_in, :type => :buffer, :size => 40
    bogieLeft.ndlcom_message_out.connect_to serialBogieLeft.ndlcom_message_in, :type => :buffer, :size => 40
    serialBogieRight.ndlcom_message_out.connect_to bogieRight.ndlcom_message_in, :type => :buffer, :size => 40
    bogieRight.ndlcom_message_out.connect_to serialBogieRight.ndlcom_message_in, :type => :buffer, :size => 40

    frontBogie.status_samples.connect_to bogieDispatcher.bogie_front, :type => :buffer, :size => 200
    leftBogie.status_samples.connect_to bogieDispatcher.bogie_left, :type => :buffer, :size => 200
    rightBogie.status_samples.connect_to bogieDispatcher.bogie_right, :type => :buffer, :size => 200

    motion_controller.actuators_command.connect_to frontBogie.command
    motion_controller.actuators_command.connect_to leftBogie.command
    motion_controller.actuators_command.connect_to rightBogie.command

    bogieDispatcher.motion_status.connect_to motion_controller.actuators_status
    

    puts "xsens.start.."
    xsens.start

    puts "serialBogieFront.start.."
    serialBogieFront.start
    puts "serialBogieLeft.start.."
    serialBogieLeft.start
    puts "serialBogieRight.start.."
    serialBogieRight.start

	puts "bogieFront.start.."
    bogieFront.start
    puts "bogieLeft.start.."
    bogieLeft.start
    puts "bogieRight.start.."
    bogieRight.start

    puts "bogieDispatcher.start.."
    bogieDispatcher.start

    puts "motion_controller.start.."
    motion_controller.start

        
    Vizkit.display motion_controller
    Vizkit.display motion_controller.wheel_debug
    Vizkit.display motion_controller.ackermann_turning_center
    Vizkit.exec
end
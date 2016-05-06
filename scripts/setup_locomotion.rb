#! /usr/bin/env ruby

require 'rock/bundle'
require 'readline'
require 'orocos'
require 'optparse'
require 'transformer/runtime'

require_relative 'helper/general.rb'

Orocos::MQueue.auto = true

include Orocos
# 8.4MB is not enough for GraphSlam and Sascha used 80MB as well.
Orocos::CORBA.max_message_size = 80000000
Bundles.initialize

Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

@allTasks = Array.new()


################################################################################################
#  Start Bundles
################################################################################################

def setupTask
    #####################################################################
    # Get the name service
    #####################################################################
    puts "GET NAME SERVICES"
   
    serialBogieFront = getTask( 'serial_bogie_front_task', @allTasks )
    serialBogieLeft = getTask( 'serial_bogie_left_task', @allTasks )
    serialBogieRight = getTask( 'serial_bogie_right_task', @allTasks )

    bogieFront = getTask( 'bogie_front_task', @allTasks )
    bogieLeft = getTask( 'bogie_left_task', @allTasks )
    bogieRight = getTask( 'bogie_right_task', @allTasks )

    bogieDispatcher = getTask( 'bogie_dispatcher', @allTasks )

    motion_controller = getTask( 'motion_controller', @allTasks )
    follower = getTask( 'trajectory_follower', @allTasks )

    odometry = getTask( 'odometry', @allTasks )

    xsens = getTask( 'xsens', @allTasks )


    #####################################################################
    # Set configuration
    #####################################################################      
    puts "SET CONFIGURATIONS"

    addConfig( serialBogieFront, 'front', @allTasks )
    addConfig( serialBogieLeft, 'left', @allTasks )
    addConfig( serialBogieRight, 'right', @allTasks )

    addConfig( bogieFront, 'front', @allTasks )
    addConfig( bogieLeft, 'left', @allTasks )
    addConfig( bogieRight, 'right', @allTasks )

    addConfig( bogieDispatcher, 'bogies', @allTasks)
   
    setAllConfigs(@allTasks)
    
    #####################################################################
    # Transformer
    #####################################################################
    puts "SETUP TRANSFORMER"
    
    setupAllTransformers(@allTasks)

    #####################################################################
    # Configure
    #####################################################################      
    puts "CONFIGURE"

    configureAll(@allTasks)

    #####################################################################
    # Connections
    #####################################################################
    puts "CONNECT PORTS"

    serialBogieFront.ndlcom_message_out.connect_to bogieFront.ndlcom_message_in, :type => :buffer, :size => 40
    bogieFront.ndlcom_message_out.connect_to serialBogieFront.ndlcom_message_in, :type => :buffer, :size => 40
    serialBogieLeft.ndlcom_message_out.connect_to bogieLeft.ndlcom_message_in, :type => :buffer, :size => 40
    bogieLeft.ndlcom_message_out.connect_to serialBogieLeft.ndlcom_message_in, :type => :buffer, :size => 40
    serialBogieRight.ndlcom_message_out.connect_to bogieRight.ndlcom_message_in, :type => :buffer, :size => 40
    bogieRight.ndlcom_message_out.connect_to serialBogieRight.ndlcom_message_in, :type => :buffer, :size => 40

    bogieFront.joints_status.connect_to bogieDispatcher.bogie_front, :type => :buffer, :size => 200
    bogieLeft.joints_status.connect_to bogieDispatcher.bogie_left, :type => :buffer, :size => 200
    bogieRight.joints_status.connect_to bogieDispatcher.bogie_right, :type => :buffer, :size => 200

    motion_controller.actuators_command.connect_to bogieFront.joints_command
    motion_controller.actuators_command.connect_to bogieLeft.joints_command
    motion_controller.actuators_command.connect_to bogieRight.joints_command

    bogieDispatcher.motion_status.connect_to motion_controller.actuators_status
    bogieDispatcher.motion_status.connect_to odometry.actuator_samples, :type => :buffer, :size => 200
 
    #####################################################################
    # starting the task
    #####################################################################
    puts "START TASKS"
    
    startAll(@allTasks)
    
    Readline.readline "Hit ENTER to stop" 
end

Bundles.run 'sb_base',
            'output' => nil,
            "wait" => 500,
            "valgrind" => false  do

        Orocos.log_all_ports()
        setupTask()
end

#! /usr/bin/env ruby

require 'rock/bundle'
require 'readline'
require 'orocos'
require 'optparse'
require 'transformer/runtime'

require_relative 'helpers/general.rb'

Orocos::MQueue.auto = true

include Orocos
Orocos::CORBA.max_message_size = 840000000
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
    
    drive_mode_controller               = getTask('motion_controller', @allTasks)
    joints                              = getTask('joints', @allTasks)
    perfect_odometry                    = getTask('perfect_odometry', @allTasks)
    follower 				= getTask('trajectory_follower',@allTasks)

    #####################################################################
    # Set configuration
    #####################################################################      
    puts "SET CONFIGURATIONS"
    
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

    drive_mode_controller.actuators_command.connect_to joints.command
    follower.motion_command.connect_to drive_mode_controller.motion_command
        
    #####################################################################
    # starting the task
    #####################################################################
    puts "START TASKS"
    
    startAll(@allTasks)
       
    Readline.readline "Hit ENTER to stop" 
end


#####################################################################
# Load deployments
#####################################################################

# Content of these language variables may not be german, otherwise '.' and ','
# are mixed reading numbers and a bad_alloc error occurs loading the scenes.
ENV['LANG'] = 'C'
ENV['LC_NUMERIC'] = 'C'

Bundles.run 'eo2_sim',
            'motion_controller::Task' => 'motion_controller',
            'trajectory_follower::Task' => 'trajectory_follower',
            "wait" => 1000 do

    #Orocos.log_all_ports()
        
    mars_simulation = Orocos::TaskContext.get("mars_simulation")
    Orocos.conf.apply( mars_simulation, ['default'] )
    mars_simulation.configure()
    mars_simulation.start()

    # Has to be called after configure.
    mars_simulation.loadScene('../../../../models/robots/eo2/smurf/eo2.smurf')
    mars_simulation.loadScene('../../../../models/terrains/spacebot_cup_building.smurfs')
    setupTask()
end

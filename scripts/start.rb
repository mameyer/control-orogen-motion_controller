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
    
    motion_controller                   = getTask('motion_controller', @allTasks)
    bogie_front                         = getTask('bogie_front_task', @allTasks)
    bogie_left                          = getTask('bogie_left_task', @allTasks)
    bogie_right                         = getTask('bogie_right_task', @allTasks)
    bogie_dispatcher                    = getTask('bogie_dispatcher', @allTasks)


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

    #motion_controller.actuators_command.connect_to joints.command
        
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

Bundles.run 'spacebot_simulation',
            'motion_controller::Task' => 'motion_controller',
            "wait" => 1000 do

    #Orocos.log_all_ports()
        
    mars_simulation = Orocos::TaskContext.get("mars_simulation")
    Orocos.conf.apply( mars_simulation, ['default'] )
    mars_simulation.configure()
    mars_simulation.start()

    # Has to be called after configure.
    mars_simulation.loadScene('../../../../simulation/models/robots/artemis/smurf/artemis.smurf')
    mars_simulation.loadScene('../../../../simulation/models/terrains/spacebot_cup_building/spacebot_cup_building.smurfs')

    setupTask()
end

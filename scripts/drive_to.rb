#! /usr/bin/env ruby

require 'rock/bundle'
require 'readline'
require 'orocos'
require 'optparse'
require "transformer/runtime"

include Orocos

Bundles.initialize

require_relative '../helpers/general'

#####################################################################
# Get the name service
#####################################################################

# navigation components
velodyne                    = Bundles.get 'velodyne'
traversability              = Bundles.get 'traversability'
slam                        = Bundles.get 'slam' 
planner                     = Bundles.get 'planner'
follower                    = Bundles.get 'follower'
puts "inSim #{@inSim}"
if(@inSim)
    controller              = Bundles.get 'drive_mode_controller'
else
    controller              = Bundles.get 'eo2_driver'
end

if @use_slam3d
    slam.optimize()
    slam.generate_map()
else
    slam.generateMap()
end

#####################################################################
# state
##################################################################### 

while true do
    puts "Enter a comma-separated goal position / a list of goal positions (meter and radians): x,y,theta <x,y,theta>"
    input = Readline::readline
    if input == "exit" || input == "quit"
        puts "Exit ... "
        exit
    end
  
    coordinates = input.split(" ")
    
    for i in 0..coordinates.size()-1 do
        puts "number of coordinates #{coordinates.size()}"
        cmds = coordinates.at(i).split(",")
        if cmds.size() != 3 
            puts "Wrong number of arguments #{cmds}"
            next
        end
    
        begin
            x = Float(cmds[0])
            y = Float(cmds[1])
            theta = Float(cmds[2])
        rescue
            puts "Argument error ( #{cmds[0]}, #{cmds[1]}, #{cmds[2]} )"
            next
        end
        
        if(planner.exception?)
            puts("restarting planner")
            restart(planner)
        end
              
        goal_writer = planner.goal_pose_samples.writer
        goal_pose = goal_writer.new_sample
        goal_pose.position[0] = x
        goal_pose.position[1] = y
        goal_pose.position[2] = 0
        goal_pose.orientation = Eigen::Quaternion.from_angle_axis( theta, Eigen::Vector3.new( 0, 0, 1 ) )
        puts "Coordinate #{i}: Set new goal pose to (#{x}, #{y}, #{goal_pose.position[2]}, #{goal_pose.orientation.yaw})"
        goal_writer.write(goal_pose)  

=begin                        
        while(true)
            puts "planner exception?"
            if(planner.exception?)
                puts("Global planning failed")
                break
            end
            puts "reached the end?"
            puts "state #{follower.state}" 
            if follower.state == :REACHED_THE_END
                puts "Robot reaches end of global trajectory"
                motion_cmd_writer = controller.motion_command.writer
                motion_cmd = motion_cmd_writer.new_sample
                motion_cmd.translation = 0.0
                motion_cmd.rotation = 0.0
                motion_cmd_writer.write(motion_cmd)
                puts "break"
                break
            end
            
            sleep 0.1
        end   
=end
    end
end


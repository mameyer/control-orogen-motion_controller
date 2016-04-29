#! /usr/bin/env ruby

require 'rock/bundle'
require 'readline'
require 'orocos'
require 'optparse'
require 'transformer/runtime'
require_relative 'helpers/general.rb'

Bundles.initialize

drive_mode_controller = Bundles.get 'drive_mode_controller'
trajectory_follower = Bundles.get 'trajectory_follower'
slam = Bundles.get 'slam'

holonomic_trajectory_writer = trajectory_follower.holonomic_trajectory.writer
slam_pose_reader = slam.pose_samples.reader()
trajectory_writer = trajectory_follower.trajectory.writer

test_sample = trajectory_writer.new_sample
test_sample.insert(Types::Base::Trajectory.new)
puts "test samples: #{test_sample.class}"

slam_pose = nil
while (!(slam_pose = slam_pose_reader.read_new)) do
   puts "wait for slam pose.."
   sleep 0.1
end

puts slam_pose

current_pose = slam_pose.clone
goal_pose = current_pose.clone
goal_pose.position[0] = 5
goal_pose.position[1] = 2.5
second_goal = goal_pose;
second_goal.position[0] = 8
second_goal.position[1] = 4
puts "current_pose: #{current_pose.position}"
puts "goal_pose: #{goal_pose.position}"
#goals = typelib_t::ContainerType</std/vector</base/samples/RigidBodyState>.new
#goals.insert(goal_pose)
#goals.insert(second_goal)
puts "goals: #{goals.class}"
trajectory_follower.exec_lateral_curve(current_pose, goal_pose, 0.5)

while (trajectory_follower.state == :FINISHED_TRAJECTORIES)
   puts "no active trajectory.."
   sleep 1
end

while (trajectory_follower.state != :FINISHED_TRAJECTORIES)
   puts "following trajectory: #{trajectory_follower.state}.."
   sleep 1
end

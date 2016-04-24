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

holonomic_trajectory_writer = trajectory_follower.holonomic_trajectory.writer
#follower_state_reader = trajectory_follower.state.reader

current_pose = Types::Base::Pose2D
goal_pose = Types::Base::Pose2D
sub_trajectory = Types::TrajectoryFollower::Lateral.new
puts sub_trajectory.class
sub_trajectory.interpolate [current_pose, goal_pose]
puts "write sample.."
holonomic_trajectory_writer.write sub_trajectory

#follower_state = follower_state_reader.read

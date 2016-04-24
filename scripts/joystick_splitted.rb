require 'orocos'
require 'orocos/async'
require 'readline'
include Orocos

if ARGV.size < 1
    puts "usage: joystick host-address [device_name]"
    exit(0)
end

host_address = ARGV[0]
device_name = "/dev/input/js0" # This might be another port
if ARGV[1] then
    device_name = ARGV[1]
end

Orocos::CORBA.name_service.ip = host_address 
Orocos.initialize

Orocos.run 'controldev::JoystickTask' => 'joystick' do
    joystick = TaskContext.get 'joystick'
    axisScale = joystick.axisScale
    #axisScale[0] = -1.0
    joystick.axisScale= axisScale
    joystick.device = device_name

    motion_controller = TaskContext.get 'motion_controller'
    motion_controller.motion_command.disconnect_all()

    if File.exist? device_name then
        joystick.motion_command.connect_to motion_controller.motion_command
        joystick.configure
        joystick.start
        
        Readline::readline("Press Enter to exit\n") 
    else
        puts 'Couldn\'t find device ' + device_name + '. Using joystick gui instead.'
        require 'vizkit'
        motion_cmd_writer = motion_controller.motion_command.writer
        motion_cmd = motion_cmd_writer.new_sample
        joystickGuiHeading = Vizkit.default_loader.create_plugin('VirtualJoystick')
        joystickGuiTranslation = Vizkit.default_loader.create_plugin('VirtualJoystick')
        joystickGuiHeading.show
        joystickGuiTranslation.show

	motion_cmd.rotation = 0

	joystickGuiTranslation.connect(SIGNAL('axisChanged(double, double)')) do |x, y|
 	    motion_cmd.translation = x * 0.5
	end

        joystickGuiHeading.connect(SIGNAL('axisChanged(double, double)')) do |x, y|
            motion_cmd.heading = - y.abs() * Math::atan2(y, x.abs()) / 1.0 * 0.3
            if motion_cmd.heading.abs() < 0.1 && motion_cmd.heading.abs() > 0.1
                motion_cmd.translation = 0
            end
            motion_cmd_writer.write(motion_cmd)
        end 
        Vizkit.exec
    end
end

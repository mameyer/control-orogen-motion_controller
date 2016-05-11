/* Generated from orogen/lib/orogen/templates/tasks/Task.cpp */

#include "Task.hpp"

#include <base/Waypoint.hpp>

using namespace motion_controller;

Task::Task(std::string const& name)
    : TaskBase(name)
{
}

Task::Task(std::string const& name, RTT::ExecutionEngine* engine)
    : TaskBase(name, engine)
{
}

Task::~Task()
{
}



/// The following lines are template definitions for the various state machine
// hooks defined by Orocos::RTT. See Task.hpp for more detailed
// documentation about them.

bool Task::configureHook()
{
    if (! TaskBase::configureHook())
        return false;

    Geometry geometry = _geometry.get();

    controllerBase = new ControllerBase();
    
    double maxRotationAngle =  _max_rotation_angle.get();
    if (maxRotationAngle < 0.)
    {
        maxRotationAngle = M_PI;
    }
    
    controllerBase->setMaxRotationAngle(maxRotationAngle);

    std::cout << "actuators.. " << std::endl;
    for (auto actuator: _actuators.get())
    {
        base::Vector2d actuatorPos = actuator.position;
        if (actuator.type != WheelType::WheelOther)
        {
            actuatorPos = geometry.getWheelPosition(actuator.type);
        }
        jointActuators[actuator.name] = controllerBase->addJointActuator(actuatorPos);
        std::cout << "actuator: " << actuator.name << ", position: " << jointActuators[actuator.name]->getPosition().transpose() << std::endl;
    }

    std::cout << "jointCommands.. " << std::endl;
    for (auto jointCommand: _joint_commands.get())
    {
        std::cout << "jointCommand: " << jointCommand.name << std::endl;
        JointCmd *jointCmd(controllerBase->addJointCmd(jointCommand.name, jointCommand.type));
        std::cout << "jointActuators.find: " << jointCommand.actuator << std::endl;
        auto jointActuator = jointActuators.find(jointCommand.actuator);
        if (jointActuator != jointActuators.end())
        {
            std::cout << "jointCmd " << jointCmd->getName() << " register at: " << jointActuator->first << std::endl;
            jointCmd->registerAt(jointActuator->second);
        }
    }
    
    controllerBase->resetAllJoints(actuatorsCommand);
    controllerBase->resetAllJoints(actuatorsFeedback);

    motion_control_dispatcher = new Dispatcher(geometry, controllerBase, _use_joints_feedback);

    if (_ackermann_ratio.get() >= 0 && _ackermann_ratio.get() <= 1)
    {
        motion_control_dispatcher->setAckermannRatio(_ackermann_ratio.get());
    }

    return true;
}

bool Task::startHook()
{
    if (! TaskBase::startHook())
        return false;
    return true;
}

void Task::updateHook()
{
    TaskBase::updateHook();
    
    base::samples::Joints joints;
    if(_actuators_status.read(joints) == RTT::NewData)
    {
        actuatorsFeedback = joints;
    }
    
    
    trajectory_follower::Motion2D motionCommand;
    
    if(_motion_command.read(motionCommand) == RTT::NewData){
        motion_control_dispatcher->compute(motionCommand, actuatorsCommand, actuatorsFeedback);
        _actuators_command.write(actuatorsCommand);
        state(EXEC_TURN_ON_SPOT);
        std::vector<base::Waypoint> wheelsDebug;
        for (auto jointActuator: controllerBase->getJointActuators())
        {
            JointCmd* positionCmd = jointActuator->getJointCmdForType(JointCmdType::Position);
            JointCmd* steeringCmd = jointActuator->getJointCmdForType(JointCmdType::Speed);

            base::JointState &jointState(actuatorsCommand[actuatorsCommand.mapNameToIndex(positionCmd->getName())]);
            base::JointState &steeringJointState(actuatorsCommand[actuatorsCommand.mapNameToIndex(steeringCmd->getName())]);

            base::Waypoint wheelOut, wheelSteeringOut;
            auto pos = jointActuator->getPosition();
            wheelOut.position.x() = pos.x();
            wheelOut.position.y() = pos.y();
            wheelOut.position.z() = 0.;
            wheelOut.heading = jointState.position;
            wheelSteeringOut.position = wheelOut.position;
            wheelSteeringOut.heading = (steeringJointState.speed > 0) ? 0 : M_PI;
            wheelsDebug.push_back(wheelOut);
            wheelsDebug.push_back(wheelSteeringOut);
        }

        _wheel_debug.write(wheelsDebug);
    }else{
        state(IDLE);
    }
}

void Task::errorHook()
{
    TaskBase::errorHook();
}

void Task::stopHook()
{
    TaskBase::stopHook();
}

void Task::cleanupHook()
{
    delete motion_control_dispatcher;
    TaskBase::cleanupHook();
}

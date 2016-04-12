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

    ackermannController = new Ackermann(geometry, controllerBase);
    lateralController = new Lateral(geometry, controllerBase);
    pointTurnController = new PointTurn(geometry, controllerBase);

    if (_ackermann_ratio.get() >= 0 && _ackermann_ratio.get() <= 1)
    {
        ackermannController->setAckermannRatio(_ackermann_ratio.get());
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

    trajectory_follower::Motion2D motionCommand;
    if (_motion_command.read(motionCommand) == RTT::NewData) {
        if (motionCommand.translation == 0 && motionCommand.rotation != 0)
        {
            const base::samples::Joints& actuators_command(pointTurnController->compute(motionCommand));
            _actuators_command.write(actuators_command);
            state(EXEC_TURN_ON_SPOT);
        }
        else
        {
            const base::samples::Joints& actuators_command(ackermannController->compute(motionCommand));
            _actuators_command.write(actuators_command);
            state(EXEC_ACKERMANN);
        }

        std::vector<base::Waypoint> wheelsDebug;
        for (auto jointActuator: controllerBase->getJointActuators())
        {
            JointCmd* positionCmd = jointActuator->getJointCmdForType(JointCmdType::Position);
            JointCmd* steeringCmd = jointActuator->getJointCmdForType(JointCmdType::Speed);

            base::JointState &jointState(controllerBase->getJoints()[controllerBase->getJoints().mapNameToIndex(positionCmd->getName())]);
            base::JointState &steeringJointState(controllerBase->getJoints()[controllerBase->getJoints().mapNameToIndex(steeringCmd->getName())]);

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

        base::Waypoint ackermannTurningCenter;
        auto turningCenter = ackermannController->getTurningCenter();
        ackermannTurningCenter.position.x() = turningCenter.x();
        ackermannTurningCenter.position.y() = turningCenter.y();
        ackermannTurningCenter.position.z() = 0.;
        _ackermann_turning_center.write(ackermannTurningCenter);
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
    TaskBase::cleanupHook();
}

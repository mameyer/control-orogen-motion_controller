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
    
    /*double maxRotationAngle =  _max_rotation_angle.get();
    if (maxRotationAngle < 0.)
    {
        maxRotationAngle = M_PI;
    }
    
    controllerBase->setMaxRotationAngle(maxRotationAngle);*/
    

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

    motionControlDispatcher = new Dispatcher(geometry, controllerBase, _use_joints_feedback);

    if (_ackermann_ratio.get() >= 0 && _ackermann_ratio.get() <= 1)
    {
        motionControlDispatcher->setAckermannRatio(_ackermann_ratio.get());
    }
    
    //motionControlDispatcher->setTurningAngleThreshold(_turning_angle_threshold.get());
    motionControlDispatcher->setJointsFeedbackTurningThreshold(_joints_feedback_turning_threshold.get());
    //motionControlDispatcher->getAckermannController()->setRotationMaxEpsilon(_rotation_max_epsilon.get());

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
    controllerBase->resetAllJoints(actuatorsCommand);
    
    
    if(_use_joints_feedback)
    {
        if (!_actuators_status.read(actuatorsFeedback) == RTT::NewData)
        {
            state(MISSING_JOINTS_FEEDBACK);
            _actuators_command.write(actuatorsCommand);
            return;
        }
    }
    
    base::commands::Motion2D motionCommand;
    
    if(_motion_command.read(motionCommand) == RTT::NewData){   
        lastCommand = motionCommand;
    }else{
        if(lastCommand == zeroCommand){
            motionCommand = zeroCommand;
        }else{
            motionCommand = lastCommand;        //TODO: Timeout
        }
    }
        
    motionControlDispatcher->compute(motionCommand, actuatorsCommand, actuatorsFeedback);
    _actuators_command.write(actuatorsCommand);
    
    switch (motionControlDispatcher->getCurrentMode())
    {
        case ModeAckermann:
            state(EXEC_ACKERMANN);
            break;
        
        case ModeTurnOnSpot:
            state(EXEC_TURN_ON_SPOT);
            break;
            
        case ModeLateral:
            state(EXEC_LATERAL);
            break;
            
        default:
            state(IDLE);
            break;
    }
    
    switch (motionControlDispatcher->getStatus())
    {
        case TooFast:
            state(TOO_FAST);
            break;
            
        case NeedsToWaitForTurn:
            state(NEEDS_WAIT_FOR_TURN);
            break;
            
        default:
            break;
    }
    
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
    
    base::Waypoint ackermannTurningCenter;
    auto turningCenter = motionControlDispatcher->getAckermannController()->getTurningCenter();
    ackermannTurningCenter.position.x() = turningCenter.x();
    ackermannTurningCenter.position.y() = turningCenter.y();
    ackermannTurningCenter.position.z() = 0.;
    _ackermann_turning_center.write(ackermannTurningCenter);
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
    delete motionControlDispatcher;
    TaskBase::cleanupHook();
}
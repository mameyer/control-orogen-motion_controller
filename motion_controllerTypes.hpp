#ifndef motion_controller_TYPES_HPP
#define motion_controller_TYPES_HPP

/* If you need to define types specific to your oroGen components, define them
 * here. Required headers must be included explicitly
 *
 * However, it is common that you will only import types from your library, in
 * which case you do not need this file
 */

#include <motion_controller/MotionControllerTypes.hpp>

#include <base/Eigen.hpp>

namespace motion_controller {

struct Actuator
{
    WheelType type;
    base::Vector2d position;
    std::string name;
};

struct JointCommand
{
    std::string actuator;
    std::string name;
    JointCmdType type;
};

}

#endif


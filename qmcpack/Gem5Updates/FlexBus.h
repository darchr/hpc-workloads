#pragma once

#include "sim/sim_object.hh"

namespace gem {

class LogicalSubBlock;
class ElectricalSubBlock;

class FlexBus: public SimObject {
  public:
    FlexBus();
    ~FlexBus();

    void startup();
    void exec();
  private:
    EventFunctionWrapper event;
}

} // namespace gem5
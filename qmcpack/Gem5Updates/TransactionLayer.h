#pragma once

#include "sim/sim_object.hh"
#include "LinkLayer.h"

namespace gem {

class TransactionLayer: public SimObject {
  public:
    TransactionLayer();
    ~TransactionLayer();

    void startup();
    void exec();
  private:
    EventFunctionWrapper event;
}

} // namespace gem5
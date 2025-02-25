#pragma once

#include "sim/sim_object.hh"
#include "CXLLink.h"

namespace gem {

class LinkLayer: public SimObject {
  public:
    LinkLayer();
    ~LinkLayer();

    void startup();
    void exec();
  private:
    EventFunctionWrapper event;
}

} // namespace gem5
#pragma once

#include "sim/sim_object.hh"

namespace gem {

class CXLLink: public SimObject {
  public:
    CXLLink();
    ~CXLLink();

    enum CXLProtocols {
      io,
      cache,
      mem
    }

    void startup();
    void exec();
  private:
    EventFunctionWrapper event;
}

} // namespace gem5
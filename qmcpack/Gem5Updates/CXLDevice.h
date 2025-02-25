#pragma once

#include "sim/sim_object.hh"
#include "FlexBus.h"
#include "TransactionLayer.h"

namespace gem {

class CXLDevice: public SimObject {
  public:
    CXLDevice();
    ~CXLDevice();

    void startup();
    void exec();

    int __cxl_pci_mbox_send_cmd(struct cxl_mailbox *cxl_mbox, struct cxl_mbox_cmd *mbox_cmd);

  private:
    EventFunctionWrapper event;
}

} // namespace gem5
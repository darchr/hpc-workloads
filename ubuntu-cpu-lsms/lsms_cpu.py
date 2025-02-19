from gem5.utils.requires import requires
from gem5.components.boards.x86_board import X86Board
from gem5.components.memory.single_channel import SingleChannelDDR3_1600
from gem5.components.cachehierarchies.ruby.mesi_two_level_cache_hierarchy import MESITwoLevelCacheHierarchy
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.coherence_protocol import CoherenceProtocol
from gem5.isas import ISA
from gem5.components.processors.cpu_types import CPUTypes
from gem5.resources.resource import KernelResource, DiskImageResource, obtain_resource, BinaryResource
from gem5.simulate.simulator import Simulator
from gem5.simulate.exit_event import ExitEvent

cache_hierarchy = MESITwoLevelCacheHierarchy(
    l1d_size="32KiB",
    l1d_assoc=8,
    l1i_size="32KiB",
    l1i_assoc=8,
    l2_size="256KiB",
    l2_assoc=16,
    num_l2_banks=1,
)

memory = SingleChannelDDR3_1600(size="3GiB")

processor = SimpleProcessor(
    cpu_type=CPUTypes.KVM,
    num_cores=4,
    isa=ISA.X86
)

board = X86Board(
    clk_freq="3GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)

command = "cd /home/lsms/Test/Au/;" \
    + "mpirun /home/build_lsms/bin/lsms ./i_lsms;"

board.set_kernel_disk_workload(
    kernel=KernelResource("./disk-image/vmlinux-x86-ubuntu"),
    disk_image=DiskImageResource("./x86-disk-image-22-04/x86-ubuntu"),
    kernel_args=[
      "earlyprintk=ttyS0",
      "console=ttyS0",
      "lpj=7999923",
      "root=/dev/sda2"
    ],
    readfile_contents=command,
)

simulator = Simulator(
    board=board
)
simulator.run()
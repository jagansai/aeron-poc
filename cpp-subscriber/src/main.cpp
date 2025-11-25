#include <iostream>
#include <thread>
#include <chrono>
#include <csignal>
#include <atomic>

#include <Aeron.h>
#include <FragmentAssembler.h>
#include <concurrent/SleepingIdleStrategy.h>

using namespace aeron;
using namespace aeron::concurrent;

std::atomic<bool> running(true);

void sigIntHandler(int) { running = false; }

int main()
{
    const std::string channel = "aeron:udp?endpoint=127.0.0.1:40123";
    const std::int32_t streamId = 1001;

    std::cout << "Subscribing to " << channel << " stream " << streamId << std::endl;

    Context ctx;
    std::shared_ptr<Aeron> aeron = Aeron::connect(ctx);
    std::signal(SIGINT, sigIntHandler);

    std::int64_t id = aeron->addSubscription(channel, streamId);
    std::shared_ptr<Subscription> sub;
    while (!(sub = aeron->findSubscription(id)))
        std::this_thread::yield();

    std::cout << "Subscription ready, polling..." << std::endl;

    FragmentAssembler assembler([](const AtomicBuffer &buf, util::index_t offset, util::index_t len, const Header &hdr) {
        std::cout << "Msg stream=" << hdr.streamId() << " <<" 
                  << std::string(reinterpret_cast<const char*>(buf.buffer()) + offset, len) 
                  << ">>" << std::endl;
    });

    SleepingIdleStrategy idle(std::chrono::milliseconds(1));

    while (running)
    {
        int fragments = sub->poll(assembler.handler(), 10);
        idle.idle(fragments);
    }

    std::cout << "Done." << std::endl;
    return 0;
}

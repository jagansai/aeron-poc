#include <iostream>
#include <thread>
#include <chrono>

// Aeron-only subscriber (no UDP fallback). Uses SleepingIdleStrategy for balanced polling.
#include <aeron/Aeron.h>
#include <aeron/Subscription.h>
#include <concurrent/AtomicBuffer.h>
#include <concurrent/SleepingIdleStrategy.h>
#include <util/Index.h>

using namespace aeron;

int main()
{
    const std::string channel = "aeron:udp?endpoint=127.0.0.1:40123";
    const std::int32_t streamId = 1001;

    aeron::Context ctx;
    std::shared_ptr<Aeron> client = Aeron::connect(ctx);

    // addSubscription returns a registration id; then find the Subscription object
    std::int64_t registrationId = client->addSubscription(channel, streamId);

    std::shared_ptr<Subscription> subscription;

    std::cout << "Waiting for subscription to become available on " << channel << " stream=" << streamId << "\n";

    // wait until the subscription object is available from the client
    while (!subscription)
    {
        subscription = client->findSubscription(registrationId);
        if (!subscription)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }

    std::cout << "Subscription available, polling for messages..." << std::endl;

    // Simple poll loop using Aeron's SleepingIdleStrategy (balanced latency vs CPU)
    aeron::concurrent::SleepingIdleStrategy idle(std::chrono::milliseconds(1)); // 1ms sleep granularity

    auto handler = [](const AtomicBuffer& buffer, util::index_t offset, util::index_t length, const Header& header)
    {
        const char* data = reinterpret_cast<const char*>(buffer.buffer()) + offset;
        std::string msg(data, static_cast<size_t>(length));
        std::cout << "Received: " << msg << std::endl;
    };

    while (true)
    {
        int fragments = subscription->poll(handler, 10);
        idle.idle(fragments);
    }

    return 0;
}

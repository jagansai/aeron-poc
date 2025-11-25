package org.example;

import org.agrona.concurrent.UnsafeBuffer;

import io.aeron.Aeron;
import io.aeron.Publication;

public class Publisher {
    private static final String CHANNEL = "aeron:udp?endpoint=127.0.0.1:40123";
    private static final int STREAM_ID = 1001;


    public record Args( boolean loop, int count, int intervalMs) {
    }


    private static Args parseArgs(String[] args) {
        boolean loop = false;
        int count = 10;
        int intervalMs = 500;

        if (args.length >= 1) {
            if ("loop".equalsIgnoreCase(args[0])) {
                loop = true;
            } else {
                try {
                    count = Integer.parseInt(args[0]);
                    if (count == -1) {
                        loop = true;
                    }
                } catch (NumberFormatException ignore) {
                }
            }
        }
        if (args.length >= 2) {
            try {
                intervalMs = Integer.parseInt(args[1]);
            } catch (NumberFormatException ignore) {
            }
        }
        return new Args(loop, count, intervalMs);
    }


    public static void main(String[] args) throws Exception {    
        // parse args: first arg can be 'loop' or a count, second arg is interval ms
        Args parsedArgs = parseArgs(args);
        
        final Aeron.Context ctx = new Aeron.Context();
        publishData(parsedArgs, ctx);
    }


    private static void publishData(Args args, final Aeron.Context ctx)
            throws InterruptedException {
        try (Aeron aeron = Aeron.connect(ctx);
                   Publication publication = aeron.addPublication(CHANNEL, STREAM_ID)) {
            System.out.println("Publishing to " + CHANNEL + " streamId=" + STREAM_ID);

            int i = 0;
            while (args.loop || i < args.count) {
                i++;

                UnsafeBuffer buffer = constructData(i);

                while (publication.offer(buffer, 0, buffer.capacity()) <= 0) { // non-blocking offer. If it fails, retry
                    Thread.yield();
                }
                System.out.println("Sent message " + i + ": " + buffer.byteArray());

                Thread.sleep(args.intervalMs);
            }
        }
    }

    private static UnsafeBuffer constructData(int i) {
        return new UnsafeBuffer(("Hello from Java Publisher(" + i + ")").getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }
}

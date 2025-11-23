package org.example;

import io.aeron.Aeron;
import io.aeron.Publication;
import org.agrona.concurrent.UnsafeBuffer;

public class Publisher {
    public static void main(String[] args) throws Exception {
        final String channel = "aeron:udp?endpoint=127.0.0.1:40123";
        final int streamId = 1001;
        // parse args: first arg can be 'loop' or a count, second arg is interval ms
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

        final Aeron.Context ctx = new Aeron.Context();

        try (Aeron aeron = Aeron.connect(ctx);
             Publication publication = aeron.addPublication(channel, streamId)) {

            System.out.println("Publishing to " + channel + " streamId=" + streamId);

            int i = 0;
            while (loop || i < count) {
                i++;
                String text = "Hello from Java Publisher(" + i + ")";
                byte[] msg = text.getBytes(java.nio.charset.StandardCharsets.UTF_8);
                UnsafeBuffer buffer = new UnsafeBuffer(msg);

                while (publication.offer(buffer, 0, msg.length) <= 0) {
                    // busy-wait retry
                    Thread.yield();
                }
                System.out.println("Sent message " + i + ": " + text);

                Thread.sleep(intervalMs);
            }
        }
    }
}

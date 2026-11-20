package com.meridian.payments.adapter.andina;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.DateTimeException;
import java.time.OffsetDateTime;
import java.util.Base64;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** Verifies Andina signatures against the exact request bytes and signed timestamp. */
public final class AndinaSignatureVerifier {

    private static final long MAX_CLOCK_SKEW_SECONDS = 600;
    private static final String HMAC_SHA_256 = "HmacSHA256";

    private AndinaSignatureVerifier() {
    }

    /**
     * Verifies Base64(HMAC-SHA256(timestamp + "." + rawBody)) and applies the
     * documented ten-minute timestamp tolerance. The clock is supplied by the
     * caller so tests can use deterministic timestamps.
     */
    public static boolean verify(
            byte[] rawBody,
            String timestampText,
            String signature,
            String secret,
            long nowEpochSeconds) {
        if (rawBody == null || timestampText == null || signature == null
                || secret == null || secret.isEmpty()) {
            return false;
        }

        final long timestampEpochSeconds;
        final byte[] suppliedSignature;
        try {
            timestampEpochSeconds = OffsetDateTime.parse(timestampText).toEpochSecond();
            suppliedSignature = Base64.getDecoder().decode(signature);
        } catch (DateTimeException | IllegalArgumentException exception) {
            return false;
        }

        if (suppliedSignature.length != 32
                || absoluteDifference(timestampEpochSeconds, nowEpochSeconds) > MAX_CLOCK_SKEW_SECONDS) {
            return false;
        }

        try {
            byte[] expectedSignature = calculateSignature(rawBody, timestampText, secret);
            return MessageDigest.isEqual(expectedSignature, suppliedSignature);
        } catch (GeneralSecurityException exception) {
            return false;
        }
    }

    private static long absoluteDifference(long left, long right) {
        // Avoid overflow at the long boundary when comparing externally supplied timestamps.
        try {
            return Math.abs(Math.subtractExact(left, right));
        } catch (ArithmeticException exception) {
            return Long.MAX_VALUE;
        }
    }

    private static byte[] calculateSignature(byte[] rawBody, String timestamp, String secret)
            throws GeneralSecurityException {
        Mac mac = Mac.getInstance(HMAC_SHA_256);
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_SHA_256));
        mac.update(timestamp.getBytes(StandardCharsets.UTF_8));
        mac.update((byte) '.');
        return mac.doFinal(rawBody);
    }
}

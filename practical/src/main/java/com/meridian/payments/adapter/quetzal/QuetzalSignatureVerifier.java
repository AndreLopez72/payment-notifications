package com.meridian.payments.adapter.quetzal;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.regex.Pattern;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** Verifies Quetzal signatures without parsing or re-serializing the request body. */
public final class QuetzalSignatureVerifier {

    private static final BigInteger MAX_CLOCK_SKEW_SECONDS = BigInteger.valueOf(300);
    private static final Pattern SIGNATURE_PATTERN = Pattern.compile("[0-9a-f]{64}");
    private static final String HMAC_SHA_256 = "HmacSHA256";

    private QuetzalSignatureVerifier() {
    }

    /**
     * Checks the documented Quetzal header format and HMAC over
     * {@code unixTimestamp + "." + rawBody}. A timestamp exactly 300 seconds
     * from {@code nowEpochSeconds} is within the provider's stated tolerance.
     */
    public static boolean verify(
            byte[] rawBody,
            String signatureHeader,
            String secret,
            long nowEpochSeconds) {
        if (rawBody == null || signatureHeader == null || secret == null || secret.isEmpty()) {
            return false;
        }

        ParsedHeader parsedHeader = parseHeader(signatureHeader);
        if (parsedHeader == null || isOutsideTolerance(parsedHeader.timestamp(), nowEpochSeconds)) {
            return false;
        }

        try {
            byte[] expected = calculateSignature(
                    rawBody,
                    parsedHeader.timestampText(),
                    secret.getBytes(StandardCharsets.UTF_8));

            boolean valid = false;
            for (String signature : parsedHeader.signatures()) {
                byte[] supplied = HexFormat.of().parseHex(signature);
                // Evaluate every accepted rotation signature; do not short-circuit on a match.
                valid |= MessageDigest.isEqual(expected, supplied);
            }
            return valid;
        } catch (IllegalArgumentException | GeneralSecurityException exception) {
            return false;
        }
    }

    private static ParsedHeader parseHeader(String header) {
        String[] parts = header.split(",", -1);
        if (parts.length < 2 || parts.length > 3 || !parts[0].startsWith("t=")) {
            return null;
        }

        String timestampText = parts[0].substring(2);
        if (!timestampText.matches("[0-9]+")) {
            return null;
        }

        long timestamp;
        try {
            timestamp = Long.parseLong(timestampText);
        } catch (NumberFormatException exception) {
            return null;
        }

        List<String> signatures = new ArrayList<>(parts.length - 1);
        for (int index = 1; index < parts.length; index++) {
            String part = parts[index];
            if (!part.startsWith("v1=")) {
                return null;
            }
            String signature = part.substring(3);
            if (!SIGNATURE_PATTERN.matcher(signature).matches()) {
                return null;
            }
            signatures.add(signature);
        }

        return new ParsedHeader(timestamp, timestampText, List.copyOf(signatures));
    }

    private static boolean isOutsideTolerance(long timestamp, long nowEpochSeconds) {
        BigInteger difference = BigInteger.valueOf(timestamp)
                .subtract(BigInteger.valueOf(nowEpochSeconds))
                .abs();
        return difference.compareTo(MAX_CLOCK_SKEW_SECONDS) > 0;
    }

    private static byte[] calculateSignature(byte[] rawBody, String timestamp, byte[] secret)
            throws GeneralSecurityException {
        Mac mac = Mac.getInstance(HMAC_SHA_256);
        mac.init(new SecretKeySpec(secret, HMAC_SHA_256));
        mac.update(timestamp.getBytes(StandardCharsets.US_ASCII));
        mac.update((byte) '.');
        return mac.doFinal(rawBody);
    }

    private record ParsedHeader(long timestamp, String timestampText, List<String> signatures) {
    }
}

<cfscript>
    /**
     * Initialize SecureRandom and Base32 codec
     */
    variables.generator = createObject("java", "java.security.SecureRandom").getInstance("SHA1PRNG");
    variables.base32 = createObject("java", "org.apache.commons.codec.binary.Base32").init();
    variables.alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    /**
     * Validate a 6-digit TOTP code
     */
    public boolean function validateTOTP(required string secret, required string code, numeric window = 1) {
        var step = JavaCast("long", createObject("java", "java.lang.System").currentTimeMillis() / 1000 / 30);
        for (var i = 0; i <= arguments.window; i++) {
            if (getOneTimeToken(arguments.secret, step - i) == arguments.code) {
                return true;
            }
        }
        return false;
    }

    /**
     * Compute TOTP code for a given counter
     */
    private string function getOneTimeToken(required string base32Secret, required numeric counter) {
        var key = variables.base32.decode(base32Secret);
        var mac = createObject("java", "javax.crypto.Mac").getInstance("HmacSHA1");
        mac.init(createObject("java", "javax.crypto.spec.SecretKeySpec").init(key, "HmacSHA1"));

        var buf = createObject("java", "java.nio.ByteBuffer").allocate(8);
        buf.putLong(arguments.counter);
        var hmacBytes = mac.doFinal(buf.array());

        var offset = bitAnd(hmacBytes[arrayLen(hmacBytes)], 15);
        var binary = bitOr(bitOr(bitSHLN(bitAnd(hmacBytes[offset + 1], 127), 24), bitSHLN(bitAnd(hmacBytes[offset + 2], 255), 16)),
                           bitOr(bitSHLN(bitAnd(hmacBytes[offset + 3], 255), 8), bitAnd(hmacBytes[offset + 4], 255)));

        var otp = binary mod 1000000;
        return numberFormat(otp, "000000");
    }
</cfscript>

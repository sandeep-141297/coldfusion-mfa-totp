<cfinclude template="validateTotp.cfm" />

<cfscript>
    // SQL SERVER Table Creation
    /**
        CREATE TABLE usersdata (
            id INT IDENTITY(1,1) PRIMARY KEY,
            email VARCHAR(255) NOT NULL UNIQUE,
            totp_secret VARCHAR(255) DEFAULT NULL,
            uri VARCHAR(255) DEFAULT NULL
        );
    */

    // Initialize database connection (using queryExecute directly)
    datasource = "localDB";

    /**
     * Generate a new Base32 secret key
     * @param length Desired length of secret key (default is 20 characters)
     */
    function generateTOTPSecret(numeric length = 20) {
        variables.secret = "";
        variables.alphaLen = len(variables.alphabet);
        for (variables.i = 1; i <= arguments.length; i++) {
            variables.idx = variables.generator.nextInt(alphaLen);
            secret &= mid(variables.alphabet, idx + 1, 1);
        }
        return secret;
    }

    /**
     * Generate a PNG QR code for Google Authenticator using ZXing
     * @return Path to the saved QR code file
     */
    public binary function generateQRCode(required string secret,
                                         required string accountName,
                                         string issuer = "",
                                         numeric width = 200,
                                         numeric height = 200) {
        // Build the otpauth URL
        var label = URLEncodedFormat(arguments.accountName);
        var secretGenerated = arguments.secret;
        var userEmail = arguments.accountName;
        var issuerParam = len(arguments.issuer) ? URLEncodedFormat(arguments.issuer) & ":" : "";
        var paramString = "secret=" & arguments.secret & (len(arguments.issuer) ? "&issuer=" & URLEncodedFormat(arguments.issuer) : "");
        var otpauthURL = "otpauth://totp/" & issuerParam & label & "?" & paramString;

        // Save to database using queryExecute
        sql = "INSERT INTO usersdata (email, totp_secret, uri) VALUES (:userEmail, :secretGenerated, :otpauthURL)";
        params = {
            userEmail = userEmail,
            secretGenerated = secretGenerated,
            otpauthURL = otpauthURL
        };
        queryExecute(sql, params, {datasource: datasource});

        // Use ZXing classes (ensure zxing-core and zxing-javase JARs are in the CF lib folder)
        var QRCodeWriter = createObject("java", "com.google.zxing.qrcode.QRCodeWriter");
        var BarcodeFormat = createObject("java", "com.google.zxing.BarcodeFormat");
        var bitMatrix = QRCodeWriter.encode(otpauthURL, BarcodeFormat.QR_CODE, arguments.width, arguments.height);

        var baos = createObject("java", "java.io.ByteArrayOutputStream").init();
        createObject("java", "com.google.zxing.client.j2se.MatrixToImageWriter").writeToStream(bitMatrix, "PNG", baos);
        return baos.toByteArray();
    }

    // Main form handling logic
    if (!structKeyExists(FORM, "userEmail") && !structKeyExists(FORM, "totpCode")) {
        writeOutput('<form method="POST">
            <label for="userEmail">Enter your email to generate:</label>
            <input type="email" name="userEmail" required>
            <button type="submit">Generate</button>
        </form>');
    } else if (structKeyExists(FORM, "userEmail")) {
        variables.userEmail = FORM.userEmail;

        try {
            // Fetch existing secret using queryExecute
            sql = "SELECT totp_secret FROM usersdata WHERE email = :userEmail";
            params = {userEmail = userEmail};
            result = queryExecute(sql, params, {datasource: datasource});

            if (result.RecordCount > 0) {
                // Secret exists, prompt for validation
                writeOutput('<form method="POST">
                    <label for="totpCode">Enter your TOTP code:</label>
                    <input type="text" name="totpCode" required>
                    <input type="hidden" name="secret" value="#result.totp_secret[1]#">
                    <button type="submit">Verify</button>
                </form>');
            } else {
                // Generate and save QR code for new user
                variables.totpSecret = generateTOTPSecret();
                variables.qrImageBytes = generateQRCode(secret=totpSecret, accountName=userEmail, issuer="gttApp");

                writeOutput('<h3>You are not setup MFA yet, So please scan this QR Code with your Authenticator App:</h3>');
                writeOutput('<img src="data:image/png;base64,#toBase64(variables.qrImageBytes)#" alt="QR Code">');
                writeOutput('<h3>Enter Secret Manually: #totpSecret#</h3>');
            }
        } catch (any e) {
            writeOutput("Error: " & e.message);
        }
    } else if (structKeyExists(FORM, "totpCode")) {
        variables.valid = validateTOTP(FORM.secret, FORM.totpCode);
        variables.message = valid ? "Authentication successful!" : "Invalid TOTP code.";
        writeOutput("<h3>#message#</h3>");
    }
</cfscript>

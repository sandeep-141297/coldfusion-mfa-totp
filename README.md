# coldfusion-mfa-totp

> 🔐 Add TOTP-based Multi-Factor Authentication to your ColdFusion or Lucee apps using Google Authenticator. Includes QR code generation, DB storage, and validation logic. Easy to set up — just drop into your webroot.

---

# 🔐 MFA Authentication for ColdFusion / Lucee Admin

This project implements **TOTP-based Multi-Factor Authentication (MFA)** for Adobe ColdFusion and Lucee servers. Users scan a QR code using Google Authenticator (or any TOTP-compatible app) and enter a 6-digit code to verify identity.

---

## 📦 Features

* ✔️ Secure TOTP authentication (RFC 6238 compliant)
* 📸 QR code generation via ZXing Java library
* 💾 MSSQL database storage for secrets
* 🧩 Compatible with Adobe ColdFusion and Lucee
* 📂 Self-contained deployment using local `/lib` folder

---

## 🗃️ Database Setup

Run the following SQL to create the user table in **SQL Server**:

```sql
CREATE TABLE usersdata (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    totp_secret VARCHAR(255) DEFAULT NULL,
    uri VARCHAR(255) DEFAULT NULL
);
```

Make sure a datasource named `localDB` exists in your Lucee or ColdFusion admin.

---

## 📁 Folder Structure

```
coldfusion-mfa-totp/
├── generateSecret.cfm           # Main user interaction and logic
├── validateTotp.cfm             # TOTP code generation & validation
├── /lib/                        # Java libraries for QR and Base32
│   ├── zxing-2.1-core.jar
│   └── zxing-2.1-javase.jar
├── README.md
```

---

## ⚙️ Installation Steps

### 1. Deploy the Files

Place the full `coldfusion-mfa-totp` folder into your Lucee or ColdFusion webroot. Example:

```
C:\lucee\tomcat\webapps\ROOT\coldfusion-mfa-totp\
```

### 2. Add Required Libraries

### 📦 Library Setup

Ensure the following `.jar` files are placed inside the appropriate **`lib` folder** based on your ColdFusion or Lucee installation, and then **restart the services**:

#### 🔧 Example Paths:

* **Adobe ColdFusion**:
  `C:\ColdFusion2025\cfusion\lib`

* **Lucee**:
  `C:\lucee\tomcat\lib`

If you're running this project from your webroot (e.g., `/coldfusion-mfa-totp/`), your local project structure might look like this:

```
C:\lucee\tomcat\webapps\ROOT\coldfusion-mfa-totp\lib\
├── zxing-2.1-core.jar
├── zxing-2.1-javase.jar
```

> ⚠️ Note: Restart the ColdFusion or Lucee service after adding the JARs to ensure they are properly loaded.

---

## 🌐 Accessing the MFA Page

Visit:

```
http://localhost:8888/coldfusion-mfa-totp/generateSecret.cfm

```
```
http://localhost:8500/coldfusion-mfa-totp/generateSecret.cfm

```

---

## 🔄 MFA Workflow

1. Enter email address.
2. If not enrolled, a secret is generated and stored.
3. A QR code is displayed — scan it using Google Authenticator or Authy.
4. Enter the TOTP code shown in the app.
5. If the code is valid, MFA is verified.

---

## 🔍 Code Highlights

* `generateSecret.cfm`: Handles form input, database insert/check, QR display.
* `validateTotp.cfm`: Contains Java-based logic for secure TOTP validation.

---

## 🔐 Security Tips

* Protect access to `/coldfusion-mfa-totp` directory if deployed to production.
* Do not expose TOTP secrets.
* Ensure system time is synchronized on the server.
* For advanced use, you can integrate this logic into login flows.

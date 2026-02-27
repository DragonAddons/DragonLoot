# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | yes       |
| older   | no        |

## Reporting a Vulnerability

Please report security issues privately by emailing <admin@xerrion.dk>. Do not open public issues for security reports.

Include the following information:

- Description of the issue
- Steps to reproduce
- Affected versions
- Potential impact

You can expect a response within 7 days.

After you report an issue, we will acknowledge receipt, investigate, and aim to provide a fix in the next release. If you would like credit, we will recognize you in the changelog.

## Scope

In scope:

- Lua code that exposes sensitive user data
- SavedVariables handling that is exploitable
- External communication or data exfiltration

Out of scope:

- World of Warcraft client bugs
- Blizzard API issues
- Gameplay exploits

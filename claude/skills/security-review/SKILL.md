---
name: security-review
description: Security code review for vulnerabilities. Use when asked to "security review", "find vulnerabilities", "check for security issues", "audit security", "OWASP review", or review code for injection, XSS, authentication, authorization, cryptography issues. Provides systematic review with confidence-based reporting.
allowed-tools: Read, Grep, Glob, Bash, Task
---
<!-- imported from: https://github.com/getsentry/skills/tree/main/skills/security-review -->
<!-- Based on OWASP Cheat Sheet Series (CC BY-SA 4.0) https://cheatsheetseries.owasp.org/ -->

# Security Review

Identify exploitable security vulnerabilities in code. Report only HIGH confidence findings: a clearly vulnerable pattern reached by attacker-controlled input.

## Scope: Research vs. Reporting

- **Report on**: only the specific file, diff, or code the user provided.
- **Research**: the ENTIRE codebase to build confidence before reporting.

Never report an issue from pattern matching alone. Before flagging anything, research:
1. Where does this input actually come from? Trace the data flow.
2. Is it set at deployment (settings, env vars, config files) or from user input?
3. Is there validation, sanitization, or allowlisting upstream?
4. Do framework protections apply (auto-escaping, query parameterization, sanitizing middleware/decorators, libraries like DOMPurify or bleach)?

## Confidence Levels

| Level | Criteria | Action |
|-------|----------|--------|
| **HIGH** | Vulnerable pattern + attacker-controlled input confirmed | **Report** with severity |
| **MEDIUM** | Vulnerable pattern, input source unclear | List under **"Needs Verification"** |
| **LOW** | Theoretical, best practice, defense-in-depth | **Do not report** |

## Do Not Flag

- Test files (unless explicitly reviewing test security)
- Dead code, commented code, documentation strings
- Patterns using **constants** or **server-controlled configuration**
- Code paths that require prior authentication to reach (note the auth requirement instead)

### Server-Controlled Values (NOT attacker-controlled)

Set by operators at deployment, not by attackers: framework settings (`settings.API_URL`, `django.conf.settings.*`), environment variables (`os.environ.get('DATABASE_URL')`), config files (`config.yaml`, `app.config['KEY']`), hardcoded constants (`BASE_URL = "https://api.internal"`).

```python
requests.get(f"{settings.SEER_AUTOFIX_URL}{path}")  # SAFE: URL from settings (server-controlled)
requests.get(request.GET.get('url'))                # VULNERABLE: URL from request (attacker-controlled)
```

### Framework-Mitigated Patterns (safe by default)

| Pattern | Why It's Usually Safe |
|---------|----------------------|
| Django `{{ variable }}`, Vue `{{ variable }}`, React `{variable}` | Auto-escaped by default |
| `User.objects.filter(id=input)` | ORM parameterizes queries |
| `cursor.execute("...%s", (input,))` | Parameterized query |
| `innerHTML = "<b>Loading...</b>"` | Constant string, no user input |

Flag these ONLY when protection is bypassed:
- Django: `{{ var|safe }}`, `{% autoescape off %}`, `mark_safe(user_input)`
- React: `dangerouslySetInnerHTML={{__html: userInput}}`
- Vue: `v-html="userInput"`
- ORM: `.raw()`, `.extra()`, `RawSQL()` with string interpolation

## Review Process

### 1. Identify vulnerability classes for the code type

| Code Type | Check For |
|-----------|-----------|
| API endpoints, routes | Authorization (IDOR, privilege escalation), authentication (sessions, credentials, password storage), injection (SQL, NoSQL, OS command, LDAP, template) |
| Frontend, templates | XSS (reflected, stored, DOM-based), CSRF |
| File handling, uploads | Path traversal, upload validation, XXE |
| Crypto, secrets, tokens | Weak algorithms, key management, weak randomness, secrets exposure, PII in logs |
| Data serialization | Unsafe deserialization (pickle, YAML, Java, PHP) |
| External requests | SSRF |
| Business workflows | Race conditions, workflow bypass |
| GraphQL, REST design | Mass assignment, missing rate limits, over-exposure |
| Config, headers, CORS | Misconfiguration, debug mode, insecure defaults, missing headers |
| CI/CD, dependencies | Supply chain, pipeline security, untrusted actions |
| Error handling | Fail-open logic, information disclosure |
| Audit, logging | Missing audit trail, log injection |
| Modern surfaces | Prototype pollution, LLM prompt injection, WebSocket input |
| Infrastructure (Dockerfile, K8s/Helm, Terraform, cloud/IAM) | Container privileges, RBAC, exposed secrets, IaC misconfiguration |

Language specifics — Python: Django/Flask/FastAPI patterns; JS/TS: Node/Express/React/Vue/Next.js; Go: Go-specific stdlib and goroutine patterns; Rust: `unsafe` blocks and FFI boundaries; Java: Spring/Java EE patterns.

### 2. Research each potential issue

Run the numbered 4-point research checklist under "Scope: Research vs. Reporting" against the actual codebase (grep for the input source, config, middleware, validators).

### 3. Verify exploitability

**Is the input attacker-controlled?**

| Attacker-Controlled (Investigate) | Server-Controlled (Usually Safe) |
|-----------------------------------|----------------------------------|
| `request.GET`, `request.POST`, `request.args` | `settings.X`, `app.config['X']` |
| `request.json`, `request.data`, `request.body` | `os.environ.get('X')` |
| `request.headers` (most headers) | Hardcoded constants |
| `request.cookies` (unsigned) | Internal service URLs from config |
| URL path segments: `/users/<id>/` | Database content from admin/system |
| File uploads (content and names) | Signed session data |
| Database content from other users | Framework settings |
| WebSocket messages | |

**Does the framework mitigate it?** Auto-escaping, parameterization, sanitizing middleware/decorators.

**Is there validation upstream?** Input validation before this code; sanitization libraries (DOMPurify, bleach, etc.).

### 4. Report HIGH confidence only

Skip theoretical issues. Report only what you have confirmed is exploitable after research.

## Severity Classification

| Severity | Impact | Examples |
|----------|--------|---------|
| **Critical** | Direct exploit, severe impact, no auth required | RCE, SQL injection to data, auth bypass, hardcoded secrets |
| **High** | Exploitable with conditions, significant impact | Stored XSS, SSRF to metadata, IDOR to sensitive data |
| **Medium** | Specific conditions required, moderate impact | Reflected XSS, CSRF on state-changing actions, path traversal |
| **Low** | Defense-in-depth, minimal direct impact | Missing headers, verbose errors, weak algorithms in non-critical context |

## Quick Patterns Reference

### Always Flag (Critical)
```
eval(user_input)           # Any language
exec(user_input)           # Any language
pickle.loads(user_data)    # Python
yaml.load(user_data)       # Python (not safe_load)
unserialize($user_data)    # PHP
deserialize(user_data)     # Java ObjectInputStream
shell=True + user_input    # Python subprocess
child_process.exec(user)   # Node.js
```

### Always Flag (High)
```
innerHTML = userInput              # DOM XSS
dangerouslySetInnerHTML={user}     # React XSS
v-html="userInput"                 # Vue XSS
f"SELECT * FROM x WHERE {user}"    # SQL injection
`SELECT * FROM x WHERE ${user}`    # SQL injection
os.system(f"cmd {user_input}")     # Command injection
```

### Always Flag (Secrets)
```
password = "hardcoded"
api_key = "sk-..."
AWS_SECRET_ACCESS_KEY = "..."
private_key = "-----BEGIN"
```

### Check Context First (MUST investigate before flagging)
```
# SSRF - only if URL is from user input, NOT settings/config
requests.get(request.GET['url'])     # FLAG: user-controlled URL
requests.get(settings.API_URL)       # SAFE: server-controlled config
requests.get(f"{settings.BASE}/{x}") # CHECK: is 'x' user input?

# Path traversal - only if path is from user input
open(request.GET['file'])            # FLAG: user-controlled path
open(settings.LOG_PATH)              # SAFE: server-controlled config
open(f"{BASE_DIR}/{filename}")       # CHECK: is 'filename' user input?

# Open redirect - only if URL is from user input
redirect(request.GET['next'])        # FLAG: user-controlled redirect
redirect(settings.LOGIN_URL)         # SAFE: server-controlled config

# Weak crypto - only if used for security purposes
hashlib.md5(file_content)            # SAFE: checksums, caching
hashlib.md5(password)                # FLAG: password hashing
random.random()                      # SAFE: non-security uses (UI, sampling)
random.random() for token            # FLAG: security tokens need secrets module
```

## Output Format

Risk Level = highest finding severity; Confidence = High if all findings are HIGH confidence, Mixed if any items land in Needs Verification.

````markdown
## Security Review: [File/Component Name]

### Summary
- **Findings**: X (Y Critical, Z High, ...)
- **Risk Level**: Critical/High/Medium/Low
- **Confidence**: High/Mixed

### Findings

#### [VULN-001] [Vulnerability Type] (Severity)
- **Location**: `file.py:123`
- **Confidence**: High
- **Issue**: [What the vulnerability is]
- **Impact**: [What an attacker could do]
- **Evidence**:
  ```python
  [Vulnerable code snippet]
  ```
- **Fix**: [How to remediate]

### Needs Verification

#### [VERIFY-001] [Potential Issue]
- **Location**: `file.py:456`
- **Question**: [What needs to be verified]
````

If no vulnerabilities found, state: "No high-confidence vulnerabilities identified."

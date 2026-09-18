---
name: rails-security
description: Use when implementing authentication, authorization, or hardening a Rails application against vulnerabilities. Also applies before deployment to verify security posture, or when reviewing code for mass assignment, XSS, SQL injection, or CSRF risks. Covers strong parameters, Devise, Pundit, security scanning, and deployment checklists.
---

# Rails Security

Guidance for implementing secure Rails applications, covering authentication, authorization, and protection against common web vulnerabilities.

## Core Principles

1. **Defense in depth** — Layer multiple security controls; never rely on a single mechanism
2. **Secure by default** — Leverage Rails' built-in protections (CSRF tokens, output escaping, parameterized queries)
3. **Least privilege** — Grant minimum necessary access at every layer
4. **Fail closed** — Deny access on error; never default to permissive

## Strong Parameters

Always whitelist parameters — this is the first line of defense against mass assignment:

```ruby
def user_params
  params.require(:user).permit(:name, :email, :avatar)
end

# Never do this:
User.create(params[:user])  # Mass assignment vulnerability!

# Never permit sensitive attributes without authorization:
# BAD:  params.require(:user).permit(:name, :email, :admin, :role)
# GOOD: Only permit :admin or :role after verifying the current user is authorized
```

Nested attributes:

```ruby
def order_params
  params.require(:order).permit(
    :customer_name,
    :total,
    line_items_attributes: [:id, :product_id, :quantity, :_destroy]
  )
end
```

## HTTPS Enforcement

Force SSL in production — this is non-negotiable:

```ruby
# config/environments/production.rb
config.force_ssl = true
```

## Quick Reference

| Vulnerability     | Prevention                                   |
| ----------------- | -------------------------------------------- |
| SQL Injection     | Use parameterized queries                    |
| XSS               | Don't use `raw` or `html_safe` on user input |
| CSRF              | Keep `protect_from_forgery` enabled          |
| Mass Assignment   | Use strong parameters                        |
| Session Hijacking | Secure, httponly, same_site cookies          |
| Broken Auth       | Use Devise with secure settings              |
| Broken Access     | Implement Pundit or CanCanCan                |

## Security Scanning

Run these tools regularly and in CI:

```bash
bundle exec brakeman --no-pager        # Static analysis
bundle exec bundler-audit check --update  # Gem CVE check
```

## Pre-Deployment Checklist

- [ ] Secrets in credentials or env vars, `master.key` not in VCS
- [ ] `config.force_ssl = true` in production
- [ ] Secure session config (httponly, secure, same_site)
- [ ] Strong parameters on all actions
- [ ] Authorization on all actions (Pundit `verify_authorized`)
- [ ] Rate limiting configured (Rack::Attack)
- [ ] Security headers set
- [ ] File upload validation
- [ ] Brakeman and bundler-audit passing

## Additional Resources

### Reference Files

For detailed patterns and code examples, consult:

- **`references/owasp-rails.md`** — OWASP Top 10 mapped to Rails: SQL injection, XSS, CSRF, broken auth, and access control patterns with Devise and Pundit
- **`references/auth-patterns.md`** — Authentication deep-dive: password security, session hardening, password reset flows, and secrets management with Rails credentials
- **`references/hardening.md`** — Application hardening: HTTP security headers, file upload security, rate limiting with Rack::Attack, logging security, scanning tools, and deployment checklist

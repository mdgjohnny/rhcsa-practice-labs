# SELinux Context Workflow (RHCSA Exam Tips)

## Finding the Right Context Type

```bash
# Method 1: Check what context a reference directory has
ls -Zd /etc           # Shows etc_t
ls -Zd /var/www/html  # Shows httpd_sys_content_t
ls -Zd /var/log       # Shows var_log_t

# Method 2: Search for context types
semanage fcontext -l | grep httpd
man semanage-fcontext  # Examples section

# Method 3: Use matchpathcon (shows expected context)
matchpathcon /var/www/html
```

## Setting Context Persistently

```bash
# Step 1: Add the rule (use regex for directory trees)
semanage fcontext -a -t httpd_sys_content_t "/webdata(/.*)?"

# Step 2: Apply the rule
restorecon -R -v /webdata
```

## Common Context Types

| Use Case | Context Type | Reference Dir |
|----------|--------------|---------------|
| Web content | httpd_sys_content_t | /var/www/html |
| Samba shares | samba_share_t | - |
| NFS exports | nfs_t or public_content_t | - |
| FTP content | public_content_t | /var/ftp |
| Log files | var_log_t | /var/log |
| Config files | etc_t | /etc |
| Home dirs | user_home_t | /home/user |
| Temp files | tmp_t | /tmp |

## Equivalency (Match Another Directory)

```bash
# Make /mydir behave like /etc
semanage fcontext -a -e /etc /mydir
restorecon -R -v /mydir
```

## Troubleshooting

```bash
# Check current context
ls -Z /path

# Check what context SHOULD be
matchpathcon /path

# Fix context to match policy
restorecon -v /path

# List all custom rules
semanage fcontext -l -C
```

## Packages You May Need to Install

These aren't pre-installed - knowing when/how to install them is part of the exam:

```bash
# SELinux man pages (man ftpd_selinux, man httpd_selinux, etc.)
dnf install selinux-policy-doc

# seinfo command for querying policy
dnf install setools-console

# semanage command (usually pre-installed, but just in case)
dnf install policycoreutils-python-utils
```

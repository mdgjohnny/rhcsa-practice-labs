# Cloud Cost Control

## Built-in Safeguards

| Feature | Protection |
|---------|------------|
| Session timeout | Default 2 hours, max 8 hours |
| Preemptible instances | ~50% cost savings |
| Single session limit | Only 1 active session at a time |
| Graceful shutdown | Cleans up on app restart/stop |
| Startup reconciliation | Terminates orphaned resources on boot |
| Static VMs mode | Reuse VMs instead of create/destroy |

## Estimated Costs (Preemptible ARM)

| Duration | Cost |
|----------|------|
| 1 hour | ~$0.01 |
| 8 hours (max) | ~$0.08 |
| 24/7 (if leaked) | ~$7/month |

## Safety Net Cron Job

Add hourly cleanup for VMs older than 10 hours:

```bash
# Add to crontab -e
0 * * * * /home/exedev/rhcsa-practice-labs/scripts/safety-cleanup.sh >> /var/log/rhcsa-cleanup.log 2>&1
```

## OCI Budget Alerts (Recommended)

Set up in OCI Console:
1. Go to **Billing & Cost Management** → **Budgets**
2. Create budget with threshold (e.g., $10/month)
3. Add alert rule to email when 80% reached

## Manual Cleanup

If something goes wrong:

```bash
# List all project VMs
oci compute instance list --compartment-id $COMPARTMENT \
    --query "data[?\"freeform-tags\".Project=='rhcsa-practice-labs'].{name:\"display-name\",id:id,state:\"lifecycle-state\"}" \
    --output table

# Terminate specific VM
oci compute instance terminate --instance-id <OCID> --force

# Or use the app's API
curl -X DELETE http://localhost:8080/api/sessions/<session-id>
```

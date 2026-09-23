# Infrastructure

Terraform configuration for the disposable Azure runtime. See
[ADR-001](../docs/adr/ADR-001-terraform.md) for the tooling decision and
[ADR-007](../docs/adr/ADR-007-terraform-state-backend.md) for where state lives.

Two resource groups exist, and the distinction matters:

| Resource group | Lifetime | Contents |
|---|---|---|
| `rg-asea-tfstate` | Permanent | Terraform state storage account and container, and nothing else |
| `rg-asea-app` | Disposable | Every application and runtime resource; destroyed after each session |

```text
rg-asea-tfstate
    └── Storage Account
        └── Terraform state only

rg-asea-app
    ├── Azure AI Search
    ├── Azure OpenAI
    ├── Functions
    ├── Storage
    ├── Key Vault
    └── Application resources
```

The state resource group is dedicated to Terraform backend storage. No application
resource belongs in it. A runtime resource placed there survives `terraform destroy`,
which breaks the cost control in
[ADR-006](../docs/adr/ADR-006-disposable-cloud-environment.md) and leaves the durable
group holding things nothing manages.

---

## One-time bootstrap

Terraform cannot create its own state backend, because the backend must exist
before `terraform init` runs. These commands are run once, by hand, and are not
managed by Terraform.

Set the variables first. The storage account name must be globally unique and
3–24 characters, lowercase letters and digits only.

```bash
LOCATION="southeastasia"
STATE_RG="rg-asea-tfstate"
STATE_SA="stasea<unique-suffix>"       # e.g. stasea7f3k2
STATE_CONTAINER="tfstate"
```

### 1. Create the state resource group

```bash
az group create \
  --name "$STATE_RG" \
  --location "$LOCATION"
```

### 2. Create the state storage account

Shared key access is disabled, so the account accepts only Microsoft Entra
tokens and no account key exists to leak or rotate. This is what makes the
backend keyless, per [ADR-004](../docs/adr/ADR-004-keyless-auth.md).

```bash
az storage account create \
  --name "$STATE_SA" \
  --resource-group "$STATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false
```

### 3. Grant yourself data-plane access

RBAC is required before the container can be created, because with shared key
access disabled there is no key to fall back on. Role assignments are eventually
consistent and can take a minute or two to take effect.

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

az role assignment create \
  --assignee-object-id "$USER_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$STATE_RG/providers/Microsoft.Storage/storageAccounts/$STATE_SA"
```

### 4. Create the state container

`--auth-mode login` uses your Entra identity rather than an account key.

```bash
az storage container create \
  --name "$STATE_CONTAINER" \
  --account-name "$STATE_SA" \
  --auth-mode login
```

### 5. Enable blob versioning

So a corrupted or truncated state file can be recovered.

```bash
az storage account blob-service-properties update \
  --account-name "$STATE_SA" \
  --resource-group "$STATE_RG" \
  --enable-versioning true
```

### 6. Create the cost budget

Budgets are a bootstrap concern, not a Terraform concern. If the budget lived in
the main configuration, `terraform destroy` would delete the cost alerts at
exactly the moment they are still needed.

`az consumption budget create` cannot attach notification thresholds, so the
budget is created through the REST API. Thresholds are percentages of the
budget amount: 33.33%, 66.67%, and 100% of $15 give alerts at roughly $5, $10,
and $15. A forecast alert is included so the warning arrives before the limit is
reached rather than after.

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Consumption/budgets/budget-asea-15usd?api-version=2021-10-01" \
  --body @budget.json
```

See `budget.example.json` for the request body. Azure budgets notify; they do not
enforce a hard cap. Teardown remains the actual cost control, per
[ADR-006](../docs/adr/ADR-006-disposable-cloud-environment.md).

### 7. Point Terraform at the backend

```bash
cp backend.hcl.example backend.hcl
# fill in resource_group_name, storage_account_name
terraform init -backend-config=backend.hcl
```

`backend.hcl` is gitignored. It holds resource names, not secrets, but it stays
out of the repository so the configuration is not tied to one subscription.

---

## Normal session

```bash
terraform plan -out=tfplan
terraform apply tfplan
# seed evidence, run, demo, capture results
terraform destroy
```

`terraform destroy` removes the project resource group's contents. It does not
touch the state resource group, which is intentional — see the scope note in
[ADR-006](../docs/adr/ADR-006-disposable-cloud-environment.md).

---

## What is committed and what is not

| Path | Committed | Reason |
|---|---|---|
| `*.tf` | Yes | The configuration is the durable asset |
| `.terraform.lock.hcl` | **Yes** | Pins provider versions; reproducibility is a stated design requirement |
| `backend.hcl.example` | Yes | Template with no values filled in |
| `terraform.tfstate` | **No** | Contains resource attributes and can contain sensitive values |
| `terraform.tfstate.backup` | **No** | Same as above |
| `backend.hcl` | **No** | Environment-specific |
| `*.tfvars` | **No** | Environment-specific; may carry sensitive input |
| `.terraform/` | **No** | Local provider cache, regenerated by `terraform init` |
| `tfplan` | **No** | Binary plan file; can contain sensitive values in plaintext |

State is never committed regardless, because it lives in the remote backend.
The `.gitignore` entries are a second line of defence for the case where someone
runs Terraform with a local backend by accident.

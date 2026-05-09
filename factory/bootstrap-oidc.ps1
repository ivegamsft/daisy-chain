#!/usr/bin/env pwsh
<#
.SYNOPSIS
Bootstrap OIDC federation and GitHub Secrets for modification-lines framework deployment.

.DESCRIPTION
Automates the entire setup process:
1. Detects current Azure session (tenant ID, subscription ID)
2. Creates service principal for GitHub Actions
3. Sets up OIDC federated credentials
4. Stores GitHub Secrets (non-secret identifiers only)
5. Ready for plant-deploy.yml to run

No manual credential entry required - uses current az login session.

.EXAMPLE
./bootstrap-oidc.ps1

.NOTES
Requires:
- az CLI (authenticated via `az login`)
- gh CLI (authenticated via `gh auth login`)
- PowerShell 7+
- Permissions to create service principals in Azure
#>

param(
    [string]$RepositoryOwner = "IBuySpy-Dev",
    [string]$RepositoryName = "app-migration-with-ai",
    [string]$ServicePrincipalName = "github-actions-modification-lines",
    [switch]$DryRun = $false
)

# Color output
function Write-Success { Write-Host -ForegroundColor Green "? $args" }
function Write-Error_ { Write-Host -ForegroundColor Red "? $args" }
function Write-Warning_ { Write-Host -ForegroundColor Yellow "??  $args" }
function Write-Info { Write-Host -ForegroundColor Cyan "??  $args" }

Write-Host ""
Write-Host "??????????????????????????????????????????????????????????????????????"
Write-Host "? OIDC Bootstrap for Modification-Lines Framework Deployment        ?"
Write-Host "??????????????????????????????????????????????????????????????????????"
Write-Host ""

# Step 1: Get current Azure session
Write-Host "STEP 1: Detecting current Azure session..."
Write-Host "????????????????????????????????????????????"

try {
    $account = az account show | ConvertFrom-Json -ErrorAction Stop
    $subscriptionId = $account.id
    $tenantId = $account.tenantId
    $accountName = $account.name
    $userName = $account.user.name
    
    Write-Success "Azure session detected"
    Write-Info "User: $userName"
    Write-Info "Tenant: $accountName"
    Write-Info "Tenant ID: $tenantId"
    Write-Info "Subscription ID: $subscriptionId"
} catch {
    Write-Error_ "Not logged into Azure. Please run: az login"
    exit 1
}

# Step 2: Check GitHub authentication
Write-Host ""
Write-Host "STEP 2: Verifying GitHub authentication..."
Write-Host "???????????????????????????????????????????"

try {
    $ghStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "GitHub CLI authenticated"
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Error_ "Not authenticated to GitHub. Please run: gh auth login"
    exit 1
}

# Step 3: Create service principal
Write-Host ""
Write-Host "STEP 3: Creating service principal..."
Write-Host "????????????????????????????????????"

$servicePrincipalDisplay = "$ServicePrincipalName-$(Get-Random -Maximum 9999)"

try {
    Write-Info "Creating app registration: $servicePrincipalDisplay"
    
    if (-not $DryRun) {
        $app = az ad app create --display-name $servicePrincipalDisplay | ConvertFrom-Json
        $appId = $app.appId
        
        Write-Info "Creating service principal..."
        $sp = az ad sp create --id $appId | ConvertFrom-Json
        $spId = $sp.id
        
        Write-Success "Service principal created"
        Write-Info "App ID: $appId"
        Write-Info "Service Principal ID: $spId"
    } else {
        Write-Warning_ "(DRY RUN) Would create: $servicePrincipalDisplay"
        $appId = "00000000-0000-0000-0000-000000000000"
        $spId = "00000000-0000-0000-0000-000000000000"
    }
} catch {
    Write-Error_ "Failed to create service principal: $_"
    exit 1
}

# Step 4: Set up OIDC federated credentials
Write-Host ""
Write-Host "STEP 4: Setting up OIDC federated credentials..."
Write-Host "??????????????????????????????????????????????????"

$repo = "$RepositoryOwner/$RepositoryName"
$federatedCredentialName = "github-$repo-main"

try {
    Write-Info "Repository: $repo"
    Write-Info "Branch: main"
    Write-Info "Federated credential name: $federatedCredentialName"
    
    if (-not $DryRun) {
        # Create federated credential for main branch
        $credentialConfig = @{
            name        = $federatedCredentialName
            issuer      = "https://token.actions.githubusercontent.com"
            subject     = "repo:$repo :ref:refs/heads/main"
            description = "GitHub Actions OIDC for $repo main branch"
            audiences   = @("api://AzureADTokenExchange")
        } | ConvertTo-Json
        
        Write-Info "Creating federated credential..."
        $credentialConfig | az ad app federated-credential create `
            --id $appId `
            --parameters '@-' | Out-Null
        
        Write-Success "OIDC federated credential created"
        Write-Info "Subject: repo:$repo :ref:refs/heads/main"
        Write-Info "Issuer: https://token.actions.githubusercontent.com"
    } else {
        Write-Warning_ "(DRY RUN) Would create federated credential"
    }
} catch {
    Write-Error_ "Failed to create federated credential: $_"
    exit 1
}

# Step 5: Grant Azure permissions
Write-Host ""
Write-Host "STEP 5: Granting Azure permissions..."
Write-Host "??????????????????????????????????????"

try {
    Write-Info "Granting Contributor role to service principal (required for deployments)"
    
    if (-not $DryRun) {
        az role assignment create `
            --assignee $spId `
            --role "Contributor" `
            --scope "/subscriptions/$subscriptionId" | Out-Null
        
        Write-Success "Contributor role assigned"
    } else {
        Write-Warning_ "(DRY RUN) Would assign Contributor role"
    }
    
    Write-Info "Granting User Access Administrator role (required for Bicep role assignments)"
    Write-Info "  Needed because Bicep templates create Microsoft.Authorization/roleAssignments resources"
    
    if (-not $DryRun) {
        az role assignment create `
            --assignee $spId `
            --role "User Access Administrator" `
            --scope "/subscriptions/$subscriptionId" | Out-Null
        
        Write-Success "User Access Administrator role assigned"
    } else {
        Write-Warning_ "(DRY RUN) Would assign User Access Administrator role"
    }
    
} catch {
    Write-Error_ "Failed to grant permissions: $_"
    exit 1
}

# Step 6: Create GitHub Secrets
Write-Host ""
Write-Host "STEP 6: Setting GitHub Secrets..."
Write-Host "?????????????????????????????????"

$repo = "$RepositoryOwner/$RepositoryName"

try {
    Write-Info "Repository: $repo"
    Write-Info "Creating secrets (non-secret identifiers only)..."
    
    if (-not $DryRun) {
        Write-Host "  Setting AZURE_CLIENT_ID..."
        gh secret set AZURE_CLIENT_ID --body $appId --repo $repo
        
        Write-Host "  Setting AZURE_TENANT_ID..."
        gh secret set AZURE_TENANT_ID --body $tenantId --repo $repo
        
        Write-Host "  Setting AZURE_SUBSCRIPTION_ID..."
        gh secret set AZURE_SUBSCRIPTION_ID --body $subscriptionId --repo $repo
        
        Write-Success "GitHub Secrets created"
        Write-Info "AZURE_CLIENT_ID: $appId"
        Write-Info "AZURE_TENANT_ID: $tenantId"
        Write-Info "AZURE_SUBSCRIPTION_ID: $subscriptionId"
    } else {
        Write-Warning_ "(DRY RUN) Would create GitHub Secrets:"
        Write-Host "  AZURE_CLIENT_ID: $appId"
        Write-Host "  AZURE_TENANT_ID: $tenantId"
        Write-Host "  AZURE_SUBSCRIPTION_ID: $subscriptionId"
    }
} catch {
    Write-Error_ "Failed to create GitHub Secrets: $_"
    exit 1
}

# Summary
Write-Host ""
Write-Host "??????????????????????????????????????????????????????????????????????"
Write-Host "? OIDC Bootstrap Complete                                           ?"
Write-Host "??????????????????????????????????????????????????????????????????????"
Write-Host ""

Write-Success "All setup steps completed successfully!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Verify secrets were created:"
Write-Host "   gh secret list --repo $repo"
Write-Host ""
Write-Host "2. Trigger the deployment workflow:"
Write-Host "   gh workflow run plant-deploy.yml --repo $repo -f plant_name=plant-eastus-dev"
Write-Host ""
Write-Host "3. Monitor the workflow:"
Write-Host "   gh run list --repo $repo --workflow=plant-deploy.yml"
Write-Host ""

if ($DryRun) {
    Write-Warning_ "This was a DRY RUN. No changes were made."
    Write-Host "To perform actual setup, run without -DryRun flag:"
    Write-Host "  ./bootstrap-oidc.ps1"
}

Write-Host ""
Write-Success "Ready to deploy! ??"

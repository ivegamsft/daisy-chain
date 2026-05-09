# IBuySpy Workflow Examples

These workflow files are the IBuySpy-specific deployment workflows used during the dAIsy Chain factory pilot run. They serve as reference implementations showing how to:

- Implement S3/S4/S5 deployment workflows for App Service (Classifieds), IIS VM (Jobs), and Azure Container Apps (TimeTracker, IBuySpy, PetShop)
- Structure hub-side orchestration with SPOKE_PAT cross-repo dispatch
- Implement anti-test-theater smoke tests
- Handle SQL firewall open/grant/close in single jobs

## Usage as Template

Copy the relevant workflow(s) for your app's treatment and deployment target. Replace IBuySpy-specific resource names, resource groups, and spoke repo references with your own.

See [hub-spoke-dispatch.md](../../../docs/factory-process/hub-spoke-dispatch.md) for guardrails.
